-- Race grid secret-message service over a hidden custom chat channel.
-- Sends your own guild race reports and applies received reports into stored guild rows.

RaceLocked_GuildChampion = RaceLocked_GuildChampion or {}
local G = RaceLocked_GuildChampion
local thisAddonName = ...

local PREFIX = 'RLRaceGridV1'
local CHANNEL_NAME = 'RaceLockedDataBus'
local channelFiltersInstalled = false

local function emptyClasses()
  return {
    druids = 0,
    rogues = 0,
    hunters = 0,
    warriors = 0,
    mages = 0,
    priests = 0,
    warlocks = 0,
    paladins = 0,
    shamans = 0,
  }
end

local function sanitizeGuildName(name)
  local s = tostring(name or '')
  s = s:gsub('|', '/')
  return s
end

local function buildPayload(raceToken, row)
  if type(row) ~= 'table' then
    return nil
  end
  local c = row.classes or emptyClasses()
  return table.concat({
    'v1',
    tostring(raceToken or ''),
    sanitizeGuildName(row.guildName or ''),
    tostring(tonumber(row.guildSize) or 0),
    tostring(tonumber(row.averageLevel) or 0),
    tostring(tonumber(c.druids) or 0),
    tostring(tonumber(c.rogues) or 0),
    tostring(tonumber(c.hunters) or 0),
    tostring(tonumber(c.warriors) or 0),
    tostring(tonumber(c.mages) or 0),
    tostring(tonumber(c.priests) or 0),
    tostring(tonumber(c.warlocks) or 0),
    tostring(tonumber(c.paladins) or 0),
    tostring(tonumber(c.shamans) or 0),
  }, '|')
end

local function parsePayload(msg)
  if type(msg) ~= 'string' or msg == '' then
    return nil
  end
  local p = { strsplit('|', msg) }
  if #p < 14 then
    return nil
  end
  if p[1] ~= 'v1' then
    return nil
  end

  local raceToken = p[2]
  local guildName = p[3]
  if raceToken == '' or guildName == '' then
    return nil
  end

  return {
    raceToken = raceToken,
    guildName = guildName,
    guildSize = tonumber(p[4]) or 0,
    averageLevel = tonumber(p[5]) or 0,
    classes = {
      druids = tonumber(p[6]) or 0,
      rogues = tonumber(p[7]) or 0,
      hunters = tonumber(p[8]) or 0,
      warriors = tonumber(p[9]) or 0,
      mages = tonumber(p[10]) or 0,
      priests = tonumber(p[11]) or 0,
      warlocks = tonumber(p[12]) or 0,
      paladins = tonumber(p[13]) or 0,
      shamans = tonumber(p[14]) or 0,
    },
  }
end

local function applyIncomingReport(report)
  if not report then
    return
  end
  if not RaceLocked_GuildChampion_IsGuildNameAllowedForRaceGrid then
    return
  end
  if not RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid then
    return
  end
  if not RaceLocked_GuildChampion_IsGuildNameAllowedForRaceGrid(report.guildName) then
    return
  end

  local rows = G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE and G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE[report.raceToken]
  if type(rows) ~= 'table' then
    return
  end

  local incomingNorm = RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid(report.guildName)
  if incomingNorm == '' then
    return
  end

  for _, row in ipairs(rows) do
    if type(row) == 'table' then
      local rowNorm = RaceLocked_GuildChampion_NormalizeGuildNameForRaceGrid(row.guildName)
      if rowNorm ~= '' and rowNorm == incomingNorm then
        row.guildSize = report.guildSize
        row.averageLevel = report.averageLevel
        row.classes = report.classes or emptyClasses()
        return
      end
    end
  end
end

local function getDataChannelId()
  if not GetChannelName then
    return 0
  end
  local id = GetChannelName(CHANNEL_NAME)
  id = tonumber(id) or 0
  return id
end

local function hideChannelFromChatWindows()
  if not ChatFrame_RemoveChannel or not NUM_CHAT_WINDOWS then
    return
  end
  for i = 1, NUM_CHAT_WINDOWS do
    local frame = _G['ChatFrame' .. i]
    if frame then
      ChatFrame_RemoveChannel(frame, CHANNEL_NAME)
    end
  end
end

local function installChannelNoticeFilters()
  if channelFiltersInstalled or not ChatFrame_AddMessageEventFilter then
    return
  end
  channelFiltersInstalled = true
  local function filterFn(_, _, ...)
    local arg1 = select(1, ...)
    local arg2 = select(2, ...)
    local arg3 = select(3, ...)
    if tostring(arg1 or '') == CHANNEL_NAME then
      return true
    end
    if tostring(arg2 or '') == CHANNEL_NAME then
      return true
    end
    if tostring(arg3 or '') == CHANNEL_NAME then
      return true
    end
    return false
  end
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE', filterFn)
  ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL_NOTICE_USER', filterFn)
end

local function ensureDataChannelJoined()
  local id = getDataChannelId()
  if id > 0 then
    hideChannelFromChatWindows()
    return id
  end
  if JoinTemporaryChannel then
    JoinTemporaryChannel(CHANNEL_NAME)
    id = getDataChannelId()
    if id > 0 then
      hideChannelFromChatWindows()
      return id
    end
  end
  return 0
end

function RaceLocked_GuildChampion_BroadcastOwnGuildRaceGridReports()
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    return
  end
  if not RaceLocked_GetGuildRaceGridReportForRaceToken then
    return
  end
  local channelId = ensureDataChannelJoined()
  if channelId <= 0 then
    return
  end

  for raceToken, _ in pairs(G.RACE_GRID_STORED_GUILD_REPORTS_BY_RACE or {}) do
    local row = RaceLocked_GetGuildRaceGridReportForRaceToken(raceToken)
    print('row', row)
    if row and row.guildName and row.guildName ~= '' then
      local payload = buildPayload(raceToken, row)
      if payload and payload ~= '' then
        print('Sending')
        C_ChatInfo.SendAddonMessage(PREFIX, payload, 'CHANNEL', channelId)
      end
    end
  end
end

local service = CreateFrame('Frame')
service:RegisterEvent('ADDON_LOADED')
service:RegisterEvent('CHAT_MSG_ADDON')
service:RegisterEvent('CHANNEL_UI_UPDATE')
service:SetScript('OnEvent', function(_, event, a1, a2, a3)
  if event == 'ADDON_LOADED' then
    local loadedAddonName = a1
    if loadedAddonName == thisAddonName and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
      installChannelNoticeFilters()
      ensureDataChannelJoined()
    end
    return
  end
  if event == 'CHANNEL_UI_UPDATE' then
    ensureDataChannelJoined()
    return
  end
  if event == 'CHAT_MSG_ADDON' then
    local prefix, msg, channelType = a1, a2, a3
    if prefix ~= PREFIX or channelType ~= 'CHANNEL' then
      return
    end
    local report = parsePayload(msg)
    if not report then
      return
    end
    print('Receiving')
    applyIncomingReport(report)
  end
end)
