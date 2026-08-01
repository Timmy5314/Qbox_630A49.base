-- Controleert welke verwachte tabellen en kolommen ontbreken.
-- Wijzigt NIETS. Veilig om altijd te draaien.
--
-- Draaien:  mysql -u qboxuser -p qbox < install/01_check_tables.sql
-- Of plak de inhoud in HeidiSQL / phpMyAdmin.

SELECT '=== ONTBREKENDE TABELLEN ===' AS report;

SELECT expected.table_name AS ontbrekende_tabel, expected.bron
FROM (
    -- ps-housing gebruikt runtime alleen `properties`. De tabellen apartments,
    -- houselocations en player_houses worden uitsluitend door de handmatige
    -- migratie-commando's bevraagd en hoeven niet te bestaan.
    SELECT 'properties'          AS table_name, 'ps-housing'        AS bron UNION ALL
    SELECT 'ps_cache_metadata',                 'ps_lib ORM'        UNION ALL
    SELECT 'mdt_data',                          'ps-mdt'            UNION ALL
    SELECT 'mdt_reports',                       'ps-mdt'            UNION ALL
    SELECT 'mdt_bulletin',                      'ps-mdt'            UNION ALL
    SELECT 'mdt_convictions',                   'ps-mdt'            UNION ALL
    SELECT 'mdt_impound',                       'ps-mdt'            UNION ALL
    SELECT 'impound_garage',                    'renzu_garage'      UNION ALL
    SELECT 'private_garage',                    'renzu_garage'      UNION ALL
    SELECT 'parking_meter',                     'renzu_garage'      UNION ALL
    SELECT 'garagekeys',                        'renzu_garage'      UNION ALL
    SELECT 'vehiclekeys',                       'renzu_garage'      UNION ALL
    SELECT 'los_anticheat_flags',               'los_anticheat'     UNION ALL
    SELECT 'los_insurance_policies',            'los_insurance'     UNION ALL
    SELECT 'los_insurance_claims',              'los_insurance'     UNION ALL
    SELECT 'los_billing_invoices',              'los_billing'       UNION ALL
    SELECT 'los_anticheat_bans',                'los_anticheat'
) AS expected
LEFT JOIN information_schema.TABLES actual
    ON actual.TABLE_SCHEMA = DATABASE()
   AND actual.TABLE_NAME = expected.table_name
WHERE actual.TABLE_NAME IS NULL;

SELECT '=== ONTBREKENDE KOLOMMEN player_vehicles (renzu_garage) ===' AS report;

SELECT expected.column_name AS ontbrekende_kolom
FROM (
    SELECT 'impound' AS column_name UNION ALL
    SELECT 'type'    UNION ALL
    SELECT 'job'     UNION ALL
    SELECT 'park_coord' UNION ALL
    SELECT 'isparked'
) AS expected
LEFT JOIN information_schema.COLUMNS actual
    ON actual.TABLE_SCHEMA = DATABASE()
   AND actual.TABLE_NAME = 'player_vehicles'
   AND actual.COLUMN_NAME = expected.column_name
WHERE actual.COLUMN_NAME IS NULL;

SELECT '=== KLAAR ===' AS report;
