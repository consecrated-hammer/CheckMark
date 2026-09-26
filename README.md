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

Type `/checkmark` (or `/cm`) for settings and set role markers on the
Markers page. In a small party, `/checkmark toggle` or right-clicking the
minimap button shows the grid; left-click each planned person's cell before
the pull, and right-click a configured cell to remove that person's marker.

| Command | Effect |
| --- | --- |
| `/checkmark` | Open settings |
| `/checkmark help` | List every command and grid action |
| `/checkmark version` | Print the loaded version and client |
| `/checkmark about` | Open the About page |
| `/checkmark debug` | Open a copyable diagnostic report |
| `/checkmark startup [on\|off]` | Show the startup message |
| `/checkmark minimap [on\|off]` | Show the minimap button |
| `/checkmark reset position` | Move the grid back to the centre |
| `/checkmark reset settings` | Reset every setting after a confirmation |
| `/checkmark toggle` | Show or hide the marker grid |
| `/checkmark lock` / `unlock` | Hide or show the drag handle |
| `/checkmark sounds` | Find marker sounds this client cannot play |

Settings, commands, the minimap button and the reference pages come from
[HammerCore](https://github.com/consecrated-hammer/HammerCore), shared by
every Consecrated Hammer addon and vendored under `Libs/HammerCore`.

## Limits worth stating plainly

- **Markers need your click and permission.** Each click sends one prepared
  marker. Only a party leader or assistant can apply markers where Blizzard
  requires that authority.
- **The plan is not a readback.** WoW does not give CheckMark a reliable,
  usable view of another player's current marker, so it never claims one.
- **Prep before the pull.** CheckMark is unavailable in combat and never
  applies markers because the group roster changed.
- **Six-plus-player raids are intentionally out of scope.**
