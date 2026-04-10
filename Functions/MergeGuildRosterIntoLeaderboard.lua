-- Apply cached guild roster rows to the leaderboard (manual Sync button only).

function RaceLocked_MergeGuildRosterIntoLeaderboard()
  if not IsInGuild() or type(RaceLocked_ApplyGuildRosterRowToLeaderboard) ~= 'function' then
    return false
  end
  local total = select(1, GetNumGuildMembers(true))
  if not total or total < 1 then
    total = select(1, GetNumGuildMembers())
  end
  total = tonumber(total) or 0
  if total < 1 then
    return false
  end

  local changed = false
  for i = 1, total do
    local name, _, _, level, _, _, _, _, _, _, _, achievementPoints, _, _, _, _, guid = GetGuildRosterInfo(i)
    if guid and guid ~= '' and name and name ~= '' then
      local rowChanged = RaceLocked_ApplyGuildRosterRowToLeaderboard({
        name = name,
        playerId = guid,
        level = level,
        achievementPoints = achievementPoints,
      })
      changed = changed or rowChanged
    end
  end
  return changed
end
