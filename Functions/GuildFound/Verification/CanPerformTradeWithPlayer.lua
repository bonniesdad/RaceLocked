function RaceLocked_CanPerformTradeWithPlayer(playerName, onComplete)
  if not playerName or not onComplete then return end

  if not RaceLocked_IsTradePartnerInMyGuild() then
    onComplete(false, 'Trade with ' .. playerName .. ' blocked - not in my Guild.')
    return
  end

  RaceLocked_PrintRestrictionMessage(
    playerName .. ' is in my Guild.' .. ' Starting verification...'
  )

  RaceLocked_BeginTradeVerification(playerName, onComplete)
end
