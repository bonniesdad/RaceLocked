function RaceLocked_ShouldOverrideVerificationViaGuildNote(playerName)
  if not playerName or not IsInGuild() then
    return nil
  end

  RaceLocked_RefreshGuildRoster()

  local targetName = Ambiguate(playerName, 'short')
  local numMembers = GetNumGuildMembers()

  for index = 1, numMembers do
    local name, _, _, _, _, _, note = GetGuildRosterInfo(index)
    if name and Ambiguate(name, 'short') == targetName then
      return note and note:find('gf_override_true', 1, true) ~= nil
    end
  end

  return nil
end
