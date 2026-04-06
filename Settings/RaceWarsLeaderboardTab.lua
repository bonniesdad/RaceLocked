-- Guild leaderboard tabs: one full-width panel per guild tab (Xaryu / Pikaboo).

local ROW_HEIGHT = 18
local ROW_GAP = 1
local HEADER_ROW_HEIGHT = 20
local PANEL_SIDE_MARGIN = 0
local PANEL_PAD = 8
local SCROLL_BAR_WIDTH = 26
local ROW_BG_XARYU = { r = 0.38, g = 0.22, b = 0.52, a = 0.92 }
local ROW_BG_PIKABOO = { r = 0.12, g = 0.38, b = 0.22, a = 0.92 }
local HEADER_STRIP = { r = 0.12, g = 0.10, b = 0.08, a = 0.98 }

-- Per-race keys: summary card shows all four races with defeated + slain per race.
local SLAIN_COLUMNS = {
  { key = 'orc', label = 'Orc', field = 'slainOrc' },
  { key = 'tauren', label = 'Tauren', field = 'slainTauren' },
  { key = 'troll', label = 'Troll', field = 'slainTroll' },
  { key = 'undead', label = 'Undead', field = 'slainUndead' },
}
local SLAIN_CELL_PAD = 12

local RACE_CHIP_ICON = {
  orc = 'Interface\\Icons\\INV_Misc_Tournaments_Banner_Orc',
  tauren = 'Interface\\Icons\\INV_Misc_Tournaments_Banner_Tauren',
  troll = 'Interface\\Icons\\INV_Misc_Tournaments_Banner_Troll',
  undead = 'Interface\\Icons\\INV_Misc_Tournaments_Banner_Scourge',
}
-- Left stripe matches each race’s faction palette (not guild tint).
local RACE_CHIP_STRIPE_RGB = {
  orc = { r = 0.22, g = 0.68, b = 0.28 },
  tauren = { r = 0.72, g = 0.52, b = 0.30 },
  troll = { r = 0.18, g = 0.62, b = 0.78 },
  undead = { r = 0.55, g = 0.32, b = 0.68 },
}
local RACE_CHIP_STRIPE_W = 3
local RACE_CHIP_ICON_SIZE = 20
local RACE_CHIP_ICON_GAP = 4
local NAME_COL_SHRINK = 20
local NAME_TO_LEVEL_SHIFT = 20
local NAME_TO_TOTAL_SHIFT = 5
local GUILD_STATS_CARD_HEIGHT = 148
local GUILD_STATS_TOP_OFFSET = -10
local GUILD_STATS_TO_TABLE_GAP = 16
local GUILD_STATS_CARD_PAD = 10
local PANEL_BACKDROP = {
  bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  tile = true,
  tileSize = 64,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function createLeaderboardPanel(parent, rows, rowTint, panelWidth, anchorSide)
  local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  panel:SetBackdrop(PANEL_BACKDROP)
  panel:SetBackdropColor(0.06, 0.05, 0.05, 0.92)
  panel:SetBackdropBorderColor(0.45, 0.4, 0.3, 0.9)
  if anchorSide ~= 'FULL' then
    panel:SetWidth(panelWidth)
  end
  if anchorSide == 'FULL' then
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
    panel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, 0)
  elseif anchorSide == 'LEFT' then
    panel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
    panel:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', 0, 0)
  else
    panel:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 0, 0)
    panel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, 0)
  end

  local tableTopY = GUILD_STATS_TOP_OFFSET - GUILD_STATS_CARD_HEIGHT - GUILD_STATS_TO_TABLE_GAP
  local tableTop = CreateFrame('Frame', nil, panel)
  tableTop:SetPoint('TOPLEFT', panel, 'TOPLEFT', PANEL_PAD, tableTopY)
  tableTop:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -PANEL_PAD, tableTopY)
  tableTop:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', PANEL_PAD, PANEL_PAD)
  tableTop:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -PANEL_PAD, PANEL_PAD)

  local tableInnerWidth = panelWidth - (PANEL_PAD * 2)
  if tableInnerWidth < 80 then
    tableInnerWidth = 200
  end
  -- Match list viewport width (scrollbar sits to the right of header + rows)
  local listInnerW = tableInnerWidth - SCROLL_BAR_WIDTH
  if listInnerW < 60 then
    listInnerW = tableInnerWidth * 0.88
  end

  local visibleSlain = {}
  for s = 1, #SLAIN_COLUMNS do
    visibleSlain[#visibleSlain + 1] = SLAIN_COLUMNS[s]
  end

  if RaceWars_SortLeaderboardInPlace then
    RaceWars_SortLeaderboardInPlace(rows)
  end

  local RIVALS_LABEL_DEFEATED = 'Rivals Defeated'
  local RIVALS_LABEL_SLAIN = 'Rivals Slain'

  local measureFs = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  measureFs:SetText(RIVALS_LABEL_DEFEATED)
  local colDefW = math.ceil(measureFs:GetStringWidth()) + SLAIN_CELL_PAD
  measureFs:SetText(RIVALS_LABEL_SLAIN)
  local colSlW = math.ceil(measureFs:GetStringWidth()) + SLAIN_CELL_PAD
  measureFs:SetText('10')
  local numW = math.ceil(measureFs:GetStringWidth()) + SLAIN_CELL_PAD
  colDefW = math.max(colDefW, numW)
  colSlW = math.max(colSlW, numW)
  measureFs:Hide()

  local colRankW = math.floor(math.min(32, math.max(22, listInnerW * 0.065)))
  local colLevelW = math.floor(math.min(32, math.max(24, listInnerW * 0.078)))
  colLevelW = colLevelW + NAME_TO_LEVEL_SHIFT
  local restW = math.max(40, listInnerW - colRankW - colDefW - colSlW - colLevelW)
  local colNameW = math.max(48, restW - NAME_COL_SHRINK - NAME_TO_TOTAL_SHIFT)
  local xDef = colRankW + colNameW
  local xSl = xDef + colDefW

  local sumSlainOrc, sumSlainTauren, sumSlainTroll, sumSlainUndead = 0, 0, 0, 0
  local sumRowTotals = 0
  local sumGuildRivalsDefeated = 0
  local sumDefeatedOrc, sumDefeatedTauren, sumDefeatedTroll, sumDefeatedUndead = 0, 0, 0, 0
  for ri = 1, #rows do
    local e = rows[ri]
    sumSlainOrc = sumSlainOrc + (e.slainOrc or 0)
    sumSlainTauren = sumSlainTauren + (e.slainTauren or 0)
    sumSlainTroll = sumSlainTroll + (e.slainTroll or 0)
    sumSlainUndead = sumSlainUndead + (e.slainUndead or 0)
    sumRowTotals = sumRowTotals + RaceWars_GetLeaderboardEntryTotalSlain(e)
    local rd = RaceWars_GetLeaderboardEntryRivalsDefeated(e)
    sumGuildRivalsDefeated = sumGuildRivalsDefeated + rd
    local t = RaceWars_GetLeaderboardEntryTotalSlain(e)
    if t > 0 then
      sumDefeatedOrc = sumDefeatedOrc + rd * (e.slainOrc or 0) / t
      sumDefeatedTauren = sumDefeatedTauren + rd * (e.slainTauren or 0) / t
      sumDefeatedTroll = sumDefeatedTroll + rd * (e.slainTroll or 0) / t
      sumDefeatedUndead = sumDefeatedUndead + rd * (e.slainUndead or 0) / t
    else
      local q = rd / 4
      sumDefeatedOrc = sumDefeatedOrc + q
      sumDefeatedTauren = sumDefeatedTauren + q
      sumDefeatedTroll = sumDefeatedTroll + q
      sumDefeatedUndead = sumDefeatedUndead + q
    end
  end
  local sumBySlainKey = {
    orc = sumSlainOrc,
    tauren = sumSlainTauren,
    troll = sumSlainTroll,
    undead = sumSlainUndead,
  }
  local defFloor = {
    orc = math.floor(sumDefeatedOrc),
    tauren = math.floor(sumDefeatedTauren),
    troll = math.floor(sumDefeatedTroll),
    undead = math.floor(sumDefeatedUndead),
  }
  local defRem =
    sumGuildRivalsDefeated
    - (defFloor.orc + defFloor.tauren + defFloor.troll + defFloor.undead)
  local defFrac = {
    { k = 'orc', f = sumDefeatedOrc - defFloor.orc },
    { k = 'tauren', f = sumDefeatedTauren - defFloor.tauren },
    { k = 'troll', f = sumDefeatedTroll - defFloor.troll },
    { k = 'undead', f = sumDefeatedUndead - defFloor.undead },
  }
  table.sort(defFrac, function(a, b)
    if a.f == b.f then
      return a.k < b.k
    end
    return a.f > b.f
  end)
  for i = 1, math.max(0, defRem) do
    defFloor[defFrac[i].k] = defFloor[defFrac[i].k] + 1
  end
  local sumDefBySlainKey = defFloor

  do
    local card = CreateFrame('Frame', nil, panel, 'BackdropTemplate')
    card:SetHeight(GUILD_STATS_CARD_HEIGHT)
    card:SetClipsChildren(true)
    card:SetPoint('TOPLEFT', panel, 'TOPLEFT', PANEL_PAD, GUILD_STATS_TOP_OFFSET)
    card:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -PANEL_PAD, GUILD_STATS_TOP_OFFSET)
    card:SetBackdrop({
      bgFile = 'Interface\\Buttons\\WHITE8x8',
      edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
      tile = false,
      edgeSize = 10,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    card:SetBackdropColor(0.05, 0.048, 0.045, 0.94)
    card:SetBackdropBorderColor(
      math.min(1, rowTint.r * 0.55 + 0.22),
      math.min(1, rowTint.g * 0.55 + 0.18),
      math.min(1, rowTint.b * 0.45 + 0.12),
      0.4
    )

    local accent = card:CreateTexture(nil, 'BORDER')
    accent:SetWidth(3)
    accent:SetPoint('TOPLEFT', card, 'TOPLEFT', 3, -3)
    accent:SetPoint('BOTTOMLEFT', card, 'BOTTOMLEFT', 3, 3)
    accent:SetColorTexture(rowTint.r, rowTint.g, rowTint.b, 0.9)

    local insetL = 12 + GUILD_STATS_CARD_PAD

    local topName = rows[1] and rows[1].name
    if not topName or topName == '' then
      topName = '—'
    end

    local championFs = card:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    championFs:SetPoint('TOPLEFT', card, 'TOPLEFT', insetL, -GUILD_STATS_CARD_PAD - 2)
    championFs:SetText('Champion: ' .. tostring(topName))
    championFs:SetTextColor(0.98, 0.86, 0.42)

    local nextFightUnix = RaceWars_GetNextFightUnix and RaceWars_GetNextFightUnix()
    local nextFightStr = (RaceWars_FormatNextFightLocal and RaceWars_FormatNextFightLocal(nextFightUnix)) or 'TBD'
    local nextFightFs = card:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    nextFightFs:SetPoint('TOPLEFT', championFs, 'BOTTOMLEFT', 0, -4)
    nextFightFs:SetText('Next Fight: ' .. nextFightStr)
    nextFightFs:SetTextColor(0.65, 0.72, 0.68)

    local eyebrow = card:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    eyebrow:SetPoint('TOPLEFT', nextFightFs, 'BOTTOMLEFT', 0, -10)
    eyebrow:SetText('Rivals by race (Orc, Tauren, Troll, Undead)')
    eyebrow:SetTextColor(0.55, 0.6, 0.52)

    local totalNum = card:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    totalNum:SetPoint('TOPLEFT', eyebrow, 'BOTTOMLEFT', 0, -4)
    totalNum:SetText(
      string.format(
        'Defeated: %s   Slain: %d',
        RaceWars_FormatRivalsDefeatedCount(sumGuildRivalsDefeated),
        sumRowTotals
      )
    )
    totalNum:SetTextColor(0.98, 0.84, 0.4)

    local cardInnerW = math.max(120, tableInnerWidth - insetL - GUILD_STATS_CARD_PAD)
    local racesRow = CreateFrame('Frame', nil, card)
    racesRow:SetHeight(46)
    racesRow:SetPoint('TOPLEFT', totalNum, 'BOTTOMLEFT', 0, -6)
    racesRow:SetWidth(cardInnerW)

    local nRace = math.max(1, #visibleSlain)
    local chipW = cardInnerW / nRace

    local bdrR = rowTint.r * 0.5 + 0.12
    local bdrG = rowTint.g * 0.5 + 0.1
    local bdrB = rowTint.b * 0.45 + 0.08

    for v = 1, #visibleSlain do
      local col = visibleSlain[v]
      local stripeRgb = RACE_CHIP_STRIPE_RGB[col.key] or RACE_CHIP_STRIPE_RGB.orc
      local cw = math.max(24, chipW - 4)
      if cw > chipW - 2 then
        cw = math.max(20, chipW - 2)
      end
      local chip = CreateFrame('Frame', nil, racesRow, 'BackdropTemplate')
      chip:SetSize(cw, 42)
      chip:SetPoint('TOPLEFT', racesRow, 'TOPLEFT', (v - 1) * chipW + (chipW - cw) / 2, 0)
      chip:SetBackdrop({
        bgFile = 'Interface\\Buttons\\WHITE8x8',
        edgeFile = 'Interface\\Buttons\\WHITE8x8',
        tile = false,
        edgeSize = 1,
      })
      chip:SetBackdropColor(0.08, 0.09, 0.08, 0.65)
      chip:SetBackdropBorderColor(bdrR, bdrG, bdrB, 0.5)

      local chipStripe = chip:CreateTexture(nil, 'ARTWORK')
      chipStripe:SetWidth(RACE_CHIP_STRIPE_W)
      chipStripe:SetPoint('TOPLEFT', chip, 'TOPLEFT', 1, -1)
      chipStripe:SetPoint('BOTTOMLEFT', chip, 'BOTTOMLEFT', 1, 1)
      chipStripe:SetColorTexture(stripeRgb.r, stripeRgb.g, stripeRgb.b, 0.95)

      local iconPath = RACE_CHIP_ICON[col.key]
      if iconPath then
        local icon = chip:CreateTexture(nil, 'ARTWORK')
        icon:SetSize(RACE_CHIP_ICON_SIZE, RACE_CHIP_ICON_SIZE)
        icon:SetPoint('LEFT', chip, 'LEFT', RACE_CHIP_STRIPE_W + RACE_CHIP_ICON_GAP, 0)
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      end

      local textX = RACE_CHIP_STRIPE_W + RACE_CHIP_ICON_GAP + RACE_CHIP_ICON_SIZE + RACE_CHIP_ICON_GAP
      local textW = math.max(24, cw - textX - 4)

      local cl = chip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
      cl:SetPoint('TOPLEFT', chip, 'TOPLEFT', textX, -3)
      cl:SetWidth(textW)
      cl:SetJustifyH('LEFT')
      cl:SetText(col.label)
      cl:SetTextColor(0.72, 0.74, 0.68)

      local cvDef = chip:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
      cvDef:SetPoint('TOPLEFT', cl, 'BOTTOMLEFT', 0, -2)
      cvDef:SetWidth(textW)
      cvDef:SetJustifyH('LEFT')
      cvDef:SetText('Defeated: ' .. RaceWars_FormatRivalsDefeatedCount(sumDefBySlainKey[col.key]))
      cvDef:SetTextColor(0.85, 0.92, 0.8)

      local cvSl = chip:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
      cvSl:SetPoint('TOPLEFT', cvDef, 'BOTTOMLEFT', 0, -1)
      cvSl:SetWidth(textW)
      cvSl:SetJustifyH('LEFT')
      cvSl:SetText('Slain: ' .. tostring(sumBySlainKey[col.key] or 0))
      cvSl:SetTextColor(0.95, 0.9, 0.75)
    end
  end

  local headerBg = CreateFrame('Frame', nil, tableTop, 'BackdropTemplate')
  headerBg:SetHeight(HEADER_ROW_HEIGHT)
  headerBg:SetPoint('TOPLEFT', tableTop, 'TOPLEFT', 0, 0)
  headerBg:SetPoint('TOPRIGHT', tableTop, 'TOPRIGHT', -SCROLL_BAR_WIDTH, 0)
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

  local hDef = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hDef:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', xDef, -3)
  hDef:SetWidth(colDefW)
  hDef:SetJustifyH('LEFT')
  hDef:SetText(RIVALS_LABEL_DEFEATED)
  hDef:SetTextColor(1, 0.92, 0.62)

  local hSl = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hSl:SetPoint('TOPLEFT', headerBg, 'TOPLEFT', xSl, -3)
  hSl:SetWidth(colSlW)
  hSl:SetJustifyH('LEFT')
  hSl:SetText(RIVALS_LABEL_SLAIN)
  hSl:SetTextColor(1, 0.92, 0.62)

  local hLvl = headerBg:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hLvl:SetPoint('TOPRIGHT', headerBg, 'TOPRIGHT', -4, -3)
  hLvl:SetWidth(colLevelW - 4)
  hLvl:SetJustifyH('RIGHT')
  hLvl:SetText('Level')
  hLvl:SetTextColor(1, 0.92, 0.62)

  local rowStep = ROW_HEIGHT + ROW_GAP
  local scrollChildHeight = #rows * ROW_HEIGHT + math.max(0, #rows - 1) * ROW_GAP

  local scroll = CreateFrame('ScrollFrame', nil, tableTop, 'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT', headerBg, 'BOTTOMLEFT', 0, -ROW_GAP)
  scroll:SetPoint('BOTTOMRIGHT', tableTop, 'BOTTOMRIGHT', -SCROLL_BAR_WIDTH, 0)
  scroll:EnableMouseWheel(true)

  local scrollChild = CreateFrame('Frame', nil, scroll)
  scrollChild:SetWidth(listInnerW)
  scrollChild:SetHeight(math.max(scrollChildHeight, 1))
  scroll:SetScrollChild(scrollChild)

  scroll:SetScript('OnSizeChanged', function(self)
    local w = self:GetWidth()
    if w and w > 4 then
      scrollChild:SetWidth(w)
    end
  end)

  for i = 1, #rows do
    local y = -((i - 1) * rowStep)
    local row = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, y)
    row:SetPoint('TOPRIGHT', scrollChild, 'TOPRIGHT', 0, y)

    local data = rows[i]
    local isLocal = RaceWars_IsLocalLeaderboardName and RaceWars_IsLocalLeaderboardName(data.name)
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
    nameFs:SetText(data.name)
    if isLocal then
      nameFs:SetTextColor(1, 0.95, 0.5)
    else
      nameFs:SetTextColor(0.95, 0.95, 0.9)
    end

    local defFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    defFs:SetPoint('LEFT', row, 'LEFT', xDef, 0)
    defFs:SetWidth(colDefW)
    defFs:SetJustifyH('LEFT')
    defFs:SetText(RaceWars_FormatRivalsDefeatedCell(data))
    if isLocal then
      defFs:SetTextColor(1, 0.92, 0.55)
    else
      defFs:SetTextColor(0.9, 0.88, 0.82)
    end

    local slainFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    slainFs:SetPoint('LEFT', row, 'LEFT', xSl, 0)
    slainFs:SetWidth(colSlW)
    slainFs:SetJustifyH('LEFT')
    slainFs:SetText(tostring(RaceWars_GetLeaderboardEntryTotalSlain(data)))
    if isLocal then
      slainFs:SetTextColor(1, 0.92, 0.55)
    else
      slainFs:SetTextColor(0.9, 0.88, 0.82)
    end

    local lvlFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    lvlFs:SetPoint('RIGHT', row, 'RIGHT', -4, 0)
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

local GUILD_LEADERBOARD_TAB_CONFIG = {
  {
    guildKey = RaceWars_GUILD_XARYU,
    rowTint = ROW_BG_XARYU,
  },
  {
    guildKey = RaceWars_GUILD_PIKABOO,
    rowTint = ROW_BG_PIKABOO,
  },
}

function RaceWars_InitializeGuildLeaderboardTab(tabContents, guildTabIndex)
  if not tabContents or not tabContents[guildTabIndex] then return end
  local cfg = GUILD_LEADERBOARD_TAB_CONFIG[guildTabIndex]
  if not cfg then return end

  local content = tabContents[guildTabIndex]
  if content.initialized then return end
  content.initialized = true

  local container = CreateFrame('Frame', nil, content)
  container:SetPoint('TOPLEFT', content, 'TOPLEFT', PANEL_SIDE_MARGIN, -12)
  container:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_SIDE_MARGIN, 12)

  local contentW = content:GetWidth()
  if not contentW or contentW < 100 then
    contentW = 508
  end

  local innerW = contentW - (PANEL_SIDE_MARGIN * 2)
  local rows = (RaceWars_GetSortedGuildLeaderboardCopy and RaceWars_GetSortedGuildLeaderboardCopy(cfg.guildKey)) or {}
  createLeaderboardPanel(container, rows, cfg.rowTint, innerW, 'FULL')
end
