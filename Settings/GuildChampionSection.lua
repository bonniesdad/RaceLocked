-- Guild Champion summary above the settings leaderboard table.
-- Two bordered sub-panels (~60% / ~40%) with separate background tints.

local MID_GAP = 6
local CHAMPION_WIDTH_FRAC = 0.60
local OUTER_PAD_Y = 4

local SECTION_H = 58
local INNER_PAD = 8
local ICON_CHAMPION = 34
local ICON_PAD = 2

local LABEL_GOLD = { 1, 0.92, 0.62 }
local NAME_COLOR = { 0.95, 0.93, 0.88 }
local MUTED = { 0.62, 0.6, 0.55 }

-- Champion panel: warm brown-gold tint
local CHAMPION_BG = { r = 0.16, g = 0.12, b = 0.08, a = 0.94 }
local CHAMPION_BORDER = { r = 0.58, g = 0.5, b = 0.32, a = 0.92 }

-- AP panel: cooler slate tint
local AP_BG = { r = 0.08, g = 0.1, b = 0.14, a = 0.94 }
local AP_BORDER = { r = 0.38, g = 0.45, b = 0.52, a = 0.88 }

local CHAMPION_ICON_TEX = 'Interface\\Icons\\spell_holy_surgeoflight'

local PANEL_BACKDROP = {
  bgFile = 'Interface\\Buttons\\WHITE8x8',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  tile = false,
  edgeSize = 10,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local AP_PANEL_BACKDROP = {
  bgFile = 'Interface\\Buttons\\WHITE8x8',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  tile = false,
  edgeSize = 8,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function makeIconFrame(parent, size, texturePath, edgeSize)
  edgeSize = edgeSize or 8
  local f = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  f:SetSize(size + ICON_PAD * 2, size + ICON_PAD * 2)
  f:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8x8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = false,
    edgeSize = edgeSize,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  f:SetBackdropColor(0.04, 0.04, 0.05, 1)
  f:SetBackdropBorderColor(0.48, 0.44, 0.36, 0.88)
  local t = f:CreateTexture(nil, 'ARTWORK')
  t:SetPoint('TOPLEFT', f, 'TOPLEFT', ICON_PAD, -ICON_PAD)
  t:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -ICON_PAD, ICON_PAD)
  t:SetTexture(texturePath)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return f
end

--- @param parent Frame
--- @param sortedRows table[]|nil same sort as leaderboard (#1 = top rank)
--- @param rightInset number align with leaderboard panel (e.g. PANEL_RIGHT_INSET)
--- @return number total height including internal padding
function RaceLocked_CreateGuildChampionSection(parent, sortedRows, rightInset)
  rightInset = rightInset or 0

  local topRank = sortedRows and sortedRows[1] or nil
  local topAp = nil
  if RaceLocked_GetTopAchievementPointsLeaderboardRowFromRows then
    topAp = RaceLocked_GetTopAchievementPointsLeaderboardRowFromRows(sortedRows)
  end

  local innerH = SECTION_H
  local root = CreateFrame('Frame', nil, parent)
  root:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
  root:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -rightInset, 0)
  root:SetHeight(OUTER_PAD_Y * 2 + innerH)

  local championPane = CreateFrame('Frame', nil, root, 'BackdropTemplate')
  championPane:SetBackdrop(PANEL_BACKDROP)
  championPane:SetBackdropColor(CHAMPION_BG.r, CHAMPION_BG.g, CHAMPION_BG.b, CHAMPION_BG.a)
  championPane:SetBackdropBorderColor(CHAMPION_BORDER.r, CHAMPION_BORDER.g, CHAMPION_BORDER.b, CHAMPION_BORDER.a)
  championPane:SetHeight(innerH)
  championPane:SetPoint('TOPLEFT', root, 'TOPLEFT', 0, -OUTER_PAD_Y)

  local apPane = CreateFrame('Frame', nil, root, 'BackdropTemplate')
  apPane:SetBackdrop(AP_PANEL_BACKDROP)
  apPane:SetBackdropColor(AP_BG.r, AP_BG.g, AP_BG.b, AP_BG.a)
  apPane:SetBackdropBorderColor(AP_BORDER.r, AP_BORDER.g, AP_BORDER.b, AP_BORDER.a)
  apPane:SetHeight(innerH)

  local iconChamp = makeIconFrame(championPane, ICON_CHAMPION, CHAMPION_ICON_TEX)

  local championTextHost = CreateFrame('Frame', nil, championPane)
  championTextHost:SetHeight(40)

  local labelChampion = championTextHost:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  labelChampion:SetJustifyH('LEFT')
  labelChampion:SetText('Guild Champion')
  labelChampion:SetTextColor(LABEL_GOLD[1], LABEL_GOLD[2], LABEL_GOLD[3])

  local nameChampion = championTextHost:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  nameChampion:SetJustifyH('LEFT')
  -- Stack straddles host vertical center so the block reads centered in the panel.
  labelChampion:SetPoint('LEFT', championTextHost, 'LEFT', 0, 0)
  labelChampion:SetPoint('RIGHT', championTextHost, 'RIGHT', 0, 0)
  labelChampion:SetPoint('BOTTOM', championTextHost, 'CENTER', 0, 2)
  nameChampion:SetPoint('LEFT', championTextHost, 'LEFT', 0, 0)
  nameChampion:SetPoint('RIGHT', championTextHost, 'RIGHT', 0, 0)
  nameChampion:SetPoint('TOP', championTextHost, 'CENTER', 0, -5)
  if topRank and topRank.name and topRank.name ~= '' then
    nameChampion:SetText(tostring(topRank.name))
    nameChampion:SetTextColor(NAME_COLOR[1], NAME_COLOR[2], NAME_COLOR[3])
  else
    nameChampion:SetText('—')
    nameChampion:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
  end

  local labelAp = apPane:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  labelAp:SetJustifyH('CENTER')
  labelAp:SetText('Most Achievements')
  labelAp:SetTextColor(LABEL_GOLD[1] * 0.9, LABEL_GOLD[2] * 0.9, LABEL_GOLD[3] * 0.9)

  local detailAp = apPane:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  detailAp:SetJustifyH('CENTER')
  detailAp:SetWordWrap(true)
  if topAp and topAp.name and topAp.name ~= '' then
    detailAp:SetText(string.format('%s  ·  %s', tostring(topAp.name), tostring(topAp.achievementPoints or 0)))
    detailAp:SetTextColor(0.82, 0.8, 0.74)
  else
    detailAp:SetText('—')
    detailAp:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
  end

  local function layoutColumns()
    local rw = root:GetWidth()
    if (not rw or rw < 2) and parent and parent.GetWidth then
      rw = math.max(0, parent:GetWidth() - rightInset)
    end
    local w = rw - MID_GAP
    if w < 50 then
      w = 280
    end
    local cw = math.floor(w * CHAMPION_WIDTH_FRAC + 0.5)
    local aw = w - cw
    championPane:SetWidth(cw)
    apPane:SetWidth(aw)
    apPane:ClearAllPoints()
    apPane:SetPoint('TOPLEFT', championPane, 'TOPRIGHT', MID_GAP, 0)
    apPane:SetHeight(innerH)

    local W = championPane:GetWidth()
    local iw = iconChamp:GetWidth()
    if W and W > 20 and iw and iw > 0 then
      local gapTextIcon = 8
      local dxIcon = W * 0.5 - INNER_PAD - iw * 0.5
      iconChamp:ClearAllPoints()
      iconChamp:SetPoint('CENTER', championPane, 'CENTER', dxIcon, 0)

      local textW = math.max(40, W - INNER_PAD * 2 - gapTextIcon - iw)
      championTextHost:SetWidth(textW)
      local offText = INNER_PAD + textW * 0.5 - W * 0.5
      championTextHost:ClearAllPoints()
      championTextHost:SetPoint('CENTER', championPane, 'CENTER', offText, 0)
    end

    labelAp:ClearAllPoints()
    detailAp:ClearAllPoints()
    labelAp:SetPoint('LEFT', apPane, 'LEFT', INNER_PAD, 0)
    labelAp:SetPoint('RIGHT', apPane, 'RIGHT', -INNER_PAD, 0)
    labelAp:SetPoint('BOTTOM', apPane, 'CENTER', 0, 5)
    detailAp:SetPoint('LEFT', apPane, 'LEFT', INNER_PAD, 0)
    detailAp:SetPoint('RIGHT', apPane, 'RIGHT', -INNER_PAD, 0)
    detailAp:SetPoint('TOP', apPane, 'CENTER', 0, -5)
  end

  root:SetScript('OnSizeChanged', layoutColumns)
  root:SetScript('OnShow', layoutColumns)
  layoutColumns()

  return OUTER_PAD_Y * 2 + innerH
end
