<?php
/**
 * One-off: fix ghost reservation notices, e.g. admin m0000hamad's.
 *
 * A "reserved" notice is only meaningful while its reservation is
 * still waiting (status 1). Cancelled (3), started (2), pending (0)
 * or deleted (row gone) rows leave the notice behind with seen=0 -
 * and a deleted row is exactly what the banner query cannot hide on
 * its own for accounts that have not loaded 1.25.3 yet. Mark such
 * notices seen; no money moves, the reservation is already settled.
 */
return static function (PDO $db): void {
    try {
        $db->prepare("
            UPDATE reserve_notice n
            LEFT JOIN plan_reserve r ON CAST(SUBSTRING(n.ref, 3) AS UNSIGNED) = r.id
            SET n.seen = 1
            WHERE n.seen = 0
              AND n.kind = 'reserved'
              AND (r.id IS NULL OR r.status <> 1)
        ")->execute();
    } catch (Throwable $error) {
        // tables missing (fresh install): nothing to fix
    }
};
