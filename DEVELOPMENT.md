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
Check Syncthing delivery separately from local staging. Kevin must `/reload`
and run `/checkmark version` on each client to confirm the loaded build.

To roll back runtime, restore the archived folder to a temporary source with
`stage.py` and stage a fresh development version. Keep both TOCs and verify the
result. Runtime rollback does not undo settings changed while testing.

Development staging does not publish to CurseForge. Release commits must reach
remote main before a release tag; follow the shared addon instructions.
