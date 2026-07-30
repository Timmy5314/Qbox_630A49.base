-- ─────────────────────────────────────────────────────────────────────────────
-- renzu_jobs 2.0 (QBox / qbx_core)
--
-- The resource creates these tables automatically on first start, so running
-- this file by hand is optional. It is here for people who prefer to review and
-- apply the schema themselves, and for the migration notes at the bottom.
-- ─────────────────────────────────────────────────────────────────────────────

-- Job treasury (society money)
CREATE TABLE IF NOT EXISTS `renzu_jobs` (
    `name`     VARCHAR(64) NOT NULL,
    `accounts` LONGTEXT NULL,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Job owned vehicles.
-- These belong to the JOB, never to a player. `taken_by` only records which
-- employee currently has it out so it can be returned / tracked.
CREATE TABLE IF NOT EXISTS `renzu_jobs_vehicles` (
    `plate`      VARCHAR(12)  NOT NULL,
    `job`        VARCHAR(64)  NOT NULL,
    `garage`     VARCHAR(64)  NOT NULL DEFAULT 'main',
    `model`      VARCHAR(64)  NOT NULL,
    `label`      VARCHAR(64)  NULL,
    `props`      LONGTEXT     NULL,
    `stored`     TINYINT(1)   NOT NULL DEFAULT 1,
    `taken_by`   VARCHAR(64)  NULL,
    `taken_at`   INT(11)      NULL,
    `created_at` INT(11)      NULL,
    PRIMARY KEY (`plate`),
    KEY `idx_job_garage` (`job`, `garage`),
    KEY `idx_stored` (`stored`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Salary overrides set from the boss menu. Grades without a row here fall back
-- to the `payment` value in qbx_core/shared/jobs.lua.
CREATE TABLE IF NOT EXISTS `renzu_jobs_salaries` (
    `job`    VARCHAR(64) NOT NULL,
    `grade`  INT(11)     NOT NULL,
    `salary` INT(11)     NOT NULL DEFAULT 0,
    PRIMARY KEY (`job`, `grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Turf ownership
CREATE TABLE IF NOT EXISTS `renzu_jobs_turfs` (
    `turf`         VARCHAR(64) NOT NULL,
    `owner`        VARCHAR(64) NULL,
    `owner_label`  VARCHAR(64) NULL,
    `claimed_at`   INT(11)     NULL,
    `vault_at`     INT(11)     NULL,
    PRIMARY KEY (`turf`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- ─────────────────────────────────────────────────────────────────────────────
-- Migration notes (only relevant if you ran renzu_jobs 1.x on ESX)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- 1. The `saveclothes` table is no longer used. Wardrobes are handled by the
--    clothing resource configured in Config.ClothingResource. You can drop it:
--        DROP TABLE IF EXISTS `saveclothes`;
--
-- 2. The `renzu_jobs`.`inventory` and `renzu_jobs`.`garage` columns are gone.
--    Storage is handled by ox_inventory stashes and by renzu_jobs_vehicles.
--    Only run these once you have confirmed the new version works:
--        ALTER TABLE `renzu_jobs` DROP COLUMN `inventory`;
--        ALTER TABLE `renzu_jobs` DROP COLUMN `garage`;
--
-- 3. Job vehicles used to live in `owned_vehicles` with the employee as owner.
--    To hand those over to the job itself, adapt and run something like:
--        INSERT IGNORE INTO renzu_jobs_vehicles (plate, job, garage, model, props, stored, created_at)
--        SELECT ov.plate, 'police', 'main',
--               JSON_UNQUOTE(JSON_EXTRACT(ov.vehicle, '$.model')),
--               ov.vehicle, 1, UNIX_TIMESTAMP()
--        FROM owned_vehicles ov
--        WHERE ov.job = 'police';
--    Check the result before deleting anything from owned_vehicles.
