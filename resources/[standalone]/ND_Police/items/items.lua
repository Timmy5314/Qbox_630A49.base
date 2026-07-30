return {
    -- the shield requires the ND_GunAnims resource, remove this item if you don't have it.
    ["shield"] = {
        label = "Police shield",
        weight = 8000,
        stack = false,
        consume = 0,
        client = {
            export = "ND_Police.useShield",
            add = function(total)
                if total > 0 then
                        pcall(function() return exports["ND_Police"]:hasShield(true) end)
                    end
                end,
            remove = function(total)
                if total < 1 then
                    pcall(function() return exports["ND_Police"]:hasShield(false) end)
                end
            end
        }
    },
    ["spikestrip"] = {
        label = "Spikestrip",
        weight = 500,
        client = {
            export = "ND_Police.deploySpikestrip"
        }
    },
    ["cuffs"] = {
        label = "Handcuffs",
        weight = 150,
        client = {
            export = "ND_Police.cuff"
        }
    },
    ["zipties"] = {
        label = "Zipties",
        weight = 10,
        client = {
            export = "ND_Police.ziptie"
        }
    },
    -- the hotwire export was NDCore only; on qbox this item just cuts zipties.
    ["tools"] = {
        label = "Tools",
        description = "Can be used to cut zipties.",
        weight = 800,
        consume = 0,
        stack = true,
        close = true,
        client = {
            event = "ND_Police:unziptie"
        }
    },
    ["handcuffkey"] = {
        label = "Handcuff key",
        weight = 10,
        client = {
            export = "ND_Police.uncuff"
        }
    },
    ["casing"] = {
        label = "Bullet Casing"
    },
    ["projectile"] = {
        label = "Projectile"
    },
}
