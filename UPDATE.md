# Update — Refresh skills from upstream

Skills in this repository are imported from 9 upstream sources (see [SOURCES.md](SOURCES.md)). They are snapshots, not submodules, so they do not update automatically.

## Update procedure

1. Re-clone (or `git pull --depth 1`) each upstream source into a temp audit directory.
2. Re-run the import/copy script (`import-skills.ps1`) to re-copy changed skill directories into `skills/<category>/<origin>/<skill>/`.
3. Regenerate the catalog:

```powershell
pwsh -ExecutionPolicy Bypass -File gen-catalog.ps1
```

4. Review the diff for new, removed, or modified skills.
5. Commit and push.

## Change detection

Compare `CATALOG.json` before and after to detect:
- New skills (added entries)
- Removed skills (missing entries)
- Modified skills (changed `version` or `description`)

## License drift

Re-check each origin's license on update. If an upstream license changes, note it in [SOURCES.md](SOURCES.md) before importing.
