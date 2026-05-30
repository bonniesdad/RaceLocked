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
local ROSTER_ROW_HEIGHT = 28
local ROSTER_COL_NAME_FRAC = 0.30
local ROSTER_COL_STATUS_FRAC = 0.21
local ROSTER_EDIT_COL_W = 28
local ROSTER_BTN_HEIGHT = 18
local ROSTER_SCROLLBAR_W = 26
local ROSTER_LOG_ROW_HEIGHT = 28
local ROSTER_VIEW_TOGGLE_W = 42

local ROSTER_LOG_COLORS = {
  sent = { r = 1.0,  g = 0.82, b = 0.0  },
  recv = { r = 0.35, g = 0.8,  b = 0.35 },
  info = { r = 0.7,  g = 0.7,  b = 0.7  },
  warn = { r = 0.82, g = 0.33, b = 0.33 },
}

local ROSTER_LOG_KIND_LABEL = {
  sent = 'Sent',
  recv = 'Recv',
  info = 'Info',
  warn = 'Warn',
}

local ROSTER_COLORS = {
  eligible   = { r = 0.35, g = 0.8,  b = 0.35 },
  ineligible = { r = 0.82, g = 0.33, b = 0.33 },
  noAddon    = { r = 0.55, g = 0.55, b = 0.55 },
  override   = { r = 0.4,  g = 0.7,  b = 1.0  },
  header     = { r = 0.85, g = 0.85, b = 0.85 },
  localRow   = { r = 1.0,  g = 0.82, b = 0.0  },
  editLink   = { r = 0.55, g = 0.55, b = 0.55 },
  editHover  = { r = 1.0,  g = 0.82, b = 0.0  },
  editActive = { r = 0.9,  g = 0.75, b = 0.45 },
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

local function withOverrideSuffix(text, isOverride)
  if isOverride then
    return text .. ' *'
  end
  return text
end

local function displayColor(val, hasAddon, isOverride)
  if isOverride then
    return ROSTER_COLORS.override
  end
  return statusColor(val, hasAddon)
end

local function tamperedText(clean)
  return (clean == false) and 'Yes' or 'No'
end

local function tamperedColor(clean, isOverride)
  if isOverride then
    return ROSTER_COLORS.override
  end
  if clean == false then
    return ROSTER_COLORS.ineligible
  end
  return ROSTER_COLORS.eligible
end

local function overrideDisplayValue(isOverride, effective, selfReported)
  if isOverride then
    return effective
  end
  return selfReported
end

local function getRosterRowsForDisplay(content)
  local freshRows, isGM = RaceLocked_GetGuildFoundRosterRows()

  if content.rosterEditingName and content.rosterLastRows then
    local freshByName = {}
    for _, row in ipairs(freshRows) do
      freshByName[row.name] = row
    end

    local rows = {}
    for _, cachedRow in ipairs(content.rosterLastRows) do
      local updated = freshByName[cachedRow.name]
      if updated then
        rows[#rows + 1] = updated
        freshByName[cachedRow.name] = nil
      end
    end
    for _, row in ipairs(freshRows) do
      if freshByName[row.name] then
        rows[#rows + 1] = row
      end
    end
    return rows, isGM
  end

  content.rosterLastRows = freshRows
  return freshRows, isGM
end

local function setEditLinkLabel(btn, text, color)
  if not btn or not btn.editLabel then return end
  btn._linkColor = color or ROSTER_COLORS.editLink
  btn.editLabel:SetText(text)
  btn.editLabel:SetTextColor(btn._linkColor.r, btn._linkColor.g, btn._linkColor.b)
end

local function ensureEditLinkButton(row)
  if row.editBtn and row.editBtn.editLabel then
    return row.editBtn
  end
  if row.editBtn then
    row.editBtn:Hide()
    row.editBtn:SetParent(nil)
  end

  local btn = CreateFrame('Button', nil, row)
  btn:SetSize(ROSTER_EDIT_COL_W, ROSTER_ROW_HEIGHT)
  btn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
  do
    local hl = btn:GetHighlightTexture()
    if hl then hl:SetAlpha(0.12) end
  end
  btn.editLabel = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  btn.editLabel:SetPoint('CENTER', btn, 'CENTER', 0, 0)
  btn:SetScript('OnEnter', function(self)
    if not self.editLabel or not self._linkColor then return end
    if self._editing then
      self.editLabel:SetTextColor(
        ROSTER_COLORS.editActive.r, ROSTER_COLORS.editActive.g, ROSTER_COLORS.editActive.b
      )
    else
      self.editLabel:SetTextColor(
        ROSTER_COLORS.editHover.r, ROSTER_COLORS.editHover.g, ROSTER_COLORS.editHover.b
      )
    end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    if self._editing then
      GameTooltip:AddLine('Done', 1, 0.92, 0.62)
      GameTooltip:AddLine('Close override editing', 1, 1, 1)
    else
      GameTooltip:AddLine('Edit', 1, 0.92, 0.62)
      GameTooltip:AddLine('Set GM overrides for this player', 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  btn:SetScript('OnLeave', function(self)
    if self.editLabel and self._linkColor then
      self.editLabel:SetTextColor(self._linkColor.r, self._linkColor.g, self._linkColor.b)
    end
    if GameTooltip then GameTooltip:Hide() end
  end)
  btn:Hide()
  row.editBtn = btn
  return btn
end

local function setPanelButtonLabel(btn, text, color)
  btn:SetText(text)
  local fs = btn:GetFontString()
  if fs then
    fs:SetFont(fs:GetFont(), 9)
    if color then
      fs:SetTextColor(color.r, color.g, color.b)
    end
  end
end

local function refreshAfterOverride(content)
  C_Timer.After(0.3, function()
    RaceLocked_InitializeGuildVerificationTab(content)
  end)
end

local function rosterFieldDropdownInit(dropdown)
  local opts = dropdown._opts
  if not opts then return end

  local info = UIDropDownMenu_CreateInfo()
  info.notCheckable = true

  if not opts.yesSelected then
    info.text = opts.yesLabel or 'Yes'
    info.func = function()
      opts.onYes()
    end
    UIDropDownMenu_AddButton(info)
  end

  if opts.yesSelected then
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = opts.noLabel or 'No'
    info.func = function()
      opts.onNo()
    end
    UIDropDownMenu_AddButton(info)
  end

  if opts.hasOverride then
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = 'Reset'
    info.func = function()
      opts.onReset()
    end
    UIDropDownMenu_AddButton(info)
  end
end

local function rosterColumnsWidth(editColW, colNameW, colStatusW)
  return colNameW + editColW + 2 + colStatusW * 3
end

local function rosterColumnOffsets(listPad, editColW, colNameW, colStatusW)
  local nameLeft = listPad
  local editLeft = nameLeft + colNameW
  local verifiedLeft = editLeft + editColW + 2
  local cleanLeft = verifiedLeft + colStatusW
  local statusLeft = cleanLeft + colStatusW
  return nameLeft, editLeft, verifiedLeft, cleanLeft, statusLeft
end

local function resizeRosterDropdown(dropdown, colW)
  if not dropdown or not dropdown.GetName or not dropdown:GetName() then
    return
  end
  local totalW = math.max(48, colW - 4)
  local middleW = totalW - 25
  UIDropDownMenu_SetWidth(dropdown, middleW, 25)
  UIDropDownMenu_SetButtonWidth(dropdown, totalW)
end

local function showFieldDropdown(row, colW, leftOffset, textFs, dropdown, opts)
  textFs:Hide()
  dropdown:Show()
  dropdown._opts = opts
  dropdown:ClearAllPoints()
  dropdown:SetPoint('TOPLEFT', row, 'TOPLEFT', leftOffset + 1, 1)
  dropdown:SetFrameLevel((row:GetFrameLevel() or 0) + 10)
  UIDropDownMenu_Initialize(dropdown, rosterFieldDropdownInit)
  UIDropDownMenu_SetText(dropdown, opts.displayText or '?')
  if UIDropDownMenu_JustifyText then
    UIDropDownMenu_JustifyText(dropdown, 'CENTER')
  end
  resizeRosterDropdown(dropdown, colW)
end

local function hideFieldDropdown(textFs, dropdown)
  textFs:Show()
  dropdown:Hide()
end

local function ensureRosterViewToggle(content)
  if content.rosterViewBtn and content.rosterViewBtn.editLabel then
    return content.rosterViewBtn
  end

  local btn = CreateFrame('Button', nil, content.rosterHeader)
  btn:SetSize(ROSTER_VIEW_TOGGLE_W, ROSTER_ROW_HEIGHT)
  btn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
  do
    local hl = btn:GetHighlightTexture()
    if hl then hl:SetAlpha(0.12) end
  end
  btn.editLabel = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  btn.editLabel:SetPoint('CENTER', btn, 'CENTER', 0, 0)
  btn._linkColor = ROSTER_COLORS.editLink
  btn:SetScript('OnEnter', function(self)
    if not self.editLabel then return end
    self.editLabel:SetTextColor(
      ROSTER_COLORS.editHover.r, ROSTER_COLORS.editHover.g, ROSTER_COLORS.editHover.b
    )
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    if content.rosterViewMode == 'log' then
      GameTooltip:AddLine('Roster', 1, 0.92, 0.62)
      GameTooltip:AddLine('Show guild roster table', 1, 1, 1)
    else
      GameTooltip:AddLine('Log', 1, 0.92, 0.62)
      GameTooltip:AddLine('Show sync messages this session', 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  btn:SetScript('OnLeave', function(self)
    if self.editLabel and self._linkColor then
      self.editLabel:SetTextColor(self._linkColor.r, self._linkColor.g, self._linkColor.b)
    end
    if GameTooltip then GameTooltip:Hide() end
  end)
  btn:SetScript('OnClick', function()
    if content.rosterViewMode == 'log' then
      content.rosterViewMode = 'roster'
    else
      content.rosterViewMode = 'log'
      content.rosterEditingName = nil
      content.rosterLastRows = nil
    end
    RaceLocked_InitializeGuildVerificationTab(content)
  end)
  content.rosterViewBtn = btn
  return btn
end

local function ensureRosterLogRow(content, index)
  if content.rosterLogRows[index] then
    return content.rosterLogRows[index]
  end

  local row = CreateFrame('Frame', nil, content.rosterScrollChild)
  row:SetHeight(ROSTER_LOG_ROW_HEIGHT)

  row.bg = row:CreateTexture(nil, 'BACKGROUND')
  row.bg:SetAllPoints()

  row.clockText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.clockText:SetJustifyH('LEFT')

  row.kindText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.kindText:SetJustifyH('LEFT')

  row.msgText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.msgText:SetJustifyH('LEFT')

  content.rosterLogRows[index] = row
  return row
end

local function updateRosterLogSection(content, scrollWidth, listPad)
  local entries = RaceLocked_Roster_GetSessionLog()
  local displayEntries = entries
  if #displayEntries == 0 then
    displayEntries = { { kind = 'info', clock = '--:--:--', text = 'No sync activity this session.' } }
  end

  content.rosterScrollChild:SetWidth(scrollWidth)
  content.rosterScrollChild:SetHeight(math.max(1, #displayEntries * ROSTER_LOG_ROW_HEIGHT))

  local clockW = 52
  local kindW = 36
  local msgLeft = listPad + clockW + kindW + 8

  for i, entry in ipairs(displayEntries) do
    local row = ensureRosterLogRow(content, i)
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', content.rosterScrollChild, 'TOPLEFT', 0, -(i - 1) * ROSTER_LOG_ROW_HEIGHT)
    row:SetPoint('RIGHT', content.rosterScrollChild, 'RIGHT', 0, 0)

    local bg = (i % 2 == 0) and ROSTER_COLORS.rowEven or ROSTER_COLORS.rowOdd
    row.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)

    local kindColor = ROSTER_LOG_COLORS[entry.kind] or ROSTER_LOG_COLORS.info
    local kindLabel = ROSTER_LOG_KIND_LABEL[entry.kind] or 'Info'

    row.clockText:SetText(entry.clock or '')
    row.clockText:SetTextColor(0.55, 0.55, 0.55)
    row.clockText:ClearAllPoints()
    row.clockText:SetPoint('LEFT', row, 'LEFT', listPad, 0)
    row.clockText:SetWidth(clockW)

    row.kindText:SetText(kindLabel)
    row.kindText:SetTextColor(kindColor.r, kindColor.g, kindColor.b)
    row.kindText:ClearAllPoints()
    row.kindText:SetPoint('LEFT', row, 'LEFT', listPad + clockW + 4, 0)
    row.kindText:SetWidth(kindW)

    row.msgText:SetText(entry.text or '')
    row.msgText:SetTextColor(ROSTER_COLORS.header.r, ROSTER_COLORS.header.g, ROSTER_COLORS.header.b)
    row.msgText:ClearAllPoints()
    row.msgText:SetPoint('LEFT', row, 'LEFT', msgLeft, 0)
    row.msgText:SetPoint('RIGHT', row, 'RIGHT', -listPad, 0)

    row:Show()
  end

  for i = #displayEntries + 1, #content.rosterLogRows do
    content.rosterLogRows[i]:Hide()
  end

  for i = 1, #content.rosterRows do
    content.rosterRows[i]:Hide()
  end

  local maxScroll = math.max(0, content.rosterScrollChild:GetHeight() - content.rosterScrollFrame:GetHeight())
  content.rosterScrollFrame:SetVerticalScroll(maxScroll)
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
  local colNames = { 'Name', '', 'Verified', 'Tampered', 'Status' }
  for i, label in ipairs(colNames) do
    local fs = content.rosterColHeaders:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    fs:SetText(label)
    fs:SetTextColor(ROSTER_COLORS.header.r, ROSTER_COLORS.header.g, ROSTER_COLORS.header.b)
    content.rosterColHeaderFs[i] = fs
  end

  content.rosterEditingName = nil
  content.rosterLastRows = nil
  content.rosterViewMode = content.rosterViewMode or 'roster'

  content.rosterScrollFrame = CreateFrame('ScrollFrame', 'RaceLocked_RosterScrollFrame', content.rosterPanel, 'UIPanelScrollFrameTemplate')
  content.rosterScrollChild = CreateFrame('Frame', nil, content.rosterScrollFrame)
  content.rosterScrollFrame:SetScrollChild(content.rosterScrollChild)

  content.rosterRows = {}
  content.rosterLogRows = {}

  ensureRosterViewToggle(content)

  RaceLocked_Roster_OnSessionLogUpdated = function()
    if content.rosterViewMode ~= 'log' then return end
    if not content:IsShown() then return end
    RaceLocked_InitializeGuildVerificationTab(content)
  end

  content.rosterLegend = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  content.rosterLegend:SetJustifyH('LEFT')
  content.rosterLegend:SetText('* GM override')
  content.rosterLegend:SetTextColor(
    ROSTER_COLORS.override.r,
    ROSTER_COLORS.override.g,
    ROSTER_COLORS.override.b
  )

  content.rosterInitialized = true
end

local function ensureRosterRow(content, index)
  if content.rosterRows[index] then
    ensureEditLinkButton(content.rosterRows[index])
    return content.rosterRows[index]
  end

  local row = CreateFrame('Frame', nil, content.rosterScrollChild)
  row:SetHeight(ROSTER_ROW_HEIGHT)

  ensureEditLinkButton(row)

  row.nameText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.nameText:SetJustifyH('LEFT')

  row.verifiedText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.verifiedText:SetJustifyH('CENTER')

  row.verifiedDropdown = CreateFrame(
    'Frame', 'RaceLockedRosterVerifiedDrop' .. index, row, 'UIDropDownMenuTemplate'
  )
  row.verifiedDropdown:Hide()

  row.cleanText = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.cleanText:SetJustifyH('CENTER')

  row.cleanDropdown = CreateFrame(
    'Frame', 'RaceLockedRosterCleanDrop' .. index, row, 'UIDropDownMenuTemplate'
  )
  row.cleanDropdown:Hide()

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

  local rows, isGM = getRosterRowsForDisplay(content)
  local showLog = content.rosterViewMode == 'log'
  local logEntries = RaceLocked_Roster_GetSessionLog()

  ensureRosterViewToggle(content)
  content.rosterViewBtn:ClearAllPoints()
  content.rosterViewBtn:SetPoint('RIGHT', content.rosterHeader, 'RIGHT', 0, 0)
  content.rosterViewBtn:Show()
  if showLog then
    setEditLinkLabel(content.rosterViewBtn, 'Roster', ROSTER_COLORS.editLink)
  else
    setEditLinkLabel(content.rosterViewBtn, 'Log', ROSTER_COLORS.editLink)
  end

  content.rosterTitle:ClearAllPoints()
  content.rosterTitle:SetPoint('LEFT', content.rosterHeader, 'LEFT', 0, 0)
  if showLog then
    content.rosterTitle:SetText('Sync Log')
    content.rosterCount:SetText('(' .. #logEntries .. ')')
  else
    content.rosterTitle:SetText('Guild Found Roster')
    content.rosterCount:SetText('(' .. #rows .. ')')
  end
  content.rosterTitle:SetTextColor(1, 0.82, 0)

  content.rosterCount:ClearAllPoints()
  content.rosterCount:SetPoint('LEFT', content.rosterTitle, 'RIGHT', 8, 0)
  content.rosterCount:SetTextColor(0.7, 0.7, 0.7)

  content.rosterColHeaders:ClearAllPoints()
  if showLog then
    content.rosterColHeaders:Hide()
    content.rosterScrollFrame:ClearAllPoints()
    content.rosterScrollFrame:SetPoint('TOPLEFT', content.rosterHeader, 'BOTTOMLEFT', 0, -4)
  else
    content.rosterColHeaders:SetPoint('TOPLEFT', content.rosterHeader, 'BOTTOMLEFT', 0, -4)
    content.rosterColHeaders:SetPoint('RIGHT', content.rosterPanel, 'RIGHT', -panelPad - ROSTER_SCROLLBAR_W, 0)
    content.rosterColHeaders:Show()
    content.rosterScrollFrame:ClearAllPoints()
    content.rosterScrollFrame:SetPoint('TOPLEFT', content.rosterColHeaders, 'BOTTOMLEFT', 0, -2)
  end
  content.rosterScrollFrame:SetPoint(
    'BOTTOMRIGHT', content.rosterPanel, 'BOTTOMRIGHT', -panelPad - ROSTER_SCROLLBAR_W, panelPad
  )
  content.rosterScrollFrame:Show()

  local scrollWidth = content.rosterScrollFrame:GetWidth()
  if scrollWidth < 40 then scrollWidth = usableWidth - panelPad * 2 - ROSTER_SCROLLBAR_W end

  local editColW = ROSTER_EDIT_COL_W
  local remainingW = scrollWidth - editColW
  local colNameW = math.floor(remainingW * ROSTER_COL_NAME_FRAC)
  local colStatusW = math.floor(remainingW * ROSTER_COL_STATUS_FRAC)
  local listPad = math.max(0, math.floor((scrollWidth - rosterColumnsWidth(editColW, colNameW, colStatusW)) / 2))
  local nameLeft, editLeft, verifiedLeft, cleanLeft, statusLeft = rosterColumnOffsets(
    listPad, editColW, colNameW, colStatusW
  )

  content.rosterLegend:ClearAllPoints()
  content.rosterLegend:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', PANEL_MARGIN + panelPad, 15)
  if showLog then
    content.rosterLegend:SetText('Session log · clears on reload')
  else
    content.rosterLegend:SetText('* GM override')
  end
  content.rosterLegend:Show()

  if showLog then
    updateRosterLogSection(content, scrollWidth, listPad)
    return
  end

  local hfs = content.rosterColHeaderFs
  hfs[1]:ClearAllPoints()
  hfs[1]:SetPoint('LEFT', content.rosterColHeaders, 'LEFT', listPad, 0)
  hfs[1]:SetWidth(colNameW)
  hfs[1]:Show()
  hfs[2]:ClearAllPoints()
  hfs[2]:SetPoint('LEFT', hfs[1], 'RIGHT', 0, 0)
  hfs[2]:SetWidth(editColW)
  hfs[2]:Show()
  hfs[3]:ClearAllPoints()
  hfs[3]:SetPoint('LEFT', hfs[2], 'RIGHT', 2, 0)
  hfs[3]:SetWidth(colStatusW)
  hfs[4]:ClearAllPoints()
  hfs[4]:SetPoint('LEFT', hfs[3], 'RIGHT', 0, 0)
  hfs[4]:SetWidth(colStatusW)
  hfs[5]:ClearAllPoints()
  hfs[5]:SetPoint('LEFT', hfs[4], 'RIGHT', 0, 0)
  hfs[5]:SetWidth(colStatusW)

  content.rosterScrollChild:SetWidth(scrollWidth)
  content.rosterScrollChild:SetHeight(math.max(1, #rows * ROSTER_ROW_HEIGHT))

  local editingName = content.rosterEditingName

  for i, data in ipairs(rows) do
    local row = ensureRosterRow(content, i)
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', content.rosterScrollChild, 'TOPLEFT', 0, -(i - 1) * ROSTER_ROW_HEIGHT)
    row:SetPoint('RIGHT', content.rosterScrollChild, 'RIGHT', 0, 0)

    local bg = (i % 2 == 0) and ROSTER_COLORS.rowEven or ROSTER_COLORS.rowOdd
    row.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a)

    local isEditing = (editingName == data.name)

    local nameColor = data.isLocalPlayer and ROSTER_COLORS.localRow or ROSTER_COLORS.header
    row.nameText:SetText(data.name)
    row.nameText:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
    row.nameText:ClearAllPoints()
    row.nameText:SetPoint('LEFT', row, 'LEFT', nameLeft, 0)
    row.nameText:SetWidth(colNameW - 4)

    row.editBtn:ClearAllPoints()
    row.editBtn:SetPoint('LEFT', row, 'LEFT', editLeft, 0)
    row.editBtn:SetSize(editColW, ROSTER_BTN_HEIGHT)
    if isGM then
      row.editBtn._editing = isEditing
      if isEditing then
        setEditLinkLabel(row.editBtn, 'Done', ROSTER_COLORS.editActive)
      else
        setEditLinkLabel(row.editBtn, 'Edit', ROSTER_COLORS.editLink)
      end
      row.editBtn:SetScript('OnClick', function()
        if content.rosterEditingName == data.name then
          content.rosterEditingName = nil
          content.rosterLastRows = nil
        else
          content.rosterLastRows = rows
          content.rosterEditingName = data.name
        end
        RaceLocked_InitializeGuildVerificationTab(content)
      end)
      row.editBtn:Show()
    else
      row.editBtn:Hide()
    end

    local verifiedOverride = data.gmVerified ~= nil
    local cleanOverride = data.gmClean ~= nil
    local displayVerified = overrideDisplayValue(
      verifiedOverride, data.effectiveVerified, data.selfVerified
    )
    local displayClean = overrideDisplayValue(
      cleanOverride, data.effectiveClean, data.selfClean
    )

    local vColor = displayColor(displayVerified, true, verifiedOverride)
    row.verifiedText:ClearAllPoints()
    row.verifiedText:SetPoint('LEFT', row, 'LEFT', verifiedLeft, 0)
    row.verifiedText:SetWidth(colStatusW)
    row.verifiedText:SetJustifyH('CENTER')
    row.verifiedText:SetText(withOverrideSuffix(statusText(displayVerified, true), verifiedOverride))
    row.verifiedText:SetTextColor(vColor.r, vColor.g, vColor.b)

    if isEditing then
      showFieldDropdown(row, colStatusW, verifiedLeft, row.verifiedText, row.verifiedDropdown, {
        displayText = withOverrideSuffix(statusText(displayVerified, true), verifiedOverride),
        hasOverride = verifiedOverride,
        yesSelected = data.effectiveVerified == true,
        onYes = function()
          RaceLocked_Roster_SendGMOverride(data.name, true, data.gmClean)
          refreshAfterOverride(content)
        end,
        onNo = function()
          RaceLocked_Roster_SendGMOverride(data.name, false, data.gmClean)
          refreshAfterOverride(content)
        end,
        onReset = function()
          RaceLocked_Roster_SendGMOverride(data.name, nil, data.gmClean)
          refreshAfterOverride(content)
        end,
      })
    else
      hideFieldDropdown(row.verifiedText, row.verifiedDropdown)
    end

    local tColor = tamperedColor(displayClean, cleanOverride)
    row.cleanText:ClearAllPoints()
    row.cleanText:SetPoint('LEFT', row, 'LEFT', cleanLeft, 0)
    row.cleanText:SetWidth(colStatusW)
    row.cleanText:SetJustifyH('CENTER')
    row.cleanText:SetText(withOverrideSuffix(tamperedText(displayClean), cleanOverride))
    row.cleanText:SetTextColor(tColor.r, tColor.g, tColor.b)

    if isEditing then
      showFieldDropdown(row, colStatusW, cleanLeft, row.cleanText, row.cleanDropdown, {
        displayText = withOverrideSuffix(tamperedText(displayClean), cleanOverride),
        hasOverride = cleanOverride,
        yesSelected = displayClean == false,
        onYes = function()
          RaceLocked_Roster_SendGMOverride(data.name, data.gmVerified, false)
          refreshAfterOverride(content)
        end,
        onNo = function()
          RaceLocked_Roster_SendGMOverride(data.name, data.gmVerified, true)
          refreshAfterOverride(content)
        end,
        onReset = function()
          RaceLocked_Roster_SendGMOverride(data.name, data.gmVerified, nil)
          refreshAfterOverride(content)
        end,
      })
    else
      hideFieldDropdown(row.cleanText, row.cleanDropdown)
    end

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
    row.statusText:SetPoint('LEFT', row, 'LEFT', statusLeft, 0)
    row.statusText:SetWidth(colStatusW)
    row.statusText:SetJustifyH('CENTER')

    row:Show()
  end

  for i = #rows + 1, #content.rosterRows do
    content.rosterRows[i]:Hide()
  end

  for i = 1, #content.rosterLogRows do
    content.rosterLogRows[i]:Hide()
  end
end

-- ── Public entry point ──────────────────────────────────────────────────

function RaceLocked_InitializeGuildVerificationTab(content)
  if not content then return end

  ensureVerificationTabLayout(content)

  local blockEnd = updateVerificationTabDisplay(content)

  updateRosterSection(content, blockEnd)
end
