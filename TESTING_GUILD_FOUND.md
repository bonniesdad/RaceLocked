# Guild Found Feature — In-Game Test Plan

Use this checklist to validate all Guild Found roster, mail, trade, and AH restrictions before PR submission.
Mark each test PASS/FAIL as you go. Tests are grouped by feature area.

---

## Prerequisites

- [ ] Two characters in the "FOR GNOMEREGAN" guild (Tester A and Tester B)
- [ ] At least one character that is NOT in the guild (Tester C)
- [ ] Tester A: level 60+ and has reached 60 while self-found (`hasBeenMaxLevelAndSelfFound = true`)
- [ ] Tester B: same as A, on a second account or have someone help
- [ ] Tester A has `/script RaceLocked_PrintMailStateReport()` accessible for diagnostics
- [ ] Fresh `/reload` before starting each section

---

## 1. Self-Verification (`AmIVerified`)

### 1.1 — Base verification
- [ ] On a verified character (60+SF, no tamper), run `/script print(RaceLocked_AmIVerified())` — expect `true`
- [ ] On a character below 60, expect `false`
- [ ] On a character 60+ who never had self-found buff, expect `false`

### 1.2 — GM roster override unlocks verification
- [ ] On a character that fails normal verification (e.g. not 60+SF), have the GM apply a roster override setting `verified = true`
- [ ] Run `/script print(RaceLocked_AmIVerified())` — expect `true` (the override should actually unlock trade/mail)
- [ ] Remove the GM override → expect `false` again

### 1.3 — Tampering suppression while self-found
> Note: tampering is ONLY detectable from an **offline edit** of the SavedVariables file.
> Gold changes made while logged in (guild bank, vendor, quests) are recorded live via
> `PLAYER_MONEY` and will match on the next login, so they never trip the flag.
- [ ] On a character with the self-found buff active, log out, edit `playerMoney` in the
      `RaceLocked.lua` SavedVariables file to a different value, then log back in
- [ ] Run `/script print(RaceLocked_GetDBValue('playerMoneyValidationFailed'))` — expect `false` or `nil` (not `true`)
- [ ] Confirm any previously set tampering flags were cleared on login (self-found exemption)

### 1.4 — GM override on clean overrides tampering
- [ ] On a character that is NOT self-found, flag it as tampered: log out, edit `playerMoney`
      in SavedVariables to a different value, log back in
- [ ] Confirm `AmIVerified()` returns `false`
- [ ] Have GM apply clean override (`gmClean = true`) via roster panel
- [ ] Confirm `AmIVerified()` now returns `true` (assuming verified is also satisfied)

### 1.5 — Rank-based self override (guild note)
- [ ] On a character that fails normal verification, have it gain a guild-note/rank override
      recognized by `RaceLocked_ShouldOverrideVerificationViaGuildNote`
- [ ] Run `/script print(RaceLocked_IsLocalVerified())` — expect `true`
- [ ] Confirm this path unlocks verification independently of a roster GM override

---

## 2. Roster Sync

### 2.1 — Self-report broadcast
- [ ] Log in with Tester A → session log should show a self-report sent within a few seconds
- [ ] On Tester B, confirm Tester A appears in the GF roster panel with correct Verified / Tampered status
- [ ] Run `/rlroster` on both characters — entries should match

### 2.2 — Sync button
- [ ] Click the Sync button in the roster panel → session log shows a new self-report sent
- [ ] Other online members should receive the update (check their session log)

### 2.2b — Manual sync prunes departed members (deferred)
- [ ] On Tester A, inject a fake entry for a non-member: `/rlroster fakedata`
- [ ] Confirm the fake names (Cheaterboy, Newbieguy, etc.) appear via `/rlroster`
- [ ] Run `/rlroster sync` (or click the Sync button) → chat shows
      "Roster cleanup queued — waiting for guild data."
- [ ] Within a few seconds, a second message should appear:
      "Removed N former member(s) from the Guild Found roster."
      (cleanup fires on the next GUILD_ROSTER_UPDATE, not inline)
- [ ] Run `/rlroster` again → the injected non-members are gone; real guild
      members (including yourself) remain
- [ ] Negative — early reload: run `/rlroster sync` immediately after `/reload`
      (before the roster finishes loading). If the live roster hasn't populated
      yet (your own name is missing or count is 0), the session log should show
      "Roster cleanup skipped — guild roster not fully loaded." and no entries
      are removed.
- [ ] Negative — count guard: if live roster members are fewer than half the
      stored entries, the session log should show "Roster cleanup skipped —
      live roster (N) is less than half of stored entries (M)." and no entries
      are removed.

### 2.3 — GM override broadcast
- [ ] As GM, change a player's Verified or Tampered status in the roster panel and click Save
- [ ] Other online members should receive the override and display updated effective status
- [ ] The target player's `AmIVerified()` should reflect the override

### 2.4 — Relay
- [ ] Have a member who missed the GM override log in and self-report
- [ ] An online member who holds the override should relay it (check session log for relay)
- [ ] The late-joining member should receive the relayed override

### 2.5 — Self-report spoofing is rejected (C3 anti-poison)
- [ ] From Tester B, broadcast a self-report naming a DIFFERENT player, e.g.
      `/run C_ChatInfo.SendAddonMessage('RaceLocked','S:Tester_A_Name,1,1','GUILD')`
- [ ] On Tester A's client, confirm the session log shows a "name/sender mismatch" warning
- [ ] Confirm Tester A's roster entry for that name is **not** changed (run `/rlroster`)
- [ ] Confirm a legitimate self-report (where payload name == sender) is still accepted

---

## 3. Trade Restrictions

### 3.1 — Trade with roster-eligible guildmate
- [ ] Both Tester A and Tester B are verified and in the GF roster
- [ ] Open trade between them → trade should be **allowed immediately** with message "X is roster eligible."
- [ ] No TV handshake overlay should appear (instant resolution from roster)

### 3.2 — Trade with roster-ineligible guildmate
- [ ] One tester has a roster entry where eligible = false (e.g. not verified or tampered)
- [ ] Open trade → trade should be **blocked immediately** with "partner not eligible"
- [ ] No TV handshake wait

### 3.3 — Trade with guildmate not in GF roster
- [ ] Remove one tester's roster entry (or use a newly joined member with no entry)
- [ ] Open trade → should show TV handshake overlay ("Starting verification...")
- [ ] If partner responds with TV:1 → trade allowed; roster entry seeded
- [ ] If partner doesn't respond (timeout) → trade blocked

### 3.4 — Trade with non-guildmate
- [ ] Open trade with Tester C (not in guild) → immediate block: "not in my Guild"

### 3.5 — Trade while not verified
- [ ] On a character where `AmIVerified()` = false, open trade with anyone
- [ ] Trade restrictions should not activate (GF rules only apply when verified)

### 3.6 — Auction House
- [ ] As a verified GF member, open the Auction House → should close immediately with "Auction House blocked"
- [ ] As an unverified member → AH should open normally

### 3.7 — Trade partner name not ready on open (L8)
- [ ] Initiate trades repeatedly (and/or in high-latency conditions) so the partner name
      is occasionally not yet available when `TRADE_SHOW` fires
- [ ] Confirm verification still runs (it retries on `TRADE_UPDATE`) and the trade is never
      allowed to complete unverified
- [ ] Confirm verification only starts once per trade window (no duplicate "Starting verification..." spam)

---

## 4. Inbound Mail Restrictions

### 4.1 — Clean mailbox
- [ ] Open mailbox with no mail (or only guild member mail from eligible senders)
- [ ] Overlay should flash briefly ("Checking mailbox...") then disappear automatically
- [ ] Chat should print "Checking mail contents." then "Mail contents verified."

### 4.2 — Mail from non-guild member
- [ ] Have Tester C (outside guild) send mail to Tester A
- [ ] Open mailbox → overlay should show the mail flagged for return
- [ ] Click Proceed → mail is returned, overlay clears
- [ ] Chat should print "Checking mail contents." then "Mail contents need resolution."

### 4.3 — AH mail
- [ ] If any AH mail exists in inbox → overlay should flag it for return
- [ ] After proceeding, AH mail should be returned/deleted

### 4.4 — Mail from eligible guildmate
- [ ] Have Tester B (verified, eligible in roster) send mail to Tester A
- [ ] Open mailbox → mail should be allowed, overlay auto-clears

### 4.5 — Mail from ineligible guildmate
- [ ] Have a guildmate with an ineligible roster entry (not verified or tampered) send mail
- [ ] Open mailbox → that mail should be flagged for return

### 4.6 — Mail from unknown guildmate (TV probe)
- [ ] Have a guildmate with NO GF roster entry send mail
- [ ] Open mailbox → the overlay subtitle shows "Verifying senders — please wait..." and the
      sender's row is listed (no Proceed/Cancel buttons while pending). Note: the literal text
      "Awaiting verification from X" only appears in the dev chat report, not the overlay row.
- [ ] Chat should print "Checking mail contents." then "Verifying mail senders..."
- [ ] If the sender is online and responds to TV probe → mail resolves (allowed, or flagged for
      return if they reply "not verified")
- [ ] If sender is offline or doesn't respond (5s timeout) → mail flagged for return ("no verification reply")

### 4.7 — GM/NPC mail
- [ ] Have GM or NPC/system mail in inbox → should always be allowed through

### 4.8 — Multiple mail items requiring return
- [ ] Have 3+ pieces of mail that need returning
- [ ] Click Proceed → each should be returned sequentially (0.6s delay between)
- [ ] The execution phase should show "Returning mail — please wait..."
- [ ] After all returns complete, the overlay should clear

### 4.9 — New mail during approved session
- [ ] Open mailbox and get approved (clean inbox)
- [ ] While mailbox is open, receive new mail from a non-guild member
- [ ] The overlay should reappear with the new mail flagged

### 4.10 — Overlay cannot be bypassed
- [ ] While the overlay is showing, try to click on mail items behind it → should be blocked
- [ ] The overlay should use DIALOG strata and EnableMouse(true)

### 4.11 — Cancel button
- [ ] While the overlay is showing return actions, click Cancel → mailbox should close entirely

### 4.12 — Mixed inbox: returns + pending together (C6 no soft-lock)
- [ ] Set up an inbox with BOTH return-required mail (non-guild or ineligible sender) AND
      pending mail (guildmate with no roster entry, sender offline so the probe won't resolve)
- [ ] Click Proceed → the return items are returned sequentially
- [ ] After returns finish, the overlay must NOT stay stuck on "Returning mail — please wait..."
      It should drop back to the pending state ("Verifying senders — please wait...") and keep probing
- [ ] When the pending probe times out (5s), that mail becomes a return and the overlay shows it for return

---

## 5. Outbound Mail Restrictions

### 5.1 — Send mail to non-guild member
- [ ] Try to send mail to Tester C (not in guild) → blocked with "not in guild" message

### 5.2 — Send mail to eligible guildmate
- [ ] Try to send mail to a roster-eligible guildmate → should succeed

### 5.3 — Send mail to ineligible guildmate
- [ ] Try to send mail to roster-ineligible guildmate → blocked with "not eligible"

### 5.4 — Send mail to unknown guildmate (probe)
- [ ] Try to send mail to a guildmate with no roster entry
- [ ] First attempt → blocked with "Verification probe sent to X. Try again in a moment."
- [ ] If recipient responds to TV probe → chat says "X responded to verification — try sending again."
      (the wording is intentionally neutral; the reply does not guarantee eligibility)
- [ ] Retry send → succeeds if the recipient replied verified; if they replied "not verified",
      the retry is blocked with "not eligible"
- [ ] If recipient doesn't respond (5s) → next attempt says "no verification reply"

### 5.5 — Send mail while not verified
- [ ] On a character where `AmIVerified()` = false → send button should work normally (no GF restrictions)

---

## 6. Verification Display (Main Menu)

### 6.1 — Checklist display
- [ ] Open the Guild Verification tab → should show 4 checks in order:
  1. In Guild
  2. 60+ Self Found
  3. Tampering
  4. GM Override
- [ ] Each check should show green (pass) or red (fail) with appropriate text
- [ ] GM Override row: blue when active, grey when inactive

### 6.2 — Overall status
- [ ] If all checks pass → "Trading unlocked" or equivalent positive header
- [ ] If any fail → appropriate locked state shown

### 6.3 — Roster table
- [ ] GF roster members are listed below the checklist
- [ ] Each member shows Verified, Tampered, and Eligible columns
- [ ] Eligible shows green "Eligible" or red "Ineligible" with GM override asterisk
- [ ] Sort: eligible members first, then alphabetical

### 6.4 — GM editing
- [ ] As GM, click Edit on a roster row → dropdown selectors appear
- [ ] Change Verified/Tampered → preview updates in real-time
- [ ] Click Save → broadcasts the override to other members
- [ ] Non-GM players should NOT see edit buttons

### 6.5 — Session log
- [ ] Toggle to session log view → should show sent/received sync messages
- [ ] Hover over log entries → should show raw wire message (if enabled)

---

## 7. Edge Cases

### 7.1 — Relog with pending mail
- [ ] Have non-compliant mail in inbox, log out, log back in
- [ ] Open mailbox → overlay should appear fresh and re-scan

### 7.2 — Multiple rapid mailbox opens/closes
- [ ] Open and close mailbox quickly several times
- [ ] The session should reset cleanly each time, no stale overlays

### 7.3 — Addon loaded without being in GF guild
- [ ] On a character not in "FOR GNOMEREGAN" → all GF restrictions should be inactive
- [ ] Trade, mail, AH should work normally

### 7.4 — Race condition: fast trade accept
- [ ] During TV handshake (before verification resolves), try to quickly add items and accept trade
- [ ] The verification overlay should block interaction; if TV fails, trade should be cancelled

### 7.5 — GM override on self + trade
- [ ] Apply GM override on self to set verified=true
- [ ] Open trade with a roster-eligible partner → should succeed
- [ ] Remove GM override → trade should fail again

---

## 8. Dev Commands

These are diagnostic commands for debugging during testing:

| Command | What it does |
|---------|-------------|
| `/script RaceLocked_PrintMailStateReport()` | Print full inbox state analysis to chat |
| `/script print(RaceLocked_AmIVerified())` | Check if you are verified |
| `/script print(RaceLocked_IsLocalVerified())` | Check verified component only |
| `/script print(RaceLocked_IsLocalClean())` | Check clean component only |
| `/rlroster` | Print all GF roster entries to chat |
| `/rlroster sync` | Force a self-report broadcast |
| `/rlroster reset` | Wipe local roster data (then requires `/reload` to re-initialize) |
| `/script RaceLocked_DevToggleGM()` | Toggle dev GM override (for testing GM features) |

---

## Sign-Off

| Tester | Date | Sections Tested | Notes |
|--------|------|----------------|-------|
| | | | |
| | | | |
