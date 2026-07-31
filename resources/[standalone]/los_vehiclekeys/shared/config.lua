--[[
    los_vehiclekeys - sleutels als echt ox_inventory-item.

    WAAROM ERNAAST EN NIET ERIN
    qbx_vehiclekeys werkt met een `keysList` in de statebag van de speler, op
    sessionId van het voertuig. Dat is de gate waar alles op leunt:
    GetIsVehicleAccessible -> HasKeys -> keysList. Die logica herschrijven raakt
    ook carjacking, lockpicken, hotwiren en de politie-alert.

    Deze resource laat dat systeem staan en zet er een laag boven: het ITEM
    bepaalt wie een sleutel hoort te hebben, en zodra iemand met dat item achter
    het stuur kruipt geeft hij de sleutels door aan qbx_vehiclekeys. De sleutel
    is daarmee iets dat je kunt verliezen, afpakken en inleveren, zonder dat er
    aan de bestaande gate iets verandert.

    WAT DE SPELER MERKT
      kopen bij renzu_vehicleshop  -> sleutel in je zak
      wegzetten in renzu_garage    -> sleutel ingeleverd
      uithalen uit renzu_garage    -> sleutel terug
      job- of gangvoertuig         -> tijdelijke sleutel, verdwijnt vanzelf

    LET OP
    Het item is de bron voor voertuigen die IEMAND toebehoren. Een gestolen auto
    hotwiren blijft werken zoals het werkte - daar komt geen item aan te pas.
]]

Config = {}

Config.debug = false

--- Het ox_inventory-item. Metadata: plate, model, label, en optioneel expires.
Config.item = 'vehiclekey'

--- Maximale afstand waarop de server een sleutelaanvraag nog accepteert.
--- Ruim genomen: de speler zit in het voertuig, maar het middelpunt van een
--- vrachtwagen ligt verder weg dan je zou denken.
Config.maxDistance = 12.0

--- Seconden die een tijdelijke sleutel (job- en gangvoertuigen) meegaat.
--- 0 = niet automatisch verlopen.
Config.temporaryLifetime = 4 * 3600

return Config
