--[[
    Zorgt dat `player_vehicles` de kolommen heeft die renzu_garage gebruikt.

    WAAROM DIT BESTAAT
    Deze kolommen stonden in install/02_renzu_garage_columns.sql, te draaien met
    de hand. Op deze server is dat misgegaan: `impound` is nooit aangemaakt,
    terwijl de serverqueries van renzu_garage er 131 keer naar verwijzen. Elke
    garage-query faalde daardoor op "Unknown column 'impound'", en dat is precies
    de "garage werkt niet meer"-klacht.

    De kolommenlijst van player_vehicles is bovendien meermaals met de hand
    toegevoegd en weer weggegooid. Een script dat bij het opstarten controleert
    en aanvult is daar bestand tegen; een los SQL-bestand dat iemand moet
    onthouden niet.

    Draait als eerste van server/*.lua - vandaar de 00-prefix, de manifest laadt
    op naam.

    IDEMPOTENT. Voegt alleen toe wat ontbreekt, wijzigt en verwijdert nooit iets.
]]

--- Kolom -> definitie. Gelijk aan install/02_renzu_garage_columns.sql.
local REQUIRED = {
    { name = 'impound',    definition = 'INT(1) NOT NULL DEFAULT 0' },
    { name = 'type',       definition = "VARCHAR(32) NOT NULL DEFAULT 'car'" },
    { name = 'job',        definition = "VARCHAR(32) NOT NULL DEFAULT 'civ'" },
    { name = 'park_coord', definition = 'LONGTEXT NULL' },
    { name = 'isparked',   definition = 'INT(1) NULL DEFAULT 0' },
}

local TABLE = 'player_vehicles'

---@param column string
---@return boolean?  nil betekent: niet kunnen vaststellen
local function columnExists(column)
    -- pcall omdat een ontbrekende tabel bij oxmysql een exception geeft en geen
    -- nil. Zonder dit sterft de resource hier bij het opstarten.
    local ok, result = pcall(MySQL.scalar.await, [[
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { TABLE, column })

    if not ok then
        lib.print.error(('renzu_garage: kon %s.%s niet controleren: %s')
            :format(TABLE, column, result))
        return nil
    end

    return result ~= nil
end

MySQL.ready(function()
    local tableOk = pcall(MySQL.scalar.await,
        'SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
        { TABLE })

    if not tableOk then
        return lib.print.error(
            ('renzu_garage: tabel `%s` is niet te lezen. Draait qbx_core wel en klopt de ' ..
             'mysql_connection_string in secrets.cfg?'):format(TABLE))
    end

    local added = {}

    for i = 1, #REQUIRED do
        local column = REQUIRED[i]
        local exists = columnExists(column.name)

        if exists == false then
            -- De kolomnaam komt uit deze lijst, niet van buiten, dus string-
            -- concatenatie is hier veilig. Een prepared statement kan geen
            -- identifier binden.
            local ok, err = pcall(MySQL.query.await, ('ALTER TABLE `%s` ADD `%s` %s')
                :format(TABLE, column.name, column.definition))

            if ok then
                added[#added + 1] = column.name
            else
                lib.print.error(('renzu_garage: kon kolom `%s` niet toevoegen: %s')
                    :format(column.name, err))
            end
        end
    end

    if added[1] then
        lib.print.info(('renzu_garage: ontbrekende kolommen toegevoegd aan `%s`: %s')
            :format(TABLE, table.concat(added, ', ')))
    end
end)
