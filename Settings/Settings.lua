-- Settings frame and toggle — same patterns as UltraFound
local TEXTURE_PATH = 'Interface\\AddOns\\GuildWars\\Textures'

local CLASS_BACKGROUND_MAP = {
  WARRIOR = TEXTURE_PATH .. '\\bg_warrior.png',
  PALADIN = TEXTURE_PATH .. '\\bg_pally.png',
  HUNTER = TEXTURE_PATH .. '\\bg_hunter.png',
  ROGUE = TEXTURE_PATH .. '\\bg_rogue.png',
  PRIEST = TEXTURE_PATH .. '\\bg_priest.png',
  MAGE = TEXTURE_PATH .. '\\bg_mage.png',
  WARLOCK = TEXTURE_PATH .. '\\bg_warlock.png',
  DRUID = TEXTURE_PATH .. '\\bg_druid.png',
  SHAMAN = TEXTURE_PATH .. '\\bg_shaman.png',
}

local CLASS_BACKGROUND_ASPECT_RATIO = 1200 / 700

local function getClassBackgroundTexture()
  local _, classFileName = UnitClass('player')
  if classFileName and CLASS_BACKGROUND_MAP[classFileName] then
    return CLASS_BACKGROUND_MAP[classFileName]
  end
  return 'Interface\\DialogFrame\\UI-DialogBox-Background'
end

local settingsFrame =
  CreateFrame('Frame', 'RaceWarsSettingsFrame', UIParent, 'BackdropTemplate')
tinsert(UISpecialFrames, 'RaceWarsSettingsFrame')
local SETTINGS_FRAME_WIDTH = 548
local SETTINGS_FRAME_HEIGHT = 680
settingsFrame:SetSize(SETTINGS_FRAME_WIDTH, SETTINGS_FRAME_HEIGHT)
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag('LeftButton')
settingsFrame:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)
settingsFrame:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
end)
settingsFrame:SetScript('OnHide', function(self)
  if _G.HideConfirmationDialog then
    _G.HideConfirmationDialog()
  end
end)
settingsFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 30)

local function ResetRaceWarsMenuPosition()
  settingsFrame:ClearAllPoints()
  settingsFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 30)
  print('|cfff44336[Guild Wars]|r Menu position reset to default.')
end

_G.ResetRaceWarsMenuPosition = ResetRaceWarsMenuPosition
settingsFrame:Hide()
settingsFrame:SetFrameStrata('DIALOG')
settingsFrame:SetFrameLevel(15)
settingsFrame:SetClipsChildren(true)

local settingsFrameBackground = settingsFrame:CreateTexture(nil, 'BACKGROUND')
settingsFrameBackground:SetPoint('CENTER', settingsFrame, 'CENTER')
settingsFrameBackground:SetTexCoord(0, 1, 0, 1)

local function updateSettingsFrameBackdrop()
  settingsFrameBackground:SetTexture(getClassBackgroundTexture())
  local frameHeight = settingsFrame:GetHeight()
  settingsFrameBackground:SetSize(frameHeight * CLASS_BACKGROUND_ASPECT_RATIO, frameHeight)
  settingsFrame:SetBackdrop({
    bgFile = nil,
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    tile = false,
    edgeSize = 2,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  settingsFrame:SetBackdropBorderColor(0, 0, 0, 1)
end
updateSettingsFrameBackdrop()

local titleBar = CreateFrame('Frame', nil, settingsFrame, 'BackdropTemplate')
titleBar:SetSize(SETTINGS_FRAME_WIDTH, 60)
titleBar:SetPoint('TOP', settingsFrame, 'TOP')
titleBar:SetFrameStrata('DIALOG')
titleBar:SetFrameLevel(20)
titleBar:SetBackdropBorderColor(0, 0, 0, 1)
titleBar:SetBackdropColor(0, 0, 0, 0.95)
local titleBarBackground = titleBar:CreateTexture(nil, 'BACKGROUND')
titleBarBackground:SetAllPoints()
titleBarBackground:SetTexture(TEXTURE_PATH .. '\\header.png')
titleBarBackground:SetTexCoord(0, 1, 0, 1)
local settingsTitleLabel = titleBar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightHuge')
settingsTitleLabel:SetPoint('CENTER', titleBar, 'CENTER', 0, 4)
settingsTitleLabel:SetText('Guild Wars')
settingsTitleLabel:SetTextColor(0.922, 0.871, 0.761)

local dividerFrame = CreateFrame('Frame', nil, settingsFrame)
dividerFrame:SetSize(SETTINGS_FRAME_WIDTH + 10, 24)
dividerFrame:SetPoint('BOTTOM', titleBar, 'BOTTOM', 0, -10)
dividerFrame:SetFrameStrata('DIALOG')
dividerFrame:SetFrameLevel(20)
local dividerTexture = dividerFrame:CreateTexture(nil, 'ARTWORK')
dividerTexture:SetAllPoints()
dividerTexture:SetTexture(TEXTURE_PATH .. '\\divider.png')
dividerTexture:SetTexCoord(0, 1, 0, 1)

local titleBarLeftIcon = titleBar:CreateTexture(nil, 'OVERLAY')
titleBarLeftIcon:SetSize(36, 36)
titleBarLeftIcon:SetPoint('LEFT', titleBar, 'LEFT', 15, 3)
titleBarLeftIcon:SetTexture(TEXTURE_PATH .. '\\bonnie-round.png')
titleBarLeftIcon:SetTexCoord(0, 1, 0, 1)

local closeButton = CreateFrame('Button', nil, titleBar, 'UIPanelCloseButton')
closeButton:SetPoint('RIGHT', titleBar, 'RIGHT', -15, 4)
closeButton:SetSize(12, 12)
closeButton:SetScript('OnClick', function()
  if RaceWars_ResetTabState then
    RaceWars_ResetTabState()
  end
  if _G.HideConfirmationDialog then
    _G.HideConfirmationDialog()
  end
  settingsFrame:Hide()
end)
closeButton:SetNormalTexture(TEXTURE_PATH .. '\\header-x.png')
closeButton:SetPushedTexture(TEXTURE_PATH .. '\\header-x.png')
closeButton:SetHighlightTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight', 'ADD')
local closeButtonTex = closeButton:GetNormalTexture()
if closeButtonTex then
  closeButtonTex:SetTexCoord(0, 1, 0, 1)
end
local closeButtonPushed = closeButton:GetPushedTexture()
if closeButtonPushed then
  closeButtonPushed:SetTexCoord(0, 1, 0, 1)
end

function ToggleRaceWarsSettings()
  if settingsFrame:IsShown() then
    if RaceWars_ResetTabState then
      RaceWars_ResetTabState()
    end
    if _G.HideConfirmationDialog then
      _G.HideConfirmationDialog()
    end
    settingsFrame:Hide()
  else
    updateSettingsFrameBackdrop()
    if RaceWars_InitializeTabs then
      RaceWars_InitializeTabs(settingsFrame)
    end
    if RaceWars_HideAllTabs and RaceWars_SetDefaultTab then
      RaceWars_HideAllTabs()
      RaceWars_SetDefaultTab()
    elseif RaceWars_SwitchToTab then
      RaceWars_SwitchToTab(1)
    end
    settingsFrame:Show()
  end
end

function OpenRaceWarsSettingsToTab(tabIndex)
  if type(tabIndex) == 'number' then
    if tabIndex == 5 then
      tabIndex = 3
    end
    if tabIndex < 1 or tabIndex > 4 then
      tabIndex = 1
    end
  end
  updateSettingsFrameBackdrop()
  if RaceWars_InitializeTabs then
    RaceWars_InitializeTabs(settingsFrame)
  end
  if RaceWars_HideAllTabs and RaceWars_SwitchToTab then
    RaceWars_HideAllTabs()
    RaceWars_SwitchToTab(tabIndex)
  end
  settingsFrame:Show()
end

if not RaceWarsDB then RaceWarsDB = {} end
if not RaceWarsDB.minimapButton then RaceWarsDB.minimapButton = { hide = false } end

local addonLDB = LibStub('LibDataBroker-1.1'):NewDataObject('GuildWars', {
  type = 'data source',
  text = 'Guild Wars',
  icon = TEXTURE_PATH .. '\\bonnie-round.png',
  OnClick = function(self, btn)
    if btn == 'LeftButton' then
      ToggleRaceWarsSettings()
    end
  end,
  OnTooltipShow = function(tooltip)
    if not tooltip or not tooltip.AddLine then return end
    tooltip:AddLine('|cffffffffGuild Wars|r\n\nLeft-click to open settings', nil, nil, nil, nil)
  end,
})

local addonIcon = LibStub('LibDBIcon-1.0')
addonIcon:Register('GuildWars', addonLDB, RaceWarsDB.minimapButton)

SLASH_RACEWARS1 = '/racewars'
SLASH_RACEWARS2 = '/rw'
SlashCmdList['RACEWARS'] = ToggleRaceWarsSettings
