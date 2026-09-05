<?php

namespace App\Http\Models;

final class Ticket extends Model
{
    protected $connection = 'default';
    protected $table = 'tickets';
	protected $guarded = ['id'];

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
