# Changelog

## [Unreleased]

### Changed

- Settings control groups use two columns throughout. Who goes first fits its full rule labels, and preset profile icons align with their titles.
- Drag fill-order markers to reorder them. Cancelled drags leave the active profile unchanged.
- Drag the live preview close to settings to snap it alongside; drag away to detach.
- Quest Complete stays available on Retail and is excluded from Forever, where its sound kit is unavailable.

- A small profile icon marks settings saved in the active profile, with one legend per page or tab. Repeated scope headings are gone.
- Markers shows the rule order in plain words. Learning and Add controls stay above the People list, and Forget learned asks before removing anyone.
- Playback uses one dropdown; Test sound comes before Find missing sounds.
- Grid, People, marker rules and sound controls now use the same plain names throughout settings and search.
- Grid now groups Layout and Position in tabs. Visibility resets only grid show rules.
- Reminder separates When and how from Marking window, with independent resets and dependent controls that close up without gaps.
- All Grid controls and layout presets are searchable. Hidden options focus the switch that enables them.
- People lists every saved person, keeps search current after edits and explains pinned versus learned assignments.
- Assignment precedence and duplicate-marker fallback are explained, with a Mark the party shortcut beside the plan.
- Sound selection hides when disabled, while Find missing sounds and Test sound stay available. Profiles now sits after the everyday settings pages.
- SavedVariables keys, schema, profile scope, defaults and gameplay behaviour are unchanged.

## [1.4.0] - 2026-11-10

The "who's the Diamond again?" update.

### Added

- **Regulars tab.** Markers now has separate Assignments and Regulars tabs.
  Pinned and learned people, friend/party pickers and learning settings live
  together on Regulars, which stays selected while you edit the list.

- **Mark party window.** When your party forms or someone joins, a big
  window pops up with everyone's marker on a card. Click each card to mark
  them, right-click to clear. It closes once you've clicked everyone, and if
  combat gets in the way it comes back afterwards with your ticks intact.
- **Markers follow people, not slots.** Pin someone to a marker and they
  keep it whoever's leading and whatever order the party's in. Battle.net
  friends keep it on all their characters.
- **CheckMark learns.** Pick a different marker for someone and it's
  remembered next time. If others in your party run CheckMark, it shares who
  got what, so your regular crew stays consistent even when you weren't
  there.
- **Profiles with auto-switching.** World, Delve and Dungeon come ready to
  go. Dungeon puts roles first (tank gets Skull, healer gets Diamond), and
  the world puts your regulars first.
- **Timing settings.** Reminders wait 2 seconds after someone joins so the
  whole party's there, and 3 seconds after combat so you can loot first.
  Both can be changed or turned off.
- If someone else is already marking the party, CheckMark tells you who and
  stays quiet.
- `/checkmark whois` explains who gets which marker and why.
- **Minimap menu.** Right-click the minimap button for settings, profiles,
  Mark the party, Show grid and the mark reminder switch, all in one spot.
  Rather it just opened settings? Minimap right-click on Visibility.
- **Settings search.** Can't find a setting? Type in the box at the top of
  settings and it takes you straight there. No more rummaging.

### Changed

- Everyone in a party of five now gets a marker. Before, the fourth and fifth
  person out in the world got nothing, which was a bit rude. The three DPS
  slots are now a fill order, and any DPS markers you'd set lead it.
- Someone joining now triggers a reminder by default.
- The on-screen message is off by default, because the window does that job
  now. It's turned off once for existing players and you can turn it back on.
- The reminder picks a random line each time, so it nags you in fresh words.
- CheckMark's wording isn't all about pulls any more, so it fits questing as
  much as dungeons.
- No more Reload UI button. Nothing needed it.
- Right-clicking the minimap button opens the menu instead of showing or
  hiding the grid. Show grid is the menu's second item.

### Fixed

- On Forever, surnames are no longer mistaken for realm names.

## [1.3.0] - 2026-11-09

### Added

- **Mark reminder.** Join a party and CheckMark gives you a nudge to mark
  everyone before the pull. Pick when it fires (joining a party, someone new
  joining, only as leader) and how (chat, an on-screen message, a sound) on
  the new **Reminder** page, or switch it off. It follows the grid's Show
  rules, so it waits until the grid can show, and it never fires mid-fight;
  it waits politely until the dust settles.
- **Live preview window.** **Show live preview** at the top of Panel and
  Markers draws your grid at actual size with a sample party, drag handle
  included, in its own window. It stays open while you hop between pages,
  and redraws as you change things. Turn on **Open with settings** to have
  it pop up every time; **Keep in front** keeps it above the settings.
- **Show the grid when you want it.** Visibility → Show can now tick rules:
  in a dungeon, in a delve or scenario, in the open world, or as party
  leader. Any match shows the grid; Always and Never still work.
- **More sounds, and only the ones you can hear.** New marker sounds: Ready
  Check, Raid Warning, Quest Complete, PvP Queue Ready, Party Invite and
  Auction House Open, plus Whisper on Retail. WoW Forever no longer lists
  Retail-only sounds, and **Select all** / **Deselect all** sit under the
  list.
- **A fresh coat of paint.** Settings match the other Consecrated Hammer
  addons: a cleaner header, two columns, proper switches, a raid marker on
  every heading and a Window scale slider.
- **What's new.** A page under REFERENCE with every release's highlights.
- **Support links.** CurseForge, Discord and Buy me a coffee in the footer.
  Hide them on Visibility.

## [1.2.2] - 2026-10-28

### Added

- The GPL v3 licence text as `LICENSE.txt`, so the licence links in the README
  and on CurseForge resolve.

## [1.2.1] - 2026-10-14

### Changed

- Support Retail 12.1.5 (interface `120105`).

## [1.2.0] - 2026-09-26

### Added

- A lore quiz: the quest "!" on the About page, or `/checkmark quiz`, asks five
  questions suited to your client, class and race. **Share result** posts
  the verdict to yourself, Say or Party in one click; it is unavailable in
  combat and during keys, PvP matches and encounters.
- **Check sounds** on the Sounds page, or `/checkmark sounds`, finds marker
  sounds this client cannot play (WoW Forever lacks some Retail sounds).
  Missing sounds are marked, cannot be chosen, and are never played.
- New commands: `help`, `version`, `about`, `debug`, `startup`, `minimap`,
  `reset position`, `reset settings`, `toggle`, `lock` and `unlock`. Help and
  the Commands page also list the grid's mouse actions.

### Changed

- CheckMark now uses HammerCore, the settings, command and chat foundation shared
  by every Consecrated Hammer addon. The login message reads
  `CheckMark v1.2.0 loaded - type /checkmark for settings, /checkmark help for commands`, chat uses
  a gold name prefix, and `/checkmark help` lists every command.
- `/checkmark` opens settings. The grid is `/checkmark toggle` or a
  right-click on the minimap button; left-click opens settings.
- Settings: Panel, Markers, Sounds and Visibility, then Commands,
  Troubleshooting and About. "Show startup message" and "Show minimap button"
  are on Visibility; existing choices carry over.

### Removed

- `/checkmark options`, `reset`, `loadmsg` and `diagnostics`; use the bare
  command, `reset settings`, `startup` and `debug`.

### Fixed

- Clicking the tick in a dropdown menu now chooses it.

## [1.1.8] - 2026-09-26

### Changed

- Remove an obsolete exploratory reference from the packaged release notes.

## [1.1.7] - 2026-09-26

### Changed

- Remove the exploratory staging mode and its packaging reference.
- Clarify the SavedVariables initialization comment.

## [1.1.6] - 2026-09-19

### Fixed

- Let minimap-button collectors such as MinimapButtonBag retain CheckMark's
  icon in their collapsed menu after an add-on settings refresh.
- Keep malformed saved data recoverable and make the diagnostic report identify
  a minimap button that was never created.

### Added

- Add a copyable troubleshooting report and compatible early SavedVariables
  loading for Retail and WoW Forever.

## [1.1.5] - 2026-09-18

### Changed

- Present the Camelot flavour as WoW Forever without beta or testing language.

## [1.1.4] - 2026-09-18

### Changed

- Identify the Camelot TOC as WoW Forever beta and declare the `camelot` load game type.

## [1.1.3] - 2026-09-18

### Fixed

- Publish one package that CurseForge classifies for both Retail and WoW Forever.

## [1.1.2] - 2026-09-18

### Fixed

- Publish distinct Retail and WoW Forever packages.

## [1.1.1] - 2026-09-18

### Added

- Provisional WoW Forever support and a default-on configurable load message.

## [1.1.0] - 2026-09-13

### Added

- Optional marker-application sounds, enabled by default.
- A selectable catalogue of 15 sounds, including Murloc Aggro, Level Up,
  Dungeon Ready, Heroism Cast, and the supplied achievement, quest, loot,
  voice, and hearthstone sounds.
- Sound-pool selection with Random and Sequential playback modes.

### Notes

- Random playback chooses only from selected sounds.
- Sequential playback follows the selected sounds in catalogue order and loops.

## [1.0.0] - 2026-08-29

### Added

- Initial public release of CheckMark.
- Compact pre-pull role-marker grid for two-to-five-player parties.
- Click-to-apply and right-click-to-clear marker actions.
- Salve-style settings for panel layout, role markers, visibility, commands,
  and About.
- Compact, Named, and Oversized panel presets.

### Notes

- CheckMark is deliberately party-only and unavailable in combat.
- It shows the configured plan but does not inspect or infer current markers.
