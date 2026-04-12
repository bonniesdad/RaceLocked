--- @param settingsFrame Frame must have `raceLockedBackgroundTexture` (BACKGROUND region)
function RaceLocked_Settings_UpdateFrameBackdrop(settingsFrame)
  local S = RaceLocked_Settings
  local bg = settingsFrame.raceLockedBackgroundTexture
  if not bg then
    return
  end
  bg:SetTexture(RaceLocked_Settings_GetClassBackgroundTexture())
  local frameHeight = settingsFrame:GetHeight()
  bg:SetSize(frameHeight * S.CLASS_BACKGROUND_ASPECT_RATIO, frameHeight)
  settingsFrame:SetBackdrop({
    bgFile = nil,
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    tile = false,
    edgeSize = 2,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  settingsFrame:SetBackdropBorderColor(0, 0, 0, 1)
end
