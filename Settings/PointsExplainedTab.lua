-- "Points Explained" settings tab: how leaderboard metrics are earned.

local SECTION_TITLE_COLOR = { r = 0.98, g = 0.86, b = 0.42 }
local BODY_COLOR = { r = 0.85, g = 0.82, b = 0.76 }

local SECTIONS = {
  {
    title = 'Level',
    body = 'Lists are sorted by character level first: higher level ranks higher. '
      .. 'When level is tied, Achievement Points breaks the tie, then character name.',
  },
  {
    title = 'Achievement Points',
    body = 'Achievement Points are earned by completing achievements from the Hardcore Achievements addon.'
  },
}

function RaceLocked_InitializePointsExplainedTab(tabContents, index)
  local content = tabContents and tabContents[index]
  if not content or content.pointsExplainedInit then
    return
  end
  content.pointsExplainedInit = true

  local scroll = CreateFrame('ScrollFrame', nil, content, 'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT', content, 'TOPLEFT', 6, -8)
  scroll:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -32, 10)

  local scrollChild = CreateFrame('Frame', nil, scroll)
  local contentW = content:GetWidth()
  if not contentW or contentW < 100 then
    contentW = 508
  end
  local padX = 14
  local w = math.max(200, contentW - 52)
  scrollChild:SetWidth(w + padX * 2)
  scroll:SetScrollChild(scrollChild)

  local y = -16
  local gapAfterTitle = 6
  local gapAfterBody = 22

  for s = 1, #SECTIONS do
    local sec = SECTIONS[s]
    local titleFs = scrollChild:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    titleFs:SetWidth(w)
    titleFs:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', padX, y)
    titleFs:SetJustifyH('LEFT')
    titleFs:SetJustifyV('TOP')
    titleFs:SetText(sec.title)
    titleFs:SetTextColor(SECTION_TITLE_COLOR.r, SECTION_TITLE_COLOR.g, SECTION_TITLE_COLOR.b)

    y = y - titleFs:GetStringHeight() - gapAfterTitle

    local bodyFs = scrollChild:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    bodyFs:SetWidth(w)
    bodyFs:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', padX, y)
    bodyFs:SetJustifyH('LEFT')
    bodyFs:SetJustifyV('TOP')
    bodyFs:SetSpacing(3)
    bodyFs:SetText(sec.body)
    bodyFs:SetTextColor(BODY_COLOR.r, BODY_COLOR.g, BODY_COLOR.b)

    y = y - bodyFs:GetStringHeight() - gapAfterBody
  end

  scrollChild:SetHeight(math.max(-y + 24, 1))
end
