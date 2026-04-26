# CheckMark

A WoW Retail addon (Interface 120005) that shows a popup for 2-5 player groups — party, dungeon, delve, or mythic — so you can assign raid target icons before the pull.

## Features

- Auto-shows when your group forms or changes, and when entering a dungeon or delve
- **Role-based mode** — Tank, Healer, DPS 1/2/3 slots with defaults (Skull for tank, Diamond for healer)
- **Name-based mode** — per-player assignments remembered from previous sessions
- Saved per-group memory: the same group of friends gets the same defaults next time
- Secure **Apply** and **Clear** buttons — marking happens via a user click, respecting WoW's protected API
- Clean, dark UI inspired by DandersFrames
- Global `SavedVariables` — shared across all characters on the account

## Usage

- `/checkmark` — toggle the popup
- `/cm` — same shortcut
- `/checkmark options` — open the options panel
- `/checkmark reset` — wipe all saved settings and reload

The **Apply** button builds a macro targeting each assigned member and marking them.  
The **Clear** button removes all marks.  
The **Save** button stores the current assignments as name-based defaults for each player and remembers the group composition for next time.

## Installation

Drop the `CheckMark` folder into:

```
World of Warcraft\_retail_\Interface\AddOns\
```

## Notes

- Raids (6+ players) are intentionally excluded
- Marking is protected in WoW retail — the addon cannot mark silently; you must click Apply
- Works with cross-realm party members
