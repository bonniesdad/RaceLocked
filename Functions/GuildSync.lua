-- Guild roster sync: broadcast and merge leaderboard fields via hidden addon messages.

local ADDON_FOLDER = 'RaceLocked'
local MSG_PREFIX = 'RaceLocked'
local MSG_SEP = '\031'

local broadcastTicker
local fallbackElapsed = 0
-- Classic Era has no PLAYER_GUILD_JOINED / PLAYER_GUILD_LEFT; derive transitions from roster + IsInGuild().
local wasInGuild = false

-- Coalesce CHAT_MSG_ADDON-driven UI refreshes (many guild peers × frequent pings).
local GUILD_NOTIFY_DEBOUNCE_SEC = 0.25
local GUILD_NOTIFY_MAX_WAIT_SEC = 1.0
local guildNotifySeq = 0
local guildNotifyFirstQueued

-- /rwguildsync toggles RaceLockedDB.debugGuildSync
local function guildSyncLog(msg)
  if not RaceLockedDB or not RaceLockedDB.debugGuildSync then
    return
  end
  print('|cfff44336[Race Locked]|r [GuildSync] ' .. tostring(msg))
end

-- Stable "Name-Realm" for guild roster / leaderboard parity (e.g. Notbonnie-SkullRock).
local function guildBroadcastDisplayName()
  local fn, realm = UnitFullName and UnitFullName('player')
  if fn and realm and realm ~= '' then
    return fn .. '-' .. realm
  end
  local u = UnitName and UnitName('player')
  if u and u ~= '' and GetRealmName then
    local r = GetRealmName()
    if r and r ~= '' then
      return u .. '-' .. r
    end
  end
  return u
end

local function inGuildNow()
  return IsInGuild() and true or false
end

local function ensureGuildPeers()
  if not RaceLockedDB then
    return
  end
  RaceLockedDB.guildPeers = RaceLockedDB.guildPeers or {}
end

local function registerMsgPrefix()
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(MSG_PREFIX)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(MSG_PREFIX)
  end
end

local function stopBroadcastTicker()
  if broadcastTicker then
    broadcastTicker:Cancel()
    broadcastTicker = nil
  end
end

local function mergeGuildPeer(entry)
  if not entry or not entry.playerId or not RaceLockedDB then
    return
  end
  ensureGuildPeers()
  local now = time and time() or 0
  RaceLockedDB.guildPeers[entry.playerId] = {
    name = entry.name,
    playerId = entry.playerId,
    achievementPoints = entry.achievementPoints,
    level = entry.level,
    lastSeen = now,
  }
end

local function parseGuildPayload(message)
  if type(message) ~= 'string' or message == '' then
    return nil
  end
  -- Avoid strsplit: use exactly five \031-separated non-empty segments (ver + 4 fields).
  local fields = {}
  for seg in string.gmatch(message, '([^\031]+)') do
    fields[#fields + 1] = seg
  end
  if #fields ~= 5 or fields[1] ~= '1' then
    return nil
  end
  local fname, playerId, apStr, lvlStr = fields[2], fields[3], fields[4], fields[5]
  if not fname or fname == '' or not playerId or playerId == '' or not apStr or lvlStr == nil or lvlStr == '' then
    return nil
  end
  local ap = tonumber(apStr) or 0
  local level = tonumber(lvlStr) or 1
  if ap < 0 then
    ap = 0
  end
  if level < 1 then
    level = 1
  end
  return {
    name = fname,
    playerId = playerId,
    achievementPoints = ap,
    level = level,
  }
end

local function fireGuildLeaderboardNotify()
  guildNotifyFirstQueued = nil
  if RaceLocked_NotifyLeaderboardDataChanged then
    RaceLocked_NotifyLeaderboardDataChanged()
  end
end

local function notifyDataChangedDeferred()
  if not C_Timer or not C_Timer.After or not GetTime then
    fireGuildLeaderboardNotify()
    return
  end
  local now = GetTime()
  if not guildNotifyFirstQueued then
    guildNotifyFirstQueued = now
  end
  guildNotifySeq = guildNotifySeq + 1
  local seq = guildNotifySeq
  local dueDebounced = now + GUILD_NOTIFY_DEBOUNCE_SEC
  local dueMaxWait = guildNotifyFirstQueued + GUILD_NOTIFY_MAX_WAIT_SEC
  local due = math.min(dueDebounced, dueMaxWait)
  local delay = due - now
  if delay < 0 then
    delay = 0
  end
  C_Timer.After(delay, function()
    if seq ~= guildNotifySeq then
      return
    end
    fireGuildLeaderboardNotify()
  end)
end

local function notifyDataChanged()
  if RaceLocked_NotifyLeaderboardDataChanged then
    RaceLocked_NotifyLeaderboardDataChanged()
  end
end

function RaceLocked_BroadcastGuildPing()
  if not IsInGuild() then
    return
  end
  local name = guildBroadcastDisplayName()
  local guid = UnitGUID and UnitGUID('player')
  if not name or name == '' or not guid then
    guildSyncLog(string.format('send skipped: missing name (%s) or guid', tostring(name)))
    return
  end
  local level = UnitLevel and UnitLevel('player')
  if not level or level < 1 then
    level = 1
  end
  local ap = 0
  if RaceLocked_GetPlayerAchievementPoints then
    ap = RaceLocked_GetPlayerAchievementPoints()
  end
  local payload = table.concat({ '1', name, guid, tostring(ap), tostring(level) }, MSG_SEP)
  if #payload > 255 then
    guildSyncLog(string.format('send skipped: payload too long (%d bytes)', #payload))
    return
  end
  local sendOk
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    sendOk = C_ChatInfo.SendAddonMessage(MSG_PREFIX, payload, 'GUILD')
  elseif SendAddonMessage then
    SendAddonMessage(MSG_PREFIX, payload, 'GUILD')
    sendOk = true
  end
  if sendOk == false then
    guildSyncLog('send returned false (rejected, throttled, or not in guild on the server)')
  end
  -- Same client never gets CHAT_MSG_ADDON for own GUILD send; merge locally so roster matches network shape.
  mergeGuildPeer({
    name = name,
    playerId = guid,
    achievementPoints = ap,
    level = level,
  })
  notifyDataChangedDeferred()
  guildSyncLog(string.format('sent GUILD: name=%s ap=%s level=%s', name, tostring(ap), tostring(level)))
end

local function startBroadcastTicker()
  if not IsInGuild() then
    return
  end
  stopBroadcastTicker()
  if C_Timer and C_Timer.NewTicker then
    broadcastTicker = C_Timer.NewTicker(60, RaceLocked_BroadcastGuildPing)
  end
end

local syncFrame = CreateFrame('Frame')

syncFrame:RegisterEvent('ADDON_LOADED')
syncFrame:RegisterEvent('PLAYER_LOGIN')
syncFrame:RegisterEvent('PLAYER_LEVEL_UP')
syncFrame:RegisterEvent('CHAT_MSG_ADDON')
syncFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

syncFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'ADDON_LOADED' then
    local name = ...
    if name == ADDON_FOLDER then
      ensureGuildPeers()
      registerMsgPrefix()
    end
  elseif event == 'PLAYER_LOGIN' then
    ensureGuildPeers()
    registerMsgPrefix()
    local now = inGuildNow()
    if now then
      RaceLocked_BroadcastGuildPing()
      startBroadcastTicker()
      notifyDataChanged()
    else
      stopBroadcastTicker()
    end
    if RaceLockedDB and RaceLockedDB.debugGuildSync then
      if C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered then
        guildSyncLog('prefix RaceLocked registered: ' .. tostring(C_ChatInfo.IsAddonMessagePrefixRegistered(MSG_PREFIX)))
      end
      if now then
        guildSyncLog('PLAYER_LOGIN: in guild — sends ~every 60s; recv only from other clients (+ local merge after own send)')
      else
        guildSyncLog('PLAYER_LOGIN: not in a guild — no guild addon messages will be sent')
      end
    end
    wasInGuild = now
  elseif event == 'PLAYER_LEVEL_UP' then
    if IsInGuild() then
      RaceLocked_BroadcastGuildPing()
      notifyDataChanged()
    end
  elseif event == 'CHAT_MSG_ADDON' then
    local prefix, message, channel, sender = ...
    if prefix ~= MSG_PREFIX then
      return
    end
    -- Do not filter on `channel`: some clients pass values other than the string "GUILD" for guild addon comms.
    guildSyncLog(string.format('recv raw: channel=%s sender=%s', tostring(channel), tostring(sender or '?')))
    local entry = parseGuildPayload(message)
    if entry then
      mergeGuildPeer(entry)
      notifyDataChangedDeferred()
      guildSyncLog(string.format(
        'recv merged: name=%s ap=%s level=%s (sender=%s)',
        tostring(entry.name),
        tostring(entry.achievementPoints),
        tostring(entry.level),
        tostring(sender or '?')
      ))
    else
      guildSyncLog(string.format('recv ignored: invalid payload (len=%d)', type(message) == 'string' and #message or 0))
    end
  elseif event == 'GUILD_ROSTER_UPDATE' then
    local now = inGuildNow()
    if now ~= wasInGuild then
      if now then
        ensureGuildPeers()
        RaceLocked_BroadcastGuildPing()
        startBroadcastTicker()
      else
        stopBroadcastTicker()
        guildNotifySeq = guildNotifySeq + 1
        guildNotifyFirstQueued = nil
        if RaceLockedDB then
          RaceLockedDB.guildPeers = {}
        end
      end
      notifyDataChanged()
    end
    wasInGuild = now
  end
end)

syncFrame:SetScript('OnUpdate', function(_, elapsed)
  if broadcastTicker or not IsInGuild() then
    return
  end
  fallbackElapsed = fallbackElapsed + elapsed
  if fallbackElapsed >= 60 then
    fallbackElapsed = 0
    RaceLocked_BroadcastGuildPing()
  end
end)

registerMsgPrefix()

SLASH_RACELOCKEDGUILDSYNC1 = '/rwguildsync'
SlashCmdList['RACELOCKEDGUILDSYNC'] = function()
  RaceLockedDB = RaceLockedDB or {}
  RaceLockedDB.minimapButton = RaceLockedDB.minimapButton or { hide = false }
  RaceLockedDB.guildPeers = RaceLockedDB.guildPeers or {}
  RaceLockedDB.debugGuildSync = not RaceLockedDB.debugGuildSync
  if RaceLockedDB.debugGuildSync then
    print('|cfff44336[Race Locked]|r Guild sync logging ON. /rwguildsync to turn off.')
    if C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered then
      print('|cfff44336[Race Locked]|r Prefix RaceLocked registered: ' .. tostring(C_ChatInfo.IsAddonMessagePrefixRegistered(MSG_PREFIX)))
    end
    if IsInGuild() then
      RaceLocked_BroadcastGuildPing()
    else
      print('|cfff44336[Race Locked]|r Not in a guild.')
    end
  else
    print('|cfff44336[Race Locked]|r Guild sync logging OFF.')
  end
end
