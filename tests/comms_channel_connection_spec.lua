local tests = {}
local unpack = table.unpack or unpack

local function test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error(string.format('%s: expected %s, got %s', message or 'assertion failed', tostring(expected), tostring(actual)), 2)
  end
end

local globalsToReset = {
  'RaceLocked_GuildChampion',
  'RaceLocked_GuildChampion_BroadcastOwnGuildRaceGridReports',
  'RaceLocked_GuildChampion_EnsureStoredGuildReportsDB',
  'CreateFrame',
  'C_Timer',
  'GetChannelName',
  'GetChannelList',
  'JoinChannelByName',
  'JoinTemporaryChannel',
  'LeaveChannelByName',
  'LeaveChannelByLocalID',
  'ChatFrame_AddMessageEventFilter',
  'ChatFrame_RemoveChannel',
  'NUM_CHAT_WINDOWS',
}

local function resetGlobals()
  for _, name in ipairs(globalsToReset) do
    _G[name] = nil
  end
end

local function loadCommsHarness()
  resetGlobals()

  local timers = {}
  local frames = {}
  local filters = {}
  local ensureDbCalls = 0
  local joinCalls = 0
  local tempJoinCalls = 0
  local leaveCalls = 0
  local dataChannelId = 0
  local channelList = {}

  _G.NUM_CHAT_WINDOWS = 0
  _G.C_Timer = {
    After = function(delay, callback)
      timers[#timers + 1] = { delay = delay, callback = callback }
    end,
  }
  _G.GetChannelName = function(channelName)
    if channelName == 'RaceLockedDataBus' then
      return dataChannelId
    end
    return 0
  end
  _G.GetChannelList = function()
    return unpack(channelList)
  end
  _G.JoinChannelByName = function(channelName)
    if channelName == 'RaceLockedDataBus' then
      joinCalls = joinCalls + 1
      dataChannelId = 4
    end
  end
  _G.JoinTemporaryChannel = function(channelName)
    if channelName == 'RaceLockedDataBus' then
      tempJoinCalls = tempJoinCalls + 1
      dataChannelId = 4
    end
  end
  _G.LeaveChannelByName = function(channelName)
    if channelName == 'RaceLockedDataBus' then
      leaveCalls = leaveCalls + 1
      dataChannelId = 0
    end
  end
  _G.LeaveChannelByLocalID = function(channelId)
    if channelId == dataChannelId then
      leaveCalls = leaveCalls + 1
      dataChannelId = 0
    end
  end
  _G.ChatFrame_AddMessageEventFilter = function(eventName, filterFn)
    filters[#filters + 1] = { eventName = eventName, filterFn = filterFn }
  end
  _G.ChatFrame_RemoveChannel = function()
  end
  _G.CreateFrame = function()
    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(eventName)
      self.events[eventName] = true
    end
    function frame:SetScript(scriptName, fn)
      self.scripts[scriptName] = fn
    end
    frames[#frames + 1] = frame
    return frame
  end
  _G.RaceLocked_GuildChampion_EnsureStoredGuildReportsDB = function()
    ensureDbCalls = ensureDbCalls + 1
  end

  dofile('Functions/Comms/Utils/WireCodec.lua')
  dofile('Functions/Comms/ChannelConnection/Index.lua')
  assert(loadfile('Functions/Comms/Index.lua'))('RaceLocked')

  return {
    frame = frames[#frames],
    timers = timers,
    filters = filters,
    setDataChannelId = function(id)
      dataChannelId = id
    end,
    setChannelList = function(list)
      channelList = list
    end,
    ensureDbCalls = function()
      return ensureDbCalls
    end,
    joinCalls = function()
      return joinCalls
    end,
    tempJoinCalls = function()
      return tempJoinCalls
    end,
    leaveCalls = function()
      return leaveCalls
    end,
  }
end

test('ADDON_LOADED installs filters and DB without scheduling the data channel join', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'ADDON_LOADED', 'RaceLocked')

  assertEqual(harness.ensureDbCalls(), 1, 'ADDON_LOADED should still initialize stored guild reports')
  assertEqual(#harness.filters, 3, 'ADDON_LOADED should still install chat filters')
  assertEqual(#harness.timers, 0, 'ADDON_LOADED should not schedule a data channel join')
  assertEqual(harness.joinCalls(), 0, 'ADDON_LOADED should not join the data channel')
end)

test('ADDON_LOADED clears an already-restored data channel without rejoining it', function()
  local harness = loadCommsHarness()
  harness.setDataChannelId(1)

  harness.frame.scripts.OnEvent(harness.frame, 'ADDON_LOADED', 'RaceLocked')

  assertEqual(harness.leaveCalls(), 1, 'ADDON_LOADED should leave a persisted data channel')
  assertEqual(#harness.timers, 0, 'ADDON_LOADED should not schedule a replacement join')
  assertEqual(harness.joinCalls(), 0, 'ADDON_LOADED should not rejoin persistently')
  assertEqual(harness.tempJoinCalls(), 0, 'ADDON_LOADED should not rejoin temporarily')
end)

test('CHANNEL_UI_UPDATE before entering world does not join the data channel', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'CHANNEL_UI_UPDATE')

  assertEqual(#harness.timers, 0, 'early CHANNEL_UI_UPDATE should not schedule a data channel join')
  assertEqual(harness.joinCalls(), 0, 'early CHANNEL_UI_UPDATE should not join the data channel')
end)

test('CHANNEL_UI_UPDATE before entering world clears a restored data channel', function()
  local harness = loadCommsHarness()
  harness.setDataChannelId(1)

  harness.frame.scripts.OnEvent(harness.frame, 'CHANNEL_UI_UPDATE')

  assertEqual(harness.leaveCalls(), 1, 'early CHANNEL_UI_UPDATE should leave a persisted data channel')
  assertEqual(harness.joinCalls(), 0, 'early CHANNEL_UI_UPDATE should not rejoin the data channel')
  assertEqual(harness.tempJoinCalls(), 0, 'early CHANNEL_UI_UPDATE should not rejoin the temporary data channel')
end)

test('PLAYER_ENTERING_WORLD schedules a delayed join but waits until another channel exists', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  assertEqual(#harness.timers, 1, 'PLAYER_ENTERING_WORLD should schedule a delayed join')

  harness.timers[1].callback()

  assertEqual(harness.joinCalls(), 0, 'delayed join should wait when only empty channel state is visible')
  assertEqual(harness.tempJoinCalls(), 0, 'delayed join should not fall back to temporary join before channels are ready')
  assertEqual(#harness.timers, 2, 'delayed join should retry while channel state is not ready')
end)

test('delayed join clears a restored data channel while waiting for another channel', function()
  local harness = loadCommsHarness()
  harness.setDataChannelId(1)

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  harness.timers[1].callback()

  assertEqual(harness.leaveCalls(), 1, 'delayed join should clear a lone restored data channel')
  assertEqual(harness.joinCalls(), 0, 'delayed join should not rejoin persistently before channels are ready')
  assertEqual(harness.tempJoinCalls(), 0, 'delayed join should not rejoin temporarily before channels are ready')
  assertEqual(#harness.timers, 2, 'delayed join should retry after clearing a lone restored data channel')
end)

test('delayed join proceeds when channel state becomes ready on a later retry', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  harness.timers[1].callback()
  harness.setChannelList({ 1, 'General' })
  harness.timers[2].callback()

  assertEqual(harness.tempJoinCalls(), 1, 'later retry should join temporarily after normal channels appear')
  assertEqual(harness.joinCalls(), 0, 'later retry should not use a persistent channel when temporary join is available')
  assertEqual(#harness.timers, 2, 'successful later retry should not schedule another attempt')
end)

test('delayed join proceeds after a non-data channel is visible', function()
  local harness = loadCommsHarness()
  harness.setChannelList({ 1, 'General' })

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  harness.timers[1].callback()

  assertEqual(harness.tempJoinCalls(), 1, 'delayed join should prefer a temporary channel after normal channels are visible')
  assertEqual(harness.joinCalls(), 0, 'delayed join should avoid persistent chat channels when temporary channels are available')
end)

test('CHANNEL_UI_UPDATE after entering world does not bypass the delayed readiness check', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  harness.frame.scripts.OnEvent(harness.frame, 'CHANNEL_UI_UPDATE')

  assertEqual(harness.joinCalls(), 0, 'CHANNEL_UI_UPDATE should not join inline')
  assertEqual(#harness.timers, 1, 'CHANNEL_UI_UPDATE should respect the existing delayed join')
end)

test('CHANNEL_UI_UPDATE after entering world clears data channel when it is the only visible channel', function()
  local harness = loadCommsHarness()

  harness.frame.scripts.OnEvent(harness.frame, 'PLAYER_ENTERING_WORLD')
  harness.setDataChannelId(1)
  harness.frame.scripts.OnEvent(harness.frame, 'CHANNEL_UI_UPDATE')

  assertEqual(harness.leaveCalls(), 1, 'CHANNEL_UI_UPDATE should clear a lone data channel after world entry')
  assertEqual(harness.joinCalls(), 0, 'CHANNEL_UI_UPDATE should not immediately rejoin persistently')
  assertEqual(harness.tempJoinCalls(), 0, 'CHANNEL_UI_UPDATE should not immediately rejoin temporarily')
  assertEqual(#harness.timers, 1, 'CHANNEL_UI_UPDATE should leave the delayed retry in control')
end)

local failures = 0
for _, spec in ipairs(tests) do
  local ok, err = pcall(spec.fn)
  if ok then
    print('ok - ' .. spec.name)
  else
    failures = failures + 1
    print('not ok - ' .. spec.name)
    print(err)
  end
end

resetGlobals()

if failures > 0 then
  os.exit(1)
end
