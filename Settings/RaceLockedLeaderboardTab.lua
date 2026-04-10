-- Leaderboard tab: one full-width panel for the single leaderboard.

local ROW_HEIGHT = 18
local ROW_GAP = 1
local HEADER_ROW_HEIGHT = 20
local PANEL_SIDE_MARGIN = 0
local PANEL_PAD = 3
-- Right-hand gutter matches scrollbar width so the bar sits inside the bordered table.
local SCROLL_BAR_WIDTH = 26
-- Shift UIPanelScrollFrameTemplate chrome left (negative x on TOPRIGHT/BOTTOMRIGHT to scroll).
local SCROLL_BAR_NUDGE_LEFT = 21
local FALLBACK_ROW_BG = { r = 0.40, g = 0.24, b = 0.26, a = 0.85 }
local RACE_PRIMARY_ROW_BG = {
  ORC = { r = 0.22, g = 0.68, b = 0.28, a = 0.92 },
  TAUREN = { r = 0.62, g = 0.44, b = 0.22, a = 0.92 },
  TROLL = { r = 0.18, g = 0.62, b = 0.78, a = 0.92 },
  SCOURGE = { r = 0.55, g = 0.32, b = 0.68, a = 0.92 },
  HUMAN = { r = 0.62, g = 0.46, b = 0.30, a = 0.92 },
  DWARF = { r = 0.70, g = 0.52, b = 0.33, a = 0.92 },
  NIGHTELF = { r = 0.47, g = 0.44, b = 0.76, a = 0.92 },
  GNOME = { r = 0.72, g = 0.45, b = 0.65, a = 0.92 },
}
local HEADER_STRIP = { r = 0.12, g = 0.10, b = 0.08, a = 0.98 }

local AP_COLUMN_PAD = 12
local NAME_COL_SHRINK = 20
local NAME_TO_LEVEL_SHIFT = 20
local PANEL_BACKDROP = {
  bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  tile = true,
  tileSize = 64,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function getPrimaryRowTint()
  local _, raceFile = UnitRace and UnitRace('player')
  local raceKey = raceFile and string.upper(raceFile) or nil
  local tint = raceKey and RACE_PRIMARY_ROW_BG[raceKey] or FALLBACK_ROW_BG
  return { r = tint.r, g = tint.g, b = tint.b, a = tint.a }
end

local SYNC_BAR_HEIGHT = 34

local function createLeaderboardPanel(parent, rows, rowTint, panelWidth, anchorSide, panelTopInset, bottomInset)
  bottomInset = bottomInset or 0
  local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  panel:SetBackdrop(PANEL_BACKDROP)
  panel:SetBackdropColor(0.06, 0.05, 0.05, 0.92)
  panel:SetBackdropBorderColor(0.45, 0.4, 0.3, 0.9)
  if anchorSide ~= 'FULL' then
    panel:SetWidth(math.max(80, panelWidth))
  end
  if anchorSide == 'FULL' then
    local topY = panelTopInset or 0
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, topY)
    panel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, bottomInset)
  elseif anchorSide == 'LEFT' then
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
    panel:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', 0, 0)
  else
    panel:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 0, 0)
    panel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, 0)
  end

  local tableTopY = -3
  local tableTop = CreateFrame('Frame', nil, panel)
  tableTop:SetPoint('TOPLEFT', panel, 'TOPLEFT', PANEL_PAD, tableTopY)
  tableTop:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -PANEL_PAD, tableTopY)
  tableTop:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', PANEL_PAD, PANEL_PAD)
  tableTop:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -PANEL_PAD, PANEL_PAD)

  local tableInnerWidth = panelWidth - (PANEL_PAD * 2)
  if tableInnerWidth < 80 then
    tableInnerWidth = 200
  end
  local listInnerW = tableInnerWidth
  if listInnerW < 60 then
    listInnerW = tableInnerWidth * 0.88
  end
  local dataInnerW = math.max(60, listInnerW - SCROLL_BAR_WIDTH)

  if RaceLocked_SortLeaderboardInPlace then
    RaceLocked_SortLeaderboardInPlace(rows)
  end

  local ACHIEVEMENT_POINTS_LABEL = 'Achievement Points'

  local measureFs = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  measureFs:SetText(ACHIEVEMENT_POINTS_LABEL)
  local colApW = math.ceil(measureFs:GetStringWidth()) + AP_COLUMN_PAD
  measureFs:SetText('12450')
  colApW = math.max(colApW, math.ceil(measureFs:GetStringWidth()) + AP_COLUMN_PAD)
  measureFs:Hide()

  local colRankW = math.floor(math.min(32, math.max(22, dataInnerW * 0.065))) + 5
  local colLevelW = math.floor(math.min(32, math.max(24, dataInnerW * 0.078)))
  colLevelW = colLevelW + NAME_TO_LEVEL_SHIFT
  local restW = math.max(40, dataInnerW - colRankW - colApW - colLevelW)
  local colNameW = math.max(48, restW - NAME_COL_SHRINK)
  local xAp = colRankW + colNameW

  local headerBg = CreateFrame('Frame', nil, tableTop, 'BackdropTemplate')
  headerBg:SetHeight(HEADER_ROW_HEIGHT)
  headerBg:SetPoint('TOPLEFT', tableTop, 'TOPLEFT', 0, 0)
  headerBg:SetPoint('TOPRIGHT', tableTop, 'TOPRIGHT', 0, 0)
  headerBg:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = nil, tile = false, edgeSize = 0 })
  headerBg:SetBackdropColor(HEADER_STRIP.r, HEADER_STRIP.g, HEADER_STRIP.b, HEADER_STRIP.a)

  local hRank = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hRank:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', 2, -3)
  hRank:SetWidth(colRankW - 2)
  hRank:SetJustifyH('CENTER')
  hRank:SetText('#')
  hRank:SetTextColor(1, 0.92, 0.62)

  local hName = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hName:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', colRankW + 2, -3)
  hName:SetWidth(colNameW - 4)
  hName:SetJustifyH('LEFT')
  hName:SetText('Character Name')
  hName:SetTextColor(1, 0.92, 0.62)

  local hAp = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hAp:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', xAp, -3)
  hAp:SetWidth(colApW)
  hAp:SetJustifyH('LEFT')
  hAp:SetText(ACHIEVEMENT_POINTS_LABEL)
  hAp:SetTextColor(1, 0.92, 0.62)

  local hLvl = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hLvl:SetPoint('TOPRIGHT', headerBg, 'TOPRIGHT', -(SCROLL_BAR_WIDTH + 4), -3)
  hLvl:SetWidth(colLevelW - 4)
  hLvl:SetJustifyH('RIGHT')
  hLvl:SetText('Level')
  hLvl:SetTextColor(1, 0.92, 0.62)

  local rowStep = ROW_HEIGHT + ROW_GAP
  local scrollChildHeight = #rows * ROW_HEIGHT + math.max(0, #rows - 1) * ROW_GAP

  local scroll = CreateFrame('ScrollFrame', nil, tableTop, 'UIPanelScrollFrameTemplate')
  scroll:SetFrameStrata(panel:GetFrameStrata())
  scroll:SetFrameLevel(tableTop:GetFrameLevel() + 5)
  scroll:SetPoint('TOPLEFT', headerBg, 'BOTTOMLEFT', 0, -ROW_GAP)
  scroll:SetPoint('BOTTOMRIGHT', tableTop, 'BOTTOMRIGHT', 0, 0)
  scroll:EnableMouseWheel(true)

  local function nudgeScrollChromeLeft(px)
    if not px or px == 0 then
      return
    end
    local function nudgeAnchorsToScroll(f)
      if not f or not f.GetNumPoints or not f.ClearAllPoints then
        return
      end
      local n = f:GetNumPoints()
      if not n or n < 1 then
        return
      end
      local pts = {}
      for i = 1, n do
        pts[i] = { f:GetPoint(i) }
      end
      f:ClearAllPoints()
      for _, p in ipairs(pts) do
        local point, rel, relPoint, x, y = p[1], p[2], p[3], p[4], p[5]
        x = x or 0
        y = y or 0
        if rel == scroll then
          x = x - px
        end
        f:SetPoint(point, rel, relPoint, x, y)
      end
    end
    nudgeAnchorsToScroll(scroll.ScrollUpButton)
    nudgeAnchorsToScroll(scroll.ScrollDownButton)
    nudgeAnchorsToScroll(scroll.ScrollBar)
  end
  nudgeScrollChromeLeft(SCROLL_BAR_NUDGE_LEFT)

  local scrollChild = CreateFrame('Frame', nil, scroll)
  scrollChild:SetFrameLevel(scroll:GetFrameLevel() + 1)
  scrollChild:SetWidth(math.max(1, listInnerW))
  scrollChild:SetHeight(math.max(scrollChildHeight, 1))
  scroll:SetScrollChild(scrollChild)

  local function raiseScrollChrome()
    local topLevel = scroll:GetFrameLevel() + 25
    local sb = scroll.ScrollBar
    if not sb then
      for i = 1, select('#', scroll:GetChildren()) do
        local c = select(i, scroll:GetChildren())
        if c and c.GetObjectType and c:GetObjectType() == 'Slider' then
          sb = c
          break
        end
      end
    end
    if sb then
      sb:SetFrameLevel(topLevel)
      sb:Show()
    end
    for i = 1, select('#', scroll:GetChildren()) do
      local c = select(i, scroll:GetChildren())
      if c and c.GetObjectType and c:GetObjectType() == 'Button' then
        c:SetFrameLevel(topLevel)
        c:Show()
      end
    end
  end

  -- Full-width child matches headerBg; clamp horizontal scroll. Refresh rect + chrome so the bar stays visible.
  local function syncScrollChildWidth()
    local w = tableTop:GetWidth()
    if not w or w <= 4 then
      w = scroll:GetWidth()
    end
    if w and w > 4 then
      scrollChild:SetWidth(w)
    end
    scroll:SetHorizontalScroll(0)
    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
    end
    raiseScrollChrome()
  end
  scroll:SetScript('OnSizeChanged', syncScrollChildWidth)
  scroll:SetScript('OnUpdate', function(self)
    if (self.GetHorizontalScroll and self:GetHorizontalScroll() or 0) ~= 0 then
      self:SetHorizontalScroll(0)
    end
  end)
  if scroll.HookScript then
    scroll:HookScript('OnScrollRangeChanged', function()
      raiseScrollChrome()
    end)
  end
  syncScrollChildWidth()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, syncScrollChildWidth)
  end

  for i = 1, #rows do
    local y = -((i - 1) * rowStep)
    local row = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, y)
    row:SetPoint('TOPRIGHT', scrollChild, 'TOPRIGHT', 0, y)

    local data = rows[i]
    local isLocal = RaceLocked_IsLocalLeaderboardRow and RaceLocked_IsLocalLeaderboardRow(data)
      or (RaceLocked_IsLocalLeaderboardName and RaceLocked_IsLocalLeaderboardName(data.name))
    if isLocal then
      row:SetBackdrop({
        bgFile = 'Interface\\Buttons\\WHITE8x8',
        edgeFile = 'Interface\\Buttons\\WHITE8x8',
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
      })
      row:SetBackdropColor(0.55, 0.38, 0.14, 1)
      row:SetBackdropBorderColor(1, 0.85, 0.25, 1)
    else
      row:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = nil, tile = false, edgeSize = 0 })
      row:SetBackdropColor(rowTint.r, rowTint.g, rowTint.b, rowTint.a)
    end

    local rankFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    rankFs:SetPoint('LEFT', row, 'LEFT', 2, 0)
    rankFs:SetWidth(colRankW - 2)
    rankFs:SetJustifyH('CENTER')
    rankFs:SetText(tostring(i))
    if isLocal then
      rankFs:SetTextColor(1, 0.95, 0.5)
    else
      rankFs:SetTextColor(0.85, 0.85, 0.78)
    end

    local nameFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    nameFs:SetPoint('LEFT', row, 'LEFT', colRankW + 2, 0)
    nameFs:SetWidth(colNameW - 4)
    nameFs:SetJustifyH('LEFT')
    local displayName = RaceLocked_LeaderboardDisplayName and RaceLocked_LeaderboardDisplayName(data.name)
      or data.name
    nameFs:SetText(displayName)
    if isLocal then
      nameFs:SetTextColor(1, 0.95, 0.5)
    else
      nameFs:SetTextColor(0.95, 0.95, 0.9)
    end

    local apFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    apFs:SetPoint('LEFT', row, 'LEFT', xAp, 0)
    apFs:SetWidth(colApW)
    apFs:SetJustifyH('LEFT')
    apFs:SetText(tostring(data.achievementPoints or 0))
    if isLocal then
      apFs:SetTextColor(1, 0.92, 0.55)
    else
      apFs:SetTextColor(0.9, 0.88, 0.82)
    end

    local lvlFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    lvlFs:SetPoint('RIGHT', row, 'RIGHT', -(SCROLL_BAR_WIDTH + 4), 0)
    lvlFs:SetWidth(colLevelW - 4)
    lvlFs:SetJustifyH('RIGHT')
    lvlFs:SetText(tostring(data.level))
    if isLocal then
      lvlFs:SetTextColor(1, 0.92, 0.55)
    else
      lvlFs:SetTextColor(0.9, 0.88, 0.82)
    end
  end

  return panel
end

local function applyGuildRosterSyncFromButton()
  if GuildRoster then
    GuildRoster()
  end
  local function tryMerge()
    if RaceLocked_MergeGuildRosterIntoLeaderboard and RaceLocked_MergeGuildRosterIntoLeaderboard() then
      if RaceLocked_NotifyLeaderboardDataChanged then
        RaceLocked_NotifyLeaderboardDataChanged()
      end
    end
  end
  tryMerge()
  if C_Timer and C_Timer.After then
    C_Timer.After(0.2, tryMerge)
    C_Timer.After(0.75, tryMerge)
  end
end

function RaceLocked_InitializeGuildLeaderboardTab(tabContents, tabIndex)
  if not tabContents or not tabContents[tabIndex] then
    return
  end
  local content = tabContents[tabIndex]
  if content.leaderboardMount then
    content.leaderboardMount:Hide()
    content.leaderboardMount:SetParent(nil)
    content.leaderboardMount = nil
  end

  local container = CreateFrame('Frame', nil, content)
  content.leaderboardMount = container
  container:SetPoint('TOPLEFT', content, 'TOPLEFT', PANEL_SIDE_MARGIN, -12)
  container:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_SIDE_MARGIN, 12)

  local contentW = content:GetWidth()
  if not contentW or contentW < 100 then
    contentW = 348
  end

  local innerW = contentW
  local rows = (RaceLocked_GetSortedGuildLeaderboardCopy and RaceLocked_GetSortedGuildLeaderboardCopy()) or {}
  local sectionGap = 8
  local championH = 0
  if RaceLocked_CreateGuildChampionSection then
    championH = RaceLocked_CreateGuildChampionSection(container, rows, 0) or 0
  end
  local panelTop = championH > 0 and -(championH + sectionGap) or 0

  local syncBar = CreateFrame('Frame', nil, container)
  syncBar:SetHeight(SYNC_BAR_HEIGHT)
  syncBar:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', 0, 0)
  syncBar:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT', 0, 0)

  local syncBtn = CreateFrame('Button', nil, syncBar)
  syncBtn:SetSize(30, 30)
  syncBtn:SetPoint('BOTTOMRIGHT', syncBar, 'BOTTOMRIGHT', -4, 2)
  syncBtn:SetNormalTexture('Interface\\Buttons\\UI-RefreshButton')
  syncBtn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
  syncBtn:SetPushedTexture('Interface\\Buttons\\UI-RefreshButton')
  syncBtn:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:SetText('Refetch guild data', 1, 1, 1)
    GameTooltip:Show()
  end)
  syncBtn:SetScript('OnLeave', GameTooltip_Hide)
  syncBtn:SetScript('OnClick', applyGuildRosterSyncFromButton)

  createLeaderboardPanel(container, rows, getPrimaryRowTint(), innerW, 'FULL', panelTop, SYNC_BAR_HEIGHT)
end

function RaceLocked_RefreshGuildLeaderboardTabUI()
  if not RaceLocked_GetTabContent or not RaceLocked_GetActiveTab then
    return
  end
  if RaceLocked_GetActiveTab() ~= 1 then
    return
  end
  local c = RaceLocked_GetTabContent(1)
  if not c then
    return
  end
  RaceLocked_InitializeGuildLeaderboardTab({ [1] = c }, 1)
end
