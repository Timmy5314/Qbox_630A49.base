/**
 * Los Balos RP - Discord-bot
 *
 * Doet twee dingen: rollen synchroniseren met de in-game job/gang, en
 * gang-kanalen alleen zichtbaar maken voor leden van die gang.
 *
 * De FiveM-kant (los_discord) bepaalt WELKE rol bij welke speler hoort. Deze
 * bot kent hem toe. Die scheiding is bewust: rollen zetten vraagt een
 * bot-token, en dat hoort niet op een gameserver.
 *
 * STAAT VAN DIT BESTAND
 * Werkend skelet, nooit tegen een echte Discord-server gedraaid. Reken op een
 * eerste run die stukloopt op iets kleins. Draai met DEBUG=1.
 */

import 'dotenv/config';
import { Client, GatewayIntentBits } from 'discord.js';

const {
  DISCORD_TOKEN,
  GUILD_ID,
  FIVEM_HOST = '127.0.0.1',
  FIVEM_PORT = '30120',
  SYNC_MINUTES = '15',
  DEBUG = '0',
} = process.env;

const debug = DEBUG === '1';
const log = (...args) => console.log('[bot]', ...args);
const dbg = (...args) => debug && console.log('[bot:debug]', ...args);

if (!DISCORD_TOKEN) {
  console.error('[bot] DISCORD_TOKEN ontbreekt. Zie .env.example.');
  process.exit(1);
}

if (!GUILD_ID) {
  console.error('[bot] GUILD_ID ontbreekt.');
  process.exit(1);
}

/**
 * Haalt de rolstand op bij de FiveM-server.
 *
 * los_discord biedt die aan; zonder draaiende server krijg je hier niets en
 * doet de bot simpelweg niets - dat is beter dan rollen intrekken op basis van
 * een lege lijst.
 *
 * @returns {Promise<Record<string, string[]>|null>} discordId -> rol-ID's
 */
async function fetchRoleState() {
  const url = `http://${FIVEM_HOST}:${FIVEM_PORT}/los_discord/roleState`;

  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!response.ok) {
      dbg('rolstand: HTTP', response.status);
      return null;
    }
    return await response.json();
  } catch (error) {
    dbg('rolstand niet op te halen:', error.message);
    return null;
  }
}

/**
 * Alle rol-ID's die deze bot beheert. Alles daarbuiten blijft met rust - je
 * handmatig toegekende rollen raakt hij dus niet aan.
 *
 * @param {Record<string, string[]>} state
 * @returns {Set<string>}
 */
function managedRoles(state) {
  const managed = new Set();
  for (const roles of Object.values(state)) {
    for (const role of roles) managed.add(role);
  }
  return managed;
}

/**
 * Zet de rollen goed voor iedereen in de rolstand.
 *
 * @param {import('discord.js').Guild} guild
 * @param {Record<string, string[]>} state
 */
async function syncRoles(guild, state) {
  const managed = managedRoles(state);
  if (managed.size === 0) {
    dbg('geen beheerde rollen ingesteld, sync overgeslagen');
    return;
  }

  const members = await guild.members.fetch();
  let changed = 0;

  for (const [id, member] of members) {
    const wanted = new Set(state[id] ?? []);

    for (const roleId of managed) {
      const has = member.roles.cache.has(roleId);
      const shouldHave = wanted.has(roleId);

      if (has === shouldHave) continue;

      try {
        if (shouldHave) {
          await member.roles.add(roleId, 'in-game job/gang');
        } else {
          await member.roles.remove(roleId, 'in-game job/gang');
        }
        changed++;
      } catch (error) {
        // Vrijwel altijd: de bot-rol staat lager in de lijst dan de rol die hij
        // probeert te zetten. Zie de README.
        log(`kon rol ${roleId} niet zetten voor ${member.user.tag}: ${error.message}`);
      }
    }
  }

  log(`rol-sync klaar, ${changed} wijziging(en)`);
}

/**
 * Gang-kanalen alleen zichtbaar voor die gang.
 *
 * Een kanaal telt mee als de topic `[gang:<rolId>]` bevat. Zo hoef je geen
 * tweede lijst met kanaal-ID's bij te houden die uit de pas gaat lopen.
 *
 * @param {import('discord.js').Guild} guild
 */
async function syncChannelVisibility(guild) {
  const channels = await guild.channels.fetch();
  let changed = 0;

  for (const [, channel] of channels) {
    if (!channel || !('topic' in channel) || !channel.topic) continue;

    const match = channel.topic.match(/\[gang:(\d+)\]/);
    if (!match) continue;

    const roleId = match[1];

    try {
      await channel.permissionOverwrites.set([
        { id: guild.roles.everyone.id, deny: ['ViewChannel'] },
        { id: roleId, allow: ['ViewChannel'] },
      ], 'gang-kanaal afschermen');
      changed++;
    } catch (error) {
      log(`kon rechten van #${channel.name} niet zetten: ${error.message}`);
    }
  }

  if (changed > 0) log(`kanaalrechten bijgewerkt voor ${changed} kanaal/kanalen`);
}

const client = new Client({
  // Alleen Guilds en GuildMembers. Presence en MessageContent zijn niet nodig
  // en dus niet aangevraagd - minder rechten is minder risico.
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

client.once('clientReady', async () => {
  log(`ingelogd als ${client.user.tag}`);

  const guild = await client.guilds.fetch(GUILD_ID).catch((error) => {
    console.error('[bot] guild niet gevonden:', error.message);
    return null;
  });

  if (!guild) process.exit(1);

  const tick = async () => {
    const state = await fetchRoleState();

    if (!state) {
      dbg('geen rolstand, deze ronde overgeslagen');
      return;
    }

    await syncRoles(guild, state);
    await syncChannelVisibility(guild);
  };

  await tick();
  setInterval(tick, Number(SYNC_MINUTES) * 60_000);
});

client.login(DISCORD_TOKEN);
