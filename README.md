# IBMI-STANDARDS

Canonical home of the Godsend Consulting IBM i coding standards.

- [CODING-STANDARDS.md](CODING-STANDARDS.md) — the baseline standard for
  RPGLE/SQLRPGLE, CL/CLLE, SQL, CMD, PNLGRP, and DDS source. **Edit it here
  only.**
- [CODING-STANDARDS.html](CODING-STANDARDS.html) — styled HTML render of the
  standard for offline reading. Regenerate after editing the markdown:

  ```text
  pandoc --from gfm --to html5 --standalone --mathjax \
    --template github-markdown.html --css github-markdown.css \
    --syntax-highlighting tango \
    --metadata title="IBM i Coding Standards" \
    --output CODING-STANDARDS.html CODING-STANDARDS.md
  ```

  `github-markdown.html` and `github-markdown.css` are installed in pandoc's
  user data directory (`%APPDATA%\pandoc\templates` and `%APPDATA%\pandoc`),
  so no local copies are needed.

- [sync-standards.ps1](sync-standards.ps1) — copies the canonical file into
  every sibling IBM i repo (any directory beside this one containing
  `QRPGLESRC`, `QCLSRC`, or `QSQLSRC`), so each repo carries an identical
  copy that travels with the code. `-Check` reports drift without copying.

## Workflow

1. Edit `CODING-STANDARDS.md` in this repo and commit.
2. Run `./sync-standards.ps1`.
3. Commit the refreshed `CODING-STANDARDS.md` in each affected repo.

## Wiring a new IBM i project

1. Run `./sync-standards.ps1` (the new repo is picked up automatically once
   its source directories exist), or copy `CODING-STANDARDS.md` to the repo
   root.
2. In the project's `CLAUDE.md`, import the local copy so Claude Code loads
   it every session:

   ```markdown
   @CODING-STANDARDS.md
   ```
