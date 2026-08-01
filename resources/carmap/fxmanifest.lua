fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'carmap'
description 'On-demand afbeeldingen-endpoint (kleding/items/voertuigen) - geen join-download'
author 'Los Balos RP'
version '1.0.0'

server_script 'server.lua'

--[[
    BEWUST GEEN files {} voor clothes/ items/ vehicle/.

    Die mappen worden NIET meegedownload door de client (dat zou ~370 MB per
    speler zijn). Ze staan op de server-schijf en worden on-demand geserveerd
    door SetHttpHandler in server.lua - alleen de plaatjes die een speler
    daadwerkelijk bekijkt gaan over de lijn.

    De map-tegels (atlas/satellite/oldschool.webp) horen bij het originele
    carmap-minimap-gedeelte en worden hier NIET gebruikt; laat ze staan of
    verwijder ze, ze doen niets zolang ze niet in een minimap-setup hangen.
]]
