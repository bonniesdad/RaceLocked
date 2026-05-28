local frame = CreateFrame('Frame')
frame:RegisterEvent('TRADE_SHOW')
frame:RegisterEvent('TRADE_CLOSED')
frame:RegisterEvent('AUCTION_HOUSE_SHOW')
frame:RegisterEvent('MAIL_INBOX_UPDATE')

frame:SetScript('OnEvent', function(self, event, ...)
  if RaceLocked_IsInGuildFoundGuild() and RaceLocked_AmIVerified() then
    if event == 'MAIL_INBOX_UPDATE' then
      for inboxIndex = GetInboxNumItems(), 1, -1 do
        local _, _, sender, _, _, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(i)
        if sender and not isGM then
          if not RaceLocked_IsPlayerInGuildRoster(sender) then
            RaceLocked_CancelMailWithMessage(
              inboxIndex,
              'Mail from ' .. sender .. ' blocked - not on my Guild.'
            )
          end
        end
      end
    elseif event == 'TRADE_SHOW' then
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
