function RaceLocked_AmIVerified()
  return RaceLocked_GetDBValue('hasBeenMaxLevelAndSelfFound') == true
    and RaceLocked_GetDBValue('playerMoneyValidationFailed') ~= true
end