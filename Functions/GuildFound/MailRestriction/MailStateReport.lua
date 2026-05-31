--- Dev-oriented mail snapshot — delegates to the consent-first access plan.
--- Not called during normal play.

--- Build human-readable lines for chat diagnostics.
--- @return table report { lines = string[] }
function RaceLocked_BuildMailStateReport()
  local lines = {}
  lines[#lines + 1] = 'Guild Found mail (consent flow)'

  if not RaceLocked_IsInGuildFoundGuild or not RaceLocked_IsInGuildFoundGuild() then
    lines[#lines + 1] = 'Not in a Guild Found guild — no mail gate.'
    return { lines = lines }
  end

  if not RaceLocked_AmIVerified or not RaceLocked_AmIVerified() then
    lines[#lines + 1] = 'You are not verified — no mail rules apply.'
    return { lines = lines }
  end

  local guildName = RaceLocked_Roster_GetPlayerGuildName and RaceLocked_Roster_GetPlayerGuildName()
  lines[#lines + 1] = 'You: verified, mail rules active'
  if guildName then
    lines[#lines + 1] = 'Guild: ' .. guildName
  end

  if not RaceLocked_BuildMailAccessPlan then
    lines[#lines + 1] = 'Mail access plan not loaded.'
    return { lines = lines }
  end

  local plan = RaceLocked_BuildMailAccessPlan()
  lines[#lines + 1] = 'Inbox: ' .. tostring(plan.inboxCount) .. ' item(s)'

  for _, line in ipairs(plan.lines) do
    lines[#lines + 1] = line
  end

  return { lines = lines }
end

--- Dev diagnostic — prints full inbox state to chat on demand.
--- Not called during normal play; use /script RaceLocked_PrintMailStateReport() to inspect.

function RaceLocked_PrintMailStateReport()
  local report = RaceLocked_BuildMailStateReport()
  RaceLocked_PrintRestrictionMessage('── Mail state ──')
  for _, line in ipairs(report.lines) do
    RaceLocked_PrintRestrictionMessage(line)
  end
end

--- Kept for roster preview in future outbound checks.
function RaceLocked_EvaluateMailPartner(guildName, playerName)
  if type(playerName) ~= 'string' or playerName == '' then
    return { name = playerName or '?', verdict = 'invalid' }
  end

  local shortName = Ambiguate(playerName, 'short')
  local onGuildRoster = RaceLocked_IsPlayerInGuildRoster
    and RaceLocked_IsPlayerInGuildRoster(shortName) or false

  if not onGuildRoster then
    return {
      name = shortName,
      onGuildRoster = false,
      hasRosterEntry = false,
      verdict = 'not_in_guild',
      summary = 'Not on guild roster — would block',
    }
  end

  local entry = guildName and RaceLocked_Roster_GetEntry(guildName, shortName) or nil
  if not entry then
    return {
      name = shortName,
      onGuildRoster = true,
      hasRosterEntry = false,
      verdict = 'unknown',
      summary = 'No roster entry — handshake fallback needed',
    }
  end

  local ev, ec = RaceLocked_Roster_GetEffectiveStatus(guildName, shortName)
  local eligible = (ev == true and ec == true)
  local function boolLabel(val)
    if val == true then return 'Yes' end
    if val == false then return 'No' end
    return '?'
  end
  return {
    name = shortName,
    onGuildRoster = true,
    hasRosterEntry = true,
    effectiveVerified = ev,
    effectiveClean = ec,
    eligible = eligible,
    verdict = eligible and 'eligible' or 'ineligible',
    summary = eligible and 'Roster eligible — would allow'
      or ('Roster ineligible — would block (V=' .. boolLabel(ev) .. ', C=' .. boolLabel(ec) .. ')'),
  }
end
