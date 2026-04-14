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
local DEFAULT_RACE_GRID_STORED_GUILD_REPORTS_BY_RACE = {
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

local function copyClasses(classes)
  local src = type(classes) == 'table' and classes or {}
  local c = zeroClasses()
  for k, _ in pairs(c) do
    c[k] = tonumber(src[k]) or 0
  end
  return c
end

local function coerceGuildRow(row, defaultRow)
  local src = type(row) == 'table' and row or {}
  return {
    guildName = defaultRow.guildName,
    guildSize = tonumber(src.guildSize) or 0,
    averageLevel = tonumber(src.averageLevel) or 0,
    classes = copyClasses(src.classes),
  }
end

local function buildStoredGuildReportsByRace(savedByRace)
  local out = {}
  local saved = type(savedByRace) == 'table' and savedByRace or {}
  for raceToken, defaults in pairs(DEFAULT_RACE_GRID_STORED_GUILD_REPORTS_BY_RACE) do
    out[raceToken] = {}
    local savedRows = type(saved[raceToken]) == 'table' and saved[raceToken] or {}
    for i = 1, #defaults do
      local defaultRow = defaults[i]
      out[raceToken][i] = coerceGuildRow(savedRows[i], defaultRow)
    end
  end
  return out
end

local function ensureStoredGuildReportsDB()
  RaceLockedDB = RaceLockedDB or {}
  RaceLockedDB.raceGridStoredGuildReportsByRace =
    buildStoredGuildReportsByRace(RaceLockedDB.raceGridStoredGuildReportsByRace)
  G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE = RaceLockedDB.raceGridStoredGuildReportsByRace
end

--- Ensure the race-grid stored rows are present and linked to RaceLockedDB.
function RaceLocked_GuildChampion_EnsureStoredGuildReportsDB()
  ensureStoredGuildReportsDB()
end

--- Persist current in-memory stored rows back to RaceLockedDB.
--- Useful after mutating rows from incoming race-grid channel reports.
function RaceLocked_GuildChampion_PersistStoredGuildReportsByRace()
  RaceLocked_GuildChampion_EnsureStoredGuildReportsDB()
  RaceLockedDB.raceGridStoredGuildReportsByRace = G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE
end

local function normalizeGuildName(name)
  if RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid then
    return RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid(name)
  end
  local s = tostring(name or ''):match('^%s*(.-)%s*$') or ''
  if s == '' then
    return ''
  end
  return string.lower(s)
end

local function applyRowReport(targetRow, report)
  if type(targetRow) ~= 'table' then
    return
  end
  targetRow.guildSize = tonumber(report and report.guildSize) or 0
  targetRow.averageLevel = tonumber(report and report.averageLevel) or 0
  targetRow.classes = copyClasses(report and report.classes)
end

--- Refresh your guild's stored rows from live roster data for each race token.
--- Only rows whose guild name matches your current guild are updated.
--- @param raceTokens string[]
--- @return boolean true when at least one row was updated
function RaceLocked_GuildChampion_UpdateOwnStoredGuildReportsFromRoster(raceTokens)
  RaceLocked_GuildChampion_EnsureStoredGuildReportsDB()
  if not raceTokens or #raceTokens < 1 then
    return false
  end
  if not RaceLocked_GetGuildRaceGridReportForRaceToken or not RaceLocked_GuildChampion_GetNormalizedPlayerGuildName then
    return false
  end
  local ownGuildNorm = RaceLocked_GuildChampion_GetNormalizedPlayerGuildName()
  if ownGuildNorm == '' then
    return false
  end

  local changed = false
  for i = 1, #raceTokens do
    local raceToken = raceTokens[i]
    local rows = G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE and G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE[raceToken]
    if type(rows) == 'table' then
      local report = RaceLocked_GetGuildRaceGridReportForRaceToken(raceToken)
      for _, row in ipairs(rows) do
        if type(row) == 'table' and normalizeGuildName(row.guildName) == ownGuildNorm then
          applyRowReport(row, report)
          changed = true
        end
      end
    end
  end

  if changed then
    RaceLocked_GuildChampion_PersistStoredGuildReportsByRace()
  end
  return changed
end

ensureStoredGuildReportsDB()
