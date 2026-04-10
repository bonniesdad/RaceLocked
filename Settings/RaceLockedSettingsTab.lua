-- Settings tab: display options, styled like UltraStatistics SettingsTab (option rows + panel chrome).

local ROW_BUTTON_HEIGHT = 48
local ROW_BUTTON_PAD_H = 14

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

function RaceLocked_InitializeSettingsTab(tabContents, tabIndex)
  local content = tabContents and tabContents[tabIndex]
  if not content or content.raceLockedSettingsInit then
    return
  end
  content.raceLockedSettingsInit = true

  local optionsFrame = CreateFrame('Frame', nil, content, 'BackdropTemplate')
  optionsFrame:SetPoint('TOPLEFT', content, 'TOPLEFT', 3, -14)
  optionsFrame:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -3, 12)
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

  local body = CreateFrame('Frame', nil, optionsFrame)
  body:SetPoint('TOPLEFT', optionsFrame, 'TOPLEFT', 10, -10)
  body:SetPoint('BOTTOMRIGHT', optionsFrame, 'BOTTOMRIGHT', -10, 10)

  local function getShowOnScreenLeaderboard()
    if not RaceLockedDB or RaceLockedDB.showOnScreenLeaderboard == nil then
      return true
    end
    return RaceLockedDB.showOnScreenLeaderboard ~= false
  end

  local leaderRow = CreateOptionRowButton(body)
  leaderRow:SetPoint('TOPLEFT', body, 'TOPLEFT', ROW_BUTTON_PAD_H, -10)
  leaderRow:SetPoint('TOPRIGHT', body, 'TOPRIGHT', -ROW_BUTTON_PAD_H, -10)
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
end
