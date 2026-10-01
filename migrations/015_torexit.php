<?php
/**
 * Exit location per Xray server (tor-geo), chosen on the admin servers page.
 *
 * torexit_node, one row per panel server (servers.id = the node id the Xray
 * agent serves), written by two sides:
 *   managed      1 once an admin picked something on the servers page; while
 *                0 the agent keeps whatever its own agent.json says
 *   want         '' = leave directly from the server, else an ISO country
 *                code the agent turns into a tor-geo exit
 *   want_at      when the admin last changed it
 *   report_json  what the node's agent reported last (tor-geo state, the
 *                current exit and its IP, the countries it can offer)
 *   seen_at      when that report came
 *
 * The agent (node/xray/xray-agent.py from 1.2.0) calls
 * xmplus-patch.php?do=torexit.sync every minute with the panel's API key.
 */
return static function (PDO $db): void {
    $db->exec(
        "CREATE TABLE IF NOT EXISTS `torexit_node` (
            `server_id`   INT UNSIGNED NOT NULL,
            `managed`     TINYINT(1) NOT NULL DEFAULT 0,
            `want`        VARCHAR(2) NOT NULL DEFAULT '',
            `want_at`     INT UNSIGNED NOT NULL DEFAULT 0,
            `report_json` MEDIUMTEXT NULL,
            `seen_at`     INT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`server_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
    );
};
