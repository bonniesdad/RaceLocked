local playerMoneyFrame = CreateFrame('Frame')

local function OnMoneyChanged()
  local current = GetMoney() or 0
  RaceLocked_SaveDBData('playerMoney', current)
end

local function ValidatePlayerMoneyOnLogin()
  if RaceLocked_PlayerHasSelfFoundBuff and RaceLocked_PlayerHasSelfFoundBuff() then
    if RaceLocked_GetDBValue('playerMoneyValidationFailed') then
      RaceLocked_SaveDBData('playerMoneyValidationFailed', false)
      RaceLocked_SaveDBData('playerMoneyValidationFailedAt', nil)
    end
    return
  end

  local playerMoney = RaceLocked_GetDBValue('playerMoney')
  local current = GetMoney()
  if playerMoney ~= nil and playerMoney ~= current
    and not RaceLocked_GetDBValue('playerMoneyValidationFailed')
  then
    RaceLocked_SaveDBData('playerMoneyValidationFailed', true)
    RaceLocked_SaveDBData('playerMoneyValidationFailedAt', time())
  end
end

playerMoneyFrame:RegisterEvent('PLAYER_MONEY')
playerMoneyFrame:RegisterEvent('PLAYER_LOGIN')

playerMoneyFrame:SetScript('OnEvent', function(_, event, arg1)
  if event == 'PLAYER_MONEY' then
    OnMoneyChanged()
  elseif event == 'PLAYER_LOGIN' then
    ValidatePlayerMoneyOnLogin()
  end
end)
