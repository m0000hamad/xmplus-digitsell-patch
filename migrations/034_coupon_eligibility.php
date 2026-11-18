<?php
declare(strict_types=1);

return static function (PDO $db): void {
    $db->exec('CREATE TABLE IF NOT EXISTS `patch_coupon_rules` (
        coupon_id BIGINT NOT NULL PRIMARY KEY,
        fresh TINYINT(1) NOT NULL DEFAULT 0,
        unique_ip TINYINT(1) NOT NULL DEFAULT 0,
        FOREIGN KEY (coupon_id) REFERENCES `coupon` (id) ON DELETE CASCADE
    ) ENGINE=InnoDB');

    // Match the native code lookup's collation, including case and accent rules.
    $column = $db->query("SHOW FULL COLUMNS FROM `coupon` WHERE Field = 'code'")->fetch(PDO::FETCH_ASSOC);
    $collation = $column['Collation'] ?? '';
    if (!preg_match('/^([a-z0-9]+)_[a-z0-9_]+$/D', $collation, $parts)) {
        throw new RuntimeException('Could not match the native coupon code collation.');
    }
    $charset = $parts[1];

    $routine = $db->prepare('SELECT 1 FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = ? AND ROUTINE_NAME = ?');
    $routine->execute(['FUNCTION', 'digitsell_coupon_eligibility']);
    if (!$routine->fetchColumn()) {
        $db->exec(str_replace(['COUPON_CHARSET', 'COUPON_COLLATION'], [$charset, $collation], <<<'COUPON_ROUTINE'
CREATE FUNCTION `digitsell_coupon_eligibility`(
    input_code TEXT CHARACTER SET COUPON_CHARSET COLLATE COUPON_COLLATION,
    account_id BIGINT UNSIGNED
) RETURNS VARCHAR(8)
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE fresh_only, first_ip TINYINT;
    DECLARE starts_at, ends_at, registered_at DATETIME;
    DECLARE installed VARCHAR(32);
    DECLARE stored_ip VARCHAR(128);
    DECLARE address, alternate VARBINARY(16);
    DECLARE ipv4 BIGINT UNSIGNED;

    IF input_code IS NULL OR input_code = '' THEN
        RETURN NULL;
    END IF;

    SELECT MAX(r.fresh), MAX(r.unique_ip), MAX(c.start_date), MAX(c.expire_date)
    INTO fresh_only, first_ip, starts_at, ends_at
    FROM `patch_coupon_rules` r JOIN `coupon` c ON c.id = r.coupon_id
    WHERE c.id = (SELECT id FROM `coupon` WHERE code = input_code LIMIT 1);
    IF COALESCE(fresh_only, 0) = 0 AND COALESCE(first_ip, 0) = 0 THEN
        RETURN NULL;
    END IF;

    -- The updater restores patch_version on rollback. Dormant rules and
    -- triggers must not enforce settings an older admin page cannot edit.
    SET installed = (SELECT value FROM `settings` WHERE name = 'patch_version' LIMIT 1);
    IF installed IS NULL OR installed NOT REGEXP '^[0-9]+[.][0-9]+[.][0-9]+$' THEN
        RETURN NULL;
    END IF;
    IF (CAST(SUBSTRING_INDEX(installed, '.', 1) AS UNSIGNED),
        CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(installed, '.', 2), '.', -1) AS UNSIGNED),
        CAST(SUBSTRING_INDEX(installed, '.', -1) AS UNSIGNED)) < (1, 38, 52) THEN
        RETURN NULL;
    END IF;

    SELECT MAX(reg_date), MAX(reg_ip) INTO registered_at, stored_ip FROM `user` WHERE id = account_id;
    IF fresh_only = 1 AND (starts_at IS NULL OR starts_at < '1970-01-01 00:00:00'
        OR ends_at IS NULL OR ends_at <= starts_at OR registered_at IS NULL OR registered_at < starts_at) THEN
        RETURN 'fresh';
    END IF;
    IF first_ip = 0 THEN
        RETURN NULL;
    END IF;

    SET address = INET6_ATON(TRIM(stored_ip));
    IF address IS NULL THEN
        RETURN 'ip';
    END IF;
    SET alternate = address;
    IF LENGTH(address) = 4 THEN
        SET alternate = CONCAT(UNHEX('00000000000000000000FFFF'), address);
    ELSEIF IS_IPV4_MAPPED(address) THEN
        SET alternate = RIGHT(address, 4);
    END IF;

    -- A loopback, private or shared carrier address is not a public IP.
    IF LENGTH(address) = 4 OR LENGTH(alternate) = 4 THEN
        SET ipv4 = INET_ATON(INET6_NTOA(RIGHT(address, 4)));
        IF ipv4 IS NULL OR (ipv4 >> 24) IN (0, 10, 127) OR (ipv4 >> 24) >= 224
            OR ipv4 BETWEEN INET_ATON('100.64.0.0') AND INET_ATON('100.127.255.255')
            OR ipv4 BETWEEN INET_ATON('169.254.0.0') AND INET_ATON('169.254.255.255')
            OR ipv4 BETWEEN INET_ATON('172.16.0.0') AND INET_ATON('172.31.255.255')
            OR ipv4 BETWEEN INET_ATON('192.168.0.0') AND INET_ATON('192.168.255.255') THEN
            RETURN 'ip';
        END IF;
    ELSEIF ASCII(LEFT(address, 1)) NOT BETWEEN 32 AND 63 THEN
        RETURN 'ip';
    END IF;

    -- Account ordering is deterministic, even when two accounts try to
    -- redeem concurrently, and applies before either one has paid.
    IF EXISTS (SELECT 1 FROM `user` WHERE role = 0 AND INET6_ATON(TRIM(reg_ip)) IN (address, alternate)
        AND (COALESCE(reg_date, '1970-01-01 00:00:00'), id)
            < (COALESCE(registered_at, '1970-01-01 00:00:00'), account_id)) THEN
        RETURN 'ip';
    END IF;
    RETURN NULL;
END
COUPON_ROUTINE));
    }

    // Native order creation writes directly to the table through the query
    // builder. Check the initial coupon and later assignments or transfers.
    $trigger = $db->prepare('SELECT 1 FROM information_schema.TRIGGERS
        WHERE TRIGGER_SCHEMA = DATABASE() AND TRIGGER_NAME = ?');
    $triggers = [
        'digitsell_coupon_order_insert' => ['INSERT', "NEW.coupon IS NOT NULL AND NEW.coupon <> ''"],
        'digitsell_coupon_order_update' => ['UPDATE', "NEW.coupon IS NOT NULL AND NEW.coupon <> ''
            AND (NOT (NEW.coupon <=> OLD.coupon) OR NOT (NEW.userid <=> OLD.userid))"],
    ];
    foreach ($triggers as $name => [$event, $when]) {
        $trigger->execute([$name]);
        if ($trigger->fetchColumn()) {
            continue;
        }
        $db->exec("CREATE TRIGGER `$name` BEFORE $event ON `orders` FOR EACH ROW
            BEGIN
                IF $when THEN
                    IF `digitsell_coupon_eligibility`(NEW.coupon, NEW.userid) IS NOT NULL THEN
                        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'COUPON_NOT_ELIGIBLE';
                    END IF;
                END IF;
            END");
    }
};
