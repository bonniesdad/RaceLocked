local ADDON_PREFIX = 'RaceLocked'

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event ~= 'CHAT_MSG_ADDON' then
    return
  end


  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or channel ~= 'WHISPER' or not sender then
    return
  end

  local isVerified = RaceLocked_ParseTradeVerificationMessage(message)
  if isVerified == nil then
    return
  end

  RaceLocked_OnTradeVerificationMessageReceived(sender, isVerified)
end)
