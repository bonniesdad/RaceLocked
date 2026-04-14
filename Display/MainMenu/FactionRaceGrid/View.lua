-- Faction race grid: four playable races for your faction in a 2×2 layout (no champion / average panel).

--- @param root Frame
--- @return Frame refreshRow, Button refreshBtn
local function createChrome(root)
  local G = RaceLocked_GuildChampion

  local refreshRow = CreateFrame('Frame', nil, root)
  refreshRow:SetHeight(G.REFRESH_ROW_H)
  local refreshBtn = CreateFrame('Button', nil, refreshRow)
  refreshBtn:SetSize(30, 30)
  refreshBtn:SetPoint('BOTTOMRIGHT', refreshRow, 'BOTTOMRIGHT', -4, -5)
  
  local refreshTex = 'Interface\\Buttons\\UI-RefreshButton'
  local prepareTex = 'Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up'
  local loadingTex = 'Interface\\Buttons\\UI-GroupLoot-Pass-Down'
  refreshBtn._refreshTex = refreshTex
  refreshBtn._prepareTex = prepareTex
  refreshBtn._loadingTex = loadingTex
  refreshBtn:SetNormalTexture(refreshTex)
  refreshBtn:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
  refreshBtn:SetPushedTexture(refreshTex)
  refreshBtn:EnableMouse(true)
  refreshBtn:SetScript('OnEnter', function(self)
    if not GameTooltip then
      return
    end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    if self._isLoading or self._isPreparing then
      GameTooltip:AddLine('Prepare', 1, 0.92, 0.62)
      GameTooltip:AddLine('Prepare guild roster data.', 1, 1, 1)
    elseif self._isPrepared then
      GameTooltip:AddLine('Apply Update', 1, 0.92, 0.62)
      GameTooltip:AddLine('Apply your guild data, rerender, and broadcast.', 1, 1, 1)
    else
      GameTooltip:AddLine('Prepare', 1, 0.92, 0.62)
      GameTooltip:AddLine('Prepare guild roster data.', 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  refreshBtn:SetScript('OnLeave', function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)

  return refreshRow, refreshBtn
end

--- @param root Frame
--- @param raceToken string API race token for icon path
--- @param raceAccent number[] rgb accent bar
--- @return Frame pane, Texture icon, FontString labelFs, FontString detailFs
local function createRaceStatPane(root, raceToken, raceAccent)
  local G = RaceLocked_GuildChampion

  local f = CreateFrame('Frame', nil, root, 'BackdropTemplate')
  f:SetBackdrop(G.CELL_BACKDROP)
  f:SetBackdropColor(G.AP_BG.r, G.AP_BG.g, G.AP_BG.b, G.AP_BG.a)
  f:SetBackdropBorderColor(G.AP_BORDER.r, G.AP_BORDER.g, G.AP_BORDER.b, G.AP_BORDER.a)
  f:SetHeight(G.STATS_ROW_H)

  local accent = f:CreateTexture(nil, 'BORDER')
  accent:SetColorTexture(raceAccent[1], raceAccent[2], raceAccent[3], 1)
  accent:SetWidth(G.ACCENT_W)
  accent:SetPoint('TOPLEFT', f, 'TOPLEFT', G.ACCENT_INSET_X, -G.ACCENT_INSET_Y)
  accent:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', G.ACCENT_INSET_X, G.ACCENT_INSET_Y)

  local icon = f:CreateTexture(nil, 'OVERLAY')
  icon:SetTexture(RaceLocked_GuildChampion_RaceIconTexture(raceToken))
  icon:SetTexCoord(0, 1, 0, 1)
  icon:SetSize(G.FACTION_ICON_SIZE, G.FACTION_ICON_SIZE)
  icon:Show()

  local lbl = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
  lbl:SetJustifyH('LEFT')
  lbl:SetTextColor(G.LABEL_GOLD[1] * 0.9, G.LABEL_GOLD[2] * 0.9, G.LABEL_GOLD[3] * 0.9)

  f._rankFs = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  f._rankFs:SetJustifyH('RIGHT')
  f._rankFs:SetTextColor(G.LABEL_GOLD[1] * 0.85, G.LABEL_GOLD[2] * 0.85, G.LABEL_GOLD[3] * 0.85)

  local det = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  det:SetJustifyH('CENTER')
  det:SetText('—')
  det:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
  f._detailFs = det

  f._guildSectionTitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._guildSectionTitle:SetJustifyH('CENTER')

  f._guildNames = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  f._guildNames:SetJustifyH('CENTER')
  f._guildNames:SetJustifyV('TOP')
  f._guildNames:SetWordWrap(true)

  f._avgSubtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._avgSubtitle:SetJustifyH('CENTER')

  f._totalPlayersSubtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._totalPlayersSubtitle:SetJustifyH('CENTER')

  f._totalPlayersFs = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  f._totalPlayersFs:SetJustifyH('CENTER')
  f._totalPlayersFs:SetText('0')
  f._totalPlayersFs:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])

  f._classSubtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  f._classSubtitle:SetJustifyH('CENTER')

  f._classBarHost = CreateFrame('Frame', nil, f)
  f._classBarHost:SetHeight(G.CLASS_BAR_HOST_H)

  f._classBarPctRow = CreateFrame('Frame', nil, f._classBarHost)
  f._classBarPctRow:SetHeight(G.CLASS_BAR_LABEL_ROW)

  f._classBarBarWell = CreateFrame('Frame', nil, f._classBarHost, 'BackdropTemplate')
  f._classBarBarWell:SetBackdrop(G.CLASS_BAR_CHART_BACKDROP)
  f._classBarBarWell:SetBackdropColor(0.05, 0.06, 0.08, 0.92)
  f._classBarBarWell:SetBackdropBorderColor(G.AP_BORDER.r, G.AP_BORDER.g, G.AP_BORDER.b, G.AP_BORDER.a * 0.85)
  f._classBarBarWell:SetHeight(G.CLASS_BAR_HEIGHT + 2 * G.CLASS_BAR_BORDER_PAD)

  f._classBarRow = CreateFrame('Frame', nil, f._classBarBarWell)
  f._classBarRow:SetHeight(G.CLASS_BAR_HEIGHT)

  f._classCol = {}
  for idx = 1, 9 do
    local col = CreateFrame('Frame', nil, f._classBarRow)
    col:SetHeight(G.CLASS_BAR_HEIGHT)
    col:EnableMouse(true)
    local tex = col:CreateTexture(nil, 'ARTWORK')
    tex:SetHeight(G.CLASS_BAR_HEIGHT)
    tex:SetPoint('TOPLEFT', col, 'TOPLEFT', 0, 0)
    tex:SetPoint('TOPRIGHT', col, 'TOPRIGHT', 0, 0)
    local pct = f._classBarPctRow:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    pct:SetHeight(G.CLASS_BAR_LABEL_ROW)
    pct:SetJustifyH('CENTER')
    pct:SetJustifyV('BOTTOM')
    local pctHit = CreateFrame('Frame', nil, f._classBarPctRow)
    pctHit:SetFrameLevel((pct.GetFrameLevel and pct:GetFrameLevel() or 0) + 3)
    pctHit:EnableMouse(true)
    pctHit:Hide()
    local cell = { frame = col, tex = tex, pct = pct, pctHit = pctHit }
    f._classCol[idx] = cell
    col._rlCell = cell
    pctHit._rlCell = cell
    col:SetScript('OnEnter', RaceLocked_GuildChampion_OnClassBarCellEnter)
    col:SetScript('OnLeave', RaceLocked_GuildChampion_OnClassBarCellLeave)
    pctHit:SetScript('OnEnter', RaceLocked_GuildChampion_OnClassBarCellEnter)
    pctHit:SetScript('OnLeave', RaceLocked_GuildChampion_OnClassBarCellLeave)
  end

  f._classBarSep = {}
  for s = 1, 8 do
    local sep = f._classBarRow:CreateTexture(nil, 'OVERLAY')
    sep:SetColorTexture(G.CLASS_BAR_SEP[1], G.CLASS_BAR_SEP[2], G.CLASS_BAR_SEP[3], 1)
    sep:SetWidth(G.CLASS_BAR_SEP_W)
    sep:SetHeight(G.CLASS_BAR_HEIGHT)
    sep:Hide()
    f._classBarSep[s] = sep
  end

  return f, icon, lbl, det
end

local function textLeftOffset()
  local G = RaceLocked_GuildChampion
  return G.ACCENT_INSET_X + G.ACCENT_W + G.GAP_AFTER_ACCENT + G.FACTION_ICON_SIZE + G.GAP_AFTER_ICON
end

--- @param pane Frame
--- @param labelFs FontString race name
--- @param detailFs FontString average level value
--- @param tx number left inset for text block
--- @param raceToken string UnitRace token for class availability
local function layoutRaceGridPane(pane, labelFs, detailFs, tx, raceToken)
  local G = RaceLocked_GuildChampion
  local lg = G.RACE_GRID_PANE_SECTION_GAP or 0
  local w = pane:GetWidth() - tx - G.INNER_PAD
  w = math.max(w, 48)
  -- Class bar: full inner width of the cell (not aligned to text column after the icon).
  local barLeft = G.INNER_PAD + G.CLASS_BAR_EXTRA_LEFT_PAD
  local barW = pane:GetWidth() - barLeft - G.INNER_PAD
  barW = math.max(barW, 48)

  labelFs:ClearAllPoints()
  labelFs:SetPoint('TOPLEFT', pane, 'TOPLEFT', tx, -6)
  local labelW = pane._rankFs and math.max(40, w - 40) or w
  labelFs:SetWidth(labelW)

  local guildH = pane._guildSectionTitle
  guildH:ClearAllPoints()
  guildH:SetPoint('TOPLEFT', labelFs, 'BOTTOMLEFT', barLeft - tx, -(10 + lg))
  guildH:SetWidth(barW)

  local gNames = pane._guildNames
  gNames:ClearAllPoints()
  gNames:SetPoint('TOPLEFT', guildH, 'BOTTOMLEFT', 0, -1)
  gNames:SetWidth(barW)

  local avgSub = pane._avgSubtitle
  local totalSub = pane._totalPlayersSubtitle
  local totalFs = pane._totalPlayersFs
  local statsGap = 8
  local avgW = math.max(24, math.floor((barW - statsGap) / 2))
  local totalW = math.max(24, barW - avgW - statsGap)
  avgSub:ClearAllPoints()
  avgSub:SetPoint('TOPLEFT', gNames, 'BOTTOMLEFT', 0, -(5 + lg))
  avgSub:SetWidth(avgW)

  totalSub:ClearAllPoints()
  totalSub:SetPoint('TOPLEFT', avgSub, 'TOPRIGHT', statsGap, 0)
  totalSub:SetWidth(totalW)

  detailFs:ClearAllPoints()
  detailFs:SetPoint('TOPLEFT', avgSub, 'BOTTOMLEFT', 0, -2)
  detailFs:SetWidth(avgW)

  totalFs:ClearAllPoints()
  totalFs:SetPoint('TOPLEFT', totalSub, 'BOTTOMLEFT', 0, -2)
  totalFs:SetWidth(totalW)

  local cSub = pane._classSubtitle
  cSub:ClearAllPoints()
  cSub:SetPoint('TOPLEFT', detailFs, 'BOTTOMLEFT', 0, -(11 + lg))
  cSub:SetWidth(barW)

  local host = pane._classBarHost
  host:ClearAllPoints()
  host:SetPoint('TOPLEFT', cSub, 'BOTTOMLEFT', 0, -4)
  host:SetWidth(barW)
  host:SetHeight(G.CLASS_BAR_HOST_H)

  local pctRow = pane._classBarPctRow
  pctRow:ClearAllPoints()
  pctRow:SetPoint('TOPLEFT', host, 'TOPLEFT', 0, 0)
  pctRow:SetWidth(barW)
  pctRow:SetHeight(G.CLASS_BAR_LABEL_ROW)

  local well = pane._classBarBarWell
  well:ClearAllPoints()
  well:SetPoint('BOTTOMLEFT', host, 'BOTTOMLEFT', 0, 0)
  well:SetWidth(barW)
  well:SetHeight(G.CLASS_BAR_HEIGHT + 2 * G.CLASS_BAR_BORDER_PAD)

  local pad = G.CLASS_BAR_BORDER_PAD
  local row = pane._classBarRow
  row:ClearAllPoints()
  row:SetPoint('TOPLEFT', well, 'TOPLEFT', pad, -pad)
  row:SetPoint('TOPRIGHT', well, 'TOPRIGHT', -pad, -pad)
  row:SetHeight(G.CLASS_BAR_HEIGHT)

  if pane._rankFs then
    pane._rankFs:ClearAllPoints()
    pane._rankFs:SetPoint('TOPRIGHT', pane, 'TOPRIGHT', -G.INNER_PAD, -4)
  end
end

--- Sort key: higher average first; ties keep stable order by race index.
local function computeRaceGridSortOrder(raceTokens)
  local rows = {}
  for i = 1, 4 do
    local token = raceTokens[i]
    local agg = RaceLocked_GuildChampion_GetAggregatedMockForRace and RaceLocked_GuildChampion_GetAggregatedMockForRace(token)
    local avg = agg and agg.averageLevel
    local avn = type(avg) == 'number' and avg or -math.huge
    rows[#rows + 1] = { idx = i, avg = avn }
  end
  table.sort(rows, function(a, b)
    if a.avg ~= b.avg then
      return a.avg > b.avg
    end
    return a.idx < b.idx
  end)
  local order = {}
  local rankByIdx = {}
  for slot = 1, 4 do
    order[slot] = rows[slot].idx
    rankByIdx[rows[slot].idx] = slot
  end
  return order, rankByIdx
end

--- Lay out the faction race grid: 2×2 panes (sorted by average level) and refresh row.
--- @param ctx table
local function layoutGrid(ctx)
  local G = RaceLocked_GuildChampion
  local root = ctx.root
  local parent = ctx.parent
  local rightInset = ctx.rightInset

  local rw = root:GetWidth()
  if (not rw or rw < 2) and parent and parent.GetWidth then
    rw = math.max(0, parent:GetWidth() - rightInset)
  end
  if rw < 80 then
    rw = 400
  end

  local rowInner = rw - G.MID_GAP
  local wLeft = math.floor(rowInner / 2)
  local wRight = rowInner - wLeft

  local gridTop = G.OUTER_PAD_Y + G.GRID_TOP_OFFSET

  local panes = ctx.panes
  local raceTokens = ctx.raceTokens

  local order, rankByIdx = computeRaceGridSortOrder(raceTokens)
  ctx.sortOrder = order

  local o1, o2, o3, o4 = order[1], order[2], order[3], order[4]

  panes[o1]:ClearAllPoints()
  panes[o1]:SetPoint('TOPLEFT', root, 'TOPLEFT', 0, -gridTop)
  panes[o1]:SetSize(wLeft, G.STATS_ROW_H)

  panes[o2]:ClearAllPoints()
  panes[o2]:SetPoint('TOPLEFT', panes[o1], 'TOPRIGHT', G.MID_GAP, 0)
  panes[o2]:SetSize(wRight, G.STATS_ROW_H)

  panes[o3]:ClearAllPoints()
  panes[o3]:SetPoint('TOPLEFT', panes[o1], 'BOTTOMLEFT', 0, -G.ROW_GAP)
  panes[o3]:SetSize(wLeft, G.STATS_ROW_H)

  panes[o4]:ClearAllPoints()
  panes[o4]:SetPoint('TOPLEFT', panes[o3], 'TOPRIGHT', G.MID_GAP, 0)
  panes[o4]:SetSize(wRight, G.STATS_ROW_H)

  local icons = ctx.icons
  for j = 1, 4 do
    local icon = icons[j]
    icon:ClearAllPoints()
    icon:SetSize(G.FACTION_ICON_SIZE, G.FACTION_ICON_SIZE)
    icon:SetPoint('LEFT', panes[j], 'LEFT', G.ACCENT_INSET_X + G.ACCENT_W + G.GAP_AFTER_ACCENT, 0)
    icon:SetPoint('TOP', panes[j], 'TOP', 0, -6)
  end

  local tx = textLeftOffset()
  for i = 1, 4 do
    layoutRaceGridPane(panes[i], ctx.labels[i], ctx.details[i], tx, ctx.raceTokens[i])
    if panes[i]._rankFs then
      panes[i]._rankFs:SetText('#' .. tostring(rankByIdx[i]))
    end
  end

  ctx.refreshRow:ClearAllPoints()
  ctx.refreshRow:SetPoint('TOPLEFT', panes[o3], 'BOTTOMLEFT', 0, -G.GAP_AFTER_GRID)
  ctx.refreshRow:SetPoint('TOPRIGHT', panes[o4], 'BOTTOMRIGHT', 0, -G.GAP_AFTER_GRID)

  local newH = gridTop
    + G.STATS_ROW_H * 2
    + G.ROW_GAP
    + G.GAP_AFTER_GRID
    + G.REFRESH_ROW_H
    + G.OUTER_PAD_Y
  root:SetHeight(newH)
  ctx.totalH = newH

  RaceLocked_GuildChampion_RefreshRaceGridDisplay(ctx.panes, ctx.raceTokens)
end

--- @param parent Frame
--- @param rightInset number|nil optional right inset (legacy; kept for call compatibility)
--- @return Frame root
--- @return number total height
function RaceLocked_CreateFactionRaceGrid(parent, rightInset)
  rightInset = rightInset or 0
  local G = RaceLocked_GuildChampion

  local totalH = G.OUTER_PAD_Y
    + G.GRID_TOP_OFFSET
    + G.STATS_ROW_H * 2
    + G.ROW_GAP
    + G.GAP_AFTER_GRID
    + G.REFRESH_ROW_H
    + G.OUTER_PAD_Y

  local root = CreateFrame('Frame', nil, parent)
  root:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
  root:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -rightInset, 0)
  root:SetHeight(totalH)

  local refreshRow, refreshBtn = createChrome(root)

  local playerFaction = UnitFactionGroup and UnitFactionGroup('player') or 'Alliance'
  local isHorde = playerFaction == 'Horde'
  local raceAccents = isHorde and G.HORDE_RACE_ACCENT or G.ALLIANCE_RACE_ACCENT
  local raceTokens = isHorde and { 'Orc', 'Troll', 'Tauren', 'Scourge' }
    or { 'Dwarf', 'NightElf', 'Human', 'Gnome' }

  local playerRaceToken = ''
  if UnitRace then
    local _, token = UnitRace('player')
    if token and token ~= '' then
      playerRaceToken = token
    end
  end

  local panes = {}
  local labels = {}
  local details = {}
  local icons = {}

  for i = 1, 4 do
    local f, icon, lbl, det = createRaceStatPane(root, raceTokens[i], raceAccents[i])
    panes[i] = f
    labels[i] = lbl
    details[i] = det
    icons[i] = icon
  end

  if isHorde then
    labels[1]:SetText('Orc')
    labels[2]:SetText('Troll')
    labels[3]:SetText('Tauren')
    labels[4]:SetText('Undead')
  else
    labels[1]:SetText('Dwarf')
    labels[2]:SetText('Night Elf')
    labels[3]:SetText('Human')
    labels[4]:SetText('Gnome')
  end

  local layoutCtx = {
    root = root,
    parent = parent,
    rightInset = rightInset,
    refreshRow = refreshRow,
    panes = panes,
    labels = labels,
    details = details,
    icons = icons,
    raceTokens = raceTokens,
    playerRaceToken = playerRaceToken,
    totalH = totalH,
  }

  local function runLayout()
    layoutGrid(layoutCtx)
  end
  RaceLocked_GuildChampion_RequestRaceGridRerender = runLayout

  refreshBtn:SetScript('OnClick', function()
    if refreshBtn._isLoading or refreshBtn._isPreparing then
      return
    end

    local inGuild = IsInGuild and IsInGuild()
    --- Must not depend on RaceLocked_GuildChampion_GetGuildRosterMemberCount existing; if that global is nil the old
    --- `if inGuild and RaceLocked_...` skipped the whole gate and the UI always refreshed.
    local function readGuildRosterMemberCountForGate()
      if RaceLocked_GuildChampion_GetGuildRosterMemberCount then
        return RaceLocked_GuildChampion_GetGuildRosterMemberCount()
      end
      if not GetNumGuildMembers then
        return 0
      end
      local n = GetNumGuildMembers(true)
      n = tonumber(n) or 0
      if n < 1 then
        n = GetNumGuildMembers()
        n = tonumber(n) or 0
      end
      return n
    end

    if not refreshBtn._isPrepared then
      if inGuild then
        local n = readGuildRosterMemberCountForGate()
        local minN = tonumber(G.MIN_GUILD_MEMBERS_FOR_RACE_GRID) or 100
        if n < minN then
          print(
            string.format(
              '|cffffffffRace Locked|r: Your guild needs at least %d guild members (current: %d) to show here.',
              minN,
              n
            )
          )
          refreshBtn._isPrepared = false
          return
        end
      end
      refreshBtn._isPreparing = true
      refreshBtn:SetNormalTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
      refreshBtn:SetPushedTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
      refreshBtn:SetDisabledTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
      refreshBtn:Disable()
      refreshBtn:SetAlpha(0.75)
      RaceLocked_RefreshGuildRoster()
      local function finishPrepare()
        refreshBtn._isPreparing = false
        refreshBtn._isPrepared = true
        refreshBtn:SetNormalTexture(refreshBtn._prepareTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Up')
        refreshBtn:SetPushedTexture(refreshBtn._prepareTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Up')
        refreshBtn:SetDisabledTexture(refreshBtn._prepareTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Up')
        refreshBtn:Enable()
        refreshBtn:SetAlpha(1)
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(1.0, finishPrepare)
      else
        finishPrepare()
      end
      return
    end

    refreshBtn._isLoading = true
    refreshBtn:SetNormalTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
    refreshBtn:SetPushedTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
    refreshBtn:SetDisabledTexture(refreshBtn._loadingTex or 'Interface\\Buttons\\UI-GroupLoot-Pass-Down')
    refreshBtn:Disable()
    refreshBtn:SetAlpha(0.75)

    local rosterRequested = false

    local function refreshOwnStoredRowsAndRedraw()
      if inGuild then
        local n = readGuildRosterMemberCountForGate()
        local minN = tonumber(G.MIN_GUILD_MEMBERS_FOR_RACE_GRID) or 100
        if rosterRequested and n < 1 then
          print('|cffffffffRace Locked|r: Roster is not yet loaded, please try again.')
          return false
        end
        if n < minN then
          print(
            string.format(
              '|cffffffffRace Locked|r: Your guild needs at least %d guild members (current: %d) to show here.',
              minN,
              n
            )
          )
          return false
        end
      end
      if RaceLocked_GuildChampion_UpdateOwnStoredGuildReportsFromRoster then
        RaceLocked_GuildChampion_UpdateOwnStoredGuildReportsFromRoster(raceTokens)
      end
      runLayout()
      return true
    end

    local function finishRefreshButton()
      refreshBtn:SetNormalTexture(refreshBtn._refreshTex or 'Interface\\Buttons\\UI-RefreshButton')
      refreshBtn:SetPushedTexture(refreshBtn._refreshTex or 'Interface\\Buttons\\UI-RefreshButton')
      refreshBtn:SetDisabledTexture(refreshBtn._refreshTex or 'Interface\\Buttons\\UI-RefreshButton')
      refreshBtn:Enable()
      refreshBtn:SetAlpha(1)
      refreshBtn._isLoading = false
      refreshBtn._isPrepared = false
    end

    if inGuild and GuildRoster then
      GuildRoster()
      rosterRequested = true
    end

    -- No refresh timer: roster still loading or under min size skips save/UI/broadcast; user clicks again when ready.
    -- SendChatMessage to CHANNEL is protected — broadcast only runs here on the same stack as this click.
    local ok = refreshOwnStoredRowsAndRedraw()
    if ok and RaceLocked_GuildChampion_BroadcastOwnGuildRaceGridReports then
      RaceLocked_GuildChampion_BroadcastOwnGuildRaceGridReports()
    end
    finishRefreshButton()
  end)

  root:SetScript('OnSizeChanged', runLayout)
  root:SetScript('OnShow', function()
    runLayout()
    if C_Timer and C_Timer.After then
      C_Timer.After(0, runLayout)
    end
  end)
  runLayout()

  return root, layoutCtx.totalH
end
