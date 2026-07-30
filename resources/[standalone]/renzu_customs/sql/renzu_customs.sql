-- renzu_customs 2.0 :: shop parts storage
-- Import this once. `player_vehicles` already exists in qbx_core.

CREATE TABLE IF NOT EXISTS `renzu_customs` (
    `shop` VARCHAR(64) NOT NULL,
    `inventory` LONGTEXT NULL DEFAULT NULL,
    PRIMARY KEY (`shop`) USING BTREE
) COLLATE = 'utf8mb4_general_ci' ENGINE = InnoDB;
