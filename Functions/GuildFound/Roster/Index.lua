--- Guild Found Roster — message handling, self-broadcast, and event wiring.
--- Members broadcast their own status (S:), the guild master broadcasts
--- overrides (G:), and peers relay overrides they already hold (O:) so a
--- member who logs in late still learns about an override that predates them.

local ADDON_PREFIX = 'RLGFRoster'
local CHAT_PREFIX = '|cff00ccff[GF Roster]|r '

--- Append to the in-panel session log (the user-facing record of traffic).
--- `raw` is the original wire message, shown on hover when enabled.
local function sessionLog(kind, text, raw)
  RaceLocked_Roster_AppendSessionLog(kind, text, raw)
end

--- Print to the chat frame (only used by the /rlroster debug command).
local function chatLog(msg)
  print(CHAT_PREFIX .. msg)
end

-- ── Helpers ──────────────────────────────────────────────────────────────

local function isSenderLocalPlayer(sender)
  if type(sender) ~= 'string' or sender == '' then return false end
  local short = Ambiguate(sender, 'short')
  if UnitName then
    return short == UnitName('player')
  end
  return false
end

local function getAddonSend()
  if not IsInGuild or not IsInGuild() then return nil end
  return SendAddonMessage or (C_ChatInfo and C_ChatInfo.SendAddonMessage)
end

local function registerPrefix()
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(ADDON_PREFIX)
  end
end

-- ── Wire encoding helpers ────────────────────────────────────────────────

local function boolToWire(val)
  if val == true then return '1' end
  if val == false then return '0' end
  return '-'
end

local function wireToBool(s)
  if s == '1' then return true end
  if s == '0' then return false end
  return nil
end

-- ── Human-readable descriptions for the session log ──────────────────────
-- These turn the raw wire values into plain language. The raw message is
-- still kept alongside each log line (shown on hover) for debugging.

--- Status wording mirrors the roster UI columns (Verified, Tampered):
--- e.g. "Verified, Not Tampered" / "Not Verified, Tampered".
local function describeStatus(verified, clean)
  local v = (verified == true) and 'Verified'
    or (verified == false) and 'Not Verified' or '?'
  local c = (clean == true) and 'Not Tampered'
    or (clean == false) and 'Tampered' or '?'
  return v .. ', ' .. c
end

--- Optional " [GM: …]" suffix that lists only the override fields that are
--- actually set, so unremarkable rows stay short.
local function describeOverrideSuffix(gmVerified, gmClean)
  local parts = {}
  if gmVerified ~= nil then
    parts[#parts + 1] = gmVerified and 'Verified' or 'Not Verified'
  end
  if gmClean ~= nil then
    parts[#parts + 1] = gmClean and 'Not Tampered' or 'Tampered'
  end
  if #parts == 0 then return '' end
  return ' [GM: ' .. table.concat(parts, ', ') .. ']'
end

--- A GM override can also clear a field (nil), reverting it to the player's
--- self-report, so spell out all three states.
local function describeGMDecision(gmVerified, gmClean)
  local v = (gmVerified == true) and 'Verified'
    or (gmVerified == false) and 'Not Verified' or 'Verified Reset'
  local c = (gmClean == true) and 'Not Tampered'
    or (gmClean == false) and 'Tampered' or 'Tampered Reset'
  return v .. ', ' .. c
end

local function staleSuffix(accepted)
  return accepted and '' or ' (stale, ignored)'
end

-- ── Build local verification state ───────────────────────────────────────

local function getLocalVerified()
  return RaceLocked_GetDBValue('hasBeenMaxLevelAndSelfFound') == true
    or RaceLocked_ShouldOverrideVerificationViaGuildNote(UnitName('player')) == true
end

local function getLocalClean()
  return RaceLocked_GetDBValue('playerMoneyValidationFailed') ~= true
end

-- ── Outgoing messages ────────────────────────────────────────────────────

-- Coalesce accidental bursts: never put two self-reports on the guild channel
-- within this many seconds (the manual Sync button and login share this path).
local SELF_REPORT_THROTTLE = 2
local lastSelfReportAt = 0

local function broadcastSelfReport()
  if UnitLevel and UnitLevel('player') < 60 then
    sessionLog('info', 'Skipping self-report (level ' .. UnitLevel('player') .. ' < 60)')
    return
  end
  local now = (GetTime and GetTime()) or 0
  if now > 0 and (now - lastSelfReportAt) < SELF_REPORT_THROTTLE then
    return
  end
  local send = getAddonSend()
  if not send then return end
  local playerName = RaceLocked_Roster_GetPlayerName()
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not playerName or not guildName then return end

  lastSelfReportAt = now

  local verified = getLocalVerified()
  local clean = getLocalClean()

  RaceLocked_Roster_SetSelfReport(guildName, playerName, verified, clean)

  local v = boolToWire(verified)
  local c = boolToWire(clean)
  local msg = 'S:' .. playerName .. ',' .. v .. ',' .. c

  local entry = RaceLocked_Roster_GetEntry(guildName, playerName)
  if entry and (entry.gmVerified ~= nil or entry.gmClean ~= nil) then
    msg = msg .. ',' .. boolToWire(entry.gmVerified) .. ',' ..
      boolToWire(entry.gmClean) .. ',' .. tostring(entry.gmTimestamp or 0)
  end

  send(ADDON_PREFIX, msg, 'GUILD')
  sessionLog('sent', playerName .. ' — ' .. describeStatus(verified, clean)
    .. describeOverrideSuffix(entry and entry.gmVerified, entry and entry.gmClean), msg)
end

--- Send a targeted O: relay for a single player whose S: arrived without
--- the GM badge we have stored locally.
local function sendTargetedRelay(guildName, playerName)
  local entry = RaceLocked_Roster_GetEntry(guildName, playerName)
  if not entry then return end
  if entry.gmVerified == nil and entry.gmClean == nil then return end

  local send = getAddonSend()
  if not send then return end

  local msg = 'O:' .. playerName .. ',' ..
    boolToWire(entry.gmVerified) .. ',' ..
    boolToWire(entry.gmClean) .. ',' .. tostring(entry.gmTimestamp or 0)
  send(ADDON_PREFIX, msg, 'GUILD')
  sessionLog('sent', playerName .. ' — Relay'
    .. describeOverrideSuffix(entry.gmVerified, entry.gmClean), msg)
end

-- Relay dampening: when many members hold the same override and a member
-- reports in without it, we don't want everyone relaying simultaneously.
-- Each pending relay waits a short randomized delay; if the override reaches
-- that player in the meantime (their own badge or another peer's relay), we
-- cancel ours. The jitter means only the earliest few members actually send.
local RELAY_MIN_DELAY = 1.5
local RELAY_MAX_JITTER = 2.0
local pendingRelay = {}
local relayTimerArmed = false

local function flushPendingRelays(guildName)
  relayTimerArmed = false
  for playerName in pairs(pendingRelay) do
    pendingRelay[playerName] = nil
    sendTargetedRelay(guildName, playerName)
  end
end

local function queueRelay(guildName, playerName)
  pendingRelay[playerName] = true
  if relayTimerArmed or not C_Timer then return end
  relayTimerArmed = true
  local delay = RELAY_MIN_DELAY + math.random() * RELAY_MAX_JITTER
  C_Timer.After(delay, function() flushPendingRelays(guildName) end)
end

local function cancelPendingRelay(playerName)
  pendingRelay[playerName] = nil
end

--- Apply a GM override to the local store WITHOUT broadcasting. Used while the
--- guild master is editing a row: each Verified/Tampered selection stages
--- locally so the UI updates, and the combined result is broadcast once when
--- they finish (see RaceLocked_Roster_CommitGMOverride). Silent no-op for
--- non-GMs.
function RaceLocked_Roster_StageGMOverride(playerName, gmVerified, gmClean)
  if not RaceLocked_AmIGuildMaster() then return end
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not guildName then return end
  RaceLocked_Roster_SetGMOverride(guildName, playerName, gmVerified, gmClean, time())
end

--- Broadcast the override currently stored for `playerName` to the guild as a
--- single message. This is the only place a GM override goes out, so editing
--- both flags still results in just one broadcast.
--- @return boolean sent  true if a message was put on the channel
function RaceLocked_Roster_CommitGMOverride(playerName)
  if not RaceLocked_AmIGuildMaster() then
    sessionLog('warn', 'Cannot send GM override — you are not the guild master.')
    return false
  end
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not guildName then return false end
  local send = getAddonSend()
  if not send then return false end

  -- Read straight from the entry; do NOT use `a and b or c`, which would turn
  -- a legitimate `false` (Not Verified / Tampered) override into nil.
  local entry = RaceLocked_Roster_GetEntry(guildName, playerName)
  local gmVerified = entry and entry.gmVerified
  local gmClean = entry and entry.gmClean
  local ts = (entry and entry.gmTimestamp) or time()

  local msg = 'G:' .. playerName .. ',' .. boolToWire(gmVerified) .. ',' ..
    boolToWire(gmClean) .. ',' .. tostring(ts)
  send(ADDON_PREFIX, msg, 'GUILD')
  sessionLog('sent', playerName .. ' — GM Override: ' .. describeGMDecision(gmVerified, gmClean), msg)
  return true
end

-- ── Incoming message parsing ─────────────────────────────────────────────

local function splitComma(str)
  local fields = {}
  for field in string.gmatch(str, '[^,]+') do
    fields[#fields + 1] = field
  end
  return fields
end

local function handleSelfReport(guildName, fields, rawMessage)
  local playerName = fields[1]
  local verified = wireToBool(fields[2])
  local clean = wireToBool(fields[3])
  if not playerName or playerName == '' or verified == nil or clean == nil then return end

  -- Capture whether we already hold a GM override this sender doesn't know
  -- about. This must happen BEFORE storing their self-report (which only
  -- touches the self-reported fields), so the check reflects prior state.
  local existingEntry = RaceLocked_Roster_GetEntry(guildName, playerName)
  local hadLocalOverride = existingEntry
    and (existingEntry.gmVerified ~= nil or existingEntry.gmClean ~= nil)

  RaceLocked_Roster_SetSelfReport(guildName, playerName, verified, clean)

  -- A self-report may carry the sender's own GM override badge (fields 4-6).
  -- If present, store it; otherwise we may need to relay an override the
  -- sender is missing.
  local incomingHasBadge = false
  if fields[4] and fields[5] then
    local gmVerified = wireToBool(fields[4])
    local gmClean = wireToBool(fields[5])
    if gmVerified ~= nil or gmClean ~= nil then
      incomingHasBadge = true
      local gmTimestamp = tonumber(fields[6]) or 0
      local accepted = RaceLocked_Roster_SetGMOverride(guildName, playerName, gmVerified, gmClean, gmTimestamp)
      -- The sender already carries an override, so no relay is needed for them.
      cancelPendingRelay(playerName)
      sessionLog('recv', playerName .. ' — ' .. describeStatus(verified, clean)
        .. describeOverrideSuffix(gmVerified, gmClean) .. staleSuffix(accepted), rawMessage)
    end
  end

  if not incomingHasBadge then
    sessionLog('recv', playerName .. ' — ' .. describeStatus(verified, clean), rawMessage)
    if hadLocalOverride then
      queueRelay(guildName, playerName)
    end
  end
end

--- Apply a flat list of override groups (name, verified, clean, timestamp, …)
--- to the store. `describe` turns each applied group into a session-log line,
--- or returns nil to skip logging it. The raw wire message is attached to each
--- logged line for the hover-to-inspect tooltip.
--- @param guildName string
--- @param fields string[]
--- @param rawMessage string
--- @param describe fun(name:string, gmVerified:boolean|nil, gmClean:boolean|nil, gmTimestamp:number, accepted:boolean):string|nil
local function applyOverrideGroups(guildName, fields, rawMessage, describe)
  local index = 1
  while index + 3 <= #fields do
    local playerName = fields[index]
    local gmVerified = wireToBool(fields[index + 1])
    local gmClean = wireToBool(fields[index + 2])
    local gmTimestamp = tonumber(fields[index + 3]) or 0
    if playerName and playerName ~= '' then
      local accepted = RaceLocked_Roster_SetGMOverride(guildName, playerName, gmVerified, gmClean, gmTimestamp)
      local line = describe(playerName, gmVerified, gmClean, gmTimestamp, accepted)
      if line then
        sessionLog('recv', line, rawMessage)
      end
    end
    index = index + 4
  end
end

local function handleGMOverride(guildName, sender, fields, rawMessage)
  if not RaceLocked_IsGuildMaster(sender) then
    sessionLog('warn', 'Rejected override from ' .. sender .. ' — not guild master', rawMessage)
    return
  end
  applyOverrideGroups(guildName, fields, rawMessage, function(name, gmVerified, gmClean, _, accepted)
    return name .. ' — GM Override (' .. sender .. '): ' .. describeGMDecision(gmVerified, gmClean) .. staleSuffix(accepted)
  end)
end

local function handlePeerRelay(guildName, fields, rawMessage)
  applyOverrideGroups(guildName, fields, rawMessage, function(name, gmVerified, gmClean, _, accepted)
    if not accepted then return nil end
    -- A current relay from a peer covers this player, so we can drop ours.
    -- (If it were stale we'd keep ours so our newer override still propagates.)
    cancelPendingRelay(name)
    return name .. ' — Relay' .. describeOverrideSuffix(gmVerified, gmClean)
  end)
end

local function onAddonMessage(prefix, message, channel, sender)
  if prefix ~= ADDON_PREFIX then return end
  if not IsInGuild or not IsInGuild() then return end
  if isSenderLocalPlayer(sender) then return end
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not guildName then return end

  local senderShort = Ambiguate(sender, 'short')

  local typeMarker = string.sub(message, 1, 2)
  local payload = string.sub(message, 3)
  if payload == '' then return end
  local fields = splitComma(payload)
  if #fields == 0 then return end

  if typeMarker == 'S:' then
    handleSelfReport(guildName, fields, message)
  elseif typeMarker == 'G:' then
    handleGMOverride(guildName, senderShort, fields, message)
  elseif typeMarker == 'O:' then
    handlePeerRelay(guildName, fields, message)
  end
end

-- ── Slash command for debug inspection ───────────────────────────────────

SLASH_RLROSTER1 = '/rlroster'

SlashCmdList['RLROSTER'] = function(input)
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not guildName then
    chatLog('Not in a guild.')
    return
  end

  local arg = (input or ''):match('^%s*(.-)%s*$')

  if arg == 'sync' then
    broadcastSelfReport()
    return
  end

  if arg == 'reset' then
    RaceLockedAccountDB = RaceLockedAccountDB or {}
    RaceLockedAccountDB.guildFoundRoster = nil
    chatLog('Roster DB wiped. /reload to re-initialize.')
    return
  end

  if arg == 'gm' then
    RaceLocked_DevToggleGM()
    return
  end

  if arg == 'fakedata' then
    local fakes = {
      { name = 'Testplayer',  v = true,  c = true  },
      { name = 'Cheaterboy',  v = true,  c = false },
      { name = 'Newbieguy',   v = false, c = true  },
      { name = 'Altchar',     v = false, c = false },
    }
    for _, f in ipairs(fakes) do
      RaceLocked_Roster_SetSelfReport(guildName, f.name, f.v, f.c)
    end
    chatLog('Injected ' .. #fakes .. ' fake roster entries.')
    return
  end

  chatLog('── Roster for <' .. guildName .. '> ──')
  chatLog('I am GM: ' .. tostring(RaceLocked_AmIGuildMaster()))

  local store = RaceLocked_Roster_GetAllEntries(guildName)
  if not store then
    chatLog('  (empty)')
    return
  end

  local count = 0
  for name, entry in pairs(store) do
    local ev, ec = RaceLocked_Roster_GetEffectiveStatus(guildName, name)
    local parts = '  ' .. name .. ': V=' .. tostring(entry.verified) ..
      ' C=' .. tostring(entry.clean)
    if entry.gmVerified ~= nil or entry.gmClean ~= nil then
      parts = parts .. ' | gmV=' .. tostring(entry.gmVerified) ..
        ' gmC=' .. tostring(entry.gmClean) ..
        ' ts=' .. tostring(entry.gmTimestamp or 0)
    end
    parts = parts .. ' | effective: V=' .. tostring(ev) .. ' C=' .. tostring(ec)
    chatLog(parts)
    count = count + 1
  end
  chatLog('Total entries: ' .. count)
  chatLog('Commands: /rlroster sync | /rlroster reset | /rlroster gm | /rlroster fakedata')
end

-- ── Event frame ──────────────────────────────────────────────────────────

local thisAddonName = ...

-- PLAYER_ENTERING_WORLD fires on every loading screen (zoning, instances,
-- etc.), not just login. We only want to announce and broadcast once per
-- session, so this stays false until the first time we successfully read the
-- player's guild (which may not be available on the very first event).
local hasAnnouncedThisSession = false

--- Log the session-start line and broadcast our self-report once guild info is
--- readable. Guild name often isn't ready on the first PLAYER_ENTERING_WORLD,
--- so several events call this until it succeeds.
local function trySessionAnnounce()
  if hasAnnouncedThisSession then return end
  local playerName = RaceLocked_Roster_GetPlayerName()
  local guildName = RaceLocked_Roster_GetPlayerGuildName()
  if not playerName or not guildName then
    -- IsInGuild can be true while GetGuildInfo('player') is still nil until
    -- the roster finishes loading — nudge a refresh and try again on
    -- GUILD_ROSTER_UPDATE.
    if IsInGuild and IsInGuild() and RaceLocked_RefreshGuildRoster then
      RaceLocked_RefreshGuildRoster()
    end
    return
  end

  hasAnnouncedThisSession = true
  local verified = getLocalVerified()
  local clean = getLocalClean()
  local loginStatus = 'Login — ' .. describeStatus(verified, clean)
  sessionLog('info', loginStatus)
  -- Echo just this one line to chat so players can confirm the addon
  -- initialized correctly on login.
  chatLog(loginStatus)
  broadcastSelfReport()
end

local service = CreateFrame('Frame')
service:RegisterEvent('ADDON_LOADED')
service:RegisterEvent('PLAYER_ENTERING_WORLD')
service:RegisterEvent('GUILD_ROSTER_UPDATE')
service:RegisterEvent('CHAT_MSG_ADDON')
service:SetScript('OnEvent', function(_, event, ...)
  if event == 'ADDON_LOADED' then
    local loadedAddonName = ...
    if loadedAddonName == thisAddonName then
      registerPrefix()
      trySessionAnnounce()
    end
    return
  end

  if event == 'PLAYER_ENTERING_WORLD' then
    trySessionAnnounce()
    return
  end

  if event == 'GUILD_ROSTER_UPDATE' then
    trySessionAnnounce()
    return
  end

  if event == 'CHAT_MSG_ADDON' then
    onAddonMessage(...)
    return
  end
end)
