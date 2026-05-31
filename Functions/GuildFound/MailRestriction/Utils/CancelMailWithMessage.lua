function RaceLocked_CancelMailWithMessage(inboxIndex, message)
  if RaceLocked_RemoveInboxMail then
    RaceLocked_RemoveInboxMail(inboxIndex, message)
  elseif inboxIndex then
    if message then
      RaceLocked_PrintRestrictionMessage(message)
    end
    ReturnInboxItem(inboxIndex)
  end
end
