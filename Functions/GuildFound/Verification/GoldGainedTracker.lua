--- Tamper detection for the "clean" half of Guild Found verification.
---
--- Model: while playing we persist the player's current gold on every
--- PLAYER_MONEY event. On the next login we compare the saved gold to the
--- live amount: if they differ, the SavedVariables file was edited offline
--- (the only way gold can change while logged out), so we set the persistent
--- flag `playerMoneyValidationFailed = true`. We only check on login because
--- that is the boundary where offline tampering can be detected.
---
--- Self-found exemption: a character still flagged self-found by the game
--- cannot meaningfully tamper for advantage, so any prior failure flag while
--- self-found is treated as a false positive and cleared.
---
--- This flag is consumed by RaceLocked_IsLocalClean() (AmIVerified.lua) and is
--- shown as the "Tampering" row in the Guild Verification display.
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
