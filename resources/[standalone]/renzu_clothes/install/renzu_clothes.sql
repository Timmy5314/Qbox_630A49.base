-- renzu_clothes v2
--
-- This table is created automatically when the resource starts. You only need
-- to run this file if you prefer doing it by hand, or if the resource has no
-- permission to create tables.

CREATE TABLE IF NOT EXISTS `renzu_clothes` (
    `identifier` VARCHAR(64) NOT NULL,
    `worn` LONGTEXT NULL,
    `outfits` LONGTEXT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────────────────
-- Cleaning up the old (ESX) version. Only run this once you are sure you no
-- longer need the old data.
-- ─────────────────────────────────────────────────────────────────────────
-- DROP TABLE IF EXISTS `renzu_clothes_outfits`;
