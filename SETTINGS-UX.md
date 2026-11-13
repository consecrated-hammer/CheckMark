# Settings UX review, 2026-11-13

Reviewed against CheckMark `e8cb3e4` (published 1.4.0), then implemented on
`feat/settings-ux`. Source files under `Options/` own the current layout.
SavedVariables schema 2, keys, defaults and profile groups are unchanged.

## Navigation

Before: Panel; Markers (Assignments, Regulars); Profiles; Reminder; Sounds;
Visibility; reference pages.

After: Grid (Layout, Position); Markers (Assignments, People); Reminder
(When and how, Marking window); Sounds; Visibility; Profiles (Profiles,
Auto-switch); reference pages (What's new, Commands, Troubleshooting, About).

No additional rail page or global advanced switch is needed. Position belongs
beside grid layout. Reminder has two distinct tasks and enough controls to
justify tabs. Assignments and Regulars already separate planning from identity
well. Sounds and Visibility remain single pages.

## Inventory and migration matrix

E = essential, S = standard, A = advanced. Rows group controls with the same
scope and destination; nothing is removed from SavedVariables.

| Previous location | Controls | Tier | New location / behaviour | Scope |
| --- | --- | --- | --- | --- |
| Panel | Compact, Named, Oversized presets | E | Grid > Layout; search registration | Profile |
| Panel | Cells per row, Spacing, Width, Height, Icon size, Player names | E/S | Grid > Layout; search ownership fixed; isolated reset | Profile |
| Visibility | Show drag handle, Handle position, Reset grid position | S | Grid > Position; hide edge selector when handle off; separate Re-centre from full position reset | Profile |
| Markers > Assignments | Who goes first | E | Same; tooltip distinguishes pinned and learned precedence | Profile |
| Markers > Assignments | Tank, Healer custom marker selectors, None | E | Same; collision notes and explanatory fallback text | Profile |
| Markers > Assignments | Eight-icon fill order; left/right click reorder | S | Same; tooltip and search retained | Profile |
| Markers > Assignments | Reset markers | S | Reset assignments includes precedence, role markers and fill order | Profile |
| Minimap | Mark the party / sample party | E | Additional Mark the party action on Assignments | Action |
| Markers > Regulars | Each identity, marker selector, remove button, Pinned/Learned status | S | All entries, no 20-person display cap; dynamic search and height update; menus close on hide | Shared |
| Markers > Regulars | Add a Battle.net friend, Add a party member | S | Same; account versus character matching preserved | Shared |
| Markers > Regulars | Forget learned | A | Same; tooltip specifies unpinned entries across profiles, keeps pins and current picks, does not disable learning | Shared |
| Markers > Regulars | Learn from my choices, Share with the party, Learn from the party | S/A | Learning and party sharing section; clicks-only learning explained | Shared |
| Reminder | Remind me to mark | E | Reminder > When and how; hides automatic trigger/timing controls while off | Shared |
| Reminder | When I join a party, When someone joins, Only as party leader, Quiet if someone else marks | S/A | When and how > When; hidden under master | Shared |
| Reminder | Wait after joining, Seconds after joining | S | When and how > Timing; slider in reflowing dependent section | Shared |
| Reminder | Wait after combat, Seconds after combat | S | Same; independent section; combat wait replacement explained | Shared |
| Reminder | Show the marking window, Window size, Close when all clicked | E/S | Reminder > Marking window; child settings hidden when off | Shared |
| Reminder | Close after a while, Seconds open | A | Marking window; nested dependency, gap-free layout | Shared |
| Reminder | Chat message, On-screen message, Sound | S | When and how > How to remind me; Sound renamed Reminder sound; available for manual test with master off | Shared |
| Reminder | Test reminder, Reset reminder | E/S | Test on both tabs with unique names; independent reminder/window reset scopes | Action |
| Sounds | Play a sound when applying a marker | S | Play marker sounds | Shared |
| Sounds | Sounds multi-select, Select/Deselect all, Random/Sequential playback | S | Available sounds and Playback hidden when sounds off; pool and selection rules unchanged | Shared |
| Sounds | Find missing sounds, diagnostic summary, Test sound, Reset sounds | S/A | Always available, including disabled marker sounds | Shared |
| Visibility | Show: Always/Never or any matching dungeon/delve/world/leader rules | S | Show grid, explicitly per profile | Profile |
| Visibility | Reset visibility | S | Reset grid visibility preserves position, handle and shared preferences | Profile + manual hide |
| Visibility (HammerCore) | Show minimap button, Minimap right-click | S | Minimap button section | Shared |
| Visibility (HammerCore) | Show startup message, Show what's new after updates, Show unread marker, What's new sound | A | Updates section | Shared |
| Visibility (HammerCore) | Settings search, Show support links | A | Settings window section | Shared |
| Window header | Window scale, search, live preview, active profile link | S | Retained; profile badge suppressed on shared-only tabs/pages | Shared / action |
| Profiles > Profiles | Active profile, rename/new/delete/copy, copy groups, new-profile source, per-character selection | S/A | Retained, page moved after everyday settings | Shared profile manager |
| Profiles > Auto-switch | Mode, ordered rules (profile, instance, group source and size), add/remove/reorder, group/instance/size events, declining/combat behaviour, manual override duration, switch chat | A | Retained; World/Delve/Dungeon defaults unchanged | Shared profile manager |
| Live preview | Sample members, Open with settings, Keep in front | S | Retained; follows layout/assignment changes | Shared / preview |
| Reference | What's new/history links, command rows, diagnostic report/debug and About links/quiz | A | Retained; Regulars highlight points directly to its tab | Action |

## Findings and decisions

P1: fixed missing Panel search ownership and unindexed presets; replaced timing
slider hiding that left layout holes; corrected misleading learned/role
precedence; made reset scopes explicit and isolated. Every custom marker row
is indexed through its owning row; its tooltip describes the interaction.

P2: split Reminder, regrouped position beside layout, removed the Regulars
visibility cap, refreshed dynamic search after background learning as well as
manual edits, hid sound/window/handle dependencies and clarified profile scope.

P3: added Mark the party next to assignments, kept sound diagnosis/testing
available while disabled, explained empty Regulars and duplicate-marker
fallback, and closed marker menus when their owner hides.

New player: Tank = Skull and Healer = Diamond remain defaults. Assignments
now has an explicit Mark the party action. Each card still needs a real click.

Regular player: identity editing stays on Regulars; timing is separate from
window appearance; grid layout and movement share one page.

Advanced player: full Regulars list remains editable, with account matching,
learning and sharing intact. Precedence is manual party picks first, then
pinned people/roles in the selected order, learned assignments when Regulars
is included, then free markers in fill order. Earlier allocations keep a
contested marker. The displayed allocation is an intended plan.

Deferred: no welcome wizard or extra advanced tab. Existing defaults and the
new action address the first-use task without more configuration decisions.
Visual clipping, real mouse focus, native scrolling, sound availability and
secure party/combat behaviour require Retail and Forever acceptance. The Lua
harness checks construction at both window-scale limits, not pixel rendering.

## Compatibility and validation

The only non-settings source change is a notification after saved Regulars
mutations so an already-built settings search index stays current. Identity,
planning, sharing, secure actions, reminder scheduling and defaults are intact.
No migration is introduced. HammerCore is re-vendored from its already-pushed
`feat/settings-ux` commit `3c1eeeb` for hidden-parent search and shared sections.

`tests/test_settings_ux.lua` covers both TOCs, page construction, all standard
row registrations, unique labels, every registered search result and focus,
presets, nested dependencies, timing reflow, reset isolation, existing schema-2
settings, large Regulars lists and removal without stale search. Existing
marker, identity, sharing, profile and reminder suites remain applicable.
See the wiki handoff for the final commands, review, Git and staging evidence.

Independent review: Claude was unavailable due to its five-hour account limit.
Kevin approved a fresh Codex review, which found two P2 issues. Assignment
reset now restores precedence before refreshing the grid/window/preview. The
mixed Visibility page keeps the active-profile badge and explicitly identifies
its shared settings. Both findings have targeted regression coverage.

## Polish follow-ups

Assignments shows the selected rule order and a visible fill-order hint. People
keeps learning and Add controls above the growing list; existing pinned-first
sorting is retained. Forget learned shows a count and confirms before clearing,
while single-person removal stays immediate. Sounds uses a standard Playback
dropdown and puts Test sound before Find missing sounds.
