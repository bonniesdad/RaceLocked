-- Live roster slice for the race grid: your guild's members of a given API race token (class counts + average level).
-- Not used for addon messages; call when building merged race-cell data for the player's race pane.

RaceLocked_GuildChampion = RaceLocked_GuildChampion or {}
local G = RaceLocked_GuildChampion

local fileToReportKey

local function ensureClassFileMap()
  if fileToReportKey then
    return
  end
  fileToReportKey = {}
  for reportKey, classFile in pairs(G.CLASS_KEY_TO_FILE) do
    fileToReportKey[classFile] = reportKey
  end
end

local function emptyClasses()
  local t = {}
  for i = 1, #G.CLASS_REPORT_KEYS do
    t[G.CLASS_REPORT_KEYS[i].key] = 0
  end
  return t
end

--- @param a string|nil
--- @param b string|nil
local function raceTokensMatch(a, b)
  if not a or not b or a == '' or b == '' then
    return false
  end
  return string.lower(a) == string.lower(b)
end

--- @param name string|nil
local function stripRealmFromRosterName(name)
  if name == nil or name == '' then
    return ''
  end
  local s = tostring(name)
  local dash = string.find(s, '-', 1, true)
  if not dash or dash <= 1 then
    return s
  end
  return string.sub(s, 1, dash - 1)
end

--- If return 17 is not a Player-/Character- GUID, scan other return indices (same roster row).
--- @param index number
--- @param guid17 string|nil
--- @return string|nil
local function resolveGuidFromRosterRow(index, guid17)
  if type(guid17) == 'string' and guid17 ~= '' then
    if string.find(guid17, '^Player%-') or string.find(guid17, '^Character%-') then
      return guid17
    end
  end
  for j = 1, 24 do
    local v = select(j, GetGuildRosterInfo(index))
    if type(v) == 'string' and v ~= '' then
      if string.find(v, '^Player%-') or string.find(v, '^Character%-') then
        return v
      end
    end
  end
  return nil
end

--- @param raceToken string UnitRace English token (e.g. Human, NightElf, Scourge)
--- @return table|nil row { guildName, guildSize, averageLevel, classes } or nil if not applicable / no data
function RaceLocked_GetPlayerGuildRaceGridReportForRaceToken(raceToken)
  if not raceToken or raceToken == '' then
    return nil
  end
  if not IsInGuild or not IsInGuild() or not GetGuildInfo or not GetGuildRosterInfo then
    return nil
  end
  local _, playerRaceEn = UnitRace and UnitRace('player')
  if not playerRaceEn or playerRaceEn == '' or not raceTokensMatch(playerRaceEn, raceToken) then
    return nil
  end
  local guildName = GetGuildInfo('player')
  if type(guildName) ~= 'string' or guildName == '' then
    return nil
  end
  ensureClassFileMap()
  local classes = emptyClasses()
  local sumLevel = 0
  local n = 0
  local total = select(1, GetNumGuildMembers(true))
  if not total or total < 1 then
    total = select(1, GetNumGuildMembers())
  end
  total = tonumber(total) or 0
  local playerShort = UnitName('player') and stripRealmFromRosterName(UnitName('player')) or ''

  for i = 1, total do
    local name, _, _, level, _, _, _, _, _, _, classFile, _, _, _, _, _, guid17 = GetGuildRosterInfo(i)
    local levelNum = tonumber(level) or 0
    local guid = resolveGuidFromRosterRow(i, guid17)

    local engRace = nil
    local engClass = nil
    if guid and guid ~= '' and GetPlayerInfoByGUID then
      _, engClass, _, engRace = GetPlayerInfoByGUID(guid)
    end

    if not engRace and name and playerShort ~= '' then
      local rosterShort = stripRealmFromRosterName(name)
      if rosterShort ~= '' and string.lower(rosterShort) == string.lower(playerShort) and UnitRace then
        _, engRace = UnitRace('player')
      end
    end

    if not engClass and classFile and classFile ~= '' then
      engClass = classFile
    end

    if engRace and raceTokensMatch(engRace, raceToken) then
      n = n + 1
      if levelNum > 0 then
        sumLevel = sumLevel + levelNum
      end
      local effClass = engClass and string.upper(tostring(engClass)) or nil
      local rk = effClass and fileToReportKey[effClass]
      if rk then
        classes[rk] = (classes[rk] or 0) + 1
      end
    end
  end
  if n < 1 then
    return nil
  end
  return {
    guildName = guildName:match('^%s*(.-)%s*$') or guildName,
    guildSize = n,
    averageLevel = sumLevel > 0 and (sumLevel / n) or nil,
    classes = classes,
  }
end
