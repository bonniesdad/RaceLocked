-- Shared Guild Wars leaderboard data and sorting (settings tab + main screen)
-- One canonical list (`RaceWars_LEADERBOARD_MOCK`); menu tabs filter by `.guild`.
-- Mock rows exclude your character; your row is merged for Xaryu + combined views.

RaceWars_GUILD_XARYU = 'XARYU'
RaceWars_GUILD_PIKABOO = 'PIKABOO'

RaceWars_LOCAL_PLAYER_NAME = 'Bonniesdad' -- fallback display name if UnitName('player') unavailable
RaceWars_MOCK_SLAIN_MAX = 4
-- Mock rivals defeated stays separate so slain can use a lower cap.
RaceWars_MOCK_DEFEATED_MAX = 10

-- Next guild war (both tabs: same event). **Update these three each month.**
-- Always 4:00 PM server time; do not change the hour in code unless the schedule changes.
RaceWars_NEXT_FIGHT_SERVER_YEAR = 2026
RaceWars_NEXT_FIGHT_SERVER_MONTH = 4
RaceWars_NEXT_FIGHT_SERVER_DAY = 1
RaceWars_NEXT_FIGHT_SERVER_HOUR = 16 -- 4 PM server; change only if schedule changes

function RaceWars_GetNextFightUnix()
  if not time then
    return 0
  end
  local u = time({
    year = RaceWars_NEXT_FIGHT_SERVER_YEAR,
    month = RaceWars_NEXT_FIGHT_SERVER_MONTH,
    day = RaceWars_NEXT_FIGHT_SERVER_DAY,
    hour = RaceWars_NEXT_FIGHT_SERVER_HOUR,
    min = 0,
    sec = 0,
    isdst = -1,
  })
  return u or 0
end

function RaceWars_FormatNextFightLocal(unix)
  if not unix or unix <= 0 then
    return 'TBD'
  end
  if date then
    return date('%a %b %d, %I:%M %p', unix) .. ' Server'
  end
  return tostring(unix)
end

function RaceWars_GetPlayerAchievementPoints()
  -- Classic Era: wire to real achievement points when available
  return 3460
end

--- Kills per opposing race (menu leaderboard + data merge). Wire to real totals when available.
function RaceWars_GetPlayerRaceSlainTotals()
  return 0, 0, 0, 0
end

function RaceWars_GetPlayerLeaderboardRow()
  local name = UnitName and UnitName('player')
  local level = UnitLevel and UnitLevel('player')
  if not level or level < 1 then
    level = 1
  end
  local o, ta, tr, u = RaceWars_GetPlayerRaceSlainTotals()
  return {
    name = name,
    level = level,
    achievementPoints = RaceWars_GetPlayerAchievementPoints(),
    slainOrc = o,
    slainTauren = ta,
    slainTroll = tr,
    slainUndead = u,
  }
end

--- Sum of all race slain fields (full kill total; includes races not shown as columns on a given guild panel).
function RaceWars_GetLeaderboardEntryTotalSlain(e)
  if not e then
    return 0
  end
  return (e.slainOrc or 0)
    + (e.slainTauren or 0)
    + (e.slainTroll or 0)
    + (e.slainUndead or 0)
end

--- Rivals defeated total for sorting/aggregates; missing or invalid counts as 0 (no achievement fallback).
function RaceWars_GetLeaderboardEntryRivalsDefeated(e)
  if not e or e.rivalsDefeated == nil then
    return 0
  end
  local n = e.rivalsDefeated
  if type(n) ~= 'number' then
    return 0
  end
  return n
end

--- Leaderboard cell: show a count only when `rivalsDefeated` is a positive number; otherwise "-".
function RaceWars_FormatRivalsDefeatedCell(e)
  if not e or e.rivalsDefeated == nil then
    return '-'
  end
  local n = e.rivalsDefeated
  if type(n) ~= 'number' or n <= 0 then
    return '-'
  end
  return tostring(n)
end

function RaceWars_FormatRivalsDefeatedCount(n)
  n = tonumber(n)
  if not n or n <= 0 then
    return '-'
  end
  return tostring(n)
end

local function leaderboardCompare(a, b)
  local la, lb = a.level or 0, b.level or 0
  if la ~= lb then
    return la > lb
  end
  local tA = RaceWars_GetLeaderboardEntryTotalSlain(a)
  local tB = RaceWars_GetLeaderboardEntryTotalSlain(b)
  if tA ~= tB then
    return tA > tB
  end
  local na, nb = tostring(a.name or ''), tostring(b.name or '')
  return na < nb
end

local XARYU_LEADERBOARD_MOCK = {
  { name = 'Xaryu', achievementPoints = 12450, level = 40 },
  { name = 'Xaryuu', achievementPoints = 11820, level = 38 },
  { name = 'Xaaryu', achievementPoints = 11590, level = 36 },
  { name = 'Xairyu', achievementPoints = 11240, level = 34 },
  { name = 'Zaryu', achievementPoints = 10980, level = 32 },
  { name = 'Sharyu', achievementPoints = 10620, level = 30 },
  { name = 'Waryu', achievementPoints = 10350, level = 28 },
  { name = 'Xaryuuu', achievementPoints = 10110, level = 26 },
  { name = 'Exaryu', achievementPoints = 9870, level = 24 },
  { name = 'Xaryous', achievementPoints = 9640, level = 22 },
  { name = 'Xaryue', achievementPoints = 9420, level = 18 },
  { name = 'Notxaryu', achievementPoints = 9190, level = 16 },
  { name = 'Xaryude', achievementPoints = 8960, level = 14 },
  { name = 'Bigxaryu', achievementPoints = 8740, level = 12 },
  { name = 'Lilxaryu', achievementPoints = 8510, level = 10 },
  { name = 'Xaryumage', achievementPoints = 8290, level = 8 },
  { name = 'Xaryubank', achievementPoints = 8070, level = 6 },
  { name = 'Xaryudot', achievementPoints = 7860, level = 4 },
  { name = 'Zaryuu', achievementPoints = 7640, level = 2 },
  { name = 'Xaryo', achievementPoints = 7420, level = 1 },
}

local PIKABOO_LEADERBOARD_MOCK = {
  { name = 'Pikaboo', achievementPoints = 4120, level = 40 },
  { name = 'Peekaboo', achievementPoints = 3950, level = 38 },
  { name = 'Pookaboo', achievementPoints = 3780, level = 36 },
  { name = 'Pikabo', achievementPoints = 3610, level = 34 },
  { name = 'Boocifer', achievementPoints = 3450, level = 32 },
  { name = 'Lilpika', achievementPoints = 3290, level = 30 },
  { name = 'Spookaboo', achievementPoints = 3140, level = 28 },
  { name = 'Pikaro', achievementPoints = 2990, level = 26 },
  { name = 'Tabooey', achievementPoints = 2840, level = 24 },
  { name = 'Booberry', achievementPoints = 2700, level = 22 },
  { name = 'Pikastab', achievementPoints = 2560, level = 20 },
  { name = 'Boosterboo', achievementPoints = 2430, level = 18 },
  { name = 'Pikawar', achievementPoints = 2300, level = 16 },
  { name = 'Boonana', achievementPoints = 2180, level = 14 },
  { name = 'Pikabloke', achievementPoints = 2060, level = 12 },
  { name = 'Boohoops', achievementPoints = 1950, level = 10 },
  { name = 'Pikanto', achievementPoints = 1840, level = 8 },
  { name = 'Boogaloo', achievementPoints = 1730, level = 6 },
  { name = 'Pikabolt', achievementPoints = 1620, level = 4 },
  { name = 'Peekabooya', achievementPoints = 1520, level = 1 },
}

--- Per-race slain fields sum to `total` in 0..RaceWars_MOCK_SLAIN_MAX (rivals slain column).
local function RaceWars_SeedSlainColumns(entries, salt)
  local slainCap = RaceWars_MOCK_SLAIN_MAX or 4
  local defCap = RaceWars_MOCK_DEFEATED_MAX or 10
  salt = salt or 0
  for i = 1, #entries do
    local e = entries[i]
    local k = i * 31 + salt * 17
    local total = (k * 7) % (slainCap + 1)
    local r1 = (k * 11) % (total + 1)
    total = total - r1
    local r2 = (k * 13) % (total + 1)
    total = total - r2
    local r3 = (k * 17) % (total + 1)
    local r4 = total - r3
    e.slainOrc = r1
    e.slainTauren = r2
    e.slainTroll = r3
    e.slainUndead = r4
    e.rivalsDefeated = (k * 23) % (defCap + 1)
  end
end

RaceWars_SeedSlainColumns(XARYU_LEADERBOARD_MOCK, 1)
RaceWars_SeedSlainColumns(PIKABOO_LEADERBOARD_MOCK, 2)

for i = 1, #XARYU_LEADERBOARD_MOCK do
  XARYU_LEADERBOARD_MOCK[i].guild = RaceWars_GUILD_XARYU
end
for i = 1, #PIKABOO_LEADERBOARD_MOCK do
  PIKABOO_LEADERBOARD_MOCK[i].guild = RaceWars_GUILD_PIKABOO
end

RaceWars_LEADERBOARD_MOCK = {}
for i = 1, #XARYU_LEADERBOARD_MOCK do
  RaceWars_LEADERBOARD_MOCK[#RaceWars_LEADERBOARD_MOCK + 1] = XARYU_LEADERBOARD_MOCK[i]
end
for i = 1, #PIKABOO_LEADERBOARD_MOCK do
  RaceWars_LEADERBOARD_MOCK[#RaceWars_LEADERBOARD_MOCK + 1] = PIKABOO_LEADERBOARD_MOCK[i]
end

--- Shallow copy of leaderboard entry refs so callers can sort without mutating mock order in place.
function RaceWars_CopyLeaderboardEntries(source)
  local r = {}
  local t = source or RaceWars_LEADERBOARD_MOCK
  for i = 1, #t do
    r[i] = t[i]
  end
  return r
end

function RaceWars_SortLeaderboardInPlace(rows)
  table.sort(rows, leaderboardCompare)
end

--- Filter the canonical list to one guild, optionally merge the live player row (Xaryu only), sorted.
function RaceWars_GetSortedGuildLeaderboardCopy(guildKey)
  guildKey = guildKey or RaceWars_GUILD_XARYU
  local rows = {}
  for i = 1, #RaceWars_LEADERBOARD_MOCK do
    local e = RaceWars_LEADERBOARD_MOCK[i]
    if e.guild == guildKey then
      rows[#rows + 1] = e
    end
  end
  if guildKey == RaceWars_GUILD_XARYU then
    table.insert(rows, RaceWars_GetPlayerLeaderboardRow())
  end
  RaceWars_SortLeaderboardInPlace(rows)
  return rows
end

function RaceWars_GetSortedLeaderboardCopy()
  return RaceWars_GetSortedGuildLeaderboardCopy(RaceWars_GUILD_XARYU)
end

function RaceWars_GetSortedOtherLeaderboardCopy()
  return RaceWars_GetSortedGuildLeaderboardCopy(RaceWars_GUILD_PIKABOO)
end

--- Full roster (both guilds) plus the live player row tagged for the main screen; one global sort.
function RaceWars_GetSortedCombinedLeaderboardCopy()
  local rows = {}
  for i = 1, #RaceWars_LEADERBOARD_MOCK do
    rows[#rows + 1] = RaceWars_LEADERBOARD_MOCK[i]
  end
  local player = RaceWars_GetPlayerLeaderboardRow()
  player.guild = RaceWars_GUILD_XARYU
  rows[#rows + 1] = player
  RaceWars_SortLeaderboardInPlace(rows)
  return rows
end

function RaceWars_IsLocalLeaderboardName(name)
  local nm = string.lower(tostring(name or ''))
  if nm == '' then
    return false
  end
  local un = UnitName and UnitName('player')
  if un and string.lower(un) == nm then
    return true
  end
  return false
end

--- Up to `maxRows` Xaryu entries (including your row); your row centered when possible.
function RaceWars_GetMainScreenHardcoreLeaderboardWindow(maxRows)
  maxRows = maxRows or 7
  local sorted = RaceWars_GetSortedGuildLeaderboardCopy(RaceWars_GUILD_XARYU)
  local n = #sorted
  if n == 0 then
    return {}, 1
  end

  local midSlot = math.floor(maxRows / 2) + 1
  local playerIdx
  for i = 1, n do
    if RaceWars_IsLocalLeaderboardName(sorted[i].name) then
      playerIdx = i
      break
    end
  end
  if not playerIdx then
    playerIdx = math.min(midSlot, n)
  end

  local start = playerIdx - (midSlot - 1)
  if start < 1 then
    start = 1
  end
  if start + maxRows - 1 > n then
    start = math.max(1, n - maxRows + 1)
  end

  local window = {}
  for i = 1, maxRows do
    window[i] = sorted[start + i - 1]
  end
  return window, start
end

--- Top `maxRows` for Pikaboo guild (mock only), ranks starting at 1.
function RaceWars_GetMainScreenOtherLeaderboardWindow(maxRows)
  maxRows = maxRows or 7
  local sorted = RaceWars_GetSortedGuildLeaderboardCopy(RaceWars_GUILD_PIKABOO)
  local n = #sorted
  if n == 0 then
    return {}, 1
  end
  local start = 1
  local window = {}
  for i = 1, maxRows do
    window[i] = sorted[start + i - 1]
  end
  return window, start
end

--- Main on-screen panel: same combined list as full roster sort (both guilds + player).
function RaceWars_GetMainScreenCombinedLeaderboardWindow(maxRows)
  maxRows = maxRows or 7
  local sorted = RaceWars_GetSortedCombinedLeaderboardCopy()
  local n = #sorted
  if n == 0 then
    return {}, 1
  end

  local midSlot = math.floor(maxRows / 2) + 1
  local playerIdx
  for i = 1, n do
    if RaceWars_IsLocalLeaderboardName(sorted[i].name) then
      playerIdx = i
      break
    end
  end
  if not playerIdx then
    playerIdx = math.min(midSlot, n)
  end

  local start = playerIdx - (midSlot - 1)
  if start < 1 then
    start = 1
  end
  if start + maxRows - 1 > n then
    start = math.max(1, n - maxRows + 1)
  end

  local window = {}
  for i = 1, maxRows do
    window[i] = sorted[start + i - 1]
  end
  return window, start
end

RaceWars_GetMainScreenLeaderboardWindow = RaceWars_GetMainScreenCombinedLeaderboardWindow
