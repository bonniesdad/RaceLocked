--- Prevents the player from sending mail to recipients outside Guild Found rules.
--- For guild members with no GF roster entry, sends a TV probe and notifies the
--- player to try again once the reply arrives.

local PROBE_TIMEOUT = RACE_LOCKED_MAIL_PROBE_TIMEOUT  -- shared in MailRestriction/Utils/Constants.lua

local pendingOutboundProbes = {}  -- shortName → timestamp

--- Called from TradeVerificationSession when a new roster entry is seeded.
--- If we had a pending outbound probe for that player, notify the player they
--- can retry. The reply doesn't guarantee the recipient is eligible (they may
--- have answered "not verified"), so the message stays neutral — the retry
--- itself will allow or block with the precise reason.
function RaceLocked_NotifyOutboundProbeResolved(shortName)
  if pendingOutboundProbes[shortName] then
    pendingOutboundProbes[shortName] = nil
    RaceLocked_PrintRestrictionMessage(shortName .. ' responded to verification — try sending again.')
  end
end

local function isGuildFoundActive()
  return RaceLocked_IsInGuildFoundGuild
    and RaceLocked_IsInGuildFoundGuild()
    and RaceLocked_AmIVerified
    and RaceLocked_AmIVerified()
end

local function getRecipient()
  if SendMailNameEditBox then
    return SendMailNameEditBox:GetText()
  end
  return nil
end

local function isRecipientAllowed(recipient)
  if not recipient or recipient == '' then return true end

  -- Must be in the WoW guild
  if not RaceLocked_IsPlayerInGuildRoster(recipient) then
    return false, 'Cannot send mail to ' .. Ambiguate(recipient, 'short') .. ' — not in guild'
  end

  local guildName = RaceLocked_Roster_GetPlayerGuildName
    and RaceLocked_Roster_GetPlayerGuildName()
  -- Default-deny: if guild data isn't available we can't verify the recipient,
  -- so block rather than silently allow (consistent with the mail policy).
  if not guildName then
    return false, 'Cannot verify ' .. Ambiguate(recipient, 'short') .. ' — guild data unavailable'
  end

  local shortRecipient = Ambiguate(recipient, 'short')
  local entry = RaceLocked_Roster_GetEntry and RaceLocked_Roster_GetEntry(guildName, shortRecipient)

  if entry then
    -- Has GF entry: require eligible
    if RaceLocked_Roster_IsPlayerEligible
      and not RaceLocked_Roster_IsPlayerEligible(guildName, shortRecipient)
    then
      return false, 'Cannot send mail to ' .. shortRecipient .. ' — not eligible'
    end
    return true
  end

  -- No GF entry: probe and hold until reply arrives
  local probeTime = pendingOutboundProbes[shortRecipient]
  if probeTime then
    local elapsed = (GetTime and GetTime() or 0) - probeTime
    if elapsed >= PROBE_TIMEOUT then
      -- Timed out: clear so player can try again (will re-probe)
      pendingOutboundProbes[shortRecipient] = nil
      return false, 'Cannot send mail to ' .. shortRecipient .. ' — no verification reply'
    end
    return false, 'Awaiting verification from ' .. shortRecipient .. '...'
  end

  -- Send probe, block this attempt, let player retry when notified
  pendingOutboundProbes[shortRecipient] = GetTime and GetTime() or 0
  if RaceLocked_SendTradeVerificationStatus and RaceLocked_AmIVerified then
    RaceLocked_SendTradeVerificationStatus(RaceLocked_AmIVerified(), recipient)
  end
  return false, 'Verification probe sent to ' .. shortRecipient .. '. Try again in a moment.'
end

-- Hook on MAIL_SHOW: SendMailSendButton is created lazily when the mail frame
-- first loads, so it does not exist at PLAYER_LOGIN. _rlGuarded prevents
-- re-hooking on subsequent opens.
local guardFrame = CreateFrame('Frame')
guardFrame:RegisterEvent('MAIL_SHOW')

guardFrame:SetScript('OnEvent', function(_, event)
  if event ~= 'MAIL_SHOW' then return end

  local btn = SendMailSendButton
  if not btn or btn._rlGuarded then return end
  btn._rlGuarded = true

  local orig = btn:GetScript('OnClick')

  btn:SetScript('OnClick', function(btnSelf, ...)
    if isGuildFoundActive() then
      local recipient = getRecipient()
      local allowed, reason = isRecipientAllowed(recipient)
      if not allowed then
        RaceLocked_PrintRestrictionMessage(reason)
        return
      end
    end

    if orig then
      orig(btnSelf, ...)
    else
      SendMailFrame_SendMail()
    end
  end)
end)
