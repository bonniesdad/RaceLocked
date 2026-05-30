--- Session-only log of Guild Found roster addon traffic (sent / received).

local MAX_ENTRIES = 200

local entries = {}

local function trimOldest()
  while #entries > MAX_ENTRIES do
    table.remove(entries, 1)
  end
end

function RaceLocked_Roster_AppendSessionLog(kind, text)
  if type(text) ~= 'string' or text == '' then return end

  entries[#entries + 1] = {
    kind = kind or 'info',
    text = text,
    clock = date('%H:%M:%S'),
  }
  trimOldest()

  if RaceLocked_Roster_OnSessionLogUpdated then
    RaceLocked_Roster_OnSessionLogUpdated()
  end
end

function RaceLocked_Roster_GetSessionLog()
  return entries
end
