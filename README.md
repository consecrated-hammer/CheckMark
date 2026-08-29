# CheckMark

**A compact pre-pull marker grid for small WoW parties.** It uses Salve-style
cells: configure role markers in Settings, then click each planned person's
small cell before the pull.

## Why CheckMark exists

Raid target markers still need a protected player action. CheckMark makes the
pre-pull setup quick without pretending it can mark a party automatically.
Each cell prepares one safe action using the party's stable unit token, not
player-name macros.

## What it does

- Works with two-to-five-player parties, including dungeons and delves.
- Uses role-template defaults such as Tank = Skull and Healer = Diamond.
- Shows the configured plan only. CheckMark deliberately does not infer whether
  another player has added, removed, or changed a current marker.
- Lets you choose Star, Circle, Diamond, Triangle, Moon, Square, Cross, Skull
  or None. Markers are kept unique.
- Uses Salve-like direct action cells: click a planned party member to send
  that member's configured marker; right-click removes that member's current
  marker. Cells without a plan cannot send an action.
- Includes a movable minimap launcher: left-click shows or hides the grid and
  right-click opens Settings. The small handle above the grid drags it;
  right-clicking that handle opens Settings.
- Has Salve-style visibility settings: **Always outside combat** shows the
  grid for an eligible party and hides it through a secure state driver the
  moment combat starts; **Hidden** keeps it off.

## Getting started

Type `/checkmark` or `/cm` in a small party. Set role markers in Settings,
then left-click each planned person's compact assignment cell before the pull.
Right-click a configured cell to remove that person's marker.

`/checkmark options` opens the Salve-style settings window, with the same
navigation rail and controls but CheckMark-specific Panel, Markers and
Visibility pages. `/checkmark reset` clears CheckMark's saved settings.

## Limits worth stating plainly

- **Markers need your click and permission.** Each click sends one prepared
  marker. Only a party leader or assistant can apply markers where Blizzard
  requires that authority.
- **The plan is not a readback.** WoW does not give CheckMark a reliable,
  usable view of another player's current marker, so it never claims one.
- **Prep before the pull.** CheckMark is unavailable in combat and never
  applies markers because the group roster changed.
- **Six-plus-player raids are intentionally out of scope.**
