# Discord-bot — Los Balos RP

Het losse Node-proces naast de server. Alles wat de Discord API nodig heeft —
rollen toekennen, kanaalrechten zetten — kan een FiveM-server niet zelf. Daar
heb je een bot-token voor, en dat hoort niet op een gameserver.

De FiveM-kant is `resources/[standalone]/los_discord`. Die logt naar webhooks en
bepaalt **welke** rol bij welke speler hoort; deze bot **kent hem toe**.

---

## Wat jij moet doen

Ik kan dit niet voor je doen — het vraagt een account en een token.

1. Ga naar <https://discord.com/developers/applications> → **New Application**.
2. Tab **Bot** → **Add Bot** → **Reset Token** → kopieer het token.
3. Zet onder **Privileged Gateway Intents** aan:
   - **Server Members Intent** (nodig om leden en hun rollen te zien)
   - Presence en Message Content zijn **niet** nodig. Laat ze uit.
4. Tab **OAuth2 → URL Generator**: scope `bot`, permissies **Manage Roles** en
   **Manage Channels**. Open de gegenereerde URL en voeg de bot toe aan je
   server.
5. In Discord: sleep de bot-rol in de rollenlijst **boven** alle rollen die hij
   moet kunnen toekennen. Een bot kan geen rol geven die boven zijn eigen rol
   staat — dat is de meest gemaakte fout.
6. Maak de rollen aan, kopieer hun ID's (rechtsklik → Copy ID, met
   ontwikkelaarsmodus aan) en vul ze in bij `Config.roles` in
   `los_discord/shared/config.lua`.

> **Plak het token nergens in een chat.** Zet het zelf in `.env`; dat bestand
> staat in `.gitignore`.

---

## Installeren

```bash
cd discord-bot
cp .env.example .env
# vul .env in
npm install
npm start
```

## .env

| Sleutel | Wat |
|---|---|
| `DISCORD_TOKEN` | het bot-token |
| `GUILD_ID` | `1067817202578890802` |
| `FIVEM_HOST` | host van je server, meestal `127.0.0.1` |
| `FIVEM_PORT` | de HTTP-poort van je server (`30120`) |
| `SYNC_MINUTES` | hoe vaak er gesynchroniseerd wordt |

---

## Wat de bot doet

**Rol-sync, beide richtingen.** Hij haalt de rolstand op bij de FiveM-server en
zet Discord-rollen bij en af. Rollen die niet in `Config.roles` staan raakt hij
niet aan — je handmatige rollen blijven dus met rust.

**Kanaalzichtbaarheid.** Gang-kanalen krijgen een permissie-override zodat
alleen leden van die gang ze zien. Ballas ziet geen Vagos-kanaal.

## Wat de bot bewust NIET doet

- **Geen berichten van spelers doorgeven.** De opdracht noemde NPWD-berichten
  loggen. Het meelezen van privéberichten tussen spelers is iets anders dan
  loggen dát er iets gebeurde. Wil je het toch, bouw het dan bewust en vertel je
  spelers dat het gebeurt.
- **Geen identifiers.** De FiveM-kant strijkt license, steam, discord en fivem
  uit elke tekst voordat hij hem verstuurt.
- **Geen bans of kicks.** Dat hoort bij je admintooling, niet bij een
  rollen-synchroniseerder.

---

## Nog niet af

De bot in `src/` is een **werkend skelet**: rol-sync en kanaalrechten staan erin,
maar niets ervan heeft tegen een echte Discord-server gedraaid. Er is ook geen
FiveM-server geweest om de rolstand bij op te halen.

Reken erop dat de eerste run stukloopt op iets kleins — een rol-ID dat niet
klopt, de bot-rol te laag in de lijst, of een HTTP-endpoint dat je server niet
open heeft staan. Draai hem met `DEBUG=1` en lees wat hij zegt.
