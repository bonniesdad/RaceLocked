RaceLocked_GuildChampion = RaceLocked_GuildChampion or {}
local G = RaceLocked_GuildChampion

G.Comms = G.Comms or {}
local Comms = G.Comms

local channelFiltersInstalled = false
local delayedJoinScheduled = false

function Comms.GetDataChannelId()
  if not GetChannelName then
    return 0
  end
  local id = GetChannelName(Comms.CHANNEL_NAME)
  id = tonumber(id) or 0
  return id
end

function Comms.HideDataChannelFromChatWindows()
  if not ChatFrame_RemoveChannel or not NUM_CHAT_WINDOWS then
    return
  end
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = _G['ChatFrame' .. i]
    if frame then
      ChatFrame_RemoveChannel(frame, Comms.CHANNEL_NAME)
    end
  end
end

function Comms.LeaveDataChannel()
  local id = Comms.GetDataChannelId()
  if id <= 0 then
    return false
  end
  if LeaveChannelByName then
    LeaveChannelByName(Comms.CHANNEL_NAME)
    return true
  end
  if LeaveChannelByLocalID then
    LeaveChannelByLocalID(id)
    return true
  end
  return false
end

function Comms.InstallChannelNoticeFilters()
  if channelFiltersInstalled or not ChatFrame_AddMessageEventFilter then
    return
  end
  channelFiltersInstalled = true
  local function filterFn(_, _, ...)
    local arg1 = select(1, ...)
    local arg2 = select(2, ...)
    local arg3 = select(3, ...)
    if tostring(arg1 or '') == Comms.CHANNEL_NAME then
      return true
    end
    if tostring(arg2 or '') == Comms.CHANNEL_NAME then
      return true
    end
    if tostring(arg3 or '') == Comms.CHANNEL_NAME then
      return true
    end
    return false
  end
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE', filterFn)
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE_USER', filterFn)

  -- Hide normal channel lines on the data bus; we still handle them via CHAT_MSG_CHANNEL.
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL', function(_, _, ...)
    local channelIndex = select(8, ...)
    local channelBaseName = select(9, ...)
    if channelBaseName == Comms.CHANNEL_NAME then
      return true
    end
    local id = tonumber(channelIndex) or 0
    if id > 0 and id == Comms.GetDataChannelId() then
      return true
    end
    return false
  end)
end

function Comms.EnsureDataChannelJoined()
  local id = Comms.GetDataChannelId()
  if id > 0 then
    Comms.HideDataChannelFromChatWindows()
    return id
  end
  -- Keep the addon bus out of the client's persisted chat-channel order.
  if JoinTemporaryChannel then
    JoinTemporaryChannel(Comms.CHANNEL_NAME)
    id = Comms.GetDataChannelId()
    if id > 0 then
      Comms.HideDataChannelFromChatWindows()
      return id
    end
  end
  if JoinChannelByName then
    JoinChannelByName(Comms.CHANNEL_NAME)
    id = Comms.GetDataChannelId()
    if id > 0 then
      Comms.HideDataChannelFromChatWindows()
      return id
    end
  end
  return 0
end

function Comms.HasNonDataChannelJoined()
  if not GetChannelList then
    return true
  end

  local channels = { GetChannelList() }
  for _, value in ipairs(channels) do
    if type(value) == 'string' and value ~= '' and value ~= Comms.CHANNEL_NAME then
      return true
    end
  end
  return false
end

function Comms.LeaveDataChannelIfAlone()
  if Comms.GetDataChannelId() <= 0 or Comms.HasNonDataChannelJoined() then
    return false
  end
  return Comms.LeaveDataChannel()
end

function Comms.ScheduleDelayedDataChannelJoin()
  if delayedJoinScheduled then
    return
  end
  delayedJoinScheduled = true
  if not C_Timer or not C_Timer.After then
    if Comms.HasNonDataChannelJoined() then
      Comms.EnsureDataChannelJoined()
    else
      Comms.LeaveDataChannelIfAlone()
    end
    delayedJoinScheduled = false
    return
  end

  local delays = { 1.0, 3.0, 7.0, 15.0 }
  local idx = 1
  local attemptJoin
  local function scheduleNextAttempt()
    if idx >= #delays then
      delayedJoinScheduled = false
      return
    end
    idx = idx + 1
    C_Timer.After(delays[idx], attemptJoin)
  end

  attemptJoin = function()
    if not Comms.HasNonDataChannelJoined() then
      Comms.LeaveDataChannelIfAlone()
      scheduleNextAttempt()
      return
    end
    local id = Comms.EnsureDataChannelJoined()
    if id > 0 then
      delayedJoinScheduled = false
      return
    end
    scheduleNextAttempt()
  end

  C_Timer.After(delays[idx], attemptJoin)
end

--- Classic does not support C_ChatInfo.SendAddonMessage(..., "CHANNEL", ...). Use SendChatMessage(..., "CHANNEL", channelIndex).
function Comms.SendRaceGridChannelLine(channelId, payload)
  if not SendChatMessage or channelId <= 0 or not payload or payload == '' then
    return
  end
  -- Hex on the wire: no '|' (chat escapes) and no raw control bytes that might get altered.
  local wire = Comms.PREFIX .. ':' .. Comms.BytesToHex(payload)
  if #wire > 255 then
    -- print(
    --   string.format(
    --     '|cffffffffRace Locked|r: Broadcast dropped (wire too long len=%s, max=255).',
    --     tostring(#wire)
    --   )
    -- )
    return
  end
  SendChatMessage(wire, 'CHANNEL', nil, channelId)
end

function Comms.IsOurDataChannelMessage(...)
  local channelIndex = select(8, ...)
  local channelBaseName = select(9, ...)
  if channelBaseName == Comms.CHANNEL_NAME then
    return true
  end
  local id = tonumber(channelIndex) or 0
  return id > 0 and id == Comms.GetDataChannelId()
end
