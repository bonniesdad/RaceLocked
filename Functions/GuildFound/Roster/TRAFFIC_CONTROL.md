# Guild Found Roster — Traffic Control

This document describes how the addon limits traffic on the guild addon-message
channel (`RLGFRoster`). The goal is to send only what is needed, when it is
needed, and no more.

Implementation lives primarily in `Functions/GuildFound/Roster/Index.lua` (send
/receive logic) and `Display/MainMenu/GuildVerification/View.lua` (GM edit UI).

---

## What gets sent (and when)

The roster uses three small message shapes. Each is sent **only in response to
a specific event**, never on a timer.

| Kind | Trigger | Typical frequency |
|------|---------|-------------------|
| **Self-report (`S:`)** | Player logs in (once per session) or clicks **Sync** | 1× per session + manual |
| **GM override (`G:`)** | Guild master clicks **Save** on a row | 1× per saved edit |
| **Peer relay (`O:`)** | A member's self-report arrives without an override we already hold | Rare; dampened (see below) |

There is **no periodic heartbeat**, no zoning/instance re-broadcast, and no
background polling of the guild channel.

---

## Outgoing limits

### 1. Login broadcast — once per session

`PLAYER_ENTERING_WORLD` fires on every loading screen (zones, instances, etc.),
not only on initial login. A session flag (`hasAnnouncedThisSession`) ensures
the login self-report and the one chat confirmation line run **at most once**
per game session.

Guild name is often **not readable yet** on the first `PLAYER_ENTERING_WORLD`
(`IsInGuild()` can be true while `GetGuildInfo('player')` is still nil). The
addon retries the announce on **`ADDON_LOADED`** (after `/reload`) and
**`GUILD_ROSTER_UPDATE`** (when the roster finishes loading), and nudges
`GuildRoster()` if membership is known but the name is not.

### 2. Self-report throttle (2 seconds)

`broadcastSelfReport()` refuses to send if another self-report went out within
the last **2 seconds**. Login and the manual Sync button share this path, so
accidental double-fires (e.g. login immediately followed by Sync) collapse to
one message.

### 3. Level gate

Characters below level **60** never send a self-report on the guild channel.
The login confirmation line still appears in chat and the Sync Log; an info
line notes that the self-report was skipped.

### 4. Sync button — once per window open

The roster **Sync** control disables after the first use and stays disabled
until the Race Locked window is closed and reopened. That prevents repeated
manual re-broadcasts during a single UI session.

### 5. GM overrides — Save only, one message per edit

While a guild master edits a row:

- Verified / Tampered dropdown changes update an **in-memory buffer only**.
- Nothing is written to saved data and **nothing is sent** until **Save** is
  clicked.
- Switching to another row or closing the window **discards** unsaved edits.
- **Save** persists the buffer and sends **exactly one** `G:` message with
  both fields combined (changing Verified and Tampered still produces one
  broadcast, not two).
- If Save is clicked with no actual change from when Edit was opened, **no
  message is sent**.

### 6. Compact payloads

Messages use a single registered prefix and minimal comma-separated fields.
When a player has a GM override, the override badge is **piggybacked on their
own `S:` self-report** so peers do not need a separate relay for that player
in the common case.

---

## Relay limits (peer `O:` messages)

Relays exist so a member who logs in late can learn about an override that
predates them. They are the easiest source of duplicate traffic, so they are
heavily constrained.

### 7. Relay only when necessary

An `O:` relay is queued **only when all of the following are true**:

- We receive someone else's `S:` self-report.
- That report does **not** include an override badge.
- We **already hold** a GM override for that player locally.

If the self-report already carries the badge, or we have no override stored,
**no relay is sent**.

### 8. Relay dampening (delay + deduplication)

When a relay is needed, it is **not sent immediately**. It enters a pending
queue with a randomized delay of **1.5–3.5 seconds**. During that window:

- If the same player later sends a self-report **with** an override badge, our
  pending relay is **cancelled**.
- If another member's **current** `O:` relay for that player is accepted, our
  pending relay is **cancelled**.

This prevents a burst where every online guildmate relays the same override at
once after someone logs in.

### 9. One relay per player per flush

Pending relays are keyed by player name. Multiple triggers for the same player
coalesce into a single send when the timer fires.

---

## Incoming guards (fewer bad messages → fewer reactive sends)

These rules reduce useless processing and avoid follow-up traffic caused by
stale or invalid data.

### 10. Ignore own messages

Incoming addon messages from the local player are dropped immediately. We
already applied our own send locally; echo handling would be redundant.

### 11. Guild master check on `G:` overrides

`G:` messages from senders who are not the guild master are rejected. No store
update, no relay side-effects.

### 12. Timestamp monotonicity on overrides

`RaceLocked_Roster_SetGMOverride` accepts an override **only if its timestamp
is ≥ the stored timestamp**. Stale badges and relays are ignored. That stops
old copies of an override from churning the roster or cancelling newer pending
relays incorrectly.

### 13. Stale peer relays do not cancel pending sends

When an `O:` relay is rejected as stale, we **keep** our own pending relay so
a newer override we hold can still propagate.

---

## Local-side efficiency (not guild channel, but related)

These do not reduce addon messages directly but avoid unnecessary work when
traffic arrives.

### 14. Session log instead of chat spam

Routine sent/received traffic is recorded in the in-panel **Sync Log** only.
Chat gets a single login confirmation line per session (plus `/rlroster` debug
output if used).

### 15. Sync Log UI refresh debounce (0.2 s)

While the log view is open, a burst of incoming messages triggers **at most one**
tab relayout every 200 ms instead of one full rebuild per message.

### 16. Session log cap (200 entries)

The in-memory log trims oldest entries beyond **200** lines so long sessions
do not grow without bound.

### 17. Roster view reset on window close

Closing the Race Locked window resets the panel to the **roster** table (not the
Sync Log) the next time it is opened. This is UI state only and does not affect
saved roster data or session log contents until reload.

---

## Normal traffic profile

For a typical guild member during a play session:

1. **One** `S:` self-report on login.
2. **Zero** messages while zoning, questing, or in combat.
3. **Zero** messages unless they click Sync (once per window open) or receive
   traffic from others.

For a guild master:

1. Same as a member, plus **one** `G:` per player row they explicitly **Save**.
2. **Zero** messages while clicking through dropdown options before Save.

For the guild as a whole after a GM sets one override on an offline player:

1. **One** `G:` from the GM on Save.
2. **At most a few** `O:` relays (not one per online member) when that player
   next logs in and self-reports without the badge — usually reduced to zero if
   the badge arrives via another path during the dampening window.

---

## Intentionally not implemented

- No relay queue that drains on a fixed interval for all stored overrides.
- No re-broadcast on `PLAYER_ENTERING_WORLD` after the first successful login
  announcement.
- No addon-message traffic for non-guild members or characters below 60.
