# murderface-pets op Los Balos RP

Deze resource was al Qbox-native (qbx_core, ox_lib, ox_target, ox_inventory,
oxmysql). Er zat dus geen ESX/QB-tak in om te strippen. Wat er wél moest gebeuren
staat hieronder — de bron staat onaangeraakt in `_external/murderface-pets/`.

## 1. Rassen die niet konden bestaan

Tien van de zesentwintig rassen gebruikten modellen uit streaming-resources die
deze server niet heeft (`dusa_addonpets` en een pdk9-pack). Gecontroleerd: er
staat geen enkele `.yft` of `.ydd` voor in `resources/`. Een ras met een model
dat niet laadt spawnt niet — de speler koopt een hond en er gebeurt niets.

Verwijderd: `dusa_doberman`, `dusa_cane`, `dusa_englishbulldog`, `dusa_sphynx`,
`a_c_poodle_2`, `A_C_Husky_2`, `A_C_Retriever_2`, `A_C_shepherd_2`,
`a_c_westy_2` en `pdk9`.

Wat overblijft zijn zestien rassen op base-game modellen.

Om dezelfde reden staat `Config.leash.enabled` op `false`: de riem hangt aan de
props `leash_model` / `_2` / `_3` uit hetzelfde pack. De drie riem-items zijn
daarom ook niet in ox_inventory geregistreerd.

## 2. De politiehond

Het originele politieras was `pdk9`. Dat is vervangen door de German Shepherd
(`A_C_shepherd`, item `murderface_shepherd`, label **Police K9**), en dat is nu
het **enige** ras met `isK9 = true`. De K9-functies — persoon doorzoeken en
voertuig doorzoeken — zitten daarmee vast aan één hond die alleen de politie kan
krijgen. Rottweiler en de rest zijn gewone huisdieren.

`Config.k9.jobs` staat op `police`, `bcso`, `sasp`. De hond moet bovendien on
duty gebruikt worden.

## 3. Waar je de dieren vandaan haalt

| Wat | Waar |
|---|---|
| Politiehond | job-supply van renzu_jobs, MRPD, prijs 0 |
| Gewone huisdieren | ingebouwde dierenwinkel van deze resource — een admin zet met `/petshop` display-honden neer, spelers kopen ze via ox_target |
| Voer, EHBO, waterfles, halsband, naamplaatje, trimset, hondenhok | renzu_shops `Petshop` |

De ped-winkel van het origineel (`Config.petShop` / `Config.suppliesShop`) blijft
uit. Die vroeg om coördinaten en peds die hier niet gedefinieerd zijn, en de
`buyPet`-callback erachter gaf een item zonder metadata.

De dieren zelf kunnen niet via renzu_shops: elk huisdier is een uniek item met
metadata (hash, naam, level, XP, vacht). Een gewone winkel geeft dat niet mee.
De job-supply kan dat wél, omdat murderface-pets bij het eerste gebruik van een
item zonder hash zelf een pet aanmaakt (`InitPet`).

## 4. Database

De tabellen maakt de resource zelf aan bij het opstarten. Zie
[install/README.md](../../../install/README.md) stap 8.

## 5. Ace permission

Staat in `permissions.cfg`:

```
add_ace group.admin murderface-pets.petshop allow
```

Zonder deze regel doet `/petshop` niets en kun je dus geen dierenwinkel neerzetten.

## 6. Toetsen en commando's

`]` (RBRACKET) opent het huisdier-menu. Commando's: `/sit`, `/come`, `/stay`,
`/heel`, `/speak`, `/lay`, `/paw`, `/petname`, `/petemote`. Geen van die namen
botst met een ander script op deze server (gecontroleerd).
