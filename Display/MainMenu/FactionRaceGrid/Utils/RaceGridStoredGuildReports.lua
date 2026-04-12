-- Per-race guild slots for the race grid: hardcoded guild names, numeric fields start at 0.
-- Update `RaceLocked_GuildChampion.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE` from addon messages or other code;
-- the whitelist is derived from these names (see AllowedRaceGridGuildNames.lua).

RaceLocked_GuildChampion = RaceLocked_GuildChampion or {}
local G = RaceLocked_GuildChampion

local function zeroClasses()
  return {
    druids = 0,
    rogues = 0,
    hunters = 0,
    warriors = 0,
    mages = 0,
    priests = 0,
    warlocks = 0,
    paladins = 0,
    shamans = 0,
  }
end

local function guildRow(guildName)
  return {
    guildName = guildName,
    guildSize = 0,
    averageLevel = 0,
    classes = zeroClasses(),
  }
end

--- @type table<string, table[]>
G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE = {
  Human = {
    guildRow('Human Error'),
    guildRow('Honorcore'),
  },
  NightElf = {
    guildRow('ELFCORE'),
  },
  Dwarf = {
    guildRow('STONECORE'),
    guildRow('ROCKCORE'),
  },
  Gnome = {
    guildRow('FOR GNOMEREGAN'),
  },
  Orc = {
    guildRow('ZUGCORE'),
  },
  Troll = {
    guildRow('Hardingo'),
  },
  Tauren = {
    guildRow('HERDCORE'),
  },
  Scourge = {
    guildRow('DEADCORE'),
  },
}
