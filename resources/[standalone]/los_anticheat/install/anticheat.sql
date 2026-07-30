-- los_anticheat tabellen.
-- Idempotent: veilig om meerdere keren te draaien.

CREATE TABLE IF NOT EXISTS `los_anticheat_flags` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`    VARCHAR(64)  DEFAULT NULL,
    `citizenid`  VARCHAR(64)  DEFAULT NULL,
    `name`       VARCHAR(64)  DEFAULT NULL,
    `check_name` VARCHAR(48)  NOT NULL,
    `points`     SMALLINT     NOT NULL DEFAULT 0,
    `detail`     TEXT         DEFAULT NULL,
    `meta`       LONGTEXT     DEFAULT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_license` (`license`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_check` (`check_name`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `los_anticheat_bans` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license`    VARCHAR(64)  NOT NULL,
    `reason`     VARCHAR(255) NOT NULL,
    `evidence`   LONGTEXT     DEFAULT NULL,
    `expires`    INT UNSIGNED DEFAULT NULL COMMENT 'unix timestamp, NULL = permanent',
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_license` (`license`),
    KEY `idx_expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
