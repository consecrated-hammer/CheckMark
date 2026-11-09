# Changelog

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
