# CheckMark

**Raid markers for your party, so everyone's easy to spot.**<br>_Skull on the tank, every time._

[![Retail](https://img.shields.io/badge/retail-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/checkmark) [![WoW Forever](https://img.shields.io/badge/wow%20forever-supported-4c9a7a?style=flat-square)](https://www.curseforge.com/wow/addons/checkmark) [![Release](https://img.shields.io/github/v/release/consecrated-hammer/CheckMark?style=flat-square&color=4c9a7a&label=release)](https://github.com/consecrated-hammer/CheckMark/releases) [![License](https://img.shields.io/badge/license-GPL--3.0-4c9a7a?style=flat-square)](https://github.com/consecrated-hammer/CheckMark/blob/main/LICENSE.txt)

[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/z3xKxRygDc) [![GitHub](https://img.shields.io/badge/github-source-6e7681?style=flat-square&logo=github&logoColor=white)](https://github.com/consecrated-hammer/CheckMark) [![Buy Me a Coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-support-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/consecratedhammer)

Questions, bugs or ideas? Come say hi on the [Consecrated Hammer Discord](https://discord.gg/z3xKxRygDc). Bug reports go in `#bug-reports`, or you can open a [GitHub issue](https://github.com/consecrated-hammer/CheckMark/issues).

---

CheckMark puts a raid marker on each party member so you can spot them at a glance, whether you're questing together or heading into a dungeon. When your party forms, a window pops up with everyone's marker; click each person to mark them. Markers stick to people, so your regulars get the same one every time, on any of their characters. It doesn't mark anyone automatically, doesn't work in combat, and doesn't guess what markers other players have already set.

![Live panel](https://media.forgecdn.net/attachments/1903/717/live-panel-dev43-png.png)

## What it does

- **Mark party window.** When your party forms or someone joins, a window shows a big card for each member with their marker. Click a card to mark them, right-click to clear, click the icon to pick another marker, or pin them. It waits a couple of seconds after people join and a few after combat, so you can loot first.
- **Markers follow people.** Pin someone to a marker and they keep it whatever the party order or leader. Battle.net friends are matched by BattleTag, so they keep it on every character.
- **It learns.** CheckMark remembers the markers you give people. Party members running CheckMark share who they marked with what, so a regular crew stays consistent.
- **Who goes first.** Your manual picks for this party come first. Pinned people and role markers (Tank = Skull, Healer = Diamond) follow in the order you choose, then learned assignments when pinned people are included, then fill order.
- **Profiles.** World, Delve and Dungeon switch automatically. Dungeon puts roles first and the world puts regulars first; change either on the Markers page.
- **One cell per party member**, in the same compact style as Salve. Left-click a cell to put that member's marker on them, right-click to take it off.
- **Two to five players**, out questing or in follower dungeons, dungeons and delves.
- **Mark reminder.** Every trigger, wait and output is a setting on the Reminder page, and it never fires in combat.
- **Marker sounds.** Clicking a cell can play a sound. On WoW Forever some Retail sounds don't exist, so CheckMark marks those as missing and never plays them.
- **Your layout.** Cells per row, spacing, cell size and icon size are all adjustable. Widen the cells to 95 or more and member names fit too.

## Getting started

Install, then type `/checkmark` (or `/cm`) for settings. On **Markers**, **Assignments** sets who goes first, the role markers and fill order. **People** holds your pinned and learned people, friend/party pickers and learning settings. **Mark the party** on Assignments opens the marking window (a sample party while solo). **Test reminder** on Reminder > When and how shows the marking window with a sample party.

Right-click the minimap button for a menu: settings, profiles, **Mark the party** (opens the marking window, or previews it when you're solo), **Show grid** and **Mark reminder**. Prefer right-click to open settings? Change **Minimap right-click** on Visibility. Lost a setting? The search box at the top of settings finds it.

In a party, `/checkmark toggle` or **Show grid** on the minimap menu shows the grid. Left-click each cell to mark that member. Drag the small handle above the grid to move it, and right-click the handle to open settings.

## Settings

- **Grid:** Layout has presets, grid spacing, size and names. Position has the drag handle, Re-centre grid and Reset grid position.
- **Markers:** Assignments has Mark the party, pinned-person/role precedence, role markers and fill order. People keeps learning and Add controls above the pinned-first list. Forget learned confirms the count and keeps pinned people.
- **Reminder:** When and how has triggers, timing, chat, on-screen text, sound and Test reminder. Marking window has its size, closing options and a test.
- **Sounds:** marker sounds, selected pool and playback mode, with Find missing sounds and Test sound always available.
- **Visibility:** grid show rules, then shared minimap, update and settings-window choices.
- **Profiles:** World, Delve and Dungeon, automatic switching, and profile management.

The active profile saves assignments, grid layout, position and show rules. Pinned and learned people, learning, sharing, reminders, marking-window options and sounds are shared. Turning a feature off hides its dependent controls; search still finds them and highlights the switch that enables them.

Page and tab resets affect only their named settings. Reset grid visibility keeps your position, handle and shared HammerCore preferences. Re-centre grid moves only the grid; Reset grid position also restores its handle. Forget learned removes unpinned learned people across all profiles, keeps pinned people and current party picks, and leaves learning enabled.

## Commands

| Command | What it does |
| --- | --- |
| `/checkmark` or `/cm` | Open settings |
| `/checkmark toggle` | Show or hide the marker grid |
| `/checkmark lock` / `unlock` | Hide or show the drag handle |
| `/checkmark reset position` | Move the grid back to the centre |
| `/checkmark sounds` | Find marker sounds this client can't play |
| `/checkmark profile [name]` | List profiles, or switch to one |
| `/checkmark whois` | Explain who gets which marker, and why |

Every Consecrated Hammer addon also has `help`, `version`, `about`, `debug`, `startup`, `minimap`, `reset settings` and `quiz`.

## Limits

- **Markers need your click and permission.** Each click puts on one marker, and where Blizzard requires it you need to be party leader or assistant.
- **It shows your plan, not what's actually marked.** WoW hides party markers from addons, so a ticked card means you clicked it, not that the marker's still there. Learning only sees CheckMark clicks, never markers set by hand or by other addons.
- **BattleTags need a Battle.net friendship.** Anyone else is matched by character.
- **Out of combat only.** The grid hides when combat starts, and CheckMark never re-marks people when the group changes.
- **Parties only.** Raids of six or more are out of scope.

## Licence

GPL v3, see [LICENSE.txt](https://github.com/consecrated-hammer/CheckMark/blob/main/LICENSE.txt).
