--- Per-player Guild Found roster storage.
--- Each guild member's verification and clean status is stored in
--- RaceLockedAccountDB keyed by normalized guild name, mirroring the
--- GuildPointsStore pattern.

local function normalizeGuild(name)
  if RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid then
    return RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid(name)
  end
  local s = tostring(name or ''):match('^%s*(.-)%s*$') or ''
  if s == '' then
    return ''
  end
  return string.lower(s)
end

local function ensureDB(guildName)
  RaceLockedAccountDB = RaceLockedAccountDB or {}
  RaceLockedAccountDB.guildFoundRoster = RaceLockedAccountDB.guildFoundRoster or {}
  local norm = normalizeGuild(guildName)
  if norm == '' then
    return nil, ''
  end
  RaceLockedAccountDB.guildFoundRoster[norm] =
    RaceLockedAccountDB.guildFoundRoster[norm] or {}
  return RaceLockedAccountDB.guildFoundRoster[norm], norm
end

local function ensureEntry(store, playerName)
  if type(playerName) ~= 'string' or playerName == '' then
    return nil
  end
  store[playerName] = store[playerName] or {}
  return store[playerName]
end

--- Store a player's self-reported verification and clean status.
--- @param guildName string
--- @param playerName string
--- @param verified boolean
--- @param clean boolean
function RaceLocked_Roster_SetSelfReport(guildName, playerName, verified, clean)
  local store = ensureDB(guildName)
  if not store then return end
  local entry = ensureEntry(store, playerName)
  if not entry then return end
  entry.verified = (verified == true)
  entry.clean = (clean == true)
  entry.lastSeen = time()
end

--- Store a GM override for a player.
--- Values of nil mean "clear this override field" (revert to self-report).
--- Only accepts the override if its timestamp is >= the stored one,
--- so stale badges or relays cannot overwrite a newer GM action.
--- @param guildName string
--- @param playerName string
--- @param gmVerified boolean|nil
--- @param gmClean boolean|nil
--- @param gmTimestamp number|nil  unix timestamp from the GM who issued the override
--- @return boolean accepted  true if the override was applied
function RaceLocked_Roster_SetGMOverride(guildName, playerName, gmVerified, gmClean, gmTimestamp)
  local store = ensureDB(guildName)
  if not store then return false end
  local entry = ensureEntry(store, playerName)
  if not entry then return false end

  local incomingTs = tonumber(gmTimestamp) or 0
  local storedTs = tonumber(entry.gmTimestamp) or 0
  if incomingTs < storedTs then
    return false
  end

  entry.gmVerified = gmVerified
  entry.gmClean = gmClean
  entry.gmTimestamp = incomingTs > 0 and incomingTs or nil
  return true
end

--- Get the raw roster entry for a player (or nil).
--- @param guildName string
--- @param playerName string
--- @return table|nil
function RaceLocked_Roster_GetEntry(guildName, playerName)
  local store = ensureDB(guildName)
  if not store or type(playerName) ~= 'string' or playerName == '' then
    return nil
  end
  return store[playerName]
end

--- Get the effective (resolved) status for a player.
--- GM overrides take precedence when non-nil.
--- @param guildName string
--- @param playerName string
--- @return boolean|nil effectiveVerified
--- @return boolean|nil effectiveClean
function RaceLocked_Roster_GetEffectiveStatus(guildName, playerName)
  local entry = RaceLocked_Roster_GetEntry(guildName, playerName)
  if not entry then
    return nil, nil
  end
  local v = entry.gmVerified
  if v == nil then v = entry.verified end
  local c = entry.gmClean
  if c == nil then c = entry.clean end
  return v, c
end

--- Return the full roster store for a guild (for iteration / relay).
--- @param guildName string
--- @return table|nil
function RaceLocked_Roster_GetAllEntries(guildName)
  return ensureDB(guildName)
end

--- Return a table of all GM overrides for a guild, for peer relay.
--- Returns { [playerName] = { gmVerified=…, gmClean=… }, … } for entries
--- that have at least one non-nil GM override field.
--- @param guildName string
--- @return table
function RaceLocked_Roster_GetAllGMOverrides(guildName)
  local store = ensureDB(guildName)
  local result = {}
  if not store then return result end
  for name, entry in pairs(store) do
    if entry.gmVerified ~= nil or entry.gmClean ~= nil then
      result[name] = {
        gmVerified = entry.gmVerified,
        gmClean = entry.gmClean,
        gmTimestamp = entry.gmTimestamp,
      }
    end
  end
  return result
end

--- Read the local player's own GM override from the roster.
--- Used (in Phase 3) by AmIVerified() to check for a GM override on self.
--- @return table { verified = bool|nil, clean = bool|nil }
function RaceLocked_Roster_GetGMOverrideForSelf()
  local guildName = GetGuildInfo and GetGuildInfo('player')
  local playerName = UnitName and UnitName('player')
  if not guildName or not playerName then
    return {}
  end
  local entry = RaceLocked_Roster_GetEntry(guildName, playerName)
  if not entry then
    return {}
  end
  return { verified = entry.gmVerified, clean = entry.gmClean }
end

--- Remove entries for players no longer in the guild roster.
--- @param guildName string
--- @param rosterNames table<string, boolean> set of names currently in guild
function RaceLocked_Roster_CleanupForRoster(guildName, rosterNames)
  local store = ensureDB(guildName)
  if not store or type(rosterNames) ~= 'table' then return end
  for name, _ in pairs(store) do
    if not rosterNames[name] then
      store[name] = nil
    end
  end
end
