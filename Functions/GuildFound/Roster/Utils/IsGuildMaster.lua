--- Guild master authority check.
--- Uses the same roster-scan pattern as IsPlayerInGuildRoster and
--- ShouldOverrideVerificationViaGuildNote.

function RaceLocked_IsGuildMaster(playerName)
  if not playerName or not IsInGuild() then
    return false
  end

  RaceLocked_RefreshGuildRoster()

  local targetName = Ambiguate(playerName, 'short')
  local numMembers = GetNumGuildMembers()

  for index = 1, numMembers do
    local name, _, rankIndex = GetGuildRosterInfo(index)
    if name and Ambiguate(name, 'short') == targetName then
      return rankIndex == 0
    end
  end

  return false
end

function RaceLocked_AmIGuildMaster()
  local playerName = UnitName and UnitName('player')
  if not playerName then
    return false
  end
  return RaceLocked_IsGuildMaster(playerName)
end
