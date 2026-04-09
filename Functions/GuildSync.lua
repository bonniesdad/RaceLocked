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

-- Enable chat logging: /run RaceLockedDB.debugGuildSync = true  (nil/false = off)
local function guildSyncLog(msg)
  if not RaceLockedDB or not RaceLockedDB.debugGuildSync then
    return
  end
  print('|cfff44336[Race Locked]|r [GuildSync] ' .. tostring(msg))
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

function RaceLocked_BroadcastGuildPing()
  if not IsInGuild() then
    return
  end
  local name = UnitName and UnitName('player')
  local guid = UnitGUID and UnitGUID('player')
  if not name or not guid then
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
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(MSG_PREFIX, payload, 'GUILD')
  elseif SendAddonMessage then
    SendAddonMessage(MSG_PREFIX, payload, 'GUILD')
  end
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

local function parseGuildPayload(message)
  if type(message) ~= 'string' or message == '' then
    return nil
  end
  local ver, name, playerId, apStr, lvlStr = strsplit(MSG_SEP, message)
  if ver ~= '1' or not name or name == '' or not playerId or playerId == '' or not apStr or not lvlStr then
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
    name = name,
    playerId = playerId,
    achievementPoints = ap,
    level = level,
  }
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

local function isGuildAddonChannel(channel)
  if channel == nil or channel == '' then
    return true
  end
  return string.upper(tostring(channel)) == 'GUILD'
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
    local now = inGuildNow()
    if now then
      RaceLocked_BroadcastGuildPing()
      startBroadcastTicker()
      notifyDataChanged()
    else
      stopBroadcastTicker()
    end
    wasInGuild = now
  elseif event == 'PLAYER_LEVEL_UP' then
    if IsInGuild() then
      RaceLocked_BroadcastGuildPing()
      notifyDataChanged()
    end
  elseif event == 'CHAT_MSG_ADDON' then
    local prefix, message, channel, sender = ...
    if prefix ~= MSG_PREFIX or not isGuildAddonChannel(channel) then
      return
    end
    local entry = parseGuildPayload(message)
    if entry then
      mergeGuildPeer(entry)
      notifyDataChangedDeferred()
      guildSyncLog(string.format(
        'recv GUILD from %s: name=%s ap=%s level=%s',
        tostring(sender or '?'),
        tostring(entry.name),
        tostring(entry.achievementPoints),
        tostring(entry.level)
      ))
    else
      guildSyncLog(string.format('recv GUILD ignored: invalid payload (len=%d)', type(message) == 'string' and #message or 0))
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

-- Fallback when C_Timer is unavailable (same throttle as ticker).
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
