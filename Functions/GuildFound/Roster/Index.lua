--- Guild Found Roster — message handling, self-broadcast, and event wiring.

local ADDON_PREFIX = 'RLGFRoster'
local MAX_ADDON_MSG = 255
local CHAT_PREFIX = '|cff00ccff[GF Roster]|r '

local function sessionLog(kind, msg)
  RaceLocked_Roster_AppendSessionLog(kind, msg)
end

local function chatLog(msg)
  print(CHAT_PREFIX .. msg)
end

-- ── Helpers (same as AchievementTracking/Index.lua) ──────────────────────

local function getPlayerGuildName()
  if not IsInGuild or not IsInGuild() or not GetGuildInfo then
    return nil
  end
  local guildName = GetGuildInfo('player')
  if type(guildName) ~= 'string' or guildName == '' then
    return nil
  end
  return guildName
end

local function getPlayerName()
  if not UnitName then return nil end
  local name = UnitName('player')
  if type(name) ~= 'string' or name == '' then return nil end
  return name
end

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

-- ── Build local verification state ───────────────────────────────────────

local function getLocalVerified()
  return RaceLocked_GetDBValue('hasBeenMaxLevelAndSelfFound') == true
    or RaceLocked_ShouldOverrideVerificationViaGuildNote(UnitName('player')) == true
end

local function getLocalClean()
  return RaceLocked_GetDBValue('playerMoneyValidationFailed') ~= true
end

-- ── Relay queue (one message per 100ms tick) ─────────────────────────────

local relayQueue = {}
local relayTicker = nil

local function drainRelayQueue()
  if #relayQueue == 0 then
    if relayTicker then
      relayTicker:Cancel()
      relayTicker = nil
    end
    return
  end
  local send = getAddonSend()
  if not send then
    relayQueue = {}
    if relayTicker then
      relayTicker:Cancel()
      relayTicker = nil
    end
    return
  end
  local msg = table.remove(relayQueue, 1)
  send(ADDON_PREFIX, msg, 'GUILD')
end

local function enqueue(msg)
  relayQueue[#relayQueue + 1] = msg
  if not relayTicker and C_Timer and C_Timer.NewTicker then
    relayTicker = C_Timer.NewTicker(0.1, drainRelayQueue)
  end
end

-- ── Outgoing messages ────────────────────────────────────────────────────

local function broadcastSelfReport()
  if UnitLevel and UnitLevel('player') < 60 then
    sessionLog('info', 'Skipping self-report (level ' .. UnitLevel('player') .. ' < 60)')
    return
  end
  local send = getAddonSend()
  if not send then return end
  local playerName = getPlayerName()
  local guildName = getPlayerGuildName()
  if not playerName or not guildName then return end

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
  sessionLog('sent', msg)
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
  sessionLog('sent', msg)
end

function RaceLocked_Roster_SendGMOverride(playerName, gmVerified, gmClean)
  if not RaceLocked_AmIGuildMaster() then
    sessionLog('warn', 'Cannot send GM override — you are not the guild master.')
    return
  end
  local guildName = getPlayerGuildName()
  if not guildName then return end
  local send = getAddonSend()
  if not send then return end

  local ts = time()
  RaceLocked_Roster_SetGMOverride(guildName, playerName, gmVerified, gmClean, ts)

  local msg = 'G:' .. playerName .. ',' .. boolToWire(gmVerified) .. ',' ..
    boolToWire(gmClean) .. ',' .. tostring(ts)
  send(ADDON_PREFIX, msg, 'GUILD')
  sessionLog('sent', msg)
end

-- ── Incoming message parsing ─────────────────────────────────────────────

local function splitComma(str)
  local fields = {}
  for field in string.gmatch(str, '[^,]+') do
    fields[#fields + 1] = field
  end
  return fields
end

local function handleSelfReport(guildName, fields)
  local playerName = fields[1]
  local v = wireToBool(fields[2])
  local c = wireToBool(fields[3])
  if not playerName or playerName == '' or v == nil or c == nil then return end

  -- Check if we already have a GM override this player doesn't know about.
  -- We need to capture this BEFORE storing their self-report (which doesn't
  -- touch GM fields), so the check is based on our existing local state.
  local hadLocalOverride = false
  local existingEntry = RaceLocked_Roster_GetEntry(guildName, playerName)
  if existingEntry and (existingEntry.gmVerified ~= nil or existingEntry.gmClean ~= nil) then
    hadLocalOverride = true
  end

  RaceLocked_Roster_SetSelfReport(guildName, playerName, v, c)

  local incomingHasBadge = false
  if fields[4] and fields[5] then
    local gv = wireToBool(fields[4])
    local gc = wireToBool(fields[5])
    if gv ~= nil or gc ~= nil then
      incomingHasBadge = true
      local gt = tonumber(fields[6]) or 0
      local accepted = RaceLocked_Roster_SetGMOverride(guildName, playerName, gv, gc, gt)
      sessionLog('recv', 'S: ' .. playerName .. ' — verified=' .. tostring(v) ..
        ', clean=' .. tostring(c) .. ', gmV=' .. tostring(gv) .. ', gmC=' .. tostring(gc) ..
        ', ts=' .. tostring(gt) .. (accepted and '' or ' (stale, ignored)'))
    end
  end

  if not incomingHasBadge then
    sessionLog('recv', 'S: ' .. playerName .. ' — verified=' .. tostring(v) ..
      ', clean=' .. tostring(c))
    if hadLocalOverride then
      sendTargetedRelay(guildName, playerName)
    end
  end
end

local function handleGMOverride(guildName, sender, fields)
  if not RaceLocked_IsGuildMaster(sender) then
    sessionLog('warn', 'Rejected G: from ' .. sender .. ' — not guild master')
    return
  end

  local i = 1
  while i + 3 <= #fields do
    local playerName = fields[i]
    local gv = wireToBool(fields[i + 1])
    local gc = wireToBool(fields[i + 2])
    local gt = tonumber(fields[i + 3]) or 0
    if playerName and playerName ~= '' then
      local accepted = RaceLocked_Roster_SetGMOverride(guildName, playerName, gv, gc, gt)
      sessionLog('recv', 'G: ' .. sender .. ' → ' .. playerName ..
        ' gmV=' .. tostring(gv) .. ', gmC=' .. tostring(gc) ..
        ', ts=' .. tostring(gt) .. (accepted and '' or ' (stale, ignored)'))
    end
    i = i + 4
  end
end

local function handlePeerRelay(guildName, fields)
  local i = 1
  while i + 3 <= #fields do
    local playerName = fields[i]
    local gv = wireToBool(fields[i + 1])
    local gc = wireToBool(fields[i + 2])
    local gt = tonumber(fields[i + 3]) or 0
    if playerName and playerName ~= '' then
      local accepted = RaceLocked_Roster_SetGMOverride(guildName, playerName, gv, gc, gt)
      if accepted then
        sessionLog('recv', 'O: ' .. playerName ..
          ' gmV=' .. tostring(gv) .. ', gmC=' .. tostring(gc) .. ', ts=' .. tostring(gt))
      end
    end
    i = i + 4
  end
end

local function onAddonMessage(prefix, message, channel, sender)
  if prefix ~= ADDON_PREFIX then return end
  if not IsInGuild or not IsInGuild() then return end
  if isSenderLocalPlayer(sender) then return end
  local guildName = getPlayerGuildName()
  if not guildName then return end

  local senderShort = Ambiguate(sender, 'short')

  local typeMarker = string.sub(message, 1, 2)
  local payload = string.sub(message, 3)
  if payload == '' then return end
  local fields = splitComma(payload)
  if #fields == 0 then return end

  if typeMarker == 'S:' then
    handleSelfReport(guildName, fields)
  elseif typeMarker == 'G:' then
    handleGMOverride(guildName, senderShort, fields)
  elseif typeMarker == 'O:' then
    handlePeerRelay(guildName, fields)
  end
end

-- ── Slash command for debug inspection ───────────────────────────────────

SLASH_RLROSTER1 = '/rlroster'

SlashCmdList['RLROSTER'] = function(input)
  local guildName = getPlayerGuildName()
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

local service = CreateFrame('Frame')
service:RegisterEvent('ADDON_LOADED')
service:RegisterEvent('PLAYER_ENTERING_WORLD')
service:RegisterEvent('CHAT_MSG_ADDON')
service:SetScript('OnEvent', function(_, event, ...)
  if event == 'ADDON_LOADED' then
    local loadedAddonName = ...
    if loadedAddonName == thisAddonName then
      registerPrefix()
    end
    return
  end

  if event == 'PLAYER_ENTERING_WORLD' then
    local playerName = getPlayerName()
    local guildName = getPlayerGuildName()
    if playerName and guildName then
      local verified = getLocalVerified()
      local clean = getLocalClean()
      sessionLog('info', 'Self: verified=' .. tostring(verified) .. ', clean=' .. tostring(clean))
      broadcastSelfReport()
    end
    return
  end

  if event == 'CHAT_MSG_ADDON' then
    onAddonMessage(...)
    return
  end
end)
