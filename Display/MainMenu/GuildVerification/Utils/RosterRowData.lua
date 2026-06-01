--- Build a sorted row list for the Guild Found roster UI.
--- Uses only the persisted roster store — no live guild roster scan.

--- @return table[] rows, boolean isGM
function RaceLocked_GetGuildFoundRosterRows()
  local rows = {}
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not guildName then
    return rows, false
  end

  local isGM = RaceLocked_AmIGuildMaster()
  local myName = RaceLocked_Roster_GetPlayerName()

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
      gmVerified = entry.gmVerified,
      gmClean = entry.gmClean,
      isLocalPlayer = isLocal,
      lastSeen = entry.lastSeen,
    }
  end

  table.sort(rows, function(a, b)
    local aElig = RaceLocked_Roster_IsPlayerEligible(guildName, a.name) and 1 or 0
    local bElig = RaceLocked_Roster_IsPlayerEligible(guildName, b.name) and 1 or 0
    if aElig ~= bElig then
      return aElig > bElig
    end
    return (a.name or '') < (b.name or '')
  end)

  return rows, isGM
end
