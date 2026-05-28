function RaceLocked_AmIVerified() 
  return (RaceLocked_GetDBValue('hasBeenMaxLevelAndSelfFound') == true or RaceLocked_ShouldOverrideVerificationViaGuildNote(UnitName('player')) == true) and RaceLocked_GetDBValue('playerMoneyValidationFailed') ~= true
end
