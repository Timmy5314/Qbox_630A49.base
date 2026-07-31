-- los_insurance
-- Idempotent: veilig om meerdere keren te draaien.

CREATE TABLE IF NOT EXISTS `los_insurance_policies` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid`  VARCHAR(64)  NOT NULL,
    `type`       ENUM('medical','vehicle') NOT NULL,

    -- Alleen gevuld bij type = 'vehicle'.
    `plate`      VARCHAR(16)  DEFAULT NULL,

    `premium`    INT UNSIGNED NOT NULL DEFAULT 0,
    `expires`    INT UNSIGNED NOT NULL COMMENT 'unix timestamp',
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_expires` (`expires`),

    -- Een burger heeft hooguit een lopende zorgpolis, en per kenteken hooguit
    -- een lopende autopolis. Zonder deze sleutel kun je dezelfde polis twee
    -- keer kopen en betaal je dubbel.
    UNIQUE KEY `uniq_policy` (`citizenid`, `type`, `plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `los_insurance_claims` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid`  VARCHAR(64)  NOT NULL,
    `type`       ENUM('medical','vehicle') NOT NULL,
    `plate`      VARCHAR(16)  DEFAULT NULL,
    `amount`     INT UNSIGNED NOT NULL DEFAULT 0,
    `reason`     VARCHAR(128) DEFAULT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
