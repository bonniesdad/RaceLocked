addonName = ...
RaceLocked = CreateFrame('Frame')

RaceLocked:RegisterEvent('ADDON_LOADED')
RaceLocked:SetScript('OnEvent', function(self, event, loadedAddonName)
  if event == 'ADDON_LOADED' and loadedAddonName == addonName then
    local achievementPoints = RaceLocked_GetHCATotalPoints()
    print("|cfff44336[Race Locked]|r Achievement points: " .. achievementPoints)
    RaceLockedDB = RaceLockedDB or {}
    RaceLockedDB.minimapButton = RaceLockedDB.minimapButton or { hide = false }
    RaceLockedDB.guildPeers = RaceLockedDB.guildPeers or {}
  end
end)
