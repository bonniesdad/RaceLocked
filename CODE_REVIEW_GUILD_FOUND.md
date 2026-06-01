# Code Review — Guild Found Roster Branch

Branch: `feat/guild-found-roster` (commits `87c1b2b` through HEAD)
Reviewer: Automated review prior to PR submission

---

## Summary

This branch adds ~3,300 lines across 24 files implementing the Guild Found roster sync system, consent-first mail restriction, trade roster checks, and GM override functionality. The code is generally well-structured with clear file boundaries and consistent naming. Below are the issues that should be addressed before merge, organized by severity.

---

## CRITICAL — Must fix before merge

### C1. Stale duplicate files on disk (confuse contributors, risk loading wrong code)

The following files exist on disk but are NOT in `RaceLocked.toc`. They are old copies from before files were moved to `MailRestriction/`. They will confuse any reviewer or contributor who searches the repo.

- `Functions/GuildFound/TradeRestriction/MailSendGuard.lua` (duplicate of `MailRestriction/MailSendGuard.lua`)
- `Functions/GuildFound/TradeRestriction/Utils/ClassifyInboxMail.lua` (duplicate of `MailRestriction/Utils/ClassifyInboxMail.lua`)
- `Functions/GuildFound/TradeRestriction/Utils/CancelMailWithMessage.lua` (duplicate of deleted `MailRestriction/Utils/CancelMailWithMessage.lua`)
- `Functions/GuildFound/Verification/MailAccessPlan.lua`
- `Functions/GuildFound/Verification/MailAccessSession.lua`
- `Functions/GuildFound/Verification/MailStateReport.lua`
- `Functions/GuildFound/Verification/MailVerificationOverlay.lua`

**Action:** Delete all 7 files.

### C2. `SetSelfReport` nil-skip for `clean` can leave stale `true` on existing entries

In `RosterStore.lua`, `SetSelfReport` was changed to skip updating `verified` or `clean` when the passed value is `nil`. This was done to support TV seeding where we pass `clean = nil` for unverified players.

However, the normal self-report path in `Index.lua` (`broadcastSelfReport` and `handleSelfReport`) always provides both fields from the wire message. If a player's `clean` status changes from `true` to `false` (they got tampered), the `wireToBool('0')` returns `false` (not `nil`), so it works correctly.

But if a wire message arrives with `clean` as `-` (nil), it would be silently ignored and the old `true` value would persist. This is currently safe because `broadcastSelfReport` always sends `0` or `1`, never `-`, for the clean field. But it's fragile.

**Action:** Add a comment in `SetSelfReport` documenting that nil means "do not update" (not "clear") and that callers must pass `false` explicitly to clear a field. OR add a dedicated `SeedFromProbe` function that explicitly handles the TV seeding case.

### C3. `S:` self-reports do not bind payload name to sender — roster poisoning

In `Roster/Index.lua` `handleSelfReport`, the player name comes from `fields[1]` (the wire payload), not the `sender` parameter. Any guild member can broadcast `S:VictimName,1,1` and overwrite the victim's `verified`/`clean` status on every client's roster. Since trade and mail now trust roster entries when they exist (skipping live TV), this enables false-allow for an ineligible player.

Similarly, `O:` relay messages have no sender authority check — any member can broadcast fake GM overrides if the timestamp wins monotonicity.

**Action:** In `handleSelfReport`, require `fields[1] == Ambiguate(sender, 'short')` and reject mismatches. For `O:`, consider requiring that the receiving client already holds a `G:` with a matching timestamp before accepting a relay.

### C4. Trade allows bypassing roster during TV handshake response

In `CanPerformTradeWithPlayer.lua`, if a roster entry exists, trade resolves instantly (eligible = allow, ineligible = block). If no entry exists, it falls through to `BeginTradeVerification` which uses the live TV whisper.

**Exploit scenario:** A malicious addon could reply `TV:1` (verified) to a probe even if the player is not actually verified. This would:
1. Allow the trade (via the TV whisper path)
2. Seed a roster entry with `verified = true, clean = true`
3. All future trades and mail would be allowed without re-checking

**Mitigation considerations:** The TV protocol trusts the remote client. This is inherent to any client-side addon — you cannot prevent a malicious addon from lying. Document this as a known limitation. The roster sync protocol (guild-wide `S:` broadcasts) will eventually correct the entry, but there's a window.

**Action:** Add a comment in `CanPerformTradeWithPlayer.lua` and `TradeVerificationSession.lua` documenting that TV is trust-based and roster sync will self-correct over time. Consider whether roster entries seeded by TV should be marked with a lower trust level (e.g. `source = 'tv'` vs `source = 'sync'`).

### C5. `PROBE_TIMEOUT` is defined in 3 separate files

The 5-second probe timeout is defined as a local in:
- `MailAccessPlan.lua` (line 6)
- `MailAccessSession.lua` (line 39)
- `MailSendGuard.lua` (line 5)

If someone changes one but not the others, behavior will be inconsistent.

**Action:** Extract to a shared constant, or at minimum add comments cross-referencing the other definitions.

---

### C6. Executing-phase stall when returns finish but pending mail remains

In `MailAccessSession.lua`, if the user clicks Proceed when the plan has both `requiresReturn` and `requiresPending` items, `executeStep` processes all returns. Once returns are done, it hits:

```lua
if not plan.requiresReturn then
  if not plan.requiresPending then
    finishExecution()
  end
  -- ...
  return  -- exits without scheduling next timer
end
```

Phase stays `'executing'`, no further timer is scheduled, and `RefreshMailAccessPlan` is blocked during execution (line 116). The overlay shows "Returning mail -- please wait..." indefinitely until the player closes the mailbox. Not a security bypass (mail stays blocked), but a UX soft-lock.

**Action:** When returns are complete but pending items remain, transition phase back to `'ready'` and refresh the overlay to show the pending state.

---

## MEDIUM — Should fix before merge

### M1. `MailVerificationOverlay.lua` is 433 lines with mixed concerns

This file handles:
- Frame creation and layout (ensureOverlay, ~100 lines)
- Rendering logic (renderPlanDisplay, showLoadingState, ~100 lines)
- Event handling (MAIL_SHOW, MAIL_CLOSED, MAIL_INBOX_UPDATE, PLAYER_LOGIN, ~50 lines)
- Session orchestration (refreshMailOverlay, ~40 lines)

Per the project rules, `View.lua` should handle frames/layout/handlers and complex logic should be extracted. The event handling and session orchestration could be a separate `Index.lua` file in the `MailRestriction/` folder.

**Action:** Consider extracting the event handler block (lines 379-432) into `MailRestriction/Index.lua`.

### M2. `MailAccessPlan.lua` comment is outdated

Line 250-251:
```
--- The next step is driven by MAIL_INBOX_UPDATE firing after the remove,
--- so indices are always fresh and never drift.
```

This comment describes the old event-driven approach. The actual execution model is now timer-driven via `executeStep()` in `MailAccessSession.lua`.

**Action:** Update the comment to reflect the timer-driven model.

### M3. `isRecipientAllowed` returns `true` when `guildName` is nil

In `MailSendGuard.lua` line 42:
```lua
if not guildName then return true end
```

If the guild name can't be retrieved (API unavailable, loading screen, etc.), the recipient is silently allowed. This should default to blocked (consistent with "default to not allowed" policy).

**Action:** Change to `return false, 'Cannot verify recipient — guild data unavailable'`.

### M4. `MailAccessPlan.lua` line 198 still has a hardcoded `8` limit for chat lines

Lines 198-204 limit chat output to 8 items. This was the old behavior before the scrollable UI was added. The scrollable list shows all items, but the `plan.lines` table (used by `MailStateReport`) still truncates. This is fine for the dev report, but the comment and constant should be documented.

**Action:** Add a constant or comment explaining this is for the dev chat report, not the UI.

### M5. `GuildVerification/View.lua` is 1,190+ lines

This is a large file. The project rules say to extract large/self-contained blocks. The roster table rendering (lines ~850-1190) is a clear candidate for extraction into a sibling folder.

**Action:** Consider extracting the roster table section into `GuildVerification/RosterTable/View.lua` in a future pass. Not blocking for this PR.

### M6. `getVerificationChecks()` reads DB values directly instead of using `IsLocalVerified` / `IsLocalClean`

In `View.lua` line 60-61, the display reads `playerMoneyValidationFailed` and `hasBeenMaxLevelAndSelfFound` directly from the DB. Now that `IsLocalVerified()` and `IsLocalClean()` exist, the display diverges from the enforcement logic if those helpers are updated.

**Action:** Consider having the display derive its state from the same helpers. The display needs more granularity (showing each check separately), so this may require the helpers to expose individual check results, or the display can continue reading DB directly since it's intentionally showing the raw state of each condition.

### M7. `RaceLocked_EvaluateMailPartner` in `MailStateReport.lua` is unused dead code

The function comment says "Kept for roster preview in future outbound checks" but it's never called. It duplicates logic that `MailSendGuard.isRecipientAllowed` already handles.

**Action:** Remove or add a `-- TODO: wire into dev UI` comment to clarify intent.

### M8. Overlay event handler missing nil guards on global functions

In `MailVerificationOverlay.lua` line 391, the event handler calls `RaceLocked_IsInGuildFoundGuild()` and `RaceLocked_AmIVerified()` directly without the `and` guards used everywhere else (`RaceLocked_IsInGuildFoundGuild and RaceLocked_IsInGuildFoundGuild()`). If TOC load order changes or either file fails to load, this will error on every mail event.

**Action:** Add nil guards consistent with the hook on lines 373-374.

### M9. `ROSTER_LOG_RAW_TOOLTIP = true` exposes wire protocol in production

In `View.lua`, `ROSTER_LOG_RAW_TOOLTIP` is set to `true` with a comment "set to false for production builds". This shows raw addon messages like `S:PlayerName,1,1,0,1,12345` in tooltips when hovering session log entries. Should be `false` before release.

**Action:** Set to `false` or gate behind a dev flag.

### M10. `HandleTradeVerificationAddonMessage.lua` auto-replies to non-guildmates

The auto-reply block (lines 24-28) checks `RaceLocked_IsInGuildFoundGuild()` (whether *you* are in GF) but does not check whether the *sender* is in your guild. Any player who sends you the right addon whisper can probe your verification status and trigger roster seeding side effects.

**Action:** Add `RaceLocked_IsPlayerInGuildRoster(sender)` check before auto-replying.

### M11. `canReply` as player mail discriminator may misclassify

In `ClassifyInboxMail.lua`, player mail requires `canReply` to be truthy. If WoW ever delivers player-originated mail with `canReply = false` (COD edge cases, system-wrapped player mail), it would be classified as NPC and allowed through without restriction.

**Action:** Document the assumption and consider additional sender-name heuristics as a safety net.

### M12. Missing `RaceLocked_PrintRestrictionMessage` in trade roster-eligible path

In `CanPerformTradeWithPlayer.lua` line 21, when trade is blocked due to partner not being eligible, the `onComplete(false, message)` callback is called — but the actual cancellation and chat message happen in the caller (`TradeRestriction.lua`). Verify that `CancelTradeWithMessage` prints the message to chat.

**Action:** Trace the message flow to confirm the user sees feedback when trade is blocked by roster ineligibility.

---

## LOW — Nice to fix, not blocking

### L1. Naming: `RaceLocked_IsLocalVerified` / `RaceLocked_IsLocalClean` live in `AmIVerified.lua`

The filename doesn't hint that these two helpers exist there. A reviewer looking for "IsLocalVerified" might not think to check `AmIVerified.lua`.

**Action:** Consider renaming the file to `LocalVerificationStatus.lua` or adding the helpers to a separate `Utils/` file.

### L2. `RaceLocked_DescribeInboxMailEnforcement` in `ClassifyInboxMail.lua` is unused

This function is defined and exported but never called.

**Action:** Remove or mark as dev-only.

### L3. `devForceGM` toggle in `IsGuildMaster.lua` is a dev-only feature shipped in production

The `/script RaceLocked_DevToggleGM()` command lets any user pretend to be GM. This is gated by the fact that `SetGMOverride` verifies `AmIGuildMaster()` before broadcasting, but a user could still see the GM edit UI locally.

**Action:** Consider gating `devForceGM` behind a debug flag or removing it for release builds.

### L4. `RaceLocked_GetAllEntries` returns the live DB reference

In `RosterStore.lua`, `GetAllEntries` returns the actual DB table. Any consumer that modifies it (e.g. during iteration) could corrupt the store.

**Action:** Consider returning a shallow copy, or document that the return value must not be modified.

### L5. `isAuctionHouseMail` calls `GetInboxInvoiceInfo` once, then the caller calls it again

In `ClassifyInboxMail.lua`, `isAuctionHouseMail` calls `GetInboxInvoiceInfo` to check for AH mail, then the main function calls it again to get the invoice type. Minor double-call.

**Action:** Refactor to call once and pass the result.

### L6. Session log `entries` is module-local and survives `/reload` since it's in memory

The session log is correctly ephemeral (resets on reload). Just confirming: `TRAFFIC_CONTROL.md` and `USER_FLOWS.md` are documentation files included in the repo — verify they don't need TOC entries (they don't, `.md` files aren't loaded by WoW).

### L7. `GoldGainedTracker.lua` has no file header explaining the tamper model

The file lacks a comment explaining why tamper detection happens only on login, why self-found buff clears flags, or how `playerMoneyValidationFailed` connects to `IsLocalClean()` and the verification display. A reviewer unfamiliar with the codebase would struggle to understand the design intent.

**Action:** Add a brief header comment.

### L8. `GetUnitName('npc', true)` may return nil on TRADE_SHOW

In `TradeRestriction.lua`, if the trade target name isn't available yet when `TRADE_SHOW` fires, the handler returns early and trade proceeds with no verification. Consider deferring with a short timer or also checking on `TRADE_UPDATE`.

### L9. `GuildVerification/Utils/Constants.lua` is stale

This file defines `RaceLocked_GuildVerification.ROW_HEIGHT = 20`, `PANEL_PAD = 3`, etc., but `View.lua` defines its own separate constants (`ROSTER_ROW_HEIGHT = 28`, `LIST_LEFT_OFFSET = 10`). Two divergent constant sources will confuse reviewers. Either consolidate or remove the unused file.

---

## Code Readability Assessment

### Well done
- File naming is clear and matches function names
- Each file has a single responsibility (with the exception of View.lua and MailVerificationOverlay.lua)
- Doc comments on `RosterStore.lua` functions are excellent — parameter types, return types, purpose
- Wire protocol encoding/decoding in `Index.lua` is well-documented
- The consent-first mail flow is logically clear: scan → plan → display → approve → execute
- Timer-driven execution loop in `MailAccessSession.lua` has clear session identity checks

### Areas for improvement
- Some functions use `and ... or` patterns that could be confusing to reviewers unfamiliar with Lua idioms
- Event handler in `MailVerificationOverlay.lua` lines 385-432 has 3 levels of nesting that could be simplified
- The word "verification" is overloaded: sometimes means "trade verification handshake", sometimes "Guild Found roster eligibility", sometimes "self-found verification". Consider more specific terminology in comments.

---

## Files Changed Summary

| File | Lines | Purpose | Review Status |
|------|-------|---------|--------------|
| `Roster/Utils/RosterStore.lua` | 136 | Persisted roster store | Reviewed |
| `Roster/Utils/IsRosterEligible.lua` | 9 | Eligibility helper | Reviewed |
| `Roster/Utils/PlayerIdentity.lua` | 24 | Guild/player name helpers | Reviewed |
| `Roster/Utils/IsGuildMaster.lua` | 46 | GM authority check | Reviewed |
| `Roster/Utils/SessionLog.lua` | 35 | Ephemeral traffic log | Reviewed |
| `Roster/Index.lua` | 496 | Wire protocol + event handling | Reviewed |
| `MailRestriction/Utils/ClassifyInboxMail.lua` | 89 | Mail sender classification | Reviewed |
| `MailRestriction/MailAccessPlan.lua` | 268 | Inbox scan + action planning | Reviewed |
| `MailRestriction/MailAccessSession.lua` | 167 | Session state + execution | Reviewed |
| `MailRestriction/MailSendGuard.lua` | 108 | Outbound mail hook | Reviewed |
| `MailRestriction/MailStateReport.lua` | 102 | Dev diagnostics | Reviewed |
| `MailRestriction/MailVerificationOverlay.lua` | 433 | Mail consent UI + events | Reviewed |
| `Verification/AmIVerified.lua` | 33 | Self-verification gate | Reviewed |
| `Verification/CanPerformTradeWithPlayer.lua` | 31 | Trade eligibility check | Reviewed |
| `Verification/TradeVerificationSession.lua` | 131 | TV handshake + roster seeding | Reviewed |
| `Verification/HandleTradeVerificationAddonMessage.lua` | 30 | Addon message handler | Reviewed |
| `Verification/GoldGainedTracker.lua` | 37 | Tamper detection | Reviewed |
| `TradeRestriction/TradeRestriction.lua` | 22 | Trade/AH event entry | Reviewed |
| `GuildVerification/Utils/RosterRowData.lua` | 49 | Roster UI data builder | Reviewed |
| `GuildVerification/View.lua` | 1190+ | Full verification UI | Reviewed |
| `RaceLocked.toc` | 107 | Addon manifest | Reviewed |
