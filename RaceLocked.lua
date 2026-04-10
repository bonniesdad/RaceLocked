addonName = ...
RaceLocked = CreateFrame('Frame')

RaceLocked:RegisterEvent('ADDON_LOADED')
RaceLocked:SetScript('OnEvent', function(self, event, loadedAddonName)
  if event == 'ADDON_LOADED' and loadedAddonName == addonName then
    RaceLockedDB = RaceLockedDB or {}
    RaceLockedDB.minimapButton = RaceLockedDB.minimapButton or { hide = false }
    RaceLockedDB.guildPeers = RaceLockedDB.guildPeers or {}
    if RaceLockedDB.showOnScreenLeaderboard == nil then
      RaceLockedDB.showOnScreenLeaderboard = true
    end
  end
end)
