-- Faction race grid: four playable races for your faction in a 2×2 layout (no champion / average panel).

--- @param root Frame
--- @return Frame refreshRow, Button refreshBtn
local function createChrome(root)
  local G = RaceLocked_GuildChampion

  local refreshRow = CreateFrame('Frame', nil, root)
  refreshRow:SetHeight(G.REFRESH_ROW_H)
  local refreshBtn = CreateFrame('Button', nil, refreshRow, 'UIPanelButtonTemplate')
  refreshBtn:SetText('Refresh')
  refreshBtn:SetSize(120, G.REFRESH_ROW_H - 2)
  refreshBtn:SetPoint('CENTER', refreshRow, 'CENTER', 0, 0)

  return refreshRow, refreshBtn
end

--- @param root Frame
--- @param raceToken string API race token for icon path
--- @param raceAccent number[] rgb accent bar
--- @return Frame pane, Texture icon, FontString labelFs, FontString detailFs
local function createRaceStatPane(root, raceToken, raceAccent)
  local G = RaceLocked_GuildChampion

  local f = CreateFrame('Frame', nil, root, 'BackdropTemplate')
  f:SetBackdrop(G.CELL_BACKDROP)
  f:SetBackdropColor(G.AP_BG.r, G.AP_BG.g, G.AP_BG.b, G.AP_BG.a)
  f:SetBackdropBorderColor(G.AP_BORDER.r, G.AP_BORDER.g, G.AP_BORDER.b, G.AP_BORDER.a)
  f:SetHeight(G.STATS_ROW_H)

  local accent = f:CreateTexture(nil, 'BORDER')
  accent:SetColorTexture(raceAccent[1], raceAccent[2], raceAccent[3], 1)
  accent:SetWidth(G.ACCENT_W)
  accent:SetPoint('TOPLEFT', f, 'TOPLEFT', G.ACCENT_INSET_X, -G.ACCENT_INSET_Y)
  accent:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', G.ACCENT_INSET_X, G.ACCENT_INSET_Y)

  local icon = f:CreateTexture(nil, 'OVERLAY')
  icon:SetTexture(RaceLocked_GuildChampion_RaceIconTexture(raceToken))
  icon:SetTexCoord(0, 1, 0, 1)
  icon:SetSize(G.FACTION_ICON_SIZE, G.FACTION_ICON_SIZE)
  icon:Show()

  local lbl = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
  lbl:SetJustifyH('LEFT')
  lbl:SetTextColor(G.LABEL_GOLD[1] * 0.9, G.LABEL_GOLD[2] * 0.9, G.LABEL_GOLD[3] * 0.9)

  local det = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  det:SetJustifyH('LEFT')
  det:SetText('—')
  det:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
  f._detailFs = det

  f._guildSectionTitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._guildSectionTitle:SetJustifyH('LEFT')

  f._guildNames = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  f._guildNames:SetJustifyH('LEFT')
  f._guildNames:SetJustifyV('TOP')
  f._guildNames:SetWordWrap(true)

  f._avgSubtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._avgSubtitle:SetJustifyH('LEFT')

  f._classSubtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._classSubtitle:SetJustifyH('LEFT')

  f._classBarHost = CreateFrame('Frame', nil, f)
  f._classBarHost:SetHeight(G.CLASS_BAR_HOST_H)

  f._classBarPctRow = CreateFrame('Frame', nil, f._classBarHost)
  f._classBarPctRow:SetHeight(G.CLASS_BAR_LABEL_ROW)

  f._classBarBarWell = CreateFrame('Frame', nil, f._classBarHost, 'BackdropTemplate')
  f._classBarBarWell:SetBackdrop(G.CLASS_BAR_CHART_BACKDROP)
  f._classBarBarWell:SetBackdropColor(0.05, 0.06, 0.08, 0.92)
  f._classBarBarWell:SetBackdropBorderColor(G.AP_BORDER.r, G.AP_BORDER.g, G.AP_BORDER.b, G.AP_BORDER.a * 0.85)
  f._classBarBarWell:SetHeight(G.CLASS_BAR_HEIGHT + 2 * G.CLASS_BAR_BORDER_PAD)

  f._classBarRow = CreateFrame('Frame', nil, f._classBarBarWell)
  f._classBarRow:SetHeight(G.CLASS_BAR_HEIGHT)

  f._classCol = {}
  for idx = 1, 9 do
    local col = CreateFrame('Frame', nil, f._classBarRow)
    col:SetHeight(G.CLASS_BAR_HEIGHT)
    col:EnableMouse(true)
    local tex = col:CreateTexture(nil, 'ARTWORK')
    tex:SetHeight(G.CLASS_BAR_HEIGHT)
    tex:SetPoint('TOPLEFT', col, 'TOPLEFT', 0, 0)
    tex:SetPoint('TOPRIGHT', col, 'TOPRIGHT', 0, 0)
    local pct = f._classBarPctRow:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    pct:SetHeight(G.CLASS_BAR_LABEL_ROW)
    pct:SetJustifyH('CENTER')
    pct:SetJustifyV('BOTTOM')
    local pctHit = CreateFrame('Frame', nil, f._classBarPctRow)
    pctHit:SetFrameLevel((pct.GetFrameLevel and pct:GetFrameLevel() or 0) + 3)
    pctHit:EnableMouse(true)
    pctHit:Hide()
    local cell = { frame = col, tex = tex, pct = pct, pctHit = pctHit }
    f._classCol[idx] = cell
    col._rlCell = cell
    pctHit._rlCell = cell
    col:SetScript('OnEnter', RaceLocked_GuildChampion_OnClassBarCellEnter)
    col:SetScript('OnLeave', RaceLocked_GuildChampion_OnClassBarCellLeave)
    pctHit:SetScript('OnEnter', RaceLocked_GuildChampion_OnClassBarCellEnter)
    pctHit:SetScript('OnLeave', RaceLocked_GuildChampion_OnClassBarCellLeave)
  end

  f._classBarSep = {}
  for s = 1, 8 do
    local sep = f._classBarRow:CreateTexture(nil, 'OVERLAY')
    sep:SetColorTexture(G.CLASS_BAR_SEP[1], G.CLASS_BAR_SEP[2], G.CLASS_BAR_SEP[3], 1)
    sep:SetWidth(G.CLASS_BAR_SEP_W)
    sep:SetHeight(G.CLASS_BAR_HEIGHT)
    sep:Hide()
    f._classBarSep[s] = sep
  end

  return f, icon, lbl, det
end

local function textLeftOffset()
  local G = RaceLocked_GuildChampion
  return G.ACCENT_INSET_X + G.ACCENT_W + G.GAP_AFTER_ACCENT + G.FACTION_ICON_SIZE + G.GAP_AFTER_ICON
end

--- @param pane Frame
--- @param labelFs FontString race name
--- @param detailFs FontString average level value
--- @param tx number left inset for text block
--- @param raceToken string UnitRace token for class availability
local function layoutRaceGridPane(pane, labelFs, detailFs, tx, raceToken)
  local G = RaceLocked_GuildChampion
  local w = pane:GetWidth() - tx - G.INNER_PAD
  w = math.max(w, 48)
  -- Class bar: full inner width of the cell (not aligned to text column after the icon).
  local barLeft = G.INNER_PAD + G.CLASS_BAR_EXTRA_LEFT_PAD
  local barW = pane:GetWidth() - barLeft - G.INNER_PAD
  barW = math.max(barW, 48)

  labelFs:ClearAllPoints()
  labelFs:SetPoint('TOPLEFT', pane, 'TOPLEFT', tx, -4)
  labelFs:SetWidth(w)

  local guildH = pane._guildSectionTitle
  guildH:ClearAllPoints()
  guildH:SetPoint('TOPLEFT', labelFs, 'BOTTOMLEFT', barLeft - tx, -20)
  guildH:SetWidth(barW)

  local gNames = pane._guildNames
  gNames:ClearAllPoints()
  gNames:SetPoint('TOPLEFT', guildH, 'BOTTOMLEFT', 0, -1)
  gNames:SetWidth(barW)

  local avgSub = pane._avgSubtitle
  avgSub:ClearAllPoints()
  avgSub:SetPoint('TOPLEFT', gNames, 'BOTTOMLEFT', 0, -5)
  avgSub:SetWidth(barW)

  detailFs:ClearAllPoints()
  detailFs:SetPoint('TOPLEFT', avgSub, 'BOTTOMLEFT', 0, -2)
  detailFs:SetWidth(barW)

  local cSub = pane._classSubtitle
  cSub:ClearAllPoints()
  cSub:SetPoint('TOPLEFT', detailFs, 'BOTTOMLEFT', 0, -6)
  cSub:SetWidth(barW)

  local host = pane._classBarHost
  host:ClearAllPoints()
  host:SetPoint('TOPLEFT', cSub, 'BOTTOMLEFT', 0, -4)
  host:SetWidth(barW)
  host:SetHeight(G.CLASS_BAR_HOST_H)

  local pctRow = pane._classBarPctRow
  pctRow:ClearAllPoints()
  pctRow:SetPoint('TOPLEFT', host, 'TOPLEFT', 0, 0)
  pctRow:SetWidth(barW)
  pctRow:SetHeight(G.CLASS_BAR_LABEL_ROW)

  local well = pane._classBarBarWell
  well:ClearAllPoints()
  well:SetPoint('BOTTOMLEFT', host, 'BOTTOMLEFT', 0, 0)
  well:SetWidth(barW)
  well:SetHeight(G.CLASS_BAR_HEIGHT + 2 * G.CLASS_BAR_BORDER_PAD)

  local pad = G.CLASS_BAR_BORDER_PAD
  local row = pane._classBarRow
  row:ClearAllPoints()
  row:SetPoint('TOPLEFT', well, 'TOPLEFT', 0, -pad)
  row:SetPoint('TOPRIGHT', well, 'TOPRIGHT', 0, -pad)
  row:SetHeight(G.CLASS_BAR_HEIGHT)
end

--- Lay out the faction race grid: 2×2 panes and refresh row; updates root height and refreshes numbers.
--- @param ctx table
local function layoutGrid(ctx)
  local G = RaceLocked_GuildChampion
  local root = ctx.root
  local parent = ctx.parent
  local rightInset = ctx.rightInset

  local rw = root:GetWidth()
  if (not rw or rw < 2) and parent and parent.GetWidth then
    rw = math.max(0, parent:GetWidth() - rightInset)
  end
  if rw < 80 then
    rw = 400
  end

  local rowInner = rw - G.MID_GAP
  local wLeft = math.floor(rowInner / 2)
  local wRight = rowInner - wLeft

  local gridTop = G.OUTER_PAD_Y + G.GRID_TOP_OFFSET

  local panes = ctx.panes
  panes[1]:ClearAllPoints()
  panes[1]:SetPoint('TOPLEFT', root, 'TOPLEFT', 0, -gridTop)
  panes[1]:SetSize(wLeft, G.STATS_ROW_H)

  panes[2]:ClearAllPoints()
  panes[2]:SetPoint('TOPLEFT', panes[1], 'TOPRIGHT', G.MID_GAP, 0)
  panes[2]:SetSize(wRight, G.STATS_ROW_H)

  panes[3]:ClearAllPoints()
  panes[3]:SetPoint('TOPLEFT', panes[1], 'BOTTOMLEFT', 0, -G.ROW_GAP)
  panes[3]:SetSize(wLeft, G.STATS_ROW_H)

  panes[4]:ClearAllPoints()
  panes[4]:SetPoint('TOPLEFT', panes[3], 'TOPRIGHT', G.MID_GAP, 0)
  panes[4]:SetSize(wRight, G.STATS_ROW_H)

  local icons = ctx.icons
  for j = 1, 4 do
    local icon = icons[j]
    icon:ClearAllPoints()
    icon:SetSize(G.FACTION_ICON_SIZE, G.FACTION_ICON_SIZE)
    icon:SetPoint('LEFT', panes[j], 'LEFT', G.ACCENT_INSET_X + G.ACCENT_W + G.GAP_AFTER_ACCENT, 0)
    icon:SetPoint('TOP', panes[j], 'TOP', 0, -6)
  end

  local tx = textLeftOffset()
  for i = 1, 4 do
    layoutRaceGridPane(panes[i], ctx.labels[i], ctx.details[i], tx, ctx.raceTokens[i])
  end

  ctx.refreshRow:ClearAllPoints()
  ctx.refreshRow:SetPoint('TOPLEFT', panes[3], 'BOTTOMLEFT', 0, -G.GAP_AFTER_GRID)
  ctx.refreshRow:SetPoint('TOPRIGHT', panes[4], 'BOTTOMRIGHT', 0, -G.GAP_AFTER_GRID)

  local newH = gridTop
    + G.STATS_ROW_H * 2
    + G.ROW_GAP
    + G.GAP_AFTER_GRID
    + G.REFRESH_ROW_H
    + G.OUTER_PAD_Y
  root:SetHeight(newH)
  ctx.totalH = newH

  RaceLocked_GuildChampion_RefreshRaceGridDisplay(ctx.panes, ctx.raceTokens)
end

--- @param parent Frame
--- @param rightInset number|nil optional right inset (legacy; kept for call compatibility)
--- @return Frame root
--- @return number total height
function RaceLocked_CreateFactionRaceGrid(parent, rightInset)
  rightInset = rightInset or 0
  local G = RaceLocked_GuildChampion

  local totalH = G.OUTER_PAD_Y
    + G.GRID_TOP_OFFSET
    + G.STATS_ROW_H * 2
    + G.ROW_GAP
    + G.GAP_AFTER_GRID
    + G.REFRESH_ROW_H
    + G.OUTER_PAD_Y

  local root = CreateFrame('Frame', nil, parent)
  root:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
  root:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -rightInset, 0)
  root:SetHeight(totalH)

  local refreshRow, refreshBtn = createChrome(root)

  local playerFaction = UnitFactionGroup and UnitFactionGroup('player') or 'Alliance'
  local isHorde = playerFaction == 'Horde'
  local raceAccents = isHorde and G.HORDE_RACE_ACCENT or G.ALLIANCE_RACE_ACCENT
  local raceTokens = isHorde and { 'Orc', 'Troll', 'Tauren', 'Scourge' }
    or { 'Dwarf', 'NightElf', 'Human', 'Gnome' }

  local playerRaceToken = ''
  if UnitRace then
    local _, token = UnitRace('player')
    if token and token ~= '' then
      playerRaceToken = token
    end
  end

  local panes = {}
  local labels = {}
  local details = {}
  local icons = {}

  for i = 1, 4 do
    local f, icon, lbl, det = createRaceStatPane(root, raceTokens[i], raceAccents[i])
    panes[i] = f
    labels[i] = lbl
    details[i] = det
    icons[i] = icon
  end

  if isHorde then
    labels[1]:SetText('Orc')
    labels[2]:SetText('Troll')
    labels[3]:SetText('Tauren')
    labels[4]:SetText('Undead')
  else
    labels[1]:SetText('Dwarf')
    labels[2]:SetText('Night Elf')
    labels[3]:SetText('Human')
    labels[4]:SetText('Gnome')
  end

  local layoutCtx = {
    root = root,
    parent = parent,
    rightInset = rightInset,
    refreshRow = refreshRow,
    panes = panes,
    labels = labels,
    details = details,
    icons = icons,
    raceTokens = raceTokens,
    playerRaceToken = playerRaceToken,
    totalH = totalH,
  }

  local function runLayout()
    layoutGrid(layoutCtx)
  end

  refreshBtn:SetScript('OnClick', function()
    if GuildRoster then
      GuildRoster()
    end
    RaceLocked_GuildChampion_RefreshRaceGridDisplay(panes, raceTokens)
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        RaceLocked_GuildChampion_RefreshRaceGridDisplay(panes, raceTokens)
        RaceLocked_GuildChampion_PrintGuildAverageAfterRefresh()
      end)
    else
      RaceLocked_GuildChampion_PrintGuildAverageAfterRefresh()
    end
  end)

  if GuildRoster then
    GuildRoster()
  end

  root:RegisterEvent('GUILD_ROSTER_UPDATE')
  root:RegisterEvent('PLAYER_GUILD_UPDATE')
  root:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_GUILD_UPDATE' or event == 'GUILD_ROSTER_UPDATE' then
      RaceLocked_GuildChampion_RefreshRaceGridDisplay(panes, raceTokens)
    end
  end)

  root:SetScript('OnSizeChanged', runLayout)
  root:SetScript('OnShow', function()
    runLayout()
    if C_Timer and C_Timer.After then
      C_Timer.After(0, runLayout)
    end
  end)
  runLayout()

  return root, layoutCtx.totalH
end
