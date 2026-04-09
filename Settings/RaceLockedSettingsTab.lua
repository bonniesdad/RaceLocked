-- Settings tab: display options, styled like UltraStatistics SettingsTab (option rows + panel chrome).

local ROW_BUTTON_HEIGHT = 48
local ROW_BUTTON_PAD_H = 14
local OPTION_ROW_TOTAL = 58

local LAYOUT = {
  PAGE_WIDTH = 355,
  HEADER_HEIGHT = 28,
  HEADER_PADDING_H = 12,
  HEADER_CONTENT_GAP = 10,
}

--- @return 'click-compatible' row with .Check, .Text, .Description, SetChecked, GetChecked
local function CreateOptionRowButton(parent)
  local row = CreateFrame('Button', nil, parent)
  row:SetHeight(ROW_BUTTON_HEIGHT)
  row:RegisterForClicks('LeftButtonUp')

  local check = CreateFrame('CheckButton', nil, row, 'UICheckButtonTemplate')
  check:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, -6)
  row.Check = check

  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  label:SetPoint('TOPLEFT', check, 'TOPRIGHT', 4, -2)
  label:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
  label:SetJustifyH('LEFT')
  label:SetNonSpaceWrap(false)
  row.Text = label

  local desc = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  desc:SetPoint('TOPLEFT', label, 'BOTTOMLEFT', 0, -2)
  desc:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
  desc:SetJustifyH('LEFT')
  desc:SetWordWrap(true)
  desc:SetNonSpaceWrap(false)
  desc:SetTextColor(0.75, 0.72, 0.65, 1)
  row.Description = desc

  function row:SetDescription(text)
    if self.Description then
      self.Description:SetText(text or '')
      self.Description:SetShown(text and text ~= '')
    end
  end

  function row:SetChecked(on)
    check:SetChecked(on and true or false)
  end

  function row:GetChecked()
    return check:GetChecked() and true or false
  end

  do
    local rawEnable, rawDisable = row.Enable, row.Disable
    row.Enable = function(self)
      if rawEnable then
        rawEnable(self)
      end
      check:Enable()
      check:SetAlpha(1)
    end
    row.Disable = function(self)
      if rawDisable then
        rawDisable(self)
      end
      check:Disable()
      check:SetAlpha(0.6)
    end
  end

  row:SetScript('OnClick', function(self)
    if not check:IsEnabled() then
      return
    end
    check:Click()
  end)

  row:SetChecked(false)
  row:SetDescription('')
  return row
end

local DISPLAY_SECTION_TITLE = 'Main Screen Leaderboard'

function RaceLocked_InitializeSettingsTab(tabContents, tabIndex)
  local content = tabContents and tabContents[tabIndex]
  if not content or content.raceLockedSettingsInit then
    return
  end
  content.raceLockedSettingsInit = true

  local optionsFrame = CreateFrame('Frame', nil, content, 'BackdropTemplate')
  optionsFrame:SetPoint('TOPLEFT', content, 'TOPLEFT', 6, -8)
  optionsFrame:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -6, 10)
  optionsFrame:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 64,
    edgeSize = 16,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })
  optionsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
  optionsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

  local scrollFrame = CreateFrame('ScrollFrame', nil, optionsFrame, 'UIPanelScrollFrameTemplate')
  scrollFrame:SetPoint('TOPLEFT', optionsFrame, 'TOPLEFT', 10, -10)
  scrollFrame:SetPoint('BOTTOMRIGHT', optionsFrame, 'BOTTOMRIGHT', -30, 10)

  local scrollChild = CreateFrame('Frame', nil, scrollFrame)
  scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
  scrollFrame:SetScrollChild(scrollChild)

  local HEADER_HEIGHT = LAYOUT.HEADER_HEIGHT
  local HEADER_CONTENT_GAP = LAYOUT.HEADER_CONTENT_GAP
  local headerPad = LAYOUT.HEADER_PADDING_H

  local displaySection = CreateFrame('Frame', nil, scrollChild, 'BackdropTemplate')
  displaySection:SetWidth(LAYOUT.PAGE_WIDTH)
  displaySection:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 10, -10)
  displaySection:SetPoint('TOPRIGHT', scrollChild, 'TOPRIGHT', 0, -10)
  displaySection:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 8,
    edgeSize = 10,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })
  displaySection:SetBackdropColor(0.08, 0.08, 0.1, 0.6)
  displaySection:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.5)

  local sectionHeader = CreateFrame('Frame', nil, displaySection, 'BackdropTemplate')
  sectionHeader:SetPoint('TOPLEFT', displaySection, 'TOPLEFT', 0, 0)
  sectionHeader:SetPoint('TOPRIGHT', displaySection, 'TOPRIGHT', 0, 0)
  sectionHeader:SetHeight(HEADER_HEIGHT)
  sectionHeader:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })
  sectionHeader:SetBackdropColor(0.15, 0.15, 0.2, 0.85)
  sectionHeader:SetBackdropBorderColor(0.5, 0.5, 0.6, 0.9)

  local sectionTitle = sectionHeader:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  sectionTitle:SetPoint('LEFT', sectionHeader, 'LEFT', headerPad, 0)
  sectionTitle:SetText(DISPLAY_SECTION_TITLE)
  sectionTitle:SetTextColor(0.9, 0.85, 0.75, 1)
  sectionTitle:SetShadowOffset(1, -1)
  sectionTitle:SetShadowColor(0, 0, 0, 0.8)

  local function getShowOnScreenLeaderboard()
    if not RaceLockedDB or RaceLockedDB.showOnScreenLeaderboard == nil then
      return true
    end
    return RaceLockedDB.showOnScreenLeaderboard ~= false
  end

  local leaderRow = CreateOptionRowButton(displaySection)
  local rowY = -(HEADER_HEIGHT + HEADER_CONTENT_GAP)
  leaderRow:SetPoint('TOPLEFT', displaySection, 'TOPLEFT', ROW_BUTTON_PAD_H, rowY)
  leaderRow:SetPoint('TOPRIGHT', displaySection, 'TOPRIGHT', -ROW_BUTTON_PAD_H, rowY)
  leaderRow.Text:SetText('Show Leaderboard on Main Screen')
  leaderRow:SetDescription('Toggle the display of the leaderboard')
  leaderRow:SetChecked(getShowOnScreenLeaderboard())

  leaderRow.Check:SetScript('OnClick', function(btn)
    local newVal = btn:GetChecked() and true or false
    leaderRow:SetChecked(newVal)
    if not RaceLockedDB then
      RaceLockedDB = {}
    end
    RaceLockedDB.showOnScreenLeaderboard = newVal
    if _G.RaceLocked_ApplyMainScreenLeaderboardVisibility then
      _G.RaceLocked_ApplyMainScreenLeaderboardVisibility()
    end
  end)

  local rowHoverOnEnter, rowHoverOnLeave = leaderRow:GetScript('OnEnter'), leaderRow:GetScript('OnLeave')
  leaderRow:SetScript('OnEnter', function(self)
    if rowHoverOnEnter then
      rowHoverOnEnter(self)
    end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText('Toggle the display of the leaderboard', nil, nil, nil, nil, true)
    GameTooltip:Show()
  end)
  leaderRow:SetScript('OnLeave', function(self)
    if rowHoverOnLeave then
      rowHoverOnLeave(self)
    end
    GameTooltip:Hide()
  end)

  local sectionHeight = HEADER_HEIGHT + HEADER_CONTENT_GAP + OPTION_ROW_TOTAL + 8
  displaySection:SetHeight(sectionHeight)
  scrollChild:SetHeight(sectionHeight + 30)

  scrollFrame:SetScript('OnSizeChanged', function()
    scrollChild:SetWidth(math.max(120, scrollFrame:GetWidth() - 10))
  end)
end
