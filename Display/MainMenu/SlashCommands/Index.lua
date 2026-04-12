function RaceLocked_Settings_RegisterSlashCommands()
  SLASH_RACELOCKED1 = '/racewars'
  SLASH_RACELOCKED2 = '/rw'
  SlashCmdList['RACELOCKED'] = ToggleRaceLockedSettings
end

RaceLocked_Settings_RegisterSlashCommands()
