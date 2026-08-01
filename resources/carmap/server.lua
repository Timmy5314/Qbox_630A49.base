--[[
    carmap - serveert de afbeeldingen ON-DEMAND vanaf schijf.

    De client haalt een plaatje op via de server-HTTP-endpoint:
        http://<jouw-server-adres>/carmap/clothes/DLC_MP_APA_F_FEET_3_2.png
        http://<jouw-server-adres>/carmap/items/10ct-gold-chain.png
        http://<jouw-server-adres>/carmap/vehicle/0x11962e49.jpg

    Niets hiervan zit in files{}, dus niets wordt bij het joinen gedownload.
    Alleen wat een speler bekijkt gaat over de lijn.

    ZET IN server.cfg (replicated, zodat de client hem ook kan lezen):
        setr carmap:baseurl "http://<jouw-connect-adres>/carmap"
    Bijvoorbeeld "http://123.45.67.89:30120/carmap". De andere resources
    (renzu_clothes, ox_inventory, renzu_vehicleshop) lezen die convar.
]]

local RESOURCE = GetCurrentResourceName()

-- Alleen deze mappen mogen naar buiten. Alles daarbuiten = 404.
local ALLOWED = { clothes = true, items = true, vehicle = true }

local MIME = {
    png  = 'image/png',
    jpg  = 'image/jpeg',
    jpeg = 'image/jpeg',
    webp = 'image/webp',
    gif  = 'image/gif',
}

SetHttpHandler(function(req, res)
    -- req.path is meestal "/clothes/x.png", maar sommige FiveM-builds laten de
    -- resourcenaam in het pad staan ("/carmap/clothes/x.png"). Beide afvangen.
    local path = req.path or ''
    path = path:gsub('%?.*$', '')            -- querystring eraf
    path = path:gsub('%%20', ' ')            -- simpele url-decode voor spaties
    path = path:gsub('^/' .. RESOURCE .. '/', '/') -- optionele resourcenaam-prefix eraf

    -- Padbeveiliging: geen directory-traversal.
    if path:find('%.%.') or path:find('\\') then
        res.writeHead(400, { ['Content-Type'] = 'text/plain' })
        return res.send('bad path')
    end

    local folder, file = path:match('^/([%w_]+)/([%w%._%-%s]+)$')
    if not folder or not ALLOWED[folder] then
        res.writeHead(404, { ['Content-Type'] = 'text/plain' })
        return res.send('not found')
    end

    local ext = file:match('%.([%w]+)$')
    local mime = ext and MIME[ext:lower()]
    if not mime then
        res.writeHead(404, { ['Content-Type'] = 'text/plain' })
        return res.send('not found')
    end

    -- Van schijf lezen (werkt ook zonder files{}). nil = bestaat niet.
    local data = LoadResourceFile(RESOURCE, folder .. '/' .. file)
    if not data then
        res.writeHead(404, { ['Content-Type'] = 'text/plain' })
        return res.send('not found')
    end

    res.writeHead(200, {
        ['Content-Type']  = mime,
        ['Cache-Control'] = 'public, max-age=2592000', -- 30 dagen in de CEF-cache
    })
    res.send(data)
end)

CreateThread(function()
    local base = GetConvar('carmap:baseurl', '')
    if base == '' then
        print('[carmap] LET OP: convar carmap:baseurl is niet gezet. Zet in server.cfg:')
        print('[carmap]   setr carmap:baseurl "http://<jouw-connect-adres>/carmap"')
        print('[carmap] Zonder die convar laden de kleding/voertuig-afbeeldingen niet.')
    else
        print(('[carmap] afbeeldingen-endpoint actief. Basis: %s'):format(base))
    end
end)
