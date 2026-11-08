<?php

namespace App\Http\Models;

final class Ticket extends Model
{
    protected $connection = 'default';
    protected $table = 'tickets';
	protected $guarded = ['id'];

    public function newEloquentBuilder($query)
    {
        return new \App\Tickets\Builder($query);
    }

    public function save(array $options = [])
    {
        return $this->getConnection()->transaction(function () use ($options) {
            if ((int) $this->rootid !== 0) {
                \App\Tickets\Lifecycle::assertOpen((int) ($this->main_id ?: $this->rootid));
            } elseif ($this->exists && $this->isDirty('status') && (int) $this->status !== 0) {
                \App\Tickets\Lifecycle::assertOpen((int) $this->id);
            }
            // The native create handler predates attachments and may omit files.
            if (!$this->exists && !$this->files) {
                $input = $_POST;
                if (($_SERVER['REQUEST_METHOD'] ?? '') === 'PUT') parse_str((string) file_get_contents('php://input'), $input);
                if (isset($input['files']) && is_string($input['files'])) $this->files = $input['files'];
            }
            if ($this->isDirty('files')) {
                \App\Tickets\Lifecycle::validateAttachment((string) $this->files, (int) $this->userid);
            }
            if (!$this->exists) {
                // Serialize all submissions by this author, including concurrent HTTP retries.
                $this->getConnection()->table('user')->where('id', (int) $this->userid)->lockForUpdate()->first();
                $duplicate = $this->getConnection()->table('tickets')
                    ->where('userid', (int) $this->userid)
                    ->where('rootid', (int) $this->rootid)
                    ->where('datetime', '>=', time() - 300)
                    ->whereRaw('BINARY title = ?', [(string) $this->title])
                    ->where('department', (string) $this->department)
                    ->whereRaw('BINARY content = ?', [(string) $this->content])
                    ->whereRaw("COALESCE(files, '') = ?", [(string) $this->files])
                    ->orderBy('id', 'desc')->lockForUpdate()->first();
                if ($duplicate) {
                    $this->setRawAttributes((array) $duplicate, true);
                    $this->exists = true;
                    $this->wasRecentlyCreated = false;
                    return true;
                }
            }
            return parent::save($options);
        });
    }

    public function isClosed()
    {
        $id = (int) ($this->rootid ? $this->main_id : $this->id);
        $root = self::find($id);
        if (!$root) return true;
        $latest = (int) self::where('main_id', $id)->max('datetime');
        return \App\Tickets\Lifecycle::expired($root, $latest);
    }

    public function attachmentUrl()
    {
        $name = (string) $this->files;
        if (\App\Tickets\Lifecycle::attachmentName($name)) {
            return '/xmplus-patch.php?do=ticket.image&file=' . rawurlencode($name);
        }
        return '/uploads/tickets/' . rawurlencode(basename($name));
    }

    public function attachmentDownloadUrl()
    {
        return $this->attachmentUrl() . (\App\Tickets\Lifecycle::attachmentName((string) $this->files) ? '&download=1' : '');
    }

    public function isImage()
    {
        return (bool) preg_match('/\.(jpg|jpeg|png|webp|gif)$/iD', (string) $this->files);
    }

	/*
	 * Ticket bodies are plain text typed into a textarea, but they used to be
	 * printed straight into the page. That collapsed every line break, left URLs
	 * dead, and handed the browser any markup a user cared to type.
	 *
	 * html() escapes first, then turns bare URLs into links. Line breaks and runs
	 * of spaces are preserved by the stylesheet (white-space: pre-wrap) rather
	 * than by <br>, so the message reads exactly as it was written.
	 */
	public function html()
	{
		$text = str_replace(["\r\n", "\r"], "\n", (string) $this->content);
		$text = htmlspecialchars($text, ENT_QUOTES, 'UTF-8');

		$linked = preg_replace_callback(
			'~(?:https?://|www\.)[^\s<]+~iu',
			function ($match) {
				$url = $match[0];

				// punctuation that ends the sentence is not part of the link
				$trailing = '';
				while ($url !== '' && strpos('.,!?)]}', substr($url, -1)) !== false) {
					$trailing = substr($url, -1) . $trailing;
					$url = substr($url, 0, -1);
				}
				if ($url === '') {
					return $match[0];
				}

				// the text is already escaped, so it is safe inside the attribute
				$href = (stripos($url, 'www.') === 0) ? 'http://' . $url : $url;

				return '<a href="' . $href . '" target="_blank" rel="noopener noreferrer nofollow" class="tk-link">'
					. $url . '</a>' . $trailing;
			},
			$text
		);

		return $linked === null ? $text : $linked;
	}

	/*
	 * A short message made only of emoji is shown big, the way a sticker would be.
	 */
	public function isSticker()
	{
		$text = trim((string) $this->content);

		if ($text === '' || mb_strlen($text, 'UTF-8') > 12) {
			return false;
		}

		$emoji = '\x{1F000}-\x{1FAFF}\x{2190}-\x{21FF}\x{2300}-\x{23FF}\x{2600}-\x{27BF}'
			. '\x{2B00}-\x{2BFF}\x{FE0F}\x{FE0E}\x{200D}\x{20E3}\x{E0020}-\x{E007F}';

		return (bool) preg_match('~^(?:[' . $emoji . ']|\s)+$~u', $text)
			&& (bool) preg_match('~[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}]~u', $text);
	}

	/*
	 * True when the message was written by a member of staff.
	 *
	 * The thread cannot just compare userid with the viewer: there is more than one
	 * admin account, so a reply from a colleague would otherwise show up on the
	 * customer's side of the conversation.
	 */
	public function isStaff()
	{
		static $staff = null;

		if ($staff === null) {
			$staff = [];
			foreach (User::where('role', '>', 0)->get(['id']) as $admin) {
				$staff[(int) $admin->id] = true;
			}
		}

		return isset($staff[(int) $this->userid]);
	}

	/*
	 * First line of the message, trimmed - handy for list previews.
	 */
	public function preview($length = 90)
	{
		$text = trim(preg_replace('~\s+~u', ' ', (string) $this->content));

		if (mb_strlen($text, 'UTF-8') <= $length) {
			return $text;
		}

		return mb_substr($text, 0, $length, 'UTF-8') . '…';
	}
}
