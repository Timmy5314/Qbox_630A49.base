---@diagnostic disable: undefined-global
--- Storage: one table holding the equipped clothing and the outfits per character.

Db = {}

local TABLE = 'renzu_clothes'

MySQL.ready(function()
    CreateThread(function()
        MySQL.query.await(([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `identifier` VARCHAR(64) NOT NULL,
                `worn` LONGTEXT NULL,
                `outfits` LONGTEXT NULL,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]):format(TABLE))

        lib.print.info('renzu_clothes: database ready')
    end)
end)

--- Reads a single character's row.
---@param identifier string
---@return { worn: table, outfits: table }
function Db.load(identifier)
    local row = MySQL.single.await(('SELECT worn, outfits FROM `%s` WHERE identifier = ?'):format(TABLE), { identifier })

    if not row then
        return { worn = {}, outfits = {} }
    end

    local worn = row.worn and json.decode(row.worn) or {}
    local outfits = row.outfits and json.decode(row.outfits) or {}

    return {
        worn = type(worn) == 'table' and worn or {},
        outfits = type(outfits) == 'table' and outfits or {},
    }
end

---@param identifier string
---@param worn table
function Db.saveWorn(identifier, worn)
    MySQL.prepare(([[
        INSERT INTO `%s` (identifier, worn) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE worn = VALUES(worn)
    ]]):format(TABLE), { identifier, json.encode(worn or {}) })
end

---@param identifier string
---@param outfits table
function Db.saveOutfits(identifier, outfits)
    MySQL.prepare(([[
        INSERT INTO `%s` (identifier, outfits) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE outfits = VALUES(outfits)
    ]]):format(TABLE), { identifier, json.encode(outfits or {}) })
end
