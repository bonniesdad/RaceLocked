-- Guild Verification tab: roster table (Character Name, Race).

local ROW_HEIGHT = 20
local ROW_GAP = 1
local HEADER_ROW_HEIGHT = 20
local PANEL_SIDE_MARGIN = 0
local CONTAINER_TOP_INSET = -24
local PANEL_PAD = 3
local SCROLL_BAR_WIDTH = 26
local SCROLL_BAR_NUDGE_LEFT = 21
local HEADER_STRIP = { r = 0.12, g = 0.10, b = 0.08, a = 0.98 }
local SYNC_BAR_HEIGHT = 34

local PANEL_BACKDROP = {
  bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  tile = true,
  tileSize = 64,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function getPrimaryRowTint()
  if RaceLocked_GetLeaderboardRowTint then
    return RaceLocked_GetLeaderboardRowTint()
  end
  return { r = 0.13, g = 0.19, b = 0.40, a = 0.30 }
end

local function stripRealmFromName(name)
  if name == nil or name == '' then
    return name
  end
  local s = tostring(name)
  local dash = string.find(s, '-', 1, true)
  if not dash or dash <= 1 then
    return s
  end
  return string.sub(s, 1, dash - 1)
end

local function isLocalGuildRow(row)
  if not row then
    return false
  end
  local myGuid = UnitGUID and UnitGUID('player')
  if myGuid and row.playerId and row.playerId == myGuid then
    return true
  end
  local un = UnitName and UnitName('player')
  if un and row.name then
    local nm = stripRealmFromName(row.name)
    if string.lower(nm) == string.lower(un) then
      return true
    end
  end
  return false
end

local COL_EDGE = 2
local COL_GAP_NAME_RACE = 6

local function computeGuildTableColumns(innerW)
  innerW = math.max(innerW or 0, 120)
  local sbReserve = SCROLL_BAR_WIDTH + 6
  local usableText = innerW - COL_EDGE * 2 - sbReserve
  if usableText < 48 then
    usableText = 48
  end
  local nameW = math.floor(usableText * 0.55)
  local raceW = usableText - nameW - COL_GAP_NAME_RACE
  if raceW < 28 then
    raceW = 28
    nameW = math.max(usableText - raceW - COL_GAP_NAME_RACE, 36)
  end
  return {
    edge = COL_EDGE,
    nameW = nameW,
    raceW = raceW,
    gapNr = COL_GAP_NAME_RACE,
  }
end

local function createNameOnlyPanel(parent, rows, rowTint, panelWidth, panelTopInset, bottomInset)
  bottomInset = bottomInset or 0
  local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  panel:SetBackdrop(PANEL_BACKDROP)
  panel:SetBackdropColor(0.06, 0.05, 0.05, 0.92)
  panel:SetBackdropBorderColor(0.45, 0.4, 0.3, 0.9)
  local topY = panelTopInset or 0
  panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, topY)
  panel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, bottomInset)

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

  local headerBg = CreateFrame('Frame', nil, tableTop, 'BackdropTemplate')
  headerBg:SetHeight(HEADER_ROW_HEIGHT)
  headerBg:SetPoint('TOPLEFT', tableTop, 'TOPLEFT', 0, 0)
  headerBg:SetPoint('TOPRIGHT', tableTop, 'TOPRIGHT', 0, 0)
  headerBg:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = nil, tile = false, edgeSize = 0 })
  headerBg:SetBackdropColor(HEADER_STRIP.r, HEADER_STRIP.g, HEADER_STRIP.b, HEADER_STRIP.a)

  local hName = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hName:SetJustifyH('LEFT')
  hName:SetText('Character Name')
  hName:SetTextColor(1, 0.92, 0.62)

  local hRace = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hRace:SetJustifyH('LEFT')
  hRace:SetText('Race')
  hRace:SetTextColor(1, 0.92, 0.62)

  local rowStep = ROW_HEIGHT + ROW_GAP

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
  scrollChild:SetHeight(1)
  scroll:SetScrollChild(scrollChild)

  local rowPool = {}
  panel._colLayout = computeGuildTableColumns(listInnerW)

  local function applyHeaderLayout(L)
    hName:ClearAllPoints()
    hName:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', L.edge, -3)
    hName:SetWidth(L.nameW)
    hRace:ClearAllPoints()
    hRace:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', L.edge + L.nameW + L.gapNr, -3)
    hRace:SetWidth(L.raceW)
  end

  local function applyRowLayout(row, L)
    row.nameFs:ClearAllPoints()
    row.nameFs:SetPoint('LEFT', row, 'LEFT', L.edge, 0)
    row.nameFs:SetWidth(L.nameW)
    row.raceFs:ClearAllPoints()
    row.raceFs:SetPoint('LEFT', row, 'LEFT', L.edge + L.nameW + L.gapNr, 0)
    row.raceFs:SetWidth(L.raceW)
  end

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

  local function syncScrollChildWidth()
    local w = tableTop:GetWidth()
    if not w or w <= 4 then
      w = scroll:GetWidth()
    end
    w = math.max(w or 0, 160)
    scrollChild:SetWidth(w)
    panel._colLayout = computeGuildTableColumns(w)
    applyHeaderLayout(panel._colLayout)
    for j = 1, #rowPool do
      local r = rowPool[j]
      if r and r:IsShown() then
        applyRowLayout(r, panel._colLayout)
      end
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
  applyHeaderLayout(panel._colLayout)
  syncScrollChildWidth()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, syncScrollChildWidth)
  end

  local function ensureRow(i)
    local row = rowPool[i]
    if row then
      return row
    end
    row = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, -((i - 1) * rowStep))
    row:SetPoint('TOPRIGHT', scrollChild, 'TOPRIGHT', 0, -((i - 1) * rowStep))

    row.nameFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    row.nameFs:SetJustifyH('LEFT')
    row.nameFs:SetMaxLines(1)

    row.raceFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    row.raceFs:SetJustifyH('LEFT')
    row.raceFs:SetMaxLines(1)

    applyRowLayout(row, panel._colLayout)
    rowPool[i] = row
    return row
  end

  function panel:UpdateRows(newRows, newRowTint)
    local n = #newRows
    local scrollChildHeight = n * ROW_HEIGHT + math.max(0, n - 1) * ROW_GAP
    scrollChild:SetHeight(math.max(scrollChildHeight, 1))

    local tint = newRowTint or rowTint
    for i = 1, n do
      local data = newRows[i]
      local row = ensureRow(i)
      row:Show()
      applyRowLayout(row, panel._colLayout)
      local isLocal = isLocalGuildRow(data)
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
        row.nameFs:SetTextColor(1, 0.95, 0.5)
        row.raceFs:SetTextColor(1, 0.95, 0.5)
      else
        row:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = nil, tile = false, edgeSize = 0 })
        row:SetBackdropColor(tint.r, tint.g, tint.b, tint.a)
        row.nameFs:SetTextColor(0.95, 0.95, 0.9)
        row.raceFs:SetTextColor(0.95, 0.95, 0.9)
      end
      local displayName = stripRealmFromName(data.name)
      row.nameFs:SetText(displayName)
      local raceLabel = (data.race and data.race ~= '') and data.race or '—'
      row.raceFs:SetText(raceLabel)
    end
    for j = n + 1, #rowPool do
      rowPool[j]:Hide()
    end
    syncScrollChildWidth()
  end

  panel:UpdateRows(rows, rowTint)
  return panel
end

local manualRefreshInProgress = false

local function applyGuildRosterSyncFromButton()
  if InCombatLockdown and InCombatLockdown() then
    return
  end
  if manualRefreshInProgress then
    return
  end
  manualRefreshInProgress = true
  if GuildRoster then
    GuildRoster()
  end
  local function finishRefresh()
    if RaceLocked_GuildVerificationTab_Refresh then
      RaceLocked_GuildVerificationTab_Refresh()
    end
    manualRefreshInProgress = false
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0.3, finishRefresh)
  else
    finishRefresh()
  end
end

function RaceLocked_GuildVerificationTab_Refresh()
  local content = _G.RaceLockedGuildVerificationTabContent
  if not content or not content.guildVerificationContainer then
    return
  end
  local container = content.guildVerificationContainer
  local panel = container.leaderboardPanel
  if not panel or not panel.UpdateRows then
    return
  end
  local rows, allSameRaceAsPlayer = {}, false
  if RaceLocked_GetGuildVerificationRosterRows then
    rows, allSameRaceAsPlayer = RaceLocked_GetGuildVerificationRosterRows()
  end
  rows = rows or {}
  panel:UpdateRows(rows, getPrimaryRowTint())
  local emptyFs = container.guildRosterEmptyLabel
  if emptyFs then
    if allSameRaceAsPlayer then
      emptyFs:SetText('All players are the same race as you')
      emptyFs:Show()
    else
      emptyFs:Hide()
    end
  end
end

function RaceLocked_InitializeGuildVerificationTab(content)
  if not content then
    return
  end
  _G.RaceLockedGuildVerificationTabContent = content

  local container = content.guildVerificationContainer
  if container and content.guildVerificationBuilt then
    container:ClearAllPoints()
    container:SetPoint('TOPLEFT', content, 'TOPLEFT', PANEL_SIDE_MARGIN, CONTAINER_TOP_INSET)
    container:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_SIDE_MARGIN, 4)
    return
  end

  if not container then
    container = CreateFrame('Frame', nil, content)
    content.guildVerificationContainer = container
    container:SetPoint('TOPLEFT', content, 'TOPLEFT', PANEL_SIDE_MARGIN, CONTAINER_TOP_INSET)
    container:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_SIDE_MARGIN, 4)
  end

  local contentW = content:GetWidth()
  if not contentW or contentW < 100 then
    contentW = 320
  end
  local innerW = contentW

  if not container.syncBar then
    local syncBar = CreateFrame('Frame', nil, container)
    container.syncBar = syncBar
    syncBar:SetHeight(SYNC_BAR_HEIGHT)
    syncBar:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', 0, 0)
    syncBar:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT', 0, 0)

    local syncBtn = CreateFrame('Button', nil, syncBar)
    container.syncBtn = syncBtn
    syncBtn:SetSize(30, 30)
    syncBtn:SetPoint('BOTTOMRIGHT', syncBar, 'BOTTOMRIGHT', -4, -5)
    local refreshTex = 'Interface\\Buttons\\UI-RefreshButton'
    local combatTex = 'Interface\\Buttons\\UI-GroupLoot-Pass-Up'
    syncBtn:SetNormalTexture(refreshTex)
    syncBtn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
    syncBtn:SetPushedTexture(refreshTex)
    syncBtn:SetScript('OnEnter', function(self)
      GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
      GameTooltip:SetText('Refetch guild roster', 1, 1, 1)
      GameTooltip:Show()
    end)
    syncBtn:SetScript('OnLeave', GameTooltip_Hide)
    syncBtn:SetScript('OnClick', applyGuildRosterSyncFromButton)

    local function updateSyncBtnCombatState()
      if InCombatLockdown and InCombatLockdown() then
        syncBtn:SetNormalTexture(combatTex)
        syncBtn:SetPushedTexture(combatTex)
        syncBtn:SetDisabledTexture(combatTex)
        syncBtn:Disable()
        syncBtn:SetAlpha(0.75)
      else
        syncBtn:SetNormalTexture(refreshTex)
        syncBtn:SetPushedTexture(refreshTex)
        syncBtn:SetDisabledTexture(refreshTex)
        syncBtn:Enable()
        syncBtn:SetAlpha(1)
      end
    end

    local combatWatcher = CreateFrame('Frame', nil, syncBar)
    combatWatcher:RegisterEvent('PLAYER_REGEN_DISABLED')
    combatWatcher:RegisterEvent('PLAYER_REGEN_ENABLED')
    combatWatcher:SetScript('OnEvent', updateSyncBtnCombatState)
    updateSyncBtnCombatState()
  end

  if not container.leaderboardPanel then
    container.leaderboardPanel = createNameOnlyPanel(
      container,
      {},
      getPrimaryRowTint(),
      innerW,
      0,
      SYNC_BAR_HEIGHT
    )
  else
    container.leaderboardPanel:ClearAllPoints()
    container.leaderboardPanel:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, 0)
    container.leaderboardPanel:SetPoint('BOTTOMRIGHT', container, 'BOTTOMRIGHT', 0, SYNC_BAR_HEIGHT)
  end

  if not container.guildRosterEmptyLabel then
    local emptyFs = container:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    emptyFs:SetPoint('TOP', container.leaderboardPanel, 'TOP', 0, -56)
    emptyFs:SetWidth(math.max(innerW - 16, 120))
    emptyFs:SetJustifyH('CENTER')
    emptyFs:SetTextColor(0.85, 0.82, 0.72)
    emptyFs:Hide()
    container.guildRosterEmptyLabel = emptyFs
  end

  content.guildVerificationBuilt = true
end
