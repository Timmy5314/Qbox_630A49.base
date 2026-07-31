-- los_billing
-- Idempotent: veilig om meerdere keren te draaien.

CREATE TABLE IF NOT EXISTS `los_billing_invoices` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,

    `citizenid`     VARCHAR(64)  NOT NULL COMMENT 'ontvanger',
    `sender_job`    VARCHAR(64)  NOT NULL,
    `sender_name`   VARCHAR(128) NOT NULL COMMENT 'naam van de medewerker, voor de audit',
    `sender_cid`    VARCHAR(64)  NOT NULL,

    `amount`        INT UNSIGNED NOT NULL COMMENT 'wat de speler zelf nog moet betalen',
    `interest`      INT UNSIGNED NOT NULL DEFAULT 0,
    `covered`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'door verzekering betaald',

    `reason`        VARCHAR(190) NOT NULL,
    `unrefusable`   TINYINT(1)   NOT NULL DEFAULT 0,

    `status`        ENUM('open','paid','refused') NOT NULL DEFAULT 'open',

    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_status` (`status`),
    KEY `idx_sender` (`sender_cid`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
