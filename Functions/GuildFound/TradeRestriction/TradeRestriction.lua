local frame = CreateFrame('Frame')
frame:RegisterEvent('TRADE_SHOW')
frame:RegisterEvent('TRADE_CLOSED')
frame:RegisterEvent('AUCTION_HOUSE_SHOW')

frame:SetScript('OnEvent', function(self, event, ...)
  if RaceLocked_IsInGuildFoundGuild() and RaceLocked_AmIVerified() then
    if event == 'TRADE_SHOW' then
      local targetName = GetUnitName('npc', true)
      if not targetName then return end
      RaceLocked_CanPerformTradeWithPlayer(targetName, function(canTrade, message)
        if not canTrade then
          RaceLocked_CancelTradeWithMessage(message)
        end
      end)
    elseif event == 'TRADE_CLOSED' then
      RaceLocked_EndTradeVerification()
    elseif event == 'AUCTION_HOUSE_SHOW' then
      RaceLocked_CancelAuctionHouseWithMessage('Auction House blocked')
    end
  end
end)
