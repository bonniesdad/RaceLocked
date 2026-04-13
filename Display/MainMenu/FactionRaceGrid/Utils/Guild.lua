


--- @param classKey string e.g. warriors
--- @return number r, number g, number b
local function classColorForReportKey(G, classKey)
  local file = G.CLASS_KEY_TO_FILE[classKey]
  if not file then
    return 0.85, 0.85, 0.8
  end
  if RAID_CLASS_COLORS and RAID_CLASS_COLORS[file] then
    local c = RAID_CLASS_COLORS[file]
    return c.r, c.g, c.b
  end
  if GetClassColor then
    local r, g, b = GetClassColor(file)
    if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
      return r, g, b
    end
  end
  return 0.85, 0.85, 0.8
end

--- @param G table
--- @param classKey string
--- @return string
local function classLabelForReportKey(G, classKey)
  for i = 1, #G.CLASS_REPORT_KEYS do
    local row = G.CLASS_REPORT_KEYS[i]
    if row.key == classKey then
      return row.label
    end
  end
  return classKey or ''
end

--- Called from bar / % hit frames (`self._rlCell` -> cell table).
function RaceLocked_GuildChampion_OnClassBarCellEnter(self)
  if not self then
    return
  end
  local cell = self._rlCell
  if not cell or not cell._rlHasTip or not GameTooltip then
    return
  end
  local G = RaceLocked_GuildChampion
  GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
  GameTooltip:ClearLines()
  if cell._rlEmptyTip then
    GameTooltip:AddLine(G.RACE_GRID_CLASS_SUBTITLE, G.LABEL_GOLD[1], G.LABEL_GOLD[2], G.LABEL_GOLD[3])
    GameTooltip:AddLine('No character counts for this race.', 1, 1, 1)
  else
    local key = cell._rlClassKey
    local count = cell._rlCount or 0
    local total = cell._rlTotal or 0
    local label = classLabelForReportKey(G, key)
    local r, g, b = classColorForReportKey(G, key)
    GameTooltip:AddLine(label, r, g, b)
    local pct = 0
    if total > 0 then
      pct = math.floor((100 * count / total) + 0.5)
    end
    GameTooltip:AddLine(
      string.format('%d of %d characters (%d%%)', count, total, pct),
      1,
      1,
      1
    )
  end
  GameTooltip:Show()
end

function RaceLocked_GuildChampion_OnClassBarCellLeave()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

--- Horizontally stack class bar segments under the class subtitle.
--- @param pane Frame
--- @param widths number[] pixel width per column index (1..9)
local function layoutClassBarColumns(pane, widths)
  local G = RaceLocked_GuildChampion
  local row = pane._classBarRow
  local pctRow = pane._classBarPctRow
  if not row or not pctRow or not pane._classCol then
    return
  end
  local seps = pane._classBarSep
  if seps then
    for s = 1, 8 do
      seps[s]:Hide()
    end
  end
  local colH = row:GetHeight()
  local x = 0
  local sepIdx = 1
  local sawVisible = false
  for idx = 1, 9 do
    local cell = pane._classCol[idx]
    if not cell then
      break
    end
    local wpx = widths[idx] or 0
    if wpx <= 0 then
      cell.frame:Hide()
      cell.pct:Hide()
      if cell.pctHit then
        cell.pctHit:Hide()
      end
    else
      if sawVisible and seps and sepIdx <= 8 then
        local sep = seps[sepIdx]
        sep:ClearAllPoints()
        sep:SetPoint('TOPLEFT', row, 'TOPLEFT', x, 0)
        sep:SetSize(G.CLASS_BAR_SEP_W, colH)
        sep:SetColorTexture(G.CLASS_BAR_SEP[1], G.CLASS_BAR_SEP[2], G.CLASS_BAR_SEP[3], 1)
        sep:Show()
        sepIdx = sepIdx + 1
      end
      sawVisible = true
      cell.frame:Show()
      cell.frame:ClearAllPoints()
      cell.frame:SetPoint('TOPLEFT', row, 'TOPLEFT', x, 0)
      cell.frame:SetSize(wpx, colH)
      cell.tex:SetWidth(math.max(1, wpx))
      cell.pct:Show()
      cell.pct:ClearAllPoints()
      cell.pct:SetPoint('BOTTOMLEFT', pctRow, 'BOTTOMLEFT', x, 0)
      cell.pct:SetSize(wpx, G.CLASS_BAR_LABEL_ROW)
      if cell.pctHit then
        cell.pctHit:Show()
        cell.pctHit:ClearAllPoints()
        cell.pctHit:SetPoint('BOTTOMLEFT', pctRow, 'BOTTOMLEFT', x, 0)
        cell.pctHit:SetSize(wpx, G.CLASS_BAR_LABEL_ROW)
      end
      x = x + wpx
    end
  end
end

--- @param G table RaceLocked_GuildChampion
local function mutedBarTexture(tex)
  tex:SetColorTexture(0.22, 0.22, 0.24, 1)
end

function RaceLocked_GuildChampion_RefreshRaceGridDisplay(panes, raceTokens)
  local G = RaceLocked_GuildChampion
  if not panes[1] or not panes[1]._guildSectionTitle or not panes[1]._classBarHost then
    return
  end
  for i = 1, 4 do
    local pane = panes[i]
    local token = raceTokens[i]
    local agg = RaceLocked_GuildChampion_GetAggregatedMockForRace and RaceLocked_GuildChampion_GetAggregatedMockForRace(token)
    local subR, subG, subB = G.LABEL_GOLD[1] * 0.85, G.LABEL_GOLD[2] * 0.85, G.LABEL_GOLD[3] * 0.85
    pane._guildSectionTitle:SetText(G.RACE_GRID_GUILD_SECTION_TITLE)
    pane._guildSectionTitle:SetTextColor(subR, subG, subB)

    if agg and agg.guildNamesText and agg.guildNamesText ~= '' then
      pane._guildNames:SetText(agg.guildNamesText)
      pane._guildNames:SetTextColor(0.88, 0.86, 0.8)
    else
      pane._guildNames:SetText('—')
      pane._guildNames:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
    end

    pane._avgSubtitle:SetText(G.RACE_GRID_AVG_SUBTITLE)
    pane._avgSubtitle:SetTextColor(subR, subG, subB)
    pane._totalPlayersSubtitle:SetText(G.RACE_GRID_TOTAL_PLAYERS_SUBTITLE or 'Total players')
    pane._totalPlayersSubtitle:SetTextColor(subR, subG, subB)

    local det = pane._detailFs
    if agg and agg.averageLevel and agg.averageLevel > 0 then
      det:SetText(tostring(math.floor(agg.averageLevel + 0.5)))
      det:SetTextColor(0.82, 0.8, 0.74)
    else
      det:SetText('-')
      det:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
    end

    local classes = (agg and agg.classes) or {}
    local totalPlayers = 0
    for _, n in pairs(classes) do
      totalPlayers = totalPlayers + (tonumber(n) or 0)
    end
    if totalPlayers > 0 then
      pane._totalPlayersFs:SetText(tostring(totalPlayers))
      pane._totalPlayersFs:SetTextColor(0.82, 0.8, 0.74)
    else
      pane._totalPlayersFs:SetText('-')
      pane._totalPlayersFs:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
    end

    pane._classSubtitle:SetText(G.RACE_GRID_CLASS_SUBTITLE)
    pane._classSubtitle:SetTextColor(subR, subG, subB)

    local keys = G.RACE_TOKEN_TO_CLASS_KEYS[token] or {}
    local nKeys = #keys
    local total = 0
    for _, k in ipairs(keys) do
      total = total + (tonumber(classes[k]) or 0)
    end

    local row = pane._classBarRow
    -- Inner width (row), not outer host — matches padded bar area inside the chart border.
    local hostW = row and row:GetWidth() or 0
    if not hostW or hostW < 4 then
      hostW = 160
    end

    local widths = {}
    for idx = 1, 9 do
      widths[idx] = 0
    end

    local pctRow = pane._classBarPctRow
    if row and pctRow and pane._classCol then
      for clearIdx = 1, 9 do
        local c = pane._classCol[clearIdx]
        if not c then
          break
        end
        c._rlHasTip = false
        c._rlEmptyTip = false
        c._rlClassKey = nil
        c._rlCount = nil
        c._rlTotal = nil
        if c.pctHit then
          c.pctHit:Hide()
        end
      end
      if pane._classBarSep then
        for s = 1, 8 do
          pane._classBarSep[s]:Hide()
        end
      end
      if nKeys < 1 or total <= 0 then
        local barH = row:GetHeight()
        for idx = 1, 9 do
          local cell = pane._classCol[idx]
          if not cell then
            break
          end
          if idx == 1 then
            cell.frame:Show()
            cell.frame:ClearAllPoints()
            cell.frame:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
            cell.frame:SetSize(hostW, barH)
            cell.tex:SetWidth(math.max(1, hostW))
            mutedBarTexture(cell.tex)
            cell.pct:Show()
            cell.pct:ClearAllPoints()
            cell.pct:SetPoint('BOTTOMLEFT', pctRow, 'BOTTOMLEFT', 0, 0)
            cell.pct:SetSize(hostW, G.CLASS_BAR_LABEL_ROW)
            cell.pct:SetText('-')
            cell.pct:SetTextColor(G.MUTED[1], G.MUTED[2], G.MUTED[3])
            cell._rlHasTip = true
            cell._rlEmptyTip = true
            if cell.pctHit then
              cell.pctHit:Show()
              cell.pctHit:ClearAllPoints()
              cell.pctHit:SetPoint('BOTTOMLEFT', pctRow, 'BOTTOMLEFT', 0, 0)
              cell.pctHit:SetSize(hostW, G.CLASS_BAR_LABEL_ROW)
            end
          else
            cell.frame:Hide()
            cell.pct:Hide()
            cell.pct:SetText('')
          end
        end
      else
        local assigned = 0
        for j = 1, nKeys - 1 do
          local k = keys[j]
          local c = tonumber(classes[k]) or 0
          local wpx = math.floor((c / total) * hostW)
          widths[j] = wpx
          assigned = assigned + wpx
        end
        widths[nKeys] = math.max(0, hostW - assigned)

        for idx = 1, nKeys do
          local cell = pane._classCol[idx]
          if not cell then
            break
          end
          local classKey = keys[idx]
          local c = tonumber(classes[classKey]) or 0
          local wpx = widths[idx] or 0
          local r, g, b = classColorForReportKey(G, classKey)
          if wpx <= 0 then
            cell.frame:Hide()
            cell.pct:Hide()
            cell.pct:SetText('')
          else
            cell.tex:SetColorTexture(r, g, b, 1)
            local pctNum = math.floor((100 * c / total) + 0.5)
            cell.pct:SetText(string.format('%d%%', pctNum))
            cell.pct:SetTextColor(r * 0.85, g * 0.85, b * 0.85)
            cell._rlHasTip = true
            cell._rlEmptyTip = false
            cell._rlClassKey = classKey
            cell._rlCount = c
            cell._rlTotal = total
          end
        end
        for idx = nKeys + 1, 9 do
          local cell = pane._classCol[idx]
          if not cell then
            break
          end
          cell.frame:Hide()
          cell.pct:Hide()
          cell.pct:SetText('')
        end
        layoutClassBarColumns(pane, widths)
      end
    end
  end
end
