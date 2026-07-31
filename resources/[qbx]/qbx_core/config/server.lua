return {
    updateInterval = 5, -- how often to update player data in minutes

    money = {
        ---@alias MoneyType 'cash' | 'bank' | 'crypto' | 'black_money'
        ---@alias Money {cash: number, bank: number, crypto: number, black_money: number}
        ---@type Money
        -- black_money = zwart geld. De naam MOET exact matchen met:
        --   1. het ox_inventory item 'black_money' (data/items.lua)
        --   2. de entry in inventory:accounts in ox.cfg
        -- De ox_inventory qbx-bridge mapt accountnaam 1-op-1 op money type
        -- (alleen 'money' wordt op 'cash' gemapt). Wijkt een van de drie af,
        -- dan valt de sync stil zonder foutmelding.
        moneyTypes = { cash = 500, bank = 5000, crypto = 0, black_money = 0 }, -- type = startamount - Add or remove money types for your server (for ex. blackmoney = 0), remember once added it will not be removed from the database!
        dontAllowMinus = { 'cash', 'crypto', 'black_money' }, -- Money that is not allowed going in minus
        paycheckTimeout = 10, -- The time in minutes that it will give the paycheck
        paycheckSociety = false -- If true paycheck will come from the society account that the player is employed at
    },

    player = {
        -- RP boven survival-grind. Deze twee liepen op 4.2 en 3.8 per tick, en
        -- een tick is `updateInterval` = 5 minuten. Van vol naar leeg was dat
        -- ongeveer twee uur voor honger en ruim twee uur voor dorst - je zat dus
        -- elke sessie meermaals te eten in plaats van te spelen.
        --
        -- Nu ongeveer drie keer zo traag: rond de zes uur van vol naar leeg. Je
        -- moet nog steeds eten, maar het onderbreekt geen scene meer.
        --
        -- De andere drie statussen (hygiëne, blaas, darmen) staan in
        -- los_hygiene/shared/config.lua. Dat bestand houdt ook een overzicht van
        -- alle vijf bij, zodat je ze op één plek kunt vergelijken.
        hungerRate = 1.4, -- Rate at which hunger goes down.
        thirstRate = 1.3, -- Rate at which thirst goes down.

        ---@enum BloodType
        bloodTypes = {
            'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
        },

        ---@alias UniqueIdType 'citizenid' | 'AccountNumber' | 'PhoneNumber' | 'FingerId' | 'WalletId' | 'SerialNumber'
        ---@type table<UniqueIdType, {valueFunction: function}>
        identifierTypes = {
            citizenid = {
                valueFunction = function()
                    return lib.string.random('A.......')
                end,
            },
            AccountNumber = {
                valueFunction = function()
                    return 'US0' .. math.random(1, 9) .. 'QBX' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
                end,
            },
            PhoneNumber = {
                valueFunction = function()
                    return math.random(100,999) .. math.random(1000000,9999999)
                end,
            },
            FingerId = {
                valueFunction = function()
                    return lib.string.random('...............')
                end,
            },
            WalletId = {
                valueFunction = function()
                    return 'QB-' .. math.random(11111111, 99999999)
                end,
            },
            SerialNumber = {
                valueFunction = function()
                    return math.random(11111111, 99999999)
                end,
            },
        }
    },

    ---@alias TableName string
    ---@alias ColumnName string
    ---@type [TableName, ColumnName][]
    characterDataTables = {
        {'properties', 'owner'},
        {'bank_accounts_new', 'id'},
        {'playerskins', 'citizenid'},
        {'player_mails', 'citizenid'},
        {'player_outfits', 'citizenid'},
        {'player_vehicles', 'citizenid'},
        {'player_groups', 'citizenid'},
        {'players', 'citizenid'},
        {'npwd_calls', 'identifier'},
        {'npwd_darkchat_channel_members', 'user_identifier'},
        {'npwd_marketplace_listings', 'identifier'},
        {'npwd_messages_participants', 'participant'},
        {'npwd_notes', 'identifier'},
        {'npwd_phone_contacts', 'identifier'},
        {'npwd_phone_gallery', 'identifier'},
        {'npwd_twitter_profiles', 'identifier'},
        {'npwd_match_profiles', 'identifier'},
    }, -- Rows to be deleted when the character is deleted

    server = {
        pvp = true, -- Enable or disable pvp on the server (Ability to shoot other players)
        closed = false, -- Set server closed (no one can join except people with ace permission 'qbadmin.join')
        closedReason = 'Server Closed', -- Reason message to display when people can't join the server
        whitelist = false, -- Enable or disable whitelist on the server
        whitelistPermission = 'admin', -- Permission that's able to enter the server when the whitelist is on
        discord = '', -- Discord invite link
        checkDuplicateLicense = true, -- Check for duplicate rockstar license on join
        ---@deprecated use cfg ACE system instead
        requireOptIn = true, -- Set to false to disable the requirement to use the /optin command before accessing admin commands
        permissions = { 'god', 'admin', 'mod' }, -- Add as many groups as you want here after creating them in your server.cfg
    },

    characters = {
        playersNumberOfCharacters = { -- Define maximum amount of player characters by rockstar license (you can find this license in your server's database in the player table)
            ['license2:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = 5,
        },

        defaultNumberOfCharacters = 3, -- Define maximum amount of default characters (maximum 3 characters defined by default)
    },

    -- this configuration is for core events only. putting other webhooks here will have no effect
    logging = {
        webhook = {
            ['default'] = nil, -- default
            ['joinleave'] = nil, -- default
            ['ooc'] = nil, -- default
            ['anticheat'] = nil, -- default
            ['playermoney'] = nil, -- default
        },
        role = {} -- Role to tag for high priority logs. Roles use <@%roleid> and users/channels are <@userid/channelid>
    },

    persistence = {
        lockState = 'lock', -- 'lock' : vehicle will be locked when spawned, 'unlock' : vehicle will be unlocked when spawned
    },

    giveVehicleKeys = function(src, plate, vehicle)
        return exports.qbx_vehiclekeys:GiveKeys(src, vehicle)
    end,

    setVehicleLock = function(vehicle, state)
        exports.qbx_vehiclekeys:SetLockState(vehicle, state)
    end,

    getSocietyAccount = function(accountName)
        return exports['Renewed-Banking']:getAccountMoney(accountName)
    end,

    removeSocietyMoney = function(accountName, payment)
        return exports['Renewed-Banking']:removeAccountMoney(accountName, payment)
    end,

    ---Paycheck function
    ---@param player Player Player object
    ---@param payment number Payment amount
    sendPaycheck = function (player, payment)
        player.Functions.AddMoney('bank', payment)
        Notify(player.PlayerData.source, locale('info.received_paycheck', payment))
        TriggerEvent('qbx_core:server:onPaycheck', player.PlayerData.source, payment)
    end,
}
