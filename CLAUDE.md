# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A small, dependency-light Bash tool that creates timestamped local backups of a
KeePass (`.kdbx`) database, aimed at users who sync their database via
OneDrive/`onedriver`, Dropbox, etc., and want a local "failsafe" copy. No
build system, no package manager, no runtime beyond Bash + coreutils.

## Structure

- [src/backup_keepass.sh](src/backup_keepass.sh) — entrypoint. Parses CLI
  flags, loads config, and drives the backup workflow (verify type → check
  daily duplicate → copy → verify checksum → cleanup).
- [src/lib_utils.sh](src/lib_utils.sh) — all the logic, sourced by the
  entrypoint: `log_message`, `load_config`, `handle_wait`, `verify_file_type`,
  `verify_checksum`, `cleanup_old_backups`, `check_daily_duplicate`.
- [tests/](tests/) — three standalone scripts (`test_config.sh`,
  `test_integrity.sh`, `test_validation.sh`), each sourcing `lib_utils.sh`
  directly and asserting via exit codes. No test framework.
- `.env` (gitignored, user-provided; see [.env.example](.env.example)) —
  `SOURCE_DB`, `BACKUP_DIR`, `RETENTION_DAYS`, `SLEEP_DELAY`.
- [.github/workflows/tests.yml](.github/workflows/tests.yml) — runs the three
  test scripts on push/PR to `main`.
- [.github/workflows/lint.yml](.github/workflows/lint.yml) — ShellCheck over
  `src/` only (tests are not linted).

## Running things locally

```bash
chmod +x tests/*.sh && ./tests/test_validation.sh && ./tests/test_integrity.sh && ./tests/test_config.sh
```

```bash
shellcheck src/*.sh
```

```bash
cd src && ./backup_keepass.sh --now
```

## Conventions to preserve

- **Emoji-prefixed, human-readable terminal output** throughout (`✅`, `❌`,
  `⏳`, `🔍`, etc.) — this is the established UX style, not incidental.
- **Functions return 0/1 and the caller decides on logging/exit** — utility
  functions in `lib_utils.sh` don't call `exit` themselves (except
  indirectly via the caller checking their return code); keep that
  separation.
- **`log_message` fires both to stdout and `notify-send`** — don't bypass it
  for user-facing success/error messages in the main script.
- Flags support both long and short forms (`--now`/`-n`, `--force`/`-f`) via
  a `case` loop in `backup_keepass.sh`; combined short flags like `-nf` are
  documented as supported (check current parsing logic before assuming this
  still holds for new flags).
- Tests are plain scripts, not a framework: each prints ✅/❌ and does
  `exit 1` on failure. New tests should follow the same shape and get added
  to `.github/workflows/tests.yml` explicitly (nothing is auto-discovered).
- ShellCheck only scans `src/`, so lint-clean code matters most there.

## Before starting any task

Always pull the latest `main` before doing anything in this repo (creating a
branch, editing files, etc.):

```bash
git checkout main && git pull
```

## Branching & commit conventions

**Branches**

- If a GitHub issue exists: `feature/ISSUE-XX-short-description` (e.g.
  `feature/ISSUE-28-add-claude-md`).
- If there is no issue: `feature/NO-ISSUE-short-description`.

**Commits**

- Clean, short one-liners. No multi-paragraph bodies, no bullet-point
  changelogs in the commit message.

## Notes

- `check_daily_duplicate` and the filename scheme
  (`${BASE_NAME}_backup_${TIMESTAMP}.kdbx` with `%Y-%m-%d_%H:%M:%S`) are
  coupled — changing the timestamp format will break duplicate detection's
  `find` glob in `check_daily_duplicate`.
- `verify_file_type` accepts both `application/x-keepass2` and
  `application/octet-stream` MIME types, since `.kdbx` often reports as the
  latter depending on OS/`file` database version.
- No `set -e`/`set -u` in either script; error handling is manual via
  explicit `if`/return-code checks. Keep new code consistent with that
  rather than introducing strict mode partway through.
