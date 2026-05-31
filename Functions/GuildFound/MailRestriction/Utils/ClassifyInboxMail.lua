--- Classify inbox mail as player, auction house, game master, or NPC/system.
--- Uses GetInboxInvoiceInfo for AH detection (does not call GetInboxText).

local KIND_PLAYER = 'player'
local KIND_AUCTION_HOUSE = 'auction_house'
local KIND_GAME_MASTER = 'game_master'
local KIND_NPC = 'npc'

local KIND_LABELS = {
  [KIND_PLAYER] = 'player',
  [KIND_AUCTION_HOUSE] = 'auction house',
  [KIND_GAME_MASTER] = 'game master',
  [KIND_NPC] = 'NPC/system',
}

local function isAuctionHouseMail(inboxIndex)
  if not GetInboxInvoiceInfo then return false end
  local invoiceType = GetInboxInvoiceInfo(inboxIndex)
  return invoiceType ~= nil
end

--- @param inboxIndex number
--- @return table|nil info { kind, sender, canReply, isGM, invoiceType, label }
function RaceLocked_ClassifyInboxMail(inboxIndex)
  if not inboxIndex or not GetInboxHeaderInfo then return nil end

  local _, _, sender, _, _, _, _, _, _, _, _, canReply, isGM =
    GetInboxHeaderInfo(inboxIndex)

  if isGM and isGM ~= false and isGM ~= 0 then
    return {
      kind = KIND_GAME_MASTER,
      sender = sender,
      canReply = canReply,
      isGM = isGM,
      invoiceType = nil,
      label = KIND_LABELS[KIND_GAME_MASTER],
    }
  end

  if isAuctionHouseMail(inboxIndex) then
    local invoiceType = GetInboxInvoiceInfo(inboxIndex)
    return {
      kind = KIND_AUCTION_HOUSE,
      sender = sender,
      canReply = canReply,
      isGM = isGM,
      invoiceType = invoiceType,
      label = KIND_LABELS[KIND_AUCTION_HOUSE],
    }
  end

  if canReply and sender and sender ~= '' then
    return {
      kind = KIND_PLAYER,
      sender = sender,
      canReply = canReply,
      isGM = isGM,
      invoiceType = nil,
      label = KIND_LABELS[KIND_PLAYER],
    }
  end

  return {
    kind = KIND_NPC,
    sender = sender,
    canReply = canReply,
    isGM = isGM,
    invoiceType = nil,
    label = KIND_LABELS[KIND_NPC],
  }
end

--- Short enforcement hint for dev overlay / logs.
--- @param info table from RaceLocked_ClassifyInboxMail
--- @return string
function RaceLocked_DescribeInboxMailEnforcement(info)
  if not info then return 'unknown mail' end

  if info.kind == KIND_GAME_MASTER or info.kind == KIND_NPC then
    return 'allowed (' .. info.label .. ')'
  end

  if info.kind == KIND_AUCTION_HOUSE then
    return 'would block — AH mail (AH disabled)'
  end

  return nil
end
