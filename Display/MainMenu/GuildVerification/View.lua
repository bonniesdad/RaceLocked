local TITLE_TOP_OFFSET = -30
local LIST_LEFT_OFFSET = 10
local TITLE_BOTTOM_GAP = 16
local ROW_GAP = 12
local HELPER_INDENT = 12
local HELPER_TOP_GAP = 4

local STATUS_TITLE = {
  valid = {
    text = 'Guild Found Trading is unlocked',
    r = 0.35,
    g = 0.8,
    b = 0.35,
  },
  invalid = {
    text = 'Guild Found Trading is locked',
    r = 0.82,
    g = 0.33,
    b = 0.33,
  },
}

local CHECK_PASS_COLOR = {
  r = 0.35,
  g = 0.8,
  b = 0.35,
}

local CHECK_FAIL_COLOR = {
  r = 0.82,
  g = 0.33,
  b = 0.33,
}

local CHECK_WARNING_COLOR = {
  r = 0.95,
  g = 0.82,
  b = 0.2,
}

local function getDetectedOnHelperText(failedAt)
  if failedAt then
    return 'Detected on ' .. date('%d %b %Y', failedAt)
  end
end

local function getVerificationChecks()
  local playerMoneyValidationFailed = RaceLocked_GetDBValue('playerMoneyValidationFailed')

  local hasBeenMaxLevelAndSelfFound = RaceLocked_GetDBValue('hasBeenMaxLevelAndSelfFound')

  if playerMoneyValidationFailed == nil then
    playerMoneyValidationFailed = false
  end

  return { {
    passed = playerMoneyValidationFailed == false,
    passMessage = 'No tampering detected',
    failMessage = 'Tampering detected',
    failHelperText = playerMoneyValidationFailed and getDetectedOnHelperText(
      RaceLocked_GetDBValue('playerMoneyValidationFailedAt')
    ),
  }, {
    passed = hasBeenMaxLevelAndSelfFound == true,
    passMessage = 'This character reached level ' .. RACE_LOCKED_GUILD_FOUND_MAX_LEVEL .. ' whilst self found',
    failMessage = UnitLevel('player') < RACE_LOCKED_GUILD_FOUND_MAX_LEVEL and 'You are not yet level ' .. RACE_LOCKED_GUILD_FOUND_MAX_LEVEL .. '' or 'Did not turn off self found at level ' .. RACE_LOCKED_GUILD_FOUND_MAX_LEVEL .. '',
    failHelperText = UnitLevel('player') < RACE_LOCKED_GUILD_FOUND_MAX_LEVEL and nil or 'You must be level ' .. RACE_LOCKED_GUILD_FOUND_MAX_LEVEL .. ' before turning off self found',
  }, {
    passed = RaceLocked_ShouldOverrideVerificationViaGuildNote(UnitName('player')) == true,
    passMessage = 'Manual override applied',
    failMessage = 'No manual override applied',
    failHelperText = 'You do not have a manual override from a GM',
    failColor = CHECK_WARNING_COLOR,
  }, {
    passed = RaceLocked_IsInGuildFoundGuild(),
    passMessage = 'You are in a Guild Found guild',
    failMessage = 'You are not in a Guild Found guild',
    failHelperText = 'You must be in the Guild Found guild to unlock Guild Found',
  } }
end

local function getOverallStatus(checks)
  if RaceLocked_IsInGuildFoundGuild() and RaceLocked_AmIVerified() then
    return STATUS_TITLE.valid
  else
    return STATUS_TITLE.invalid
  end
end

local function getWrapWidth(content, extraIndent)
  extraIndent = extraIndent or 0

  local width = content:GetWidth() - (LIST_LEFT_OFFSET * 2) - extraIndent

  if width < 1 then
    return 1
  end

  return width
end

local function applyWrappedText(fontString, content, extraIndent)
  fontString:SetWidth(getWrapWidth(content, extraIndent))

  fontString:SetWordWrap(true)

  fontString:SetJustifyH('LEFT')

  fontString:SetJustifyV('TOP')
end

local function ensureVerificationTabLayout(content)
  if content.verificationInitialized then return end

  content.titleLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')

  content.checkRows = {}

  content.checkHelpers = {}

  content.verificationInitialized = true
end

local function updateVerificationTabDisplay(content)
  local checks = getVerificationChecks()

  local status = getOverallStatus(checks)

  applyWrappedText(content.titleLabel, content)

  content.titleLabel:ClearAllPoints()

  content.titleLabel:SetPoint('TOPLEFT', content, 'TOPLEFT', LIST_LEFT_OFFSET, TITLE_TOP_OFFSET)

  content.titleLabel:SetText(status.text)

  content.titleLabel:SetTextColor(status.r, status.g, status.b)

  local blockEnd = content.titleLabel

  local firstRowGap = -TITLE_BOTTOM_GAP

  for index, check in ipairs(checks) do
    local row = content.checkRows[index]

    if not row then
      row = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')

      content.checkRows[index] = row
    end

    applyWrappedText(row, content)

    row:ClearAllPoints()

    row:SetPoint('TOP', blockEnd, 'BOTTOM', 0, firstRowGap)

    row:SetPoint('LEFT', content, 'LEFT', LIST_LEFT_OFFSET, 0)

    firstRowGap = -ROW_GAP

    local passed = check.passed

    local color = passed and CHECK_PASS_COLOR or (check.failColor or CHECK_FAIL_COLOR)

    row:SetText('• ' .. (passed and check.passMessage or check.failMessage))

    row:SetTextColor(color.r, color.g, color.b)

    row:Show()

    blockEnd = row

    local helper = content.checkHelpers[index]

    if check.failHelperText and not passed then
      if not helper then
        helper = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')

        content.checkHelpers[index] = helper
      end

      applyWrappedText(helper, content, HELPER_INDENT)

      helper:ClearAllPoints()

      helper:SetPoint('TOP', row, 'BOTTOM', 0, -HELPER_TOP_GAP)

      helper:SetPoint('LEFT', content, 'LEFT', LIST_LEFT_OFFSET + HELPER_INDENT, 0)

      helper:SetText(check.failHelperText)

      helper:SetTextColor(0.85, 0.85, 0.85)

      helper:Show()

      blockEnd = helper
    elseif helper then
      helper:Hide()
    end
  end

  for index = #checks + 1, #content.checkRows do
    content.checkRows[index]:Hide()
  end

  if content.checkHelpers then
    for index = #checks + 1, #content.checkHelpers do
      content.checkHelpers[index]:Hide()
    end
  end

  return blockEnd
end

-- ── Roster Section (Phase 2) ─────────────────────────────────────────────

local ROSTER_SECTION_GAP = 24
local ROSTER_ROW_HEIGHT = 22
local ROSTER_COL_NAME_FRAC = 0.38
local ROSTER_COL_STATUS_FRAC = 0.18
local ROSTER_BTN_WIDTH = 52
local ROSTER_BTN_HEIGHT = 18

local ROSTER_COLORS = {
  eligible   = { r = 0.35, g = 0.8,  b = 0.35 },
  ineligible = { r = 0.82, g = 0.33, b = 0.33 },
  noAddon    = { r = 0.55, g = 0.55, b = 0.55 },
  override   = { r = 0.4,  g = 0.7,  b = 1.0  },
  header     = { r = 0.85, g = 0.85, b = 0.85 },
  localRow   = { r = 1.0,  g = 0.82, b = 0.0  },
  rowEven    = { r = 0.12, g = 0.12, b = 0.15, a = 0.5 },
  rowOdd     = { r = 0.08, g = 0.08, b = 0.10, a = 0.3 },
}

local REFRESH_TEX = 'Interface\\Buttons\\UI-RefreshButton'
local VALID_TEX   = 'Interface\\AddOns\\RaceLocked\\Textures\\valid.png'

local function statusText(val, hasAddon)
  if not hasAddon then return '-' end
  if val == true then return 'Yes' end
  if val == false then return 'No' end
  return '?'
end

local function statusColor(val, hasAddon)
  if not hasAddon then return ROSTER_COLORS.noAddon end
  if val == true then return ROSTER_COLORS.eligible end
  if val == false then return ROSTER_COLORS.ineligible end
  return ROSTER_COLORS.noAddon
end

local function ensureRosterLayout(content)
  if content.rosterInitialized then return end

  content.rosterPanel = CreateFrame('Frame', nil, content, 'BackdropTemplate')
  content.rosterPanel:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 64,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  content.rosterPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
  content.rosterPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

  content.rosterHeader = CreateFrame('Frame', nil, content.rosterPanel)
  content.rosterHeader:SetHeight(22)

  content.rosterTitle = content.rosterHeader:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  content.rosterCount = content.rosterHeader:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')

  content.rosterSyncBtn = CreateFrame('Button', nil, content)
  content.rosterSyncBtn:SetSize(30, 30)
  content.rosterSyncBtn:SetNormalTexture(REFRESH_TEX)
  content.rosterSyncBtn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
  content.rosterSyncBtn:SetPushedTexture(REFRESH_TEX)
  content.rosterSyncBtn:EnableMouse(true)
  content.rosterSyncBtn._synced = false

  content.rosterSyncBtn:SetScript('OnEnter', function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    if self._synced then
      GameTooltip:AddLine('Synced', 1, 0.92, 0.62)
      GameTooltip:AddLine('Roster has been synced this session', 1, 1, 1)
    else
      GameTooltip:AddLine('Sync', 1, 0.92, 0.62)
      GameTooltip:AddLine('Re-broadcast your status and refresh the roster', 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  content.rosterSyncBtn:SetScript('OnLeave', function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  content.rosterSyncBtn:SetScript('OnClick', function(self)
    if self._synced then return end

    local slashHandler = SlashCmdList['RLROSTER']
    if slashHandler then
      slashHandler('sync')
    end

    self._synced = true
    self:SetNormalTexture(VALID_TEX)
    self:SetPushedTexture(VALID_TEX)
    self:SetDisabledTexture(VALID_TEX)
    self:Disable()
    self:SetAlpha(1)

    C_Timer.After(0.5, function()
      RaceLocked_InitializeGuildVerificationTab(content)
    end)
  end)

  local settingsFrame = _G.RaceLockedSettingsFrame
  if settingsFrame and settingsFrame.HookScript then
    settingsFrame:HookScript('OnHide', function()
      content.rosterSyncBtn._synced = false
      content.rosterSyncBtn:SetNormalTexture(REFRESH_TEX)
      content.rosterSyncBtn:SetPushedTexture(REFRESH_TEX)
      content.rosterSyncBtn:Enable()
      content.rosterSyncBtn:SetAlpha(1)
    end)
  end

  content.rosterColHeaders = CreateFrame('Frame', nil, content.rosterPanel)
  content.rosterColHeaders:SetHeight(16)
  content.rosterColHeaderFs = {}
  local colNames = { 'Name', 'Verified', 'Tampered', 'Status' }
  for i, label in ipairs(colNames) do
    local fs = content.rosterColHeaders:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    fs:SetText(label)
    fs:SetTextColor(ROSTER_COLORS.header.r, ROSTER_COLORS.header.g, ROSTER_COLORS.header.b)
    content.rosterColHeaderFs[i] = fs
  end

  content.rosterScrollFrame = CreateFrame('ScrollFrame', 'RaceLocked_RosterScrollFrame', content.rosterPanel, 'UIPanelScrollFrameTemplate')
  content.rosterScrollChild = CreateFrame('Frame', nil, content.rosterScrollFrame)
  content.rosterScrollFrame:SetScrollChild(content.rosterScrollChild)

  content.rosterRows = {}
  content.rosterInitialized = true
end

local function ensureRosterRow(content, index)
  if content.rosterRows[index] then
    return content.rosterRows[index]
  end

  local row = CreateFrame('Frame', nil, content.rosterScrollChild)
  row:SetHeight(ROSTER_ROW_HEIGHT)

  row.nameText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.nameText:SetJustifyH('LEFT')

  row.verifiedText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.verifiedText:SetJustifyH('CENTER')

  row.cleanText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.cleanText:SetJustifyH('CENTER')

  row.statusText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.statusText:SetJustifyH('CENTER')

  row.bg = row:CreateTexture(nil, 'BACKGROUND')
  row.bg:SetAllPoints()

  content.rosterRows[index] = row
  return row
end

local function updateRosterSection(content, blockEnd)
  ensureRosterLayout(content)

  local contentWidth = content:GetWidth()
  local usableWidth = contentWidth - LIST_LEFT_OFFSET * 2

  local SYNC_BTN_SIZE = 30
  local SYNC_BTN_GAP = 4

  local PANEL_MARGIN = 3

  content.rosterSyncBtn:ClearAllPoints()
  content.rosterSyncBtn:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_MARGIN, 2)
  content.rosterSyncBtn:Show()

  content.rosterPanel:ClearAllPoints()
  content.rosterPanel:SetPoint('TOPLEFT', blockEnd, 'BOTTOMLEFT', -LIST_LEFT_OFFSET + PANEL_MARGIN, -ROSTER_SECTION_GAP)
  content.rosterPanel:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -PANEL_MARGIN, SYNC_BTN_SIZE + SYNC_BTN_GAP + 2)
  content.rosterPanel:Show()

  local panelPad = 10
  content.rosterHeader:ClearAllPoints()
  content.rosterHeader:SetPoint('TOPLEFT', content.rosterPanel, 'TOPLEFT', panelPad, -panelPad)
  content.rosterHeader:SetPoint('RIGHT', content.rosterPanel, 'RIGHT', -panelPad, 0)

  local rows, isGM = RaceLocked_GetGuildFoundRosterRows()

  content.rosterTitle:ClearAllPoints()
  content.rosterTitle:SetPoint('LEFT', content.rosterHeader, 'LEFT', 0, 0)
  content.rosterTitle:SetText('Guild Found Roster')
  content.rosterTitle:SetTextColor(1, 0.82, 0)

  content.rosterCount:ClearAllPoints()
  content.rosterCount:SetPoint('LEFT', content.rosterTitle, 'RIGHT', 8, 0)
  content.rosterCount:SetText('(' .. #rows .. ')')
  content.rosterCount:SetTextColor(0.7, 0.7, 0.7)

  local colNameW = math.floor(usableWidth * ROSTER_COL_NAME_FRAC)
  local colStatusW = math.floor(usableWidth * ROSTER_COL_STATUS_FRAC)

  content.rosterColHeaders:ClearAllPoints()
  content.rosterColHeaders:SetPoint('TOPLEFT', content.rosterHeader, 'BOTTOMLEFT', 0, -4)
  content.rosterColHeaders:SetPoint('RIGHT', content.rosterPanel, 'RIGHT', -panelPad, 0)

  local hfs = content.rosterColHeaderFs
  hfs[1]:ClearAllPoints()
  hfs[1]:SetPoint('LEFT', content.rosterColHeaders, 'LEFT', 2, 0)
  hfs[1]:SetWidth(colNameW)
  hfs[2]:ClearAllPoints()
  hfs[2]:SetPoint('LEFT', hfs[1], 'RIGHT', 0, 0)
  hfs[2]:SetWidth(colStatusW)
  hfs[3]:ClearAllPoints()
  hfs[3]:SetPoint('LEFT', hfs[2], 'RIGHT', 0, 0)
  hfs[3]:SetWidth(colStatusW)
  hfs[4]:ClearAllPoints()
  hfs[4]:SetPoint('LEFT', hfs[3], 'RIGHT', 0, 0)
  hfs[4]:SetWidth(colStatusW)

  content.rosterScrollFrame:ClearAllPoints()
  content.rosterScrollFrame:SetPoint('TOPLEFT', content.rosterColHeaders, 'BOTTOMLEFT', 0, -2)
  content.rosterScrollFrame:SetPoint('BOTTOMRIGHT', content.rosterPanel, 'BOTTOMRIGHT', -panelPad - 26, panelPad)
  content.rosterScrollFrame:Show()

  local scrollWidth = content.rosterScrollFrame:GetWidth()
  if scrollWidth < 40 then scrollWidth = usableWidth - 52 end
  content.rosterScrollChild:SetWidth(scrollWidth)
  content.rosterScrollChild:SetHeight(math.max(1, #rows * ROSTER_ROW_HEIGHT))

  for i, data in ipairs(rows) do
    local row = ensureRosterRow(content, i)
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', content.rosterScrollChild, 'TOPLEFT', 0, -(i - 1) * ROSTER_ROW_HEIGHT)
    row:SetPoint('RIGHT', content.rosterScrollChild, 'RIGHT', 0, 0)

    local bg = (i % 2 == 0) and ROSTER_COLORS.rowEven or ROSTER_COLORS.rowOdd
    row.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)

    local nameColor = data.isLocalPlayer and ROSTER_COLORS.localRow or ROSTER_COLORS.header
    row.nameText:SetText(data.name)
    row.nameText:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
    row.nameText:ClearAllPoints()
    row.nameText:SetPoint('LEFT', row, 'LEFT', 2, 0)
    row.nameText:SetWidth(colNameW - 4)

    local vColor = statusColor(data.selfVerified, true)
    row.verifiedText:SetText(statusText(data.selfVerified, true))
    row.verifiedText:SetTextColor(vColor.r, vColor.g, vColor.b)
    row.verifiedText:ClearAllPoints()
    row.verifiedText:SetPoint('LEFT', row.nameText, 'RIGHT', 0, 0)
    row.verifiedText:SetWidth(colStatusW)

    local tampered = data.selfClean == false
    local tColor = tampered and ROSTER_COLORS.ineligible or ROSTER_COLORS.eligible
    row.cleanText:SetText(tampered and 'Yes' or 'No')
    row.cleanText:SetTextColor(tColor.r, tColor.g, tColor.b)
    row.cleanText:ClearAllPoints()
    row.cleanText:SetPoint('LEFT', row.verifiedText, 'RIGHT', 0, 0)
    row.cleanText:SetWidth(colStatusW)

    local eligible = data.effectiveVerified == true and data.effectiveClean == true
    local effColor
    local effText
    if eligible then
      effText = 'Eligible'
      effColor = ROSTER_COLORS.eligible
    else
      effText = 'Ineligible'
      effColor = ROSTER_COLORS.ineligible
    end
    if data.hasGMOverride then
      effText = effText .. ' *'
      effColor = ROSTER_COLORS.override
    end
    row.statusText:SetText(effText)
    row.statusText:SetTextColor(effColor.r, effColor.g, effColor.b)
    row.statusText:ClearAllPoints()
    row.statusText:SetPoint('LEFT', row.cleanText, 'RIGHT', 0, 0)
    row.statusText:SetWidth(colStatusW)

    if row.overrideBtnV then row.overrideBtnV:Hide() end

    if isGM and not data.isLocalPlayer then
      if not row.overrideBtnV then
        local btn = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
        btn:SetSize(ROSTER_BTN_WIDTH, ROSTER_BTN_HEIGHT)
        btn:SetPoint('RIGHT', row, 'RIGHT', -4, 0)
        local fs = btn:GetFontString()
        if fs then fs:SetFont(fs:GetFont(), 10) end
        row.overrideBtnV = btn
      end
      local curGmV = nil
      local entry = RaceLocked_Roster_GetEntry(GetGuildInfo('player'), data.name)
      if entry then curGmV = entry.gmVerified end

      if curGmV == true then
        row.overrideBtnV:SetText('Un-Verify')
        row.overrideBtnV:SetScript('OnClick', function()
          RaceLocked_Roster_SendGMOverride(data.name, nil, nil)
          C_Timer.After(0.3, function()
            RaceLocked_InitializeGuildVerificationTab(content)
          end)
        end)
      else
        row.overrideBtnV:SetText('Verify')
        row.overrideBtnV:SetScript('OnClick', function()
          RaceLocked_Roster_SendGMOverride(data.name, true, nil)
          C_Timer.After(0.3, function()
            RaceLocked_InitializeGuildVerificationTab(content)
          end)
        end)
      end
      row.overrideBtnV:Show()
    end

    row:Show()
  end

  for i = #rows + 1, #content.rosterRows do
    content.rosterRows[i]:Hide()
  end
end

-- ── Public entry point ──────────────────────────────────────────────────

function RaceLocked_InitializeGuildVerificationTab(content)
  if not content then return end

  ensureVerificationTabLayout(content)

  local blockEnd = updateVerificationTabDisplay(content)

  updateRosterSection(content, blockEnd)
end
