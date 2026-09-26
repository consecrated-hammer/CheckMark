# Changelog

## [Unreleased]

### Changed

- CheckMark now uses HammerCore, the settings, command and chat foundation
  shared by every Consecrated Hammer addon:
  - `/checkmark` opens settings; the grid moves to `/checkmark toggle` and
    to a right-click on the minimap button. A left-click on the minimap
    button opens settings.
  - The settings rail ends with Commands, Troubleshooting and About,
    after a divider.
  - "Show startup message" and "Show minimap button" are on Visibility.
    Your existing choices, minimap position and settings position carry
    over.
  - The login message now reads `CheckMark v1.1.8 loaded - type /checkmark
    for settings, /checkmark help for commands`.
  - New commands: `help`, `version`, `about`, `debug`, `startup`,
    `minimap`, `reset position`, `reset settings`, `toggle`,
    `lock` and `unlock`. Help and the Commands page also list grid actions.
  - Chat messages use the shared gold name prefix.
- Clicking the tick in a multi-select menu now chooses it.

### Added

- A lore quiz behind the "!" on the About page, or `/checkmark quiz`: five questions
  suited to your client, class and race, with a verdict in chat.

- **Check sounds** on the Sounds page, and `/checkmark sounds`, find marker
  sounds this client cannot play (WoW Forever lacks some Retail sounds).
  Missing sounds are marked, cannot be selected, and are never played.

### Removed

- `/checkmark options`, `/checkmark reset`, `/checkmark loadmsg` and
  `/checkmark diagnostics`; use the bare command, `reset settings`,
  `startup` and `debug`.

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
