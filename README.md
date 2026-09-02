# IBMI-STANDARDS

Canonical home of the Godsend Consulting IBM i coding standards.

- [CODING-STANDARDS.md](CODING-STANDARDS.md) — the baseline standard for
  RPGLE/SQLRPGLE, CL/CLLE, SQL, CMD, PNLGRP, and DDS source. **Edit it here
  only.**
- [CODING-STANDARDS.html](CODING-STANDARDS.html) — styled HTML render of the
  standard for offline reading. Regenerate after editing the markdown:

  ```text
  pandoc --from gfm --to html5 --standalone --embed-resources --mathjax \
    --template github-markdown.html \
    --css "%APPDATA%\pandoc\github-markdown.css" \
    --syntax-highlighting tango \
    --metadata title="IBM i Coding Standards" \
    --output CODING-STANDARDS.html CODING-STANDARDS.md
  ```

  `github-markdown.html` and `github-markdown.css` are installed in pandoc's
  user data directory (`%APPDATA%\pandoc\templates` and `%APPDATA%\pandoc`);
  `--embed-resources` inlines the CSS (hence the explicit path) so the HTML
  is fully self-contained.

- [pandoc_setup.cmd](pandoc_setup.cmd) — one-shot pandoc setup: installs or
  upgrades pandoc via winget, downloads the latest
  [github-markdown-css](https://github.com/sindresorhus/github-markdown-css),
  installs it and [github-markdown.html](github-markdown.html) (the pandoc
  template, master copy kept here) into `%APPDATA%\pandoc`, and smoke-tests a
  conversion.
- [sync-standards.ps1](sync-standards.ps1) — copies the canonical file into
  every sibling IBM i repo (any directory beside this one containing
  `QRPGLESRC`, `QCLSRC`, or `QSQLSRC` **and** a `.git`), so each repo carries
  an identical copy that travels with the code. Directories with source but no
  `.git` — reference-only checkouts such as `RBXREF` — are reported as `SKIP`
  and left alone. `-Check` reports drift without copying.

- [md2pdf.cmd](md2pdf.cmd) — renders any `.md` to a PDF beside it, GitHub
  styled, through pandoc and weasyprint. `-Path` is required, `-Title`
  defaults to the file's base name.

  Two flags are load bearing. **`--to html5` selects the route, not the
  output**: the `.pdf` extension is what makes pandoc produce a PDF, and
  `--to html5` is what makes it get there through HTML rather than LaTeX —
  remove it and pdflatex fails on the injected HTML. **`--pdf-engine
  weasyprint`** names what pandoc would otherwise pick for itself, so the
  render cannot change because something else appeared on the PATH.

- [github-markdown-print.html](github-markdown-print.html) — print overrides
  injected with `--include-in-header`, installed to `%APPDATA%\pandoc` by
  `pandoc_setup.cmd`. The GitHub stylesheet has no `@page` rule, so without
  this you get A4 with no page numbers; and the template's screen layout
  (980px column, 45px padding) doubles the page margin and narrows the text.
  `CODING-STANDARDS.md` is 69 pages without it and 57 with.

  Nothing may contain the literal closing `style` tag, comments included —
  HTML parsing wins over CSS comments, so it ends the element early and every
  rule after it is silently dropped. That failure looks exactly like the file
  not being found.

- [check-iledoc.ps1](check-iledoc.ps1)
 — checks ILEDoc `@param` tags against
  the declarations they document, across every sibling IBM i repo (same
  discovery rule as `sync-standards.ps1`). Reports `UNNAMED` where a tag omits
  the variable name section 2.3 requires, and `MISMATCH` where a doc block's
  tag count differs from its parameter count — which means descriptions are
  attached to the wrong parameters *today*. `-Fix` names and reflows the
  unnamed ones; a mismatch is never repaired automatically, because the
  alignment cannot be inferred. Only `**FREE` members are read.

  This exists because the drift is silent. Code for i binds tags to parameters
  by position and compares nothing, so a block out of step with its parameter
  list reads perfectly well while documenting the wrong things.

## Workflow

1. Edit `CODING-STANDARDS.md` in this repo and commit.
2. Run `./sync-standards.ps1`.
3. Commit the refreshed `CODING-STANDARDS.md` in each affected repo.

## Wiring a new IBM i project

1. Run `./sync-standards.ps1` (the new repo is picked up automatically once
   its source directories exist and it has been `git init`ed — until then it
   reports as `SKIP`), or copy `CODING-STANDARDS.md` to the repo root.
2. In the project's `CLAUDE.md`, import the local copy so Claude Code loads
   it every session:

   ```markdown
   @CODING-STANDARDS.md
   ```
