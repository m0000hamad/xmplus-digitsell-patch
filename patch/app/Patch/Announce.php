<?php
/**
 * Announcements - two independent broadcast campaigns, controlled from the
 * admin notices page.
 *
 * Included by public/xmplus-patch.php after requireAdmin(), in its global
 * scope, and borrows its helpers: db(), fail(), done(), setting(), putSetting()
 * and requireToken(). Every path ends in done() or fail().
 *
 *   campaign 1 (c1)  the notice: the title and body written in the notice form,
 *                    with the three channel switches that replaced the single
 *                    "Send Notice" select. Saving a notice keeps a copy here
 *                    and queues it once.
 *   campaign 2 (c2)  the dashboard invite nudge: whether it is shown at all,
 *                    the message it broadcasts, and the same three channels.
 *
 * Nothing is sent here: the switches only decide, and stamping a campaign
 * queues it. bin/announce.php (App\Jobs\AnnounceJob) does the sending, a batch
 * per run, each customer claimed first so nobody is told twice. "Group" is one
 * post, in the chat set as announce_group_id.
 */

declare(strict_types=1);

const ANNOUNCE_SETTING = 'announce_campaigns';
const ANNOUNCE_GROUP_SETTING = 'announce_group_id';
const ANNOUNCE_POPUP_SETTING = 'invite_popup';
const ANNOUNCE_DEFAULT_INVITE = "🎁 دوستانت را دعوت کن، ارزان‌تر تمدید کن!\n"
    . "از هر خرید دوستانت %percent% درصد پورسانت می‌گیری و اشتراک بعدیت را با تخفیف می‌خری.\n\n"
    . "👉 لینک دعوت اختصاصی‌ات در پنل، بخش «دعوت از دوستان»: %site%";

function announceDefaults(): array
{
    return [
        'c1' => ['on' => 1, 'tg' => 1, 'mail' => 1, 'grp' => 0, 'title' => '', 'body' => '',
            'stamp' => 0, 'sent_stamp' => 0, 'grp_stamp' => 0, 'sent_at' => 0, 'sent_users' => 0,
            'updated_at' => 0],
        'c2' => ['on' => 1, 'tg' => 1, 'mail' => 1, 'grp' => 0, 'popup' => 1, 'text' => '',
            'stamp' => 0, 'sent_stamp' => 0, 'grp_stamp' => 0, 'sent_at' => 0, 'sent_users' => 0,
            'updated_at' => 0],
    ];
}

function announceMap(): array
{
    $decoded = json_decode((string) setting(ANNOUNCE_SETTING, ''), true);
    $map = is_array($decoded) ? $decoded : [];
    $out = [];

    foreach (announceDefaults() as $key => $default) {
        $out[$key] = array_merge($default, isset($map[$key]) && is_array($map[$key]) ? $map[$key] : []);
    }

    return $out;
}

function announceSaveMap(array $map): void
{
    putSetting(ANNOUNCE_SETTING, (string) json_encode($map, JSON_UNESCAPED_UNICODE));
}

function announceFlag($value): int
{
    return !empty($value) && $value !== '0' ? 1 : 0;
}

/** the message campaign 2 will broadcast, with its placeholders filled in */
function announceInviteText(array $entry): string
{
    $text = trim((string) ($entry['text'] ?? ''));

    if ($text === '') {
        $text = ANNOUNCE_DEFAULT_INVITE;
    }

    $site = rtrim((string) setting('appName', ''), '/');

    return str_replace(
        ['%percent%', '%site%'],
        [(string) setting('commission', ''), $site],
        $text
    );
}

/** how many customers a broadcast would reach right now */
function announceAudience(): int
{
    $statement = db()->prepare('SELECT COUNT(*) FROM user WHERE role = 0');
    $statement->execute();

    return (int) $statement->fetchColumn();
}

/*
 * The chat the group channel posts in. Ours wins once it exists; before that
 * the panel's own channel / admin chat is offered, so the switch works out of
 * the box. The job resolves it the same way.
 */
function announceGroupId(): string
{
    $own = setting(ANNOUNCE_GROUP_SETTING, null);

    if ($own !== null && $own !== false) {
        return trim((string) $own);
    }

    foreach (['promo_channel_id', 'telegramgroup', 'TGGroupID', 'telegramchatid'] as $name) {
        $value = trim((string) setting($name, ''));

        if ($value !== '') {
            return $value;
        }
    }

    return '';
}

/* the settings card: the campaigns, the group target and the token its buttons need */
function announceState(): void
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    $map = announceMap();
    // the popup switch is mirrored into its own row so a user template can read it
    $popup = (int) setting(ANNOUNCE_POPUP_SETTING, $map['c2']['popup'] ? '1' : '0');

    done([
        'token'    => $_SESSION['patch_csrf'],
        'group'    => announceGroupId(),
        'audience' => announceAudience(),
        'popup'    => $popup,
        'invite'   => announceInviteText($map['c2']),
        'c1'       => $map['c1'],
        'c2'       => $map['c2'],
    ]);
}

function announceCampaignKey($raw): string
{
    $key = (string) $raw;

    if (!in_array($key, ['c1', 'c2'], true)) {
        fail('unknown campaign');
    }

    return $key;
}

/* one campaign's switches and text, saved without sending unless $queue */
function announceSave(bool $queue): void
{
    requireToken();

    $key = announceCampaignKey($_POST['campaign'] ?? '');
    $map = announceMap();
    $entry = $map[$key];

    $entry['tg']   = announceFlag($_POST['tg'] ?? 0);
    $entry['mail'] = announceFlag($_POST['mail'] ?? 0);
    $entry['grp']  = announceFlag($_POST['grp'] ?? 0);
    $entry['on']   = announceFlag($_POST['on'] ?? 1);

    if ($key === 'c2') {
        $entry['popup'] = announceFlag($_POST['popup'] ?? 0);
        $entry['text']  = mb_substr(trim((string) ($_POST['text'] ?? '')), 0, 2000);
        putSetting(ANNOUNCE_POPUP_SETTING, (string) $entry['popup']);
    } elseif (array_key_exists('title', $_POST) || array_key_exists('body', $_POST)) {
        // the card only sends channels; the notice form also sends the text
        $entry['title'] = mb_substr(trim(strip_tags((string) ($_POST['title'] ?? ''))), 0, 200);
        $entry['body']  = mb_substr(trim((string) ($_POST['body'] ?? '')), 0, 20000);
    }

    if (array_key_exists('group', $_POST)) {
        putSetting(ANNOUNCE_GROUP_SETTING, trim((string) $_POST['group']));
    }

    if ($queue && ($entry['tg'] || $entry['mail'] || $entry['grp'])) {
        $entry['stamp'] = (int) $entry['stamp'] + 1;
    }

    $entry['updated_at'] = time();
    $map[$key] = $entry;
    announceSaveMap($map);

    done([
        'campaign' => $key,
        'entry'    => $entry,
        'queued'   => (int) $entry['stamp'] > (int) $entry['sent_stamp'],
    ]);
}

/* the notice form: keep its text as campaign 1 and queue it when a channel is on */
function announceNotice(): void
{
    requireToken();

    $map = announceMap();
    $entry = $map['c1'];
    $entry['title'] = mb_substr(trim(strip_tags((string) ($_POST['title'] ?? ''))), 0, 200);
    $entry['body']  = mb_substr(trim((string) ($_POST['body'] ?? '')), 0, 20000);
    $entry['tg']    = announceFlag($_POST['tg'] ?? 0);
    $entry['mail']  = announceFlag($_POST['mail'] ?? 0);
    $entry['grp']   = announceFlag($_POST['grp'] ?? 0);
    $entry['on']    = 1;

    if ($entry['tg'] || $entry['mail'] || $entry['grp']) {
        $entry['stamp'] = (int) $entry['stamp'] + 1;
    }

    $entry['updated_at'] = time();
    $map['c1'] = $entry;
    announceSaveMap($map);

    done(['queued' => (int) $entry['stamp'] > (int) $entry['sent_stamp']]);
}

// ---------------------------------------------------------------- dispatch

$announceAction = substr((string) ($_GET['do'] ?? ''), strlen('announce.'));

if (in_array($announceAction, ['save', 'send', 'notice'], true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($announceAction) {
    case 'state':
        announceState();
    case 'save':
        announceSave(false);
    case 'send':
        announceSave(true);
    case 'notice':
        announceNotice();
}

fail('unknown announcement action');
