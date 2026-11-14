# Development workflow

Develop from this Git clone. Syncthing folders are client deployment targets.

Run Lua 5.1 syntax and every `tests/test_*.lua` suite, then HammerCore's
`tools/check.py`, `tools/toc_check.py` and `tools/whatsnew_check.py` against this
clone. `tests/test_settings_ux.lua` checks both clients, search registration,
dependent controls, reset isolation and settings construction at 0.7 and 1.3.
The tests run in lint and release CI through the existing `test_*.lua` glob.

For authorised development staging, archive the existing client folders for
rollback, then run from this clone:

```sh
python3 ../HammerCore/tools/stage.py . --client both
```

The current tool selects a fresh `-devN`, copies runtime files and both TOCs,
and stamps only the selected client's TOC. Confirm its current targets before
running: Retail `wow-interface/AddOns`, Forever `wow-forever-interface/AddOns`,
both under `/mnt/backup/syncthing/kevin/`. Preserve the separate WTF tree.
Compare staged runtime files to tested source, allowing only that TOC stamp.
Trust Syncthing delivery after local verification per the current workstream policy. Kevin must `/reload`
and run `/checkmark version` on each client to confirm the loaded build.

To roll back runtime, restore the archived folder to a temporary source with
`stage.py` and stage a fresh development version. Keep both TOCs and verify the
result. Runtime rollback does not undo settings changed while testing.

Development staging does not publish to CurseForge. Release commits must reach
remote main before a release tag; follow the shared addon instructions.

## Party sync diagnostics

Share.lua retains v1/M marker messages and adds optional v1/Q and v1/A probes.
Older clients ignore those kinds. Queries carry sender GUID, bounded token and
version; replies also name the requester GUID so broadcasts cannot acknowledge
someone else's check. Accept only current-party, matching author identities on
PARTY/INSTANCE_CHAT; unique first-name forms handle Forever's surname variants.
Queries/replies never learn markers or suppress marking reminders. Manual checks
are spaced ten seconds apart after accepted sends (two-second retry guard after
failures), time out after five, and invalidate if the roster
changes. Replies are rate limited per sender, with a short retry guard on failed replies; disabled
sharing sends nothing. Rapid identical log rows coalesce with counts, ignored
packet reasons are rate limited and visible-panel refreshes coalesce per frame.

Modern SendAddonMessage returns SendAddonMessageResult (Success=0), confirmed
against Blizzard ChatInfoDocumentation/ChatConstantsDocumentation on the Forever
UI source. Explicit errors, false, throttling and lockdown are not success.
Legacy nil/true returns mean only queued, never receipt. Register also respects
an explicit false result. A real acknowledgement is the only confirmed transport
result; no reply remains inconclusive for old/disabled copies.

The bounded local sync_log contains timestamps, fixed outcome text, sanitized
versions and anonymous party slots only. It is shared diagnostic state, excluded
from marker profiles, and cleared separately. No payloads, names, GUIDs, BattleTags
or assignment history are stored in it. Troubleshooting extends HammerCore via
its supported spec hook; no vendored changes. tests/test_sync.lua runs two isolated
addon copies under each client TOC through the real Share request/reply handlers.
Native two-client transport remains a separate acceptance check.
