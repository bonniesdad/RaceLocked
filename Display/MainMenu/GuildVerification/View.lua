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
    passMessage = 'Guild note override detected',
    failMessage = 'No guild note override detected',
    failHelperText = 'You are not in a guild or do not have a guild note override',
    failColor = CHECK_WARNING_COLOR,
  } }
end

local function getOverallStatus(checks)
  if RaceLocked_AmIVerified() then
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
end

function RaceLocked_InitializeGuildVerificationTab(content)
  if not content then return end

  ensureVerificationTabLayout(content)

  updateVerificationTabDisplay(content)
end
