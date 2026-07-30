-- Idempotente versie van de ALTER-statements uit
-- resources/[standalone]/renzu_garage/QBCORE_garage.sql
--
-- Het origineel gebruikt kale `ALTER TABLE ... ADD kolom`, wat hard faalt als de
-- kolom al bestaat. Dat maakt het onbruikbaar op een database waar renzu_garage
-- al eens gedraaid heeft. Deze versie voegt alleen toe wat ontbreekt.
--
-- De CREATE TABLE-statements uit dat bestand zijn wel idempotent
-- (IF NOT EXISTS) en kun je gewoon uit het origineel draaien.

DELIMITER $$

DROP PROCEDURE IF EXISTS los_add_column_if_missing $$

CREATE PROCEDURE los_add_column_if_missing(
    IN p_table  VARCHAR(64),
    IN p_column VARCHAR(64),
    IN p_definition VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table
          AND COLUMN_NAME = p_column
    ) THEN
        SET @ddl = CONCAT('ALTER TABLE `', p_table, '` ADD `', p_column, '` ', p_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;

CALL los_add_column_if_missing('player_vehicles', 'impound',    'INT(1) NOT NULL DEFAULT 0');
CALL los_add_column_if_missing('player_vehicles', 'type',       "VARCHAR(32) NOT NULL DEFAULT 'car'");
CALL los_add_column_if_missing('player_vehicles', 'job',        "VARCHAR(32) NOT NULL DEFAULT 'civ'");
CALL los_add_column_if_missing('player_vehicles', 'park_coord', 'LONGTEXT NULL');
CALL los_add_column_if_missing('player_vehicles', 'isparked',   'INT(1) NULL DEFAULT 0');

DROP PROCEDURE IF EXISTS los_add_column_if_missing;
