local ADDON_PREFIX = 'RaceLocked'

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event ~= 'CHAT_MSG_ADDON' then return end

  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or channel ~= 'WHISPER' or not sender then return end

  local isVerified = RaceLocked_ParseTradeVerificationMessage(message)
  if isVerified == nil then return end

  RaceLocked_OnTradeVerificationMessageReceived(sender, isVerified)

  -- Auto-reply: if this probe did not come from our own active trade session,
  -- reply with our status so the sender can seed our Guild Found roster entry.
  local activeSession = RaceLocked_TradeVerificationSession
  local isOurTradePartner = activeSession
    and RaceLocked_PlayerNamesMatch
    and RaceLocked_PlayerNamesMatch(sender, activeSession.targetName)

  if not isOurTradePartner
    and RaceLocked_IsInGuildFoundGuild and RaceLocked_IsInGuildFoundGuild()
    and RaceLocked_AmIVerified and RaceLocked_SendTradeVerificationStatus
  then
    RaceLocked_SendTradeVerificationStatus(RaceLocked_AmIVerified(), sender)
  end
end)
