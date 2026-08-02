-- ps-housing: tabel `properties`
--
-- WAAROM DIT BESTAND BESTAAT
-- De meegeleverde `ps-housing/README - INSTALL INSTRUCTIONS/QBOX/properties.sql`
-- faalt op deze database met:
--
--     SQL Error (1005): Can't create table `qbox`.`properties`
--     (errno: 150 "Foreign key constraint is incorrectly formed")
--
-- Errno 150 komt ALTIJD van de foreign key. Er zijn vier mogelijke oorzaken en
-- ze zijn van buitenaf niet te onderscheiden:
--
--   1. verschil in COLLATIE tussen owner_citizenid en players.citizenid
--   2. verschil in TYPE of LENGTE (varchar(50) tegen varchar(46) bijvoorbeeld)
--   3. players.citizenid is niet geindexeerd
--   4. players bestaat niet of is geen InnoDB
--
-- Een eerdere poging zette alleen de collatie goed. Dat was niet genoeg, dus het
-- zit in een van de andere drie.
--
-- DE FOREIGN KEY IS HIER WEGGELATEN.
--
-- Dat is geen omweg om het probleem heen: die sleutel doet maar een ding, en dat
-- is properties opruimen als een character uit de tabel `players` verdwijnt.
-- ps-housing gebruikt hem nergens voor. Zonder sleutel maakt de tabel gewoon
-- aan, en dat is wat er nu moet gebeuren.
--
-- De UNIQUE-sleutel blijft wel staan: die bewaakt de regel dat een character
-- hooguit een appartement bezit, en daar hangt de code wel op.
--
-- Draai dit in plaats van het bestand uit de resource.

CREATE TABLE IF NOT EXISTS `properties` (
    `property_id`     int(11)      NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(50)  NULL,

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

    -- Zoeken op eigenaar gebeurt vaak (getOwnedApartment, de eigen panden van
    -- een speler). Zonder de foreign key komt die index er niet vanzelf.
    KEY `idx_owner` (`owner_citizenid`),

    -- Een character kan hooguit een appartement bezitten. Hier hangt de code op.
    CONSTRAINT `UQ_owner_apartment` UNIQUE (`owner_citizenid`, `apartment`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- ─────────────────────────────────────────────────────────────────────────────
-- OPTIONEEL - de foreign key alsnog toevoegen
--
-- Wil je het opruimen bij het verwijderen van een character toch hebben, kijk dan
-- eerst wat players.citizenid precies is:
--
--     SELECT COLUMN_TYPE, CHARACTER_SET_NAME, COLLATION_NAME
--     FROM information_schema.COLUMNS
--     WHERE TABLE_SCHEMA = DATABASE()
--       AND TABLE_NAME = 'players' AND COLUMN_NAME = 'citizenid';
--
-- Neem die drie waarden exact over in owner_citizenid, en voeg dan toe:
--
--     ALTER TABLE `properties`
--       ADD CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`)
--       REFERENCES `players` (`citizenid`) ON UPDATE CASCADE ON DELETE CASCADE;
--
-- Krijg je dan nog steeds 1005, vraag de echte reden op met:
--
--     SHOW ENGINE INNODB STATUS;
--
-- Onder "LATEST FOREIGN KEY ERROR" staat letterlijk wat er niet matcht.
-- ─────────────────────────────────────────────────────────────────────────────
