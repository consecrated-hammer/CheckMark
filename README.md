# CheckMark

**Pre-pull raid markers for parties.**

_Skull on the tank, every time._

[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/z3xKxRygDc) [![Retail](https://img.shields.io/badge/retail-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/checkmark) [![WoW Forever](https://img.shields.io/badge/wow%20forever-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/checkmark) [![Release](https://img.shields.io/github/v/release/consecrated-hammer/CheckMark?style=flat-square&color=4c9a7a&label=release)](https://github.com/consecrated-hammer/CheckMark/releases) [![License](https://img.shields.io/badge/license-GPL--3.0-4c9a7a?style=flat-square)](https://github.com/consecrated-hammer/CheckMark/blob/main/LICENSE.txt)

Questions, bugs or ideas? Come say hi on the [Consecrated Hammer Discord](https://discord.gg/z3xKxRygDc). Bug reports go in `#bug-reports`, or you can open a [GitHub issue](https://github.com/consecrated-hammer/CheckMark/issues).

---

CheckMark makes the bit of marker admin before a pull quick. Pick a marker for each role once, then before the pull click each party member's small cell to put their marker on them. It's deliberately a prep tool, so it doesn't mark anyone automatically, doesn't work in combat, and doesn't guess what markers other players have already set.

![Live panel](https://media.forgecdn.net/attachments/1903/717/live-panel-dev43-png.png)

## What it does

- **Role markers.** Set a marker for Tank, Healer and three DPS slots, such as Tank = Skull and Healer = Diamond. Markers stay unique, so picking one another role already has moves it over.
- **One cell per party member**, in the same compact style as Salve. Left-click a cell to put that member's marker on them, right-click to take it off.
- **Two to five players**, in normal parties, follower dungeons, dungeons and delves.
- **Marker sounds.** Clicking a cell can play a sound. On WoW Forever some Retail sounds don't exist, so CheckMark marks those as missing and never plays them.
- **Your layout.** Cells per row, spacing, cell size and icon size are all adjustable. Widen the cells to 95 or more and member names fit too.

## Getting started

Install, then type `/checkmark` (or `/cm`) for settings and set your role markers on the **Markers** page.

In a party, `/checkmark toggle` or right-clicking the minimap button shows the grid. Left-click each cell before the pull. Drag the small handle above the grid to move it, and right-click the handle to open settings.

## Commands

| Command | What it does |
| --- | --- |
| `/checkmark` or `/cm` | Open settings |
| `/checkmark toggle` | Show or hide the marker grid |
| `/checkmark lock` / `unlock` | Hide or show the drag handle |
| `/checkmark reset position` | Move the grid back to the centre |
| `/checkmark sounds` | Find marker sounds this client can't play |

Every Consecrated Hammer addon also has `help`, `version`, `about`, `debug`, `startup`, `minimap`, `reset settings` and `quiz`.

## Limits

- **Markers need your click and permission.** Each click puts on one marker, and where Blizzard requires it you need to be party leader or assistant.
- **It shows your plan, not what's actually marked.** WoW doesn't give addons a reliable view of other players' markers, so CheckMark doesn't pretend to know.
- **Out of combat only.** The grid hides when combat starts, and CheckMark never re-marks people when the group changes.
- **Parties only.** Raids of six or more are out of scope.

## Licence

GPL v3, see [LICENSE.txt](https://github.com/consecrated-hammer/CheckMark/blob/main/LICENSE.txt).
