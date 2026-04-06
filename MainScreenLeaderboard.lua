-- On-screen Guild Wars: same combined roster as settings (both guilds + player), globally sorted

local FRAME_WIDTH = 202
local ROW_H = 18
local ROW_GAP = 2
local VISIBLE_ROWS = 7
-- Asymmetric: 1px tighter on the left so the table sits slightly left (inner width unchanged).
local FRAME_PAD_LEFT = 5
local FRAME_PAD_RIGHT = 7
-- Top 1px tighter than bottom so content sits higher inside the dialog art.
local FRAME_PAD_TOP = 5
local FRAME_PAD_BOTTOM = 6
local BOTTOM_PAD = 6

local ROW_BG_XARYU = { r = 0.38, g = 0.22, b = 0.52, a = 0.92 }
-- Same values as settings tab local-player row (`RaceWarsLeaderboardTab.lua`).
local ROW_HIGHLIGHT_LOCAL = { bg = { r = 0.55, g = 0.38, b = 0.14, a = 1 }, border = { r = 1, g = 0.85, b = 0.25, a = 1 } }
local ROW_BG_PIKABOO = { r = 0.12, g = 0.38, b = 0.22, a = 0.92 }

local function setRowBackdropPlain(row)
  row:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    edgeFile = nil,
    tile = false,
    edgeSize = 0,
  })
end

local function setRowBackdropLocalHighlight(row)
  row:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    tile = false,
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  row:SetBackdropColor(ROW_HIGHLIGHT_LOCAL.bg.r, ROW_HIGHLIGHT_LOCAL.bg.g, ROW_HIGHLIGHT_LOCAL.bg.b, ROW_HIGHLIGHT_LOCAL.bg.a)
  row:SetBackdropBorderColor(
    ROW_HIGHLIGHT_LOCAL.border.r,
    ROW_HIGHLIGHT_LOCAL.border.g,
    ROW_HIGHLIGHT_LOCAL.border.b,
    ROW_HIGHLIGHT_LOCAL.border.a
  )
end

local function contentWidth(frameW)
  return frameW - FRAME_PAD_LEFT - FRAME_PAD_RIGHT
end

local innerW = contentWidth(FRAME_WIDTH)

-- #, Name, Rivals Defeated, Rivals Slain, Lvl — packs to width `w`
local function layoutRowColumns(w)
  w = math.max(80, math.floor(w + 0.5))
  local lEdge, rEdge, gapRN = 1, 2, 1
  local colRankW = math.floor(math.min(28, math.max(16, w * 0.10)))
  local xName = lEdge + colRankW + gapRN
  local colLvlW = math.floor(math.min(28, math.max(16, w * 0.10)))
  local mid = w - rEdge - xName - colLvlW - 2 * gapRN
  local colDefW = math.floor(math.max(18, math.min(50, w * 0.14)))
  local colSlW = math.floor(math.max(18, math.min(50, w * 0.14)))
  local colNameW = mid - colDefW - colSlW
  if colNameW < 20 then
    colNameW = 20
    local spare = mid - colNameW
    colDefW = math.floor(spare / 2)
    colSlW = spare - colDefW
  end
  local xDef = xName + colNameW + gapRN
  local xSl = xDef + colDefW + gapRN
  return colRankW, colNameW, colDefW, colSlW, colLvlW, lEdge, rEdge, gapRN, xName, xDef, xSl
end

local mainFrame = CreateFrame('Frame', 'RaceWarsMainLeaderboardFrame', UIParent, 'BackdropTemplate')
mainFrame:SetSize(FRAME_WIDTH, 279)
mainFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 360, -10)
mainFrame:SetFrameStrata('LOW')
mainFrame:SetFrameLevel(5)

-- Outer panel fill only (no edge); border is a separate overlay above the table.
mainFrame:SetBackdrop({
  bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
  edgeFile = nil,
  tile = true,
  tileSize = 32,
  edgeSize = 16,
  insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
mainFrame:SetBackdropColor(1, 1, 1, 1)

local TABLE_HEADER_H = 18

local LAYER_BG = 1
local LAYER_TABLE = 3
local LAYER_BORDER = 10

-- Solid fill behind the table (header + rows); sits under them, above the outer panel texture.
local tableContentBg = CreateFrame('Frame', nil, mainFrame, 'BackdropTemplate')
tableContentBg:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', FRAME_PAD_LEFT, -FRAME_PAD_TOP)
tableContentBg:SetPoint('BOTTOMRIGHT', mainFrame, 'BOTTOMRIGHT', -FRAME_PAD_RIGHT, FRAME_PAD_BOTTOM)
tableContentBg:SetFrameStrata(mainFrame:GetFrameStrata())
tableContentBg:SetFrameLevel(mainFrame:GetFrameLevel() + LAYER_BG)
tableContentBg:EnableMouse(false)
tableContentBg:SetBackdrop({
  bgFile = 'Interface\\Buttons\\WHITE8x8',
  edgeFile = nil,
  tile = false,
  edgeSize = 0,
})
tableContentBg:SetBackdropColor(0.07, 0.06, 0.055, 1)

-- Header inset matches table horizontal inset.
local function buildTableHeader(parent, w)
  local cr, cn, cd, cs, cl, lEdge, rEdge, gapRN, xName, xDef, xSl = layoutRowColumns(w)
  local strip = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  strip:SetHeight(TABLE_HEADER_H)
  strip:SetPoint('TOPLEFT', parent, 'TOPLEFT', FRAME_PAD_LEFT, -FRAME_PAD_TOP)
  strip:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -FRAME_PAD_RIGHT, -FRAME_PAD_TOP)
  strip:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = nil, tile = false, edgeSize = 0 })
  strip:SetBackdropColor(0.12, 0.1, 0.08, 0.98)

  local hRank = strip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  hRank:SetPoint('LEFT', strip, 'LEFT', lEdge, 0)
  hRank:SetWidth(cr)
  hRank:SetJustifyH('CENTER')
  hRank:SetText('#')
  hRank:SetTextColor(1, 0.92, 0.62)
  local hName = strip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  hName:SetPoint('LEFT', strip, 'LEFT', xName, 0)
  hName:SetWidth(cn)
  hName:SetJustifyH('LEFT')
  hName:SetText('Name')
  hName:SetTextColor(1, 0.92, 0.62)
  local hDef = strip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  hDef:SetPoint('LEFT', strip, 'LEFT', xDef, 0)
  hDef:SetWidth(cd)
  hDef:SetJustifyH('LEFT')
  hDef:SetText('Rivals Defeated')
  hDef:SetTextColor(1, 0.92, 0.62)
  local hSl = strip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  hSl:SetPoint('LEFT', strip, 'LEFT', xSl, 0)
  hSl:SetWidth(cs)
  hSl:SetJustifyH('LEFT')
  hSl:SetText('Rivals Slain')
  hSl:SetTextColor(1, 0.92, 0.62)
  local hLvl = strip:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  hLvl:SetPoint('RIGHT', strip, 'RIGHT', -rEdge, 0)
  hLvl:SetWidth(cl)
  hLvl:SetJustifyH('RIGHT')
  hLvl:SetText('Lvl')
  hLvl:SetTextColor(1, 0.92, 0.62)
  return strip
end

local tableHeader = buildTableHeader(mainFrame, innerW)

local function makeDataRow(parent, w)
  local cr, cn, cd, cs, cl, lEdge, rEdge, gapRN, xName, xDef, xSl = layoutRowColumns(w)
  local row = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  row:SetHeight(ROW_H)
  setRowBackdropPlain(row)
  row.rankFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.rankFs:SetPoint('LEFT', row, 'LEFT', lEdge, 0)
  row.rankFs:SetWidth(cr)
  row.rankFs:SetJustifyH('CENTER')
  row.nameFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.nameFs:SetPoint('LEFT', row, 'LEFT', xName, 0)
  row.nameFs:SetWidth(cn)
  row.nameFs:SetJustifyH('LEFT')
  row.defeatedFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.defeatedFs:SetPoint('LEFT', row, 'LEFT', xDef, 0)
  row.defeatedFs:SetWidth(cd)
  row.defeatedFs:SetJustifyH('LEFT')
  row.slainFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.slainFs:SetPoint('LEFT', row, 'LEFT', xSl, 0)
  row.slainFs:SetWidth(cs)
  row.slainFs:SetJustifyH('LEFT')
  row.lvlFs = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.lvlFs:SetPoint('RIGHT', row, 'RIGHT', -rEdge, 0)
  row.lvlFs:SetWidth(cl)
  row.lvlFs:SetJustifyH('RIGHT')
  return row
end

local dataRows = {}
for i = 1, VISIBLE_ROWS do
  dataRows[i] = makeDataRow(mainFrame, innerW)
  if i == 1 then
    dataRows[i]:SetPoint('TOPLEFT', tableHeader, 'BOTTOMLEFT', 0, -ROW_GAP)
    dataRows[i]:SetPoint('TOPRIGHT', tableHeader, 'BOTTOMRIGHT', 0, -ROW_GAP)
  else
    dataRows[i]:SetPoint('TOPLEFT', dataRows[i - 1], 'BOTTOMLEFT', 0, -ROW_GAP)
    dataRows[i]:SetPoint('TOPRIGHT', dataRows[i - 1], 'BOTTOMRIGHT', 0, -ROW_GAP)
  end
end

-- Border only (no visible fill): draws on top of the table so the frame sits over the cells.
local borderOverlay = CreateFrame('Frame', nil, mainFrame, 'BackdropTemplate')
borderOverlay:SetAllPoints()
borderOverlay:SetFrameStrata(mainFrame:GetFrameStrata())
borderOverlay:SetFrameLevel(mainFrame:GetFrameLevel() + LAYER_BORDER)
borderOverlay:EnableMouse(false)
borderOverlay:SetBackdrop({
  bgFile = 'Interface\\Buttons\\WHITE8x8',
  edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
  tile = true,
  tileSize = 32,
  edgeSize = 16,
  insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
borderOverlay:SetBackdropColor(1, 1, 1, 0)
borderOverlay:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.85)

local baseLevel = mainFrame:GetFrameLevel()
tableHeader:SetFrameLevel(baseLevel + LAYER_TABLE)
for i = 1, VISIBLE_ROWS do
  dataRows[i]:SetFrameLevel(baseLevel + LAYER_TABLE)
end

-- Row tint by guild (same roster as menu). `data.guild` comes from `LeaderboardData.lua`.
local function styleDataRow(row, data, pos)
  if not data then
    row:Hide()
    return
  end
  row:Show()
  local isLocalPlayer = RaceWars_IsLocalLeaderboardName(data.name)
  if isLocalPlayer then
    setRowBackdropLocalHighlight(row)
    row.rankFs:SetTextColor(1, 0.95, 0.5)
    row.nameFs:SetTextColor(1, 0.95, 0.5)
    row.defeatedFs:SetTextColor(1, 0.92, 0.55)
    row.slainFs:SetTextColor(1, 0.92, 0.55)
    row.lvlFs:SetTextColor(1, 0.92, 0.55)
  elseif data.guild == RaceWars_GUILD_PIKABOO then
    setRowBackdropPlain(row)
    row:SetBackdropColor(ROW_BG_PIKABOO.r, ROW_BG_PIKABOO.g, ROW_BG_PIKABOO.b, ROW_BG_PIKABOO.a)
    row.rankFs:SetTextColor(0.75, 0.96, 0.82)
    row.nameFs:SetTextColor(0.94, 0.98, 0.94)
    row.defeatedFs:SetTextColor(0.88, 0.95, 0.88)
    row.slainFs:SetTextColor(0.88, 0.95, 0.88)
    row.lvlFs:SetTextColor(0.88, 0.95, 0.88)
  else
    setRowBackdropPlain(row)
    row:SetBackdropColor(ROW_BG_XARYU.r, ROW_BG_XARYU.g, ROW_BG_XARYU.b, ROW_BG_XARYU.a)
    row.rankFs:SetTextColor(0.88, 0.82, 1)
    row.nameFs:SetTextColor(0.95, 0.92, 1)
    row.defeatedFs:SetTextColor(0.9, 0.86, 0.98)
    row.slainFs:SetTextColor(0.9, 0.86, 0.98)
    row.lvlFs:SetTextColor(0.9, 0.86, 0.98)
  end
  row.rankFs:SetText(tostring(pos))
  row.nameFs:SetText(data.name)
  row.defeatedFs:SetText(RaceWars_FormatRivalsDefeatedCell(data))
  row.slainFs:SetText(tostring(RaceWars_GetLeaderboardEntryTotalSlain(data)))
  row.lvlFs:SetText(tostring(data.level))
end

local function refreshMainLeaderboard()
  if RaceWars_GetMainScreenCombinedLeaderboardWindow then
    local window, rankStart = RaceWars_GetMainScreenCombinedLeaderboardWindow(VISIBLE_ROWS)
    for i = 1, VISIBLE_ROWS do
      local data = window[i]
      local pos = data and ((rankStart or 1) + i - 1) or nil
      styleDataRow(dataRows[i], data, pos)
    end
  end

  local topBlock = FRAME_PAD_TOP + TABLE_HEADER_H
  local rowsBlock = VISIBLE_ROWS * (ROW_H + ROW_GAP)
  mainFrame:SetHeight(math.max(109, topBlock + rowsBlock + BOTTOM_PAD - 1))
end

mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag('LeftButton')
mainFrame:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)
mainFrame:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
end)

local mouseDownPos
mainFrame:SetScript('OnMouseDown', function(_, button)
  if button == 'LeftButton' then
    local x, y = GetCursorPosition()
    local s = mainFrame:GetEffectiveScale()
    mouseDownPos = { x = x / s, y = y / s }
  end
end)
mainFrame:SetScript('OnMouseUp', function(_, button)
  if button == 'LeftButton' and mouseDownPos then
    local x, y = GetCursorPosition()
    local s = mainFrame:GetEffectiveScale()
    x, y = x / s, y / s
    local dx = math.abs(x - mouseDownPos.x)
    local dy = math.abs(y - mouseDownPos.y)
    mouseDownPos = nil
    if dx < 4 and dy < 4 and _G.ToggleRaceWarsSettings then
      _G.ToggleRaceWarsSettings()
    end
  end
end)
mainFrame:SetScript('OnEnter', function()
  GameTooltip:SetOwner(mainFrame, 'ANCHOR_RIGHT')
  GameTooltip:SetText(
    'Left-click: open settings\nDrag: move panel',
    nil,
    nil,
    nil,
    nil,
    true
  )
  GameTooltip:Show()
end)
mainFrame:SetScript('OnLeave', function()
  mouseDownPos = nil
  GameTooltip:Hide()
end)

mainFrame:RegisterEvent('PLAYER_LOGIN')
mainFrame:RegisterEvent('PLAYER_LEVEL_UP')
mainFrame:SetScript('OnEvent', function(self, event)
  if event == 'PLAYER_LOGIN' or event == 'PLAYER_LEVEL_UP' then
    refreshMainLeaderboard()
  end
end)

RaceWarsMainLeaderboardFrame = mainFrame
RaceWars_RefreshMainScreenLeaderboard = refreshMainLeaderboard

refreshMainLeaderboard()
