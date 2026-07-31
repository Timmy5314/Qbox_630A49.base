--[[
    s4t4n667_moneywash - Qbox-versie voor Los Balos RP.

    Verschillen met het origineel:
      - ESX- en QB-paden volledig weg. Het origineel riep
        exports["qb-core"]:GetCoreObject() aan; die resource draait hier niet,
        dus dat pad crashte.
      - Toegang is niet langer "sleutel of politie", maar "je bent eigenaar van
        een renzu_shops winkel". Witwassen hoort bij wie een dekmantel heeft.
      - Alle bedragen en afstanden worden server-side gecontroleerd. In het
        origineel deed de client de validatie en nam de server het over.
]]

return {
    debug = false,

    -- ── Toegang ──────────────────────────────────────────────────────────
    access = {
        -- Alleen spelers die een renzu_shops winkel bezitten mogen naar
        -- binnen. Server-side gecontroleerd tegen GlobalState.Stores.
        requireShopOwner = true,

        -- Daarnaast een sleutel nodig. De sleutel is te koop via het
        -- management-menu van je eigen winkel.
        requireKey = true,
        keyItem = 'moneywash_key',

        -- Sleutel opnemen bij binnenkomst. Uit: de sleutel blijft.
        removeKey = false,

        -- Target verbergen voor wie geen toegang heeft. Uit betekent: je ziet
        -- de deur wel en krijgt een melding waarom je er niet in mag.
        hideWithoutAccess = false,
    },

    -- ── Wassen ───────────────────────────────────────────────────────────
    washing = {
        requireToken = true,
        tokenItem = 'moneywash_token',

        minAmount = 10000,
        -- Plafond per wasbeurt. Zonder plafond kan iemand in een keer een
        -- fortuin doorspoelen en is de tax betekenisloos.
        maxAmount = 500000,

        duration = 10000,
        taxRate = 0.10,

        dirtyMoney = 'black_money',  -- ox_inventory account-item
        wetMoney = 'wet_bills',
        cleanMoney = 'money',
    },

    drying = {
        duration = 10000,
        maxAmount = 500000,
    },

    -- ── Winkel bij de laundromat ─────────────────────────────────────────
    shop = {
        enabled = true,
        coords = vec4(1129.6237, -988.6730, 45.9730, 116.6544),
        pedModel = `u_m_m_streetart_01`,
        currency = 'black_money',
        items = {
            { label = 'Laundromat Key',   item = 'moneywash_key',   icon = 'fa-key',   price = 25000 },
            { label = 'Laundromat Token', item = 'moneywash_token', icon = 'fa-coins', price = 2500 },
        },
    },

    -- ── Locaties ─────────────────────────────────────────────────────────
    -- Een van deze wordt bij resource-start gekozen. De ingang wisselt dus
    -- per restart.
    exteriors = {
        vec4(1142.34, -986.67, 46.17, 190.0),  -- Mirror Park
        vec4(84.47, -1552.26, 29.66, 320.0),   -- Strawberry
    },

    interior = {
        spawn = vec4(1137.76, -3198.47, -39.67, 41.47),
        wash  = vec3(1122.2819, -3194.0934, -40.3986),
        count = vec3(1116.36, -3194.58, -39.92),
        exit  = vec3(1137.76, -3198.47, -39.67),
    },

    -- Hoe ver je van een machine mag staan. Server-side afgedwongen.
    interactDistance = 3.0,

    blip = {
        enabled = true,
        label = 'Laundromat',
        sprite = 77,
        colour = 3,
        scale = 0.9,
    },
}
