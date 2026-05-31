# Guild Found Roster — User Flows

This document describes the **user-facing experience** of the Guild Found
roster feature: who interacts with it, what they see, and what they can do.

It intentionally stays at the experience level and does not document internal
mechanics (status calculation, message formats, or anti-tampering logic).

---

## Actors

- **Guild member** — any character in a Guild Found guild running the addon.
- **Guild master (GM)** — the guild's rank-0 leader. The GM gets extra controls
  that no other member has.

---

## Where it lives

The roster appears in the **Guild Verification** tab of the Race Locked window.
Below the player's own verification summary is a panel titled
**"Guild Found Roster"** listing guildmates and their status.

Each row shows:

- **Name** — the guildmate's character name (the local player is highlighted).
- **Verified** — whether that member meets the verification requirement.
- **Tampered** — whether that member's data shows signs of tampering.
- **Status** — the combined result: **Eligible** or **Ineligible**.

A `*` next to a value indicates the GM has manually set that value.

---

## Flow 1 — A member views the roster

1. The member opens the Race Locked window and selects **Guild Verification**.
2. The panel lists guildmates who have previously shared their status with the
   guild, sorted with eligible members first, then alphabetically.
3. The member can read each guildmate's status at a glance. No editing controls
   are shown to non-GM members.

## Flow 2 — Status stays in sync

1. When a member logs in, the addon automatically shares the member's own
   current status with the guild (characters level 60 and above).
2. A one-line **Login** confirmation also appears in chat so the member can
   see the addon initialized correctly.
3. As guildmates come online and share their status, the roster fills in.
4. A member can press the **Sync** button (circular refresh icon, bottom-right
   of the panel) to re-share their own status and refresh the view on demand.
5. After a successful sync the button shows a confirmation state until the
   window is closed and reopened.

## Flow 3 — The guild master reviews and overrides

1. When the **guild master** opens the roster, each row gains an **Edit** link
   (in the column to the right of the name).
2. Clicking **Edit** turns the Verified and Tampered cells into selectors with
   **Yes / No / Reset** choices (only the choices that change the current value
   are offered).
   - **Yes / No** set a pending manual decision for that member in the UI.
   - **Reset** clears the pending decision for that field so it would revert to
     the member's self-reported value once saved.
3. Changes are **previewed in the row** but are not saved or shared until the
   GM clicks **Save** on that row.
4. Clicking **Save** writes the override and shares **one** combined update
   with the guild. If nothing changed since **Edit** was opened, **Save** sends
   nothing.
5. Opening **Edit** on a different row, or closing the Race Locked window,
   **discards** any unsaved edits on the row being left.
6. Members who come online later still receive decisions made before they
   logged in.
7. Manual decisions are marked with `*` and explained by the
   **"\* GM override"** note at the bottom of the panel.

> Only the actual guild master can make these decisions. Edit controls are not
> offered to other members, and decisions that do not come from the guild
> master are not accepted.

## Flow 4 — Viewing recent activity (Sync Log)

1. The panel header has a **Log** link. Clicking it swaps the roster table for a
   **Sync Log** showing this session's sync activity.
2. Each log line shows a timestamp, a category (sent / received / info), and a
   short description in plain language (e.g. **Verified, Not Tampered**).
3. Hovering a log line shows the raw wire message (when enabled for the build).
4. The log is **session-only** — it is not saved and clears on UI reload.
5. Clicking **Roster** returns to the roster table.
6. Closing and reopening the Race Locked window always opens back on the
   **roster** view, not the log.

---

## Notes

- The roster is shared across the account, so alts in the same guild see the
  same information.
- The table lists players who have shared status with the guild (via addon
  sync); it is not a live scan of the full guild roster.
- Roster entries persist in saved data across sessions; there is no automatic
  removal when someone leaves the guild.
- This feature surfaces information only; it does not by itself change what a
  member can or cannot do in game.
