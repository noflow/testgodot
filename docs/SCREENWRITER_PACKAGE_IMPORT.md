# Screenwriter game-package workflow

Screenwriter’s **Build** window is the deployment boundary between authored content
and Port Alder. It exports one `.screenwriter-package` containing character-owned
quests, conversations, text messages, schedules, residences, and optional world-map
updates in the same JSON formats the game already loads.

## Import from the Godot editor

1. In Screenwriter, choose **Build**.
2. Select **Only new and changed files** for routine work or **Complete game content
   package** for a release snapshot.
3. Resolve blocking preflight issues and download the package.
4. In Godot, choose **Project → Tools → Import Screenwriter Package…**.
5. Select the downloaded file, review the dry-run list, then choose **Import and
   create backup**.

The importer accepts only `characters/*.character` and the supported world registry
paths. It rejects path traversal, malformed JSON, mismatched character/file ids,
unknown operations, duplicate destinations, and bad checksums. Imports never delete
content. A full package may report removed files, but they remain in the project for
manual review.

Changed targets are copied to `.screenwriter-backups/` before an atomic replacement.
The character validator runs after the write. If validation fails, updated files are
restored and newly added files are removed automatically.

## Command-line preview and import

The command defaults to a safe dry run:

```sh
python3 tools/import_screenwriter_package.py ~/Downloads/port_alder_story_content-v1.screenwriter-package
```

Apply exactly that preview with:

```sh
python3 tools/import_screenwriter_package.py ~/Downloads/port_alder_story_content-v1.screenwriter-package --apply
```

Run the focused importer regression suite with:

```sh
python3 tools/test_screenwriter_package_import.py
```
