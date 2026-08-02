-- ps-housing: tabel `properties`
--
-- WAAROM DIT BESTAND BESTAAT
-- De meegeleverde `ps-housing/README - INSTALL INSTRUCTIONS/QBOX/properties.sql`
-- faalt op deze database met:
--
--     SQL Error (1005): Can't create table `qbox`.`properties`
--     (errno: 150 "Foreign key constraint is incorrectly formed")
--
-- De oorzaak is de COLLATIE. Dat originele bestand sluit af met
-- `COLLATE=utf8mb4_unicode_ci`, dus `owner_citizenid` krijgt die collatie mee.
-- De foreign key wijst naar `players`.`citizenid`, en die is op deze stack
-- `varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci` (zie ook
-- ps-mdt/sql/qbcore.sql, dat het overal expliciet zo neerzet).
--
-- MySQL/MariaDB eist dat beide kanten van een foreign key exact hetzelfde type
-- EN dezelfde collatie hebben. utf8mb4_unicode_ci tegen utf8mb4_general_ci is
-- niet hetzelfde, dus weigert hij de tabel aan te maken. Dat is meteen de reden
-- dat ps-housing niets deed: de tabel bestond nooit.
--
-- Hieronder staat de collatie op general_ci, en op de FK-kolom ook nog eens
-- expliciet. Verder identiek aan het origineel.
--
-- Draai dit in plaats van het bestand uit de resource.

CREATE TABLE IF NOT EXISTS `properties` (
    `property_id`     int(11)      NOT NULL AUTO_INCREMENT,

    -- Expliciete charset/collatie: dit is de kolom van de foreign key en die
    -- MOET overeenkomen met players.citizenid. Niet weghalen.
    `owner_citizenid` varchar(50)  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,

    `street`          VARCHAR(100) NULL,
    `region`          VARCHAR(100) NULL,
    `description`     LONGTEXT     NULL,

    `has_access`      JSON NULL DEFAULT (JSON_ARRAY()), -- [citizenid1, citizenid2, ...]
    `extra_imgs`      JSON NULL DEFAULT (JSON_ARRAY()),
    `furnitures`      JSON NULL DEFAULT (JSON_ARRAY()),

    `for_sale`        boolean      NOT NULL DEFAULT 1,
    `price`           int(11)      NOT NULL DEFAULT 0,
    `shell`           varchar(50)  NOT NULL,
    `apartment`       varchar(50)  NULL DEFAULT NULL, -- NULL = het is een huis

    `door_data`       JSON NULL DEFAULT NULL, -- {"x":0.0,"y":0.0,"z":0.0,"h":0.0,"length":0.0,"width":0.0}
    `garage_data`     JSON NULL DEFAULT NULL, -- {"x":0.0,"y":0.0,"z":0.0}, NULL = geen garage
    `zone_data`       JSON NULL DEFAULT NULL,

    PRIMARY KEY (`property_id`),

    CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`)
        REFERENCES `players` (`citizenid`) ON UPDATE CASCADE ON DELETE CASCADE,

    -- Een character kan hooguit een appartement bezitten.
    CONSTRAINT `UQ_owner_apartment` UNIQUE (`owner_citizenid`, `apartment`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- ─────────────────────────────────────────────────────────────────────────────
-- Werkt het nog steeds niet, controleer dan eerst hoe players.citizenid eruitziet:
--
--     SELECT COLUMN_NAME, COLUMN_TYPE, CHARACTER_SET_NAME, COLLATION_NAME
--     FROM information_schema.COLUMNS
--     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players' AND COLUMN_NAME = 'citizenid';
--
-- Staat daar iets anders dan varchar(50) / utf8mb4 / utf8mb4_general_ci, neem dan
-- die waarden over in de `owner_citizenid`-regel hierboven. Beide kanten moeten
-- exact gelijk zijn.
-- ─────────────────────────────────────────────────────────────────────────────
