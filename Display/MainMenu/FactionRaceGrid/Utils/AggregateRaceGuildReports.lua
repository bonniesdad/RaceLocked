RaceLocked_GuildChampion = RaceLocked_GuildChampion or {}
local G = RaceLocked_GuildChampion

--- Comma-separated guild slot names for this race (always from the store; never depends on merge/live).
--- @param raceToken string
--- @return string
function RaceLocked_GuildChampion_HardcodedGuildNamesTextForRace(raceToken)
  local names = {}
  local rows = G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE and G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE[raceToken]
  if type(rows) == 'table' then
    for _, e in ipairs(rows) do
      if type(e) == 'table' and e.guildName and e.guildName ~= '' then
        names[#names + 1] = e.guildName
      end
    end
  end
  return table.concat(names, ', ')
end

local function zeroClassesAggregate()
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

--- @param entries table[] guild report rows for one race
--- @return table|nil guildNamesText, averageLevel, classes
function RaceLocked_GuildChampion_AggregateGuildsForRace(entries)
  if not entries or #entries < 1 then
    return nil
  end
  local totalMembers = 0
  local weightedSum = 0
  local names = {}
  local classes = {
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
  for _, e in ipairs(entries) do
    local sz = tonumber(e.guildSize) or 0
    local av = tonumber(e.averageLevel) or 0
    if sz > 0 then
      totalMembers = totalMembers + sz
      weightedSum = weightedSum + av * sz
    end
    if e.guildName and e.guildName ~= '' then
      names[#names + 1] = e.guildName
    end
    local c = e.classes
    if type(c) == 'table' then
      for k, _ in pairs(classes) do
        classes[k] = classes[k] + (tonumber(c[k]) or 0)
      end
    end
  end
  return {
    guildNamesText = table.concat(names, ', '),
    averageLevel = totalMembers > 0 and (weightedSum / totalMembers) or nil,
    classes = classes,
  }
end

--- Aggregate directly from stored guild rows (DB-backed source of truth).
--- @param raceToken string
--- @return table|nil
function RaceLocked_GuildChampion_GetAggregatedMockForRace(raceToken)
  RaceLocked_GuildChampion_EnsureRaceGridAllowedGuildNamesBuilt()
  local stored = G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE and G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE[raceToken]
  local agg = RaceLocked_GuildChampion_AggregateGuildsForRace(type(stored) == 'table' and stored or nil)
  local namesText = RaceLocked_GuildChampion_HardcodedGuildNamesTextForRace(raceToken)
  if not agg then
    return {
      guildNamesText = namesText,
      averageLevel = nil,
      classes = zeroClassesAggregate(),
    }
  end
  agg.guildNamesText = namesText
  return agg
end
