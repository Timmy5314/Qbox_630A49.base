# los_wipe

Maandelijkse wipe. Draait op de 1e van de maand, met drie sloten ervoor.

## Wat er weg gaat en wat blijft

**Weg** (elk apart aan/uit): geld, inventories, voertuigen, eigendommen.
**Blijft, altijd:** characters, identiteiten en spelersaccounts. Daar zit
bewust geen schakelaar op — dat is het hele punt van een wipe die spelers niet
wegjaagt.

## De drie sloten

1. `Config.dryRun = true` — alles wordt berekend en gelogd, niets gewijzigd.
2. `Config.armed = false` — ook met `dryRun = false` gebeurt er niets.
3. `Config.dumpConfirmed` moet **de datum van vandaag** zijn (`YYYY-MM-DD`).

Dat derde slot doet twee dingen tegelijk: het maakt scherpzetten een bewuste
handeling, en het voorkomt dat een wipe draait op een dump van vorige maand of
per ongeluk een tweede keer.

## Over de database-dump

**Deze resource kan geen `mysqldump` draaien.** FiveM's Lua heeft geen
`os.execute` en geen shell; dat is een harde grens, geen instelling.

Wat hij wel doet: vlak voor de wipe een JSON-momentopname wegschrijven van
precies de rijen die hij gaat aanraken, naar `snapshots/`. Dat is een vangnet,
**geen vervanging** van een echte dump. Maak die zelf, en zet dan pas
`dumpConfirmed`.

## Commando's

| Commando | Rechten | Wat het doet |
|---|---|---|
| `/wipedryrun` | admin | Toont wat een wipe nu zou doen. Wijzigt niets. |
| `/wipenow` | god | Voert hem direct uit — alleen als alle drie de sloten open staan. |

## Aankondiging

30, 15, 5 en 1 minuut van tevoren in-game, en naar Discord als je de webhook
zet. Die hoort in `secrets.cfg` als convar `los_wipe:webhook`, niet in de config.
