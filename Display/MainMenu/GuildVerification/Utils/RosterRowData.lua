--- Build a sorted row list for the Guild Found roster UI.
--- Uses only the persisted roster store — no live guild roster scan.

local function getPlayerGuildName()
  if not IsInGuild or not IsInGuild() or not GetGuildInfo then
    return nil
  end
  local guildName = GetGuildInfo('player')
  if type(guildName) ~= 'string' or guildName == '' then
    return nil
  end
  return guildName
end

--- @return table[] rows, boolean isGM
function RaceLocked_GetGuildFoundRosterRows()
  local rows = {}
  local guildName = getPlayerGuildName()
  if not guildName then
    return rows, false
  end

  local isGM = RaceLocked_AmIGuildMaster()
  local myName = UnitName and UnitName('player')

  local store = RaceLocked_Roster_GetAllEntries(guildName)
  if not store then
    return rows, isGM
  end

  for name, entry in pairs(store) do
    local ev, ec = RaceLocked_Roster_GetEffectiveStatus(guildName, name)
    local hasGMOverride = (entry.gmVerified ~= nil or entry.gmClean ~= nil)
    local isLocal = myName and name == myName

    rows[#rows + 1] = {
      name = name,
      selfVerified = entry.verified,
      selfClean = entry.clean,
      effectiveVerified = ev,
      effectiveClean = ec,
      hasGMOverride = hasGMOverride,
      isLocalPlayer = isLocal,
      lastSeen = entry.lastSeen,
    }
  end

  table.sort(rows, function(a, b)
    local aElig = (a.effectiveVerified == true and a.effectiveClean == true) and 1 or 0
    local bElig = (b.effectiveVerified == true and b.effectiveClean == true) and 1 or 0
    if aElig ~= bElig then
      return aElig > bElig
    end
    return (a.name or '') < (b.name or '')
  end)

  return rows, isGM
end
