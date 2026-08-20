# IBM i Coding Standards

Baseline standards for RPGLE/SQLRPGLE, CL/CLLE, SQL, CMD, PNLGRP, and DDS source
in **all Godsend Consulting IBM i repositories** — GCUTL, BSLIB, RBUTL, and any
future project. They were derived from the current best practice in these libraries —
primarily the Task Manager (`TM*`) and developer-utility (`RB*`) members in
**RBUTL**, which is the curated exemplar. BSLIB additionally carries legacy,
third-party, and scratch code that does *not* set the standard (see section 10,
Legacy and scratch code).

> **Canonical copy:** the master of this document lives in the `IBMI-STANDARDS`
> repository; every IBM i repo carries an identical copy so the standard travels
> with the code. Edit the master, then run its `sync-standards.ps1` to refresh
> the repo copies — don't edit a repo copy directly.

**Precedence:** when this document and an existing member disagree, follow this
document for new code. When this document is silent, match the closest RBUTL
sibling of the same member type.

---

## 1. Universal member conventions

These apply to every source member regardless of language.

### 1.1 Standard header

Every member begins with, in order:

1. **Purpose comment** — what the member does, plus any design notes worth a
   paragraph. Write *why*, not just *what*.
2. **`MODIFICATIONS:` log** (see 1.2).
3. **BLDOBJ build directives** (see 1.3).
4. **Copyright** — `(c) Copyright Godsend Consulting, <first year>-<current year>`.
   In RPG this is the `ctl-opt copyright(...)` keyword; in CL the `COPYRIGHT`
   command; elsewhere a comment line (CMD) or `:COPYR.` tag (PNLGRP).

Comment syntax per language:

| Language | Block comment | Build directive line |
| --- | --- | --- |
| RPGLE (**FREE) | `///` doc block / `//` | `//  *>  <BLDOBJ CRTDFT/>` |
| CL, CMD | `/* ... */` with floating `+` continuation | `/*> CRTCMD ... <*/` |
| SQL | `/* ... */`, `--` inline | `/*> RUNSQLSTM ... <*/` |
| PNLGRP | `.*` | `.*> <BLDOBJ CRTDFT/>` |
| DDS (DSPF) | `␣*` doc block / `A*` | `*> CRTDSPF FILE(&O/&N) ... -` |

### 1.2 MODIFICATIONS log

Every change appends a dated entry. Format is fixed — tools and habit depend on it:

```text
MODIFICATIONS:
BS  08/03/25  Created.
BS  06/15/26  Updated documentation to acknowledge that default
               values for an undefined location effectively remove
               all restrictions that can be set for a location.
@@
```

- `XX  MM/DD/YY  description` — contributor initials, US date, sentence-case
  description ending in a period.
- Entries are chronological, oldest first; **append new entries at the bottom**,
  immediately before the `@@` terminator line.
- Continuation lines align under the description, indented one extra space.
- **A change spanning more than one day carries a date RANGE**: the start date in
  the date column of the first line, the end date in the same columns on the
  **second** line, with the initials column left blank. Only two dates are ever
  shown, and only when the work actually crossed a day — a same-day change has no
  second date. Where the description needs no second line, the end date stands
  alone on one:

  ```text
  MW  09/07/18  Do not purge POSCL if the filegroup or blockout is not
                 populated for some reason.
  MW  06/21/19  Do not enforce Louise Paris edit.
  BS  11/22/19  Add question to allow blockout to be
      12/22/19   split by style if the buyer has been
                 configured to allow this feature.
  MW  06/21/20  Some change 2-day change text here.
      06/22/20
  MW  07/21/20  The last change
  @@
  ```
- One entry may describe several changes made together; start each on its own
  continuation line.
- The `@@` line terminates the log. Never remove it.
- `@todo` lines may follow the log (before the build directives) to record known
  future work. **One `@todo` per item** — two things to do are two lines, not one
  line with two sentences, so that each can be read, counted and struck off on
  its own. **Lowercase**, like every other ILEDoc command (§2.3): `@todo`, never
  `@TODO` or `@ToDo`.

### 1.3 BLDOBJ build directives

There is no external build system. Each member embeds its own create/compile
command(s) between `*>` and `<*` markers; the `BLDOBJ` command extracts and runs
them on the IBM i (see `QRPGLESRC/BLDOBJ.SQLRPGLE` header for the full reference).

- If the default create command for the member type is correct, use:

  ```text
  /*> <BLDOBJ CRTDFT/>                                                <*/
  /*> <BLDOBJ EOF/>                                                   <*/
  ```

- Otherwise spell out the command(s) with substitution variables — `&O` object
  library, `&L` source library, `&F` source file, `&N` member, `&ON` object name,
  `&T` type, `&X` member text:

  ```text
  /*> CRTCMD CMD(&O/&ON) SRCFILE(&L/&F) SRCMBR(&N) PGM(TMACRUSR)      <*/
  /*> <BLDOBJ EOF/>                                                   <*/
  ```

- Prefix a command with `IGN:` when its failure must not stop the build
  (e.g. `IGN:DLTF QTEMP/OUTPUT`).
- Always end with `<BLDOBJ EOF/>` so scanning stops.
- Keep directives correct when copying a member — that *is* its build script.

**Member text lives in the source.** Source edited off-platform round-trips
through the IFS, and a source physical file member's **text description does not
survive that trip**. The only place it can be kept is the member itself, so every
member carries its own:

| Member type | Where the text goes |
| --- | --- |
| `.CMD` | `TEXT('…')` on the `CMD` statement |
| CL (`.CLLE`, `.CLP`) | `TEXT('…')` on `DCLPRCOPT` |
| Everything else | `*> <BLDOBJ TEXT="…"/>` |

So altering the source is what preserves the source. This applies even to
members that are never built — a reference-only layout still has member text
worth keeping, and a `TEXT` directive carries no create command, so it does not
make the member buildable.

**Put it immediately after the `@@`.** Two reasons, and the second is the
general one:

- `@@` is the marker everyone navigates to, because appending a `MODIFICATIONS`
  entry means finding it and working back. A directive on the line after it is
  seen by anyone who touches the member; the same directive above the include
  guard, or anywhere else in the header, is documentation nobody scrolls to.
- It is **one location for every member type**. A buildable member already
  carries its create commands there, so putting the text directive in the same
  place means source-only and source-to-object members read alike — you look
  after the `@@` and find whatever that member has, without first working out
  which kind it is.

**Text at the top is better than no text at all.** A member carrying the
directive somewhere else in the header is not broken and is not worth a sweep;
move it down when you are in the member for another reason.

### 1.4 Layout

- **Line width.** The hard maximum is the source file's **`SRCDTA` length** —
  the source line itself — and a longer line is **truncated silently**:

  | Source file | Line (`SRCDTA`) | Record length |
  | --- | --- | --- |
  | `QRPGLESRC` | **100** | 112 |
  | `QPNLSRC` | **134** | 146 |
  | `QTXTSRC` | **132** | 144 |
  | Everything else — `QCLSRC`, `QCMDSRC`, `QSQLSRC`, `QDDSSRC`, `QREXSRC`, `QMNUSRC`, … | **80** | 92 |

  **Measure against the `SRCDTA` column, never the record length.** A source
  physical file record carries a 12-byte prefix — a 6-byte sequence number and a
  6-byte date — that is not part of your line. Quoting the record length as a
  line limit hands you 12 characters that do not exist, and the overflow is
  discovered by truncation. That mistake is exactly how the `XFENV.SQLT` lines
  below got through review at 81 and 83 characters in an 80-column file.

  RBUTL practice is ~76, and these are a limit rather than a budget to spend.

  **Nothing warns you when you exceed it.** The line is cut when the member is
  written or transferred, and the loss surfaces later as a compile failure — or
  worse, as code that still looks right with a character missing. The dangerous
  case is a truncated string literal: lose the closing quote and the parser runs
  on into whatever follows, so the error is reported nowhere near the damage.
  This has actually happened here (`XFENV.SQLT`, two `LABEL ON COLUMN` lines at
  81 and 83 characters in an 80-wide file, both cut to exactly 80). Any tool that
  rewrites source in bulk will do this to every over-length line at once.

  **An over-length line is not the only cause of truncation, and the symptom is
  identical.** A build or source-manipulation tool that stages members through a
  work file — typically `QTEMP/QSQLSRC` or `QTEMP/QSQLTEMP` — truncates to
  *that* file's record length, whatever your lines measure. If the work file was
  created earlier by something else, at the wrong width, it persists for the life
  of the job and silently cuts every member that passes through it.

  Diagnose in this order:

  1. **Measure the longest line in the member.** If nothing exceeds the limit in
     §1.4, the member is not the problem and no amount of reformatting will fix
     it. Verified `XFBLD.SQLT`, whose longest line was 79 in an 80-column file,
     while the build still failed.
  2. **Delete the QTEMP work files and let the system recreate them** —
     `DLTF QTEMP/QSQLSRC`, and `QTEMP/QSQLTEMP` with it. Recreated on demand,
     they come back at the correct width.

  The failure surfaces from wherever the truncated text lands, which is rarely
  where the truncation happened. A compound `CREATE OR REPLACE` built as dynamic
  SQL goes to the SQL precompiler, which generates C and compiles it — so a cut
  line is reported as a **C compile error**, naming neither your member nor the
  work file. Balanced quotes plus a C-level error is the signature: the source is
  fine and something between it and the compiler is not.

  - **Hybrid RPG** (no `**FREE`): fixed-form specs are, well, fixed — their
    columns aren't a style choice. Free-form lines in a hybrid member must fit
    **columns 8–80** whatever the record length, because the compiler does not
    read free-form code past column 80.
  - **PNLGRP:** a `:HELP` title that would exceed 80 stays on one line (see §6)
    rather than wrapping or being abbreviated — that is what the 134 is for.
- **Section separators:** a full-width comment rule between major sections and a
  shorter/dashed rule between minor groups:
  - RPG: `// ****...****` (major), `// ----...----` (minor)
  - CL/SQL: `/* ****...**** */`
  - PNLGRP: `.* ****...****` with a `.* Title` + `.* -----` underline per section
- **Blocks read top-down:** mainline first, error handling next, subroutines/
  procedures last, each introduced by a one-line comment saying what it does.

### 1.5 Naming and member families

- **Prefixes:** `TM*` / `*TM` = Task Manager, `RB*` = developer utilities,
  `BS*` = BSLIB personal utilities. `JUNK*` = scratch (never promote, git-ignored).
- A user-facing command is a **family sharing one base name**:
  - `QCMDSRC/NAME.CMD` — command definition (`HLPPNLGRP(NAME)`, `MSGF(TMMSG)`)
  - `QCLSRC/NAME.CLLE` or an RPGLE — command-processing program (CPP)
  - `QPNLSRC/NAME.PNLGRP` — command help
  - messages come from the shared `TMMSG` message file (`QREXSRC/TMMSG.REXX`)
- **RPG member suffixes:** base name = program/entry, `…H` = prototypes/constants
  copybook, `…P` = service-procedure implementations. Example: `RTVLOCTM` +
  `RTVLOCTMH`. An `…R` suffix (subprocedure-only module, e.g. `SQL2XLSXR`)
  appears in third-party code and tool-generated members — recognize it as a
  pattern, but it is not required for new members.
- Related CRUD commands funnel into one shared CPP distinguished by a
  `CONSTANT(*ADD|*CHANGE|…)` MODE parameter (e.g. `TMACRUSR`, `TMCCDTSK`).
- **Symbol namespaces — use the full object name, never a truncation.**
  A member that publishes names into other members — any `…H` copybook, and
  the `…P` implementation copybook that goes with it — prefixes **every**
  constant, template, and procedure it publishes with its own full name.

  **The namespace exists to prevent collisions, and that is a requirement, not
  a preference.** Every name a member publishes lands in the symbol table of
  every program that pulls it in, alongside the names from every other member
  pulled into the same program. Without a namespace those names compete, and
  the failure is a compile error at best and the wrong procedure at worst.
  That a prefix also tells a reader where a name came from is a large bonus —
  but it is the bonus, not the reason. Do not weigh the bonus against the cost
  and conclude a namespace is optional; the requirement is not negotiable.

  | Kind | Form | Example |
  | --- | --- | --- |
  | Constant | `@FULLNAME_SCREAMING_SNAKE` | `@GUXLINF_ATR_MAX` |
  | Template | `fullname_lowercase_t` | `guxlinf_infatr_t` |
  | Procedure | `fullname_camelCase` | `guxlinf_getSheetName` |

  The namespace is the object name **in full**. An older IP convention dropped
  the two-character application id and namespaced on the remainder — `GUXLINF`
  publishing `xlinf_*` — and that is no longer used anywhere. Do not
  reintroduce it, and never mix the two within one member: `@GUXLINF_ATR_MAX`
  sitting beside `xlinf_infatr_t` is the specific defect this rule exists to
  prevent. The full name is what a reader greps for and what `WRKOBJ` shows;
  a truncation is a second name for the same thing.

  This applies to a `/copy` copybook exactly as it does to a bound service
  program — a copy member's names carry the same collision exposure as a
  `*SRVPGM`'s exports, which is why `GUSQCPYP` namespaces its procedures
  despite being copied rather than bound.

  **A copybook shared by only one closed family of programs is not exempt.**
  The argument for exempting one is that nothing outside the family will ever
  pull it in, so nothing can collide — but that premise is a claim about the
  future, and the include graph is what actually decides it. Copy members
  include each other, sometimes mutually behind their guards, so a member
  three includes away can acquire the whole set without anyone intending it.
  Check before believing the premise, and expect it to have already failed.
  `TMXXXWRKH` is the worked example: it serves the `WRK*TM` panel family, yet
  `RTVLOCTM` — a retrieve CPP, not a panel program — receives every one of its
  names through `RTVLOCTMH`, which `TMXXXWRKH` in turn includes.

  Two things keep their own names rather than taking the copybook's:

  - **External-file templates**, which are namespaced by the table they
    mirror — `dcl-ds tmusr_t extname('TMUSR')`. Two copybooks may declare the
    same one behind an `/IF NOT DEFINED` guard so both can be pulled in.
  - **Names owned by IBM or a third party** — the C types that arrive with
    `/copy QSYSINC/QRPGLESRC,IFS` (`size_t`, `mode_t`, `pid_t`), IBM API
    structure names, and third-party members, which keep their original
    spelling so they still match the documentation.

  Constants are namespaced by **what they describe**, which is not always the
  member that declares them. Three cases, all correct:

  - **Owned by the publishing member** — `@GUXLINF_ATR_MAX`. Takes the
    member's full name, as above.
  - **Owned by another object** — `@WRKOBJTM_PNLID` belongs to the `WRKOBJTM`
    panel group (see section 6), `@QUIM_*` to UIM. Takes that object's name,
    which is what keeps the panel-group constants matching their `:VARRCD`
    and `:LISTDEF` names.
  - **Owned by a concept rather than an object** — `@OPTNBR_*` for list option
    numbers, `@QUALOBJ_*` for qualified object names. There is no object to
    name, so a stable category prefix serves.

  The third case is a **fallback that has to be justified, not a free choice**.
  Use it only when no object owns the concept; if one does, its name wins. The
  risk being accepted is that nothing stops a second member declaring its own
  `@OPTNBR_*`, and two copy members pulled into one program would compete.
  That surfaces as a duplicate-definition compile error where the collision
  happens rather than as wrong behaviour at run time, which is what makes it
  tolerable — but only while the set of programs that can see the constant
  stays small.

  **`@SQLCODE_*` was in this list and has been taken out of it, which is the
  case working as intended.** The SQLCODE values had no owner, so three
  separate members each declared their own — and the moment two of them could
  be pulled into one program, the category prefix was a collision waiting to
  happen. Giving them an owner resolved it: `GUSQCPYH` already published
  `@GUSQCPY_SQLSTATE_CLASS_*`, so SQLCODE belonged beside it as
  `@GUSQCPY_SQLCODE_*`. **When a concept turns out to have a natural owner,
  move it — the fallback is not a resting place.**

  **So category prefixes must not appear in a general-use copybook.** A member
  written to be pulled in broadly — the API wrapper copybooks (`QAPIH`,
  `QILEH`, `QUIMH`), a library-wide utility header, anything a new program is
  expected to `/copy` as a matter of course — declares **only** constants in
  its own namespace. Two reasons: its reach is exactly what makes a category
  name likely to collide, and every name it declares is imposed on every
  consumer whether that consumer wants it or not. A category prefix is only
  defensible where the consumer set is bounded and known, as in a copybook
  serving one application family. Test it by asking who can see the constant:
  if the answer is "anything that might be written later," take the member's
  namespace instead.

  So the rule is that a namespace is the full name of whatever owns the
  symbol — not that every symbol in a file carries that file's name.

  Local subprocedures inside a single program are not published and take the
  plain `<verb><Object>` form of section 2.5.
- **Object-role suffixes.** Object names follow a 2+2+3 shape — application,
  area, object. Where the third element has no entity to describe, because the
  object is infrastructure rather than application, it names the object's
  **role** instead. These are reserved across all repos:

  | Suffix | Object type | Role |
  | --- | --- | --- |
  | `…SRV` | `*SRVPGM` | Bound service program — the API other programs call |
  | `…AGT` | `*PGM` | Agent — a never-ending job that processes queued work |
  | `…REQ` | `*FILE` | The request table an agent drains |
  | `…DTQ` | `*DTAQ` | Data queue, where one is used as a doorbell |

  `SVR` is **never** used for a service program. `SRV` and `SVR` sort adjacent
  in `WRKOBJ`, are one transposition apart when typing, and are
  indistinguishable when spoken aloud. Pick `SRV` and never write the other.

  Prefer a role suffix that stays true for the whole life of a row or object.
  `…REQ` beats `…QUE` for the request table because a sent row is still a
  request that was fulfilled, whereas it is no longer queued — and because
  `QUE` reads as `*DTAQ`/`*MSGQ` in an object listing.

### 1.6 Agents — the never-ending job pattern

An **agent** (`…AGT`) is a submitted job that runs indefinitely: it wakes on a
timer or a queue, does one unit of work, and goes back to sleep. This is what an
AS/400 shop has always called a *server job* or a *NEP* (never-ending program) —
the pattern is old, only the name is new.

`AGT` is the right name for it because the term already belongs to this
platform: `STRAGTSRV` / `ENDAGTSRV` and the `CMDAGT` menu are IBM's own
Electronic Service Agent. "Service Agent" there is a compound proper noun for an
IBM facility, not a composition of the `SRV` and `AGT` suffixes, so there is no
conceptual collision with a `…SRV` service program. The alternatives lose:
`MON` implies passive watching or dispatch only, when the job actually acts;
`DMN` is Unix vocabulary and misreads as "domain".

A subsystem built this way is a **family of four**, named together:

| Member | Type | Responsibility |
| --- | --- | --- |
| `xxSRV` | `*SRVPGM` | Validates and enqueues. What applications bind to. |
| `xxREQ` | `*FILE` | The request rows. System of record. |
| `xxAGT` | `*PGM` | Drains ready rows, dispatches, housekeeping, breaker. |
| `xx<verb>` | `*PGM` | Performs one unit of work, records its disposition. |

Rules that keep the family honest:

- **The agent and the worker are separate programs — never one program with a
  mode parameter.** A bare `CALL` on a merged program starts a second
  never-ending job draining the same queue, which is lock contention at best and
  duplicate work at worst. The job log stops distinguishing the all-day daemon
  from a single unit of work. And the two have genuinely different lifecycles:
  the agent holds file opens and state across thousands of iterations, while the
  worker opens, works, and ends. Merging them means conditional initialization
  inside a NEP, which is where the subtle bugs live.
- **The worker writes the row's final status; the agent never does.** The agent
  reads return codes only for its own arithmetic. Two writers to one status
  column works fine until a unit of work takes longer than expected.
- **The agent claims the row before dispatch; the worker takes a lock.**
  The agent moves the row out of the ready status and stamps a *claim timestamp*
  before it calls or submits the worker. It has to: `SBMJOB` returns as soon as
  the job is queued, so a row left in ready status is re-selected and submitted
  again on the agent's very next pass.

  The worker then **fetches the row by key *and expected status*, with a lock,
  and holds that lock for the whole unit of work.** Put the status in the
  predicate rather than testing it after the read — a row in the wrong status is
  simply not found, so there is no lock to release and no branch to get wrong.
  Not found is a silent no-op: no error, no escape, just a diagnostic in the job
  log. The lock — not the predicate by itself — is what serializes two workers,
  keeps a human from re-flagging mid-flight, and lets an accidental double
  dispatch resolve itself.
  - Name the claimed status for what is true of it. A submitted row can sit on a
    job queue for a long time, so *queued* is honest where *running* or *sending*
    would not be.
  - **The worker stamps its own qualified job name** when it accepts the row —
    not the agent, which would have to dig the job id out of `SBMJOB`'s
    completion message. Leaving the column empty until a worker actually starts
    is the more useful design anyway: it lets the sweep tell "never started"
    (dead job queue, held subsystem) from "started and died," which recover
    differently.
  - **The worker registers a termination handler**, sets a flag while it holds a
    locked row, and has the handler record the failed status and release. An ILE
    cancel handler (`CEERTX`) or RPG `ON-EXIT` covers unhandled exceptions,
    function checks, and `ENDJOB`/`ENDSBS *CNTRLD`. This is the primary recovery
    path: the outcome is recorded by the job that knows what happened, seconds
    after it happens, instead of being inferred later by another program.
    - It does **not** run for `ENDJOB *IMMED`, system failure, or abnormal IPL.
    - The handler usually cannot know whether an external side effect already
      succeeded, so word its disposition as *the job ended abnormally* — not
      *the work was not done*. Only the first is true.
  - **The sweep is a backstop, not the recovery path.** With a termination
    handler in place it exists for the cases where no program was alive to record
    anything: a worker that never started, and one killed outright. It reads
    without locks — reasoning about rows, not changing them — and thresholds on
    the claim timestamp, which covers the legitimate gap between claim and pickup.
  - **Recover by returning the row to the ready status, not by re-dispatching
    it.** The agent picks it up again through the normal path, so the sweep never
    duplicates dispatch logic; the trigger clears the claim fields on the way
    through; and it throttles itself, because a recovered row is immediately
    re-claimed with a fresh timestamp and cannot re-qualify until the threshold
    passes again. Re-dispatching in place leaves the original timestamp untouched
    and re-qualifies the same rows every tick, each one adding another worker to
    the queue it is already waiting on.
  - **Recovery is only free where nothing was done yet.** The lock serializes
    concurrent workers; it says nothing about a sequential one. A worker that
    completed an external side effect and died before recording it leaves a row
    that looks identical to one never started — recovering it does the work
    twice. Use the worker-stamped job name to tell them apart: absent means
    nothing started; present means the outcome is unknowable and the decision
    belongs to whatever low-stakes/high-stakes split the subsystem already has.
  - **Every side effect of a status change belongs in the table's trigger, not
    in the programs.** Programs set the status; the trigger does the rest, keyed
    on a status *change* (compare `OLD` to `NEW`, and let an unchanged status
    fall through so the worker can stamp its own job name). Statuses that re-arm
    a row clear the outcome fields — a retried request must not carry the
    previous attempt's error text — while statuses that record an outcome leave
    them alone. Done in the programs instead, the fields are only as honest as
    the last one to touch the row, and say nothing about the green-screen path
    where someone re-runs work by typing over the status. In the trigger, no
    path can forget, including paths that do not exist yet.
  - **A processed timestamp, set by the trigger only on the terminal statuses**,
    and cleared when a row is re-armed. Null for in-flight rows and non-null for
    finished ones, it makes "not yet processed" a property of the data rather
    than a list of status codes each query has to know, and the retention pass
    selects on it without status logic.
  - **Time in-flight rows by `audit_timestamp`**, not by their created timestamp.
    A row's age since *creation* says nothing about how long it has been claimed:
    after an agent outage, every row it then claims would look instantly stale
    and a recovery sweep would start fighting the agent that just claimed them.
    The mandated `audit_timestamp` moves on any update, so for a claimed row it
    means "nothing has touched this since," which is the actual question — and it
    costs no extra column.
  - **Age unprocessed rows separately from processed ones, and never delete them
    silently.** Retention on finished rows is routine; a row that grows old while
    still in flight is evidence of a bug or an outage, and deleting it destroys
    the only record that the work never happened. Move it to the failed status
    with a disposition saying it expired unprocessed, alert out of band, and let
    it age out through the normal retention path.
  - **Do not pre-load the worker's job name at claim time**, even where it is
    technically available (an inline path knows its own job; a submitted one can
    recover the job id from `SBMJOB`'s `CPC1221`). The column earns its place by
    meaning "a worker picked this row up." Fill it at claim time and every row
    has a name from the moment it is claimed, the never-started and died-midway
    cases become indistinguishable, and recovery is back to guessing. The empty
    column is carrying information.
  - **The agent must release its own claim lock before dispatching.** On an
    inline path the worker runs in the *same job* and requests the same record
    through its own open, which is a lock conflict rather than a free pass. This
    works in isolation and fails when the two programs are first wired together,
    so prove it early.
- **Decide what recovering an orphaned row means before writing the sweep.**
  There is always a window where the worker finished its unit of work but died
  before recording the outcome, so requeueing risks doing the work twice while
  failing the row risks not doing it at all. Choose per the cost of each — and
  where the subsystem already distinguishes low-stakes from high-stakes work,
  let that existing split decide rather than inventing a second one.
- **Shut down by flag, not by cancel.** A run/stop indicator in a data area or
  control record, tested at the top of each pass, ends the job cleanly between
  units of work rather than mid-unit.
- **Whatever the agent talks to** — a command, an API, an external transport —
  **appears in exactly one program**, so replacing it touches one object.
- **Count failures for the circuit breaker where every path is visible.** An
  agent that both calls a worker inline and submits it for some rows sees return
  codes only on the inline path. Counting recent failures during the housekeeping
  pass catches both, and also catches submitted jobs that died without writing
  back.

---

## 2. RPGLE / SQLRPGLE

### 2.1 Form

- **All new RPG is fully free-form:** `**FREE` on line 1, column 1.
- Use `.SQLRPGLE` when the member contains embedded SQL, `.RPGLE` otherwise.
- Never write new fixed-form or hybrid code. Convert opportunistically when a
  fixed member needs nontrivial changes (CVTRPGFREE/CVTRPG1511 tools exist for
  this).
- When maintaining fixed-form **D specs**: subfields indent the **name only**,
  by one space — nothing else shifts. Keywords always start in the first
  column of the keyword area (column 44); don't stagger them per line:

  ```rpgle
       D PgmSts         SDs                  Qualified
       D  PgmNam           *Proc
       D  CurJob                       10a   Overlay( PgmSts: 244 )
       D  UsrPrf                       10a   Overlay( PgmSts: 254 )
  ```

### 2.2 Header and control options

```rpgle
**FREE
///
//  Retrieves the attributes for the requested location.  If the
//       location has not been setup in the Task Manager, default
//       values will be returned.
//
//  MODIFICATIONS:
//  BS  08/03/25  Created.
//  @@
///
//  *>  <BLDOBJ CRTDFT/>
//  *>  <BLDOBJ EOF/>

ctl-opt copyright('(c) Copyright Godsend Consulting, 2020-2026');
ctl-opt option(*NODEBUGIO: *NOUNREF);
ctl-opt debug(*CONSTANTS);
ctl-opt decedit('0.');
ctl-opt expropts(*ALWBLANKNUM: *USEDECEDIT);
ctl-opt extbinint(*YES);
/IF NOT DEFINED(*CRTRPGMOD)
ctl-opt dftactgrp(*NO);
ctl-opt actgrp(*CALLER);
/ENDIF
```

- One keyword per `ctl-opt` statement, `copyright` first.
- The standard option set is exactly the block above. Add `bnddir(...)`,
  `alwnull(*USRCTL)`, etc. only when needed.
- Guard binding-only keywords with `/IF NOT DEFINED(*CRTRPGMOD)` so the member
  compiles as either a bound program or a module.
- Activation group: `*CALLER` for called/service-style programs; `*NEW` for
  top-level interactive programs (work-with panels, menus).

### 2.3 Copybooks (`…H` members)

- Include with `/copy qrpglesrc,membername` (lowercase, no library).
- **Every copybook starts with an include guard, and the guard comes FIRST** —
  immediately after `**FREE`, ahead of the purpose comment, the `MODIFICATIONS`
  log and the `BLDOBJ` directives:

  ```rpgle
  **FREE
  /IF DEFINED(TMXXXWRKH)
  /EOF
  /ENDIF
  /DEFINE TMXXXWRKH

  //  Purpose of the member ...
  //
  //  MODIFICATIONS:
  //  BS  08/20/26  Created.
  //  @@
  //  *> <BLDOBJ TEXT="..."/>
  ```

  **The order matters because of what reads the member.** `BLDOBJ` does not
  inline copy members today, but the SQL precompiler does: it builds an exploded
  copy of the source before compiling, with every `/copy` expanded in place. On a
  second inclusion the guard's `/EOF` stops that expansion — but only from the
  `/EOF` onward. **Anything above it has already been read**, on every inclusion.

  Comments above the guard are harmless, which is why an existing member carrying
  its purpose block on top is not a defect worth a sweep. A **compiler directive**
  above it is not harmless: a `/DEFINE`, `/SET` or `/COPY` placed there is acted
  on again on the second inclusion, which is the thing the guard exists to
  prevent. Nothing marks that boundary, so the safe rule is the simple one — put
  the guard first, and there is no "is this line safe above the guard" question
  left to get wrong later.

  A member-level `///` ILEDoc block on a copybook buys nothing: ILEDoc documents
  symbols, and a copy member is not one. Use plain `//` for the header comment
  and keep `///` for the constants, templates and prototypes inside.

- A copybook contains, in order: nested `/copy` of its dependencies, named
  constants, data-structure templates, then prototypes. Terminate each group with
  a separator rule.
- Everything a copybook publishes carries the copybook's **full** name as its
  namespace — `@GUSQCPY_*`, `gusqcpy_*_t`, `gusqcpy_*` — including the `…P`
  member's procedure bodies. See section 1.5 for the rule and its two
  exceptions.
- Shared IBM API prototypes live in the `QAPIH` (QUS*/QMH* APIs), `QILEH` (ILE
  CEE/QSN), and `QUIMH` (UIM) copybooks — extend those rather than redeclaring
  APIs inline.
- Document every prototype with a `///` doc block in **ILEDoc format**:
  one-line summary, `@param` per parameter, `@return` when a value is
  returned. Doc commands are lowercase (`@param`, `@return`); use `@return` —
  `@returns` (with an s) is not supported.

### 2.4 Declarations

- **Constants:** SCREAMING_SNAKE_CASE prefixed with `@` (C-style), grouped by
  topic: `dcl-c @QUIM_FNCKEY_ENTER 1;`, `dcl-c @GUSQCPY_SQLCODE_NODATA 100;`
- **Templates:** all-lowercase name with a `_t` suffix — "My Template
  Variable" becomes `mytemplatevariable_t` — declared `template qualified inz`,
  and namespaced with the publishing member's full name (section 1.5):

  ```rpgle
  dcl-ds tmxxxwrk_usrlste_t   template qualified inz;
    opt            Int(5);
    usrPrf         Char(10);
  end-ds;
  ```

  Instances drop the namespace, since they are local:
  `dcl-ds usrLstE likeds(tmxxxwrk_usrlste_t) inz(*LIKEDS);`
- **External-file templates:** one per table, used for `like()` typing and fetch
  buffers. These are namespaced by the table, not by the copybook, so two
  copybooks may declare the same one behind an `/IF NOT DEFINED` guard:

  ```rpgle
  dcl-ds tmusr_t  extname('TMUSR') inz(*EXTDFT) qualified template;
  end-ds;
  ```

- Type fields with `like(...)`/`likeds(...)` against templates or other fields —
  avoid re-hardcoding lengths.
- **Casing:** camelCase for variables, procedures, and DS subfields; type
  keywords capitalized (`Char`, `Varchar`, `Int`, `Uns`, `Packed`, `Ind`,
  `Timestamp`); all other keywords lowercase — opcodes, declarations, and
  control words (`dcl-s`, `dcl-ds`, `ds`, `begsr`, `exsr`, `endif`) and BIFs
  (`%scan`, `%char`, `%trim`); figurative constants and compiler values
  uppercase (`*ON`, `*OFF`, `*BLANK`, `*NULL`, `*VARSIZE`, `*ESCAPE`,
  `*LIKEDS`).
- Align the type column within a declaration group; separate groups with blank
  lines or minor rules.
- Entry parameters take a `px` prefix (`pxTskName`); indicators declare `Ind`;
  cursors are named `csrXxx`.

### 2.5 Program structure

- **Entry:** the program's `dcl-pi PGMNAME` sits directly under a `// *ENTRY`
  marker, immediately after `/copy` of the program's own `…H` copybook (the
  copybook carries the matching `dcl-pr … extpgm('PGMNAME')`).
- **Mainline** is linear cycle-main code introduced by a `/// main() ///` doc
  block. It delegates to subprocedures and ends with `exsr exitPgm` / `return`.
- Use **subroutines** (`begsr`) only for mainline flow plumbing: `exitPgm`
  (set `*inLR`, close handles) and `*inzsr` (one-time init, cursor DECLAREs).
  All real logic goes in **subprocedures** (`dcl-proc`).
- Name subroutines — and subprocedures — `<verb><Object>` in camelCase:
  `getItemHeader`, `loadList`, `sndStsMsg`, `exitPgm`. A subprocedure that is
  published to other members through a copybook takes the namespace of
  section 1.5 in front of that name — `tmxxxwrk_sndStsMsg`.
- Every procedure carries a `///` doc block (ILEDoc, see 2.3): a one-line
  short description, then `@param` and `@return` lines as needed.
- Subprocedure skeleton:

  ```rpgle
  ///
  // Loads a panel work with ... list
  //
  // @param hdl        Panel handle
  // @param refreshDta Refresh the list data before loading
  // @return *ON when the list is not positioned at the first entry
  ///
  dcl-proc loadList;
    dcl-pi *N Ind;
      hdl            Char(8)    const;
      refreshDta     Ind        const options(*NOPASS);
    end-pi;
    // ----------------------------------------------------------------

    dcl-s rcdNam       Char(10);
    // ----------------------------------------------------------------

    ...body...
    return endOpt <> @QUIM_LSTPOS_FIRST;
  end-proc;
  ```

  `dcl-pi *N`, locals after a minor rule, single exit where practical.
- Parameters are `const` unless returned; use `options(*NOPASS)` /
  `options(*OMIT: *NOPASS)` for optional parameters. Test them with:

  ```rpgle
  if %parms() >= %parmnum(topEnt) and %addr(topEnt) <> *NULL;
  ```

- Prefer modern expression forms: `%char(%date(): *ISO0)`, `snd-msg`, and the
  `IN` operator — which has one rule attached to it.
- **ALWAYS parenthesize an `in %list(...)` test.** Write it

  ```rpgle
  if (needle in %list('stack1': 'stack2'));
  if not (needle in %list('stack1': 'stack2'));
  ```

  A bare `if needle in %list(…)` on its own **evaluates correctly** — IBM gets
  that case right and there is nothing to fix in existing code that reads this
  way. The rule is not about the statement as written; it is about the statement
  as it will be edited.

  **`not` binds tighter than `in`.** Put a `not` in front of an unparenthesized
  test and it negates the **needle**, then searches the list for *that* — it does
  not negate the result of the search. The comparison still runs, still returns
  something, and the program carries on with the wrong answer. No compile error,
  nothing to see in the source. The same exposure applies once the condition
  grows an `and` or an `or`.

  So the parentheses are insurance against the edit, not a fix for the
  expression. `if needle in %list(…)` is correct today and becomes silently
  wrong the moment somebody adds a `not` in front or joins another condition to
  it — and that somebody will not stop to re-check operator precedence first.
  Parenthesizing always costs nothing and removes the trap.

  **The fragility is also how the unprotected form keeps creeping in.** Nothing
  pushes back on it: it compiles, it runs, and it is right. Every other bad
  habit eventually meets a compile error or a failing test, so it gets trained
  out; this one never does, and spreads unopposed. That is why the rule is
  absolute rather than a preference — the parentheses have to come from the
  standard, because they will never come from the feedback.

  **Balance the siblings.** Once one operand of an `and`/`or` is parenthesized,
  parenthesize the others so the alternatives read as parallel:

  ```rpgle
  when (srcType in %list(@SRCTYPE_RPGLE: @SRCTYPE_SQLRPGLE))
      or (%scan('RPG': srcType) > 0);

  if (objType = @OBJTYPE_FILE)
      and (%subst(objName: 1: 3) in %list('PRT': 'WRK': 'WSN'));
  ```

  The parentheses arrive for the `in %list()`, but leaving the other side bare
  makes the two sides look like different kinds of thing when they are the same
  kind of thing. This applies to **expressions** — a comparison, a BIF result
  being tested. A bare indicator or boolean variable is already atomic and gains
  nothing: write `when isNative and (inBldDir in %list(…))`, not
  `when (isNative) and (…)`.

  **Do not read this as C-style `if (condition)`.** The parentheses go around
  each operand, never around the whole condition — that is a different language's
  convention and RPG has no use for it.

  There is also **no `NOT IN` operator**: `needle not in %list(…)` does not
  compile. The negation goes in front of the parenthesized test.
- Indent 2 spaces per level. Continuation lines indent 4 spaces; when breaking a
  parameter list, lead continuation lines with the `:` separator:

  ```rpgle
  quim_displayPanel(hdl: fncKey: pnlIDName: @QUIM_REDISPLAY_YES
      : errc0100: @QUIM_USRTSK_OLD
      : msgRefKey);
  ```

### 2.6 Error handling and messages

- Call APIs through the `qapi_*`/`quim_*`/`qile_*` wrappers with an
  `errc0100` structure (`likeds(qapi_errc0100_t)`); `reset errc0100;` and set
  `bytPrv` before each call, then test `bytAvl`.
- Use `callp(e)` + `%error()` for tolerated command failures; escalate with
  `snd-msg *ESCAPE %msg(...) %target('*PGMBDY': 1);`.
- **"Qualified" and "fully qualified" are two DIFFERENT layouts, and the
  component order is reversed between them.** The terms differ by one word and
  are used in different contexts, which is the whole difficulty:

  | Term | Bytes | Layout | Where it appears |
  | --- | --- | --- | --- |
  | **fully qualified** | up to 21 | `LIB/NAME` — library first, slash, name | what a user *types*; what `%msg` accepts |
  | **qualified** | 20 | `NAME` in 1–10, `LIB` in 11–20 — name first, no slash | what a `QUAL` parameter *delivers to the CPP*; what the `QMH*` APIs take |

  So typing `MSGF(MSGLIB/MSGF)` hands the CPP `'MSGF      MSGLIB    '`. The
  library leads on the way in and the name leads on the way out. This is the same
  inversion that makes the `PGMXRF` convention work (§5): the two `QUAL`
  constants are written *CPP then command*, so the compiled reference arrives
  with the CPP in the object field and the command name in the library field.

  **This is not a battle worth fighting on the word alone.** "Qualified" is too
  overloaded across IBM's own documentation, the API reference and the command
  reference for the adjective to carry the meaning by itself, and no house
  convention will change that. So do not depend on it: when the layout matters,
  **name it** — say "20-byte", or write `LIB/NAME`, or say "as the CPP receives
  it". Context is what disambiguates, so supply the context.

- **`%msg` takes the message file as a name — plain or FULLY qualified, never the
  20-byte form.** It accepts `MSGF`, `MSGLIB/MSGF` and `*LIBL/MSGF`, so a
  variable holding one needs room for 21 characters. Name the file from a
  constant rather than a literal, and pick the right constant — `QAPIH` publishes
  two that look interchangeable and are not:

  | Constant | Value | For |
  | --- | --- | --- |
  | `@QAPI_QCPF_MSGF_NAME` | `'QCPFMSG   '` | `%msg` — a 10-byte name, trailing blanks ignored |
  | `@QAPI_QCPF_MSGF` | `'QCPFMSG   *LIBL     '` | `QMHSNDPM` and friends — the 20-byte qualified form |

  Passing `@QAPI_QCPF_MSGF` to `%msg` is wrong even though it compiles and looks
  deliberate: `%msg` would read the whole 20 bytes as one name.
- Status messages go through a small `sndStsMsg` procedure (CPDA0FF / *STATUS);
  clear with a blank message when done.

### 2.7 Embedded SQL

- `exec sql` on its own line; the statement indented under it.
- SQL keywords UPPERCASE; table/column names lowercase; host variables
  `:camelCase` (qualified DS subfields allowed: `:recUsr.usrPrf`).
- Continuation style: **leading commas**, 2-space progressive indent:

  ```rpgle
  exec sql
    SELECT a.usrPrf
        , a.grpPrf, a.usrName, a.emlAdr
      INTO :recUsr
      FROM tmusr a
      WHERE a.usrPrf = :usrPrf;
  ```

- Alias every table (`a`, `b`; `z` for innermost subselects) and qualify every
  column.
- Singleton reads end with `FETCH FIRST 1 ROWS ONLY`.
- Bulk reads use a `DECLARE`d cursor + multi-row fetch into a `dim(...)` DS
  array, then `CLOSE`; row count from `sqlEr3`:

  ```rpgle
  exec sql
    FETCH csrUsrs FOR :@WRKUSRTM_USRS_MAX ROWS INTO :recUsrs;
  ```

- `DECLARE CURSOR` belongs in the mainline/`*inzsr`, **not** in a subprocedure
  (activation-group/scoping surprises).
- Test `sqlcode` against named constants — `@GUSQCPY_SQLCODE_SUCCESS`,
  `@GUSQCPY_SQLCODE_NODATA` from `GUSQCPYH` —
  right after each statement; reset stale state (e.g. counts) before reuse.

---

## 3. CL / CLLE

`QCLSRC/TEMPLATE.CLP` is the canonical skeleton — start new programs from it.

### 3.1 Member type and header

- New CL is **CLLE** (`.CLLE`). `.CLP` remains only for legacy/OPM-specific cases.
- Header: purpose comment, `MODIFICATIONS:` log (comment lines continued with
  `+`), BLDOBJ directives, then:

  ```text
             PGM        PARM(&TSKNAME &#TOLOC ... &PGMXRF)
             COPYRIGHT  TEXT('(c) Copyright Godsend Consulting, 2020-2026')
             DCLPRCOPT  DFTACTGRP(*NO) ACTGRP(*CALLER)
  ```

### 3.2 Layout

- Keyword form always — `DCL VAR(&X) TYPE(*CHAR) LEN(10)`, never positional
  (except `CMD`/`PARM` positional prompts where conventional).
- **The layout is what `F4=Prompt` produces.** That is the whole rule, and
  everything below follows from it: prompting emits keywords in **command
  definition order**, aligns the columns, and wraps at keyword boundaries. When
  in doubt about a statement's shape, prompt it and keep what comes back.

  The one thing prompting does not do is **indent** — SEU has no concept of
  block level, so the nesting in the table below is the house addition. (A VS
  Code formatter appears to apply the same rules *with* indentation, but driving
  it would mean a round-trip syntax check per line, which is far too slow to
  use in bulk.)

- **Columns follow standard CL prompting.** The command name occupies a 10-wide
  field followed by one blank, so the keyword column is always the command
  column **+ 11**:

  | | Command | Keywords | Wrapped keywords |
  | --- | ---: | ---: | ---: |
  | Top level | **14** | **25** | **27** |
  | Inside one control block | 16 | 27 | 29 |
  | Inside two | 18 | 29 | 31 |
  | …each level | +2 | +2 | +2 |

  **A subroutine is a control block.** `SUBR`/`ENDSUBR` sit at column 14 and the
  body starts at 16 — which is a good reason to prefer `SUBR` over wrapping work
  in a `DO`, since it costs no extra level.

  - **Labels** start in column 2 on their own line, at any depth.
  - **`DCL` with `STG(*DEFINED)`** is indented 2 under the variable it overlays,
    shifting the line and its continuations right by 2 like any other level.
  - **Comments start in column 1**, not the command column, and then follow the
    indentation level like anything else: column 1 at top level, 3 inside a
    subroutine, 5 inside a block within it. Continuations align under the
    comment text.
  - Stay within the 80-column `SRCDTA` limit (§1.4) at every level; deeper
    nesting spends the same budget.

- **Wrap on a keyword boundary.** Given
  `MYCMD KWD1(xxx) KWD2(yyy) KWD3(zzz)`, break so the continuation *starts* with
  a keyword rather than splitting one across lines:

  ```text
             MYCMD      KWD1(xxx) KWD2(yyy) +
                          KWD3(zzz)
  ```

  Two things the column rules do not govern, so do not "correct" them:

  - **A command name longer than 10 characters** — a fully qualified name such as
    `HAWKEYE/DSPFILSETUP` — pushes its keywords right of the nominal column. The
    field cannot hold it; nothing is wrong.
  - **Large literals — SQL statements, built command strings — break the column
    rules on purpose, so the literal stays readable.** The command itself follows
    the normal columns; the *content* is laid out as what it is:

    ```text
                   CHGVAR     VAR(&SQL) VALUE('+
    DELETE +
      FROM qtemp.' *CAT &OUTFILE1 *TCAT ' a +
      WHERE a.tudlib <> ''' *CAT &JC_LIB *CAT ''' +
                                ')
    ```

    The `CHGVAR` sits at its proper column, the SQL starts in column 1 and is
    indented by SQL rules (§4.6), and the closing `')` returns to the
    continuation column. `RUNSQL SQL('` takes the same shape.

    **Prefer this to concatenating a statement across CL continuations.** Wrapping
    SQL at CL keyword columns produces text that is legal and nearly unreadable —
    the statement's own structure disappears, and a reviewer cannot see the
    clauses. Readability of the literal outranks column discipline here, which is
    why the exception exists rather than being tolerated.
- Commands UPPERCASE; comments sentence case.
- **Block form for conditionals:** wrap `IF`/`ELSE`/`WHEN` bodies in
  `DO … ENDDO` even when the body is a single statement, so a block can grow
  later without rewriting the conditional. Recognized exceptions where a
  one-liner is fine: the standard STDERR handler (`IF COND(&STDERR)
  THEN(RETURN)` — the most common one, written verbatim across programs),
  the occasional `SELECT`/`WHEN` one-liner, and legacy code.

### 3.3 Declarations

Order after `PGM`/`COPYRIGHT`/`DCLPRCOPT`:

1. **Parameters**, in `PARM` order.
2. **`DCLF`** if the program reads a file (use `OPNID`).
3. **Named-constant style variables** (`DCL ... VALUE(...)`) used as enums,
   e.g. `&FROMTO_FRM ... VALUE(1)`.
4. **Locals, alphabetical.**
5. **`&STDERR` + the global MONMSG** (see 3.4) — always last.

- Structure overlays use `STG(*DEFINED)` with `DEFVAR`, indented two extra
  spaces under their base variable:

  ```text
             DCL        VAR(&JOBD) TYPE(*CHAR) LEN(20)
               DCL        VAR(&JOBD_NAME) TYPE(*CHAR) STG(*DEFINED) +
                            LEN(10) DEFVAR(&JOBD 1)
               DCL        VAR(&JOBD_LIB) TYPE(*CHAR) STG(*DEFINED) +
                            LEN(10) DEFVAR(&JOBD 11)
  ```

- Qualified-object parameters are `*CHAR 20` (name + library) split with
  overlays, as above.
- A parameter that can carry special values (`*SAME`, `*N`, generics) is named
  `&#NAME`; resolve it into a plain working variable `&NAME` before use.

### 3.4 Error handling — the STDERR pattern

Every program monitors globally and funnels to one handler:

```text
             DCL        VAR(&STDERR) TYPE(*LGL) VALUE('0')
             MONMSG     MSGID(CEE0000 CPA0000 CPD0000 CPF0000 +
                          CPI0000 CPP0000 MCH0000 QSH0000 PDM0000 +
                          RNI0000 RNQ0000 RNS0000 RNX0000 RPG0000 +
                          SQL0000 SQ20000 SQ30000 TCP0000 USR0000) +
                          EXEC(GOTO CMDLBL(STDERR))
   ...
/* Handles thrown errors */
 STDERR:
             IF         COND(&STDERR) THEN(RETURN)
             CHGVAR     VAR(&STDERR) VALUE('1')

/* Forward messages, resignaling escape message(s). */
             INCLUDE    SRCMBR(FWDMSGH) SRCFILE(QCLSRC)
             RETURN
```

- A module adds its own message prefix to the MSGID list — `XFF0000` for the
  Cross Reference. Task Manager adds `DEP0000 EXC0000 LOC0000 OBJ0000 TSK0000
  UIM0000`, six prefixes for one module — the standing exception of section 8.2,
  not the pattern to copy.
- The `&STDERR` flag prevents handler re-entry; `FWDMSGH` (QMHMOVPM +
  QMHRSNEM) moves diagnostics to the caller and resignals the escape — callers
  see the original error, not a generic one.
- **Expected** conditions are monitored per-command and cleaned up immediately:

  ```text
             CHKOBJ     OBJ(QTEMP/&OUTFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST) RMV(*YES)
               CHGVAR     VAR(&EXISTS) VALUE('0')
             ENDDO
  ```

  Always `RCVMSG ... RMV(*YES)` a handled message so the joblog stays honest.

### 3.5 Subroutines and flow

- Mainline delegates with `CALLSUBR`; `SUBR ... ENDSUBR` blocks sit after the
  STDERR handler, each preceded by a one-line comment. Use `RTNSUBR` for early
  exit. Standard names: `INITPGM`, `SNDSTSMSG`, plus task-specific ones.
- **`MONMSG` cannot follow `CALLSUBR`.** A monitor placed after a `CALLSUBR`
  does not catch what happened inside the subroutine — it attaches to the wrong
  statement. So a caller cannot trap an escape thrown by a subroutine it called.

  Where the caller must react rather than let the escape reach the STDERR
  handler, **monitor each statement inside the subroutine and return a code**:

  ```text
             CALLSUBR   SUBR(BLDONE) RTNVAL(&RC)
             IF         COND(&RC *EQ -1) THEN(GOTO CMDLBL(NEXTONE))
  ```

  with the subroutine ending `RTNSUBR RTNVAL(-1)` on the failure path. The
  return variable must be a **4-byte signed integer** — `TYPE(*INT) LEN(4)`.

  Reset the variable before the first call in a loop. After a failed iteration it
  still holds -1, and a subroutine that succeeds without an explicit
  `RTNVAL` will not necessarily clear it.

  Use this only for conditions the caller can act on — typically a property of
  the data being processed, where the next item may still succeed. A genuine
  error still escapes to the STDERR handler; converting those to return codes
  discards the message that says what went wrong.
- Optional parameters: `IF COND(%PARMS *GE n *AND %ADDR(&VAR) *NE *NULL)`.
- Work files live in `QTEMP`; inline SQL uses `RUNSQL ... COMMIT(*NONE)`;
  file repositioning uses `OVRDBF ... POSITION(*RRN &N) SECURE(*YES)` followed by
  `DLTOVR` — always scope and remove overrides.
- **Create an outfile explicitly, and remove its size limit.** Do not let the
  command that fills it create it as a side effect:

  ```text
             CRTDUPOBJ  OBJ(QADSPPGM) FROMLIB(QSYS) OBJTYPE(*FILE) +
                          TOLIB(QTEMP) NEWOBJ(XFPGMREF)
             CHGPF      FILE(QTEMP/XFPGMREF) SIZE(*NOMAX)
  ```

  `CRTDUPOBJ` of the IBM-supplied template (`QADSPPGM`, `QADSPOBJ`, …) gives the
  correct record format, and `CHGPF SIZE(*NOMAX)` removes the member size limit
  the template carries.

  **The `CHGPF` is not optional.** The inherited limit is generous enough that
  development-sized data never reaches it, so omitting it fails only once the
  program is pointed at real volume — and it fails as a member-full condition on
  a `QTEMP` file, which explains nothing about the program that caused it. A
  limit that only bites in production is worse than one that bites immediately.

---

## 4. SQL (QSQLSRC)

Standards follow **RBUTL** practice exclusively (BSLIB's QSQLSRC contains ad-hoc
test members that are not exemplars).

### 4.1 Member types and build

| Ext | Contents |
| --- | --- |
| `.SQLT` | One table: DDL + labels + audit trigger + indexes |
| `.SQLV` | View(s) for one purpose |
| `.SQLS` | Everything else run as a script (UDFs, sequences, fix-up statements) |

Every member is built by `RUNSQLSTM` via its directive header:

```text
/*> RUNSQLSTM SRCFILE(&L/&F) SRCMBR(&N) COMMIT(*NONE) -             <*/
/*>           DFTRDBCOL(&O) DATFMT(*ISO) TIMFMT(*ISO)               <*/
```

### 4.2 The schema-resolving compound block

DDL members are a single `BEGIN … END` compound statement of **dynamic SQL**, so
the target schema is resolved at run time (from `DFTRDBCOL`/`*CURLIB`) instead of
being hardcoded:

```sql
BEGIN
  DECLARE tblNam  VARCHAR(10) DEFAULT 'TMTSK';
  DECLARE tblLib  VARCHAR(10);
  DECLARE tblRef  VARCHAR(21);
  DECLARE sqlStmt VARCHAR(5000);

  --Resolve the DFTRDBCOL/CURRENT SCHEMA/*CURLIB reference
  CREATE OR REPLACE TABLE bldobj_temp_resolve_dftrdbcol_schema (fld1 char(1));
  GET DIAGNOSTICS CONDITION 1 tblLib = DB2_ORDINAL_TOKEN_2;
  SET tblLib = TRIM(tblLib);
  SET sqlStmt = '
      DROP TABLE ' || tblLib || '.bldobj_temp_resolve_dftrdbcol_schema';
  EXECUTE IMMEDIATE sqlStmt;
  SET tblRef = tblLib || '.' || tblNam;
  ...
END;
```

- Build each statement into `sqlStmt` and `EXECUTE IMMEDIATE` it.
- Before re-creating a table, loop the `qsys2.sysindexes` / `qsys2.systrigger`
  catalogs and `DROP` existing indexes and triggers (`FOR row AS csr CURSOR FOR
  … DO … END FOR;`).
- Members must be **re-runnable**: `CREATE OR REPLACE` everywhere; identity
  columns re-seeded at the end with `ALTER … RESTART WITH` from `MAX(id) + 1`.

### 4.3 Tables (`.SQLT`)

```sql
CREATE OR REPLACE TABLE ... (
    task_id           FOR COLUMN tskid      BIGINT
       GENERATED BY DEFAULT
       AS IDENTITY (START WITH 1 INCREMENT BY 1 CYCLE)
       PRIMARY KEY
   ,task_name         FOR COLUMN tskname    CHAR(10)
       NOT NULL DEFAULT UNIQUE
   ,task_status       FOR COLUMN tsksts     CHAR(1)
       NOT NULL DEFAULT ''0''
       CHECK(task_status BETWEEN ''0'' AND ''9'')
   ...
) RCDFMT r' || tblNam;
```

- **Long descriptive names** with `FOR COLUMN` short (≤10) system names, both
  lowercase.
- **Avoid SQL reserved words as column names, even where they compile.** Db2
  enforces the [reserved word
  list](https://www.ibm.com/docs/en/i/7.6.0?topic=words-reserved) *by context*,
  so a column named `SEQUENCE` or `POSITION` is accepted today — the word has no
  meaning in that position, so the parser allows it. Do not rely on that. IBM
  reserves the right to add to the list at any time, including in PTFs against a
  GA release, and has done so in ways that broke working code. A name that
  compiles this year is not a name that compiles next year.
- **The defence is a domain prefix, not the list.** You cannot keep up with the
  list, so make the question moot: name every column for what it belongs to —
  `libl_position`, `merge_sequence`, `build_status`, `environment_type`. IBM will
  never reserve those. This is the same move IBM itself makes in
  `QSYS2.LIBRARY_LIST_INFO`, whose column is `ordinal_position` rather than
  `position`. Note that *compound* is not by itself sufficient — `SYSTEM_USER`
  and `CURRENT_DATE` are reserved — it is the domain prefix that makes a
  collision implausible. Prefer this to a delimited identifier, which merely
  postpones the problem into every statement that reads the column.
- Identity `BIGINT` primary key named `<entity>_id`.
- `NOT NULL DEFAULT` on business columns; `CHECK` constraints where the domain
  is enumerable. Enumerated values are **numeric, not alpha** — see section 9.
- **Audit columns**, all `IMPLICITLY HIDDEN`: `audit_timestamp` (row change
  timestamp), `audit_job_number/user/name`, `audit_current_user`, plus matching
  `create_*` columns.
- A `BEFORE INSERT OR UPDATE … FOR EACH ROW MODE DB2ROW` trigger, named
  `<table>T1`, normalizes keys (`LTRIM(UPPER(...))`), fills defaults, and
  populates the audit/create columns; new rows are detected by the identity
  column being NULL in the OLD row.
- `RCDFMT r<table>` so record-level access sees a stable format name.
- `LABEL ON TABLE`, `LABEL ON COLUMN ... TEXT IS` (full text) **and**
  `LABEL ON COLUMN ... IS` (column headings) for every column.
- Indexes named `<table>9`, `<table>8`, … (9 = unique/primary alternate key,
  descending from there), each with `LABEL ON INDEX ... IS 'By <keys> (u)'`.

### 4.4 Views (`.SQLV`)

- `CREATE OR REPLACE VIEW <ref>(col, …) AS` with an explicit column list.
- Structure complex logic as `WITH` CTEs; name CTE columns explicitly.
- Cap recursive/`CONNECT BY` depth explicitly (e.g. `AND a.recid <= 250`) and
  document why in the header comment.
- `LABEL ON TABLE <view> IS '…'` after creation.

### 4.5 Routines (UDFs/procedures, usually `.SQLS`)

- `CREATE OR REPLACE FUNCTION` with a `SPECIFIC` name per overload
  (`char8ToDate`, `dec8ToDate`).
- Declare behavior: `DETERMINISTIC`, `CONTAINS SQL`/`READS SQL DATA`,
  `RETURNS NULL ON NULL INPUT`, `NO EXTERNAL ACTION`.
- Handle bad input via a scoped `DECLARE CONTINUE HANDLER FOR SQLEXCEPTION`
  and return NULL rather than erroring.
- `COMMENT ON SPECIFIC FUNCTION` and `COMMENT ON PARAMETER` for every routine —
  these surface in catalogs and client tools.
- Parameter defaults (`DEFAULT 'YMD'`) instead of overload explosions.

### 4.6 Style

- Keywords UPPERCASE; identifiers lowercase; 2-space indent; leading commas on
  continuation lines (both column lists and select lists).
- Alias every table; qualify every column reference.
- `--` for inline comments inside SQL bodies; `/* */` for the member header.

### 4.7 NULL handling

- **Use `COALESCE`, not `IFNULL`.** Db2 documents them as equivalent for the
  two-argument case, and for a scratch query either is fine. In production
  queries `IFNULL` has been observed to send the optimizer off into a bad plan
  on complex statements — not on large *data*, but on structurally complex ones
  (deep CTEs, recursion, lateral joins). No mechanism is claimed here; the point
  is that the two are interchangeable in meaning, so there is nothing to weigh
  against standardizing on the one that has never caused trouble. `COALESCE` is
  also the SQL-standard spelling and takes more than two arguments, so a
  fallback chain does not have to be rewritten when a third source appears.

- **Assume every column from an IBM i Service is nullable unless documented
  otherwise.** The services return `NULL` rather than blanks for absent text —
  `TEXT_DESCRIPTION`, `OBJTEXT` and their like — which collides with the
  `NOT NULL DEFAULT` convention of section 4.3. Coalesce at the point the value
  enters a table.

- **Test for null and blank together** when a value is "missing or empty",
  because a service may express the same idea either way:

  ```sql
  CASE WHEN COALESCE(TRIM(a.text), '') <> '' THEN a.text
       ELSE COALESCE(b.text, '') END
  ```

- Weigh the blast radius, not the row. A `NOT NULL` violation fails the whole
  statement, and where that statement is one step of a build that escapes on
  error, a single unguarded row takes down the entire run — on data nobody
  controls. That asymmetry is why the guard goes in by default rather than
  after the first failure.

---

## 5. Commands (QCMDSRC)

```text
/*  MODIFICATIONS: +
    BS  08/02/25  Created. +
    @@  */
/*> CRTCMD CMD(&O/&ON) SRCFILE(&L/&F) SRCMBR(&N) PGM(TMACRUSR)       <*/
/*> <BLDOBJ EOF/>                                                    <*/
/*  (c) Copyright Godsend Consulting, 2025-2026 */
             CMD        PROMPT('Add User') MSGF(TMMSG) HLPID(*CMD) +
                          HLPPNLGRP(ADDUSRTM)
```

- Every command declares `PROMPT`, `MSGF(TMMSG)` (or product message file),
  `HLPID(*CMD)`, and `HLPPNLGRP(<own name>)` — help is not optional.
- `PARM` conventions:
  - `EXPR(*YES)` on user-enterable parameters.
  - Mixed-case text parameters: `TYPE(*CHAR) LEN(n) CASE(*MIXED)`, **fixed
    length**. See below before reaching for `VARY`.
  - Special values via `SPCVAL((*NONE ' '))` mapping to storable values.
  - Selection lists via `CHOICE(*PGM) CHOICEPGM(<…CHC program>)`.
  - Shared-CPP commands pass their mode as
    `PARM KWD(MODE) TYPE(*CHAR) CONSTANT('*ADD')`.
  - **A special value that replaces the WHOLE parameter goes in `SNGVAL`.**
    `VALUES` and `SPCVAL` are **per element**. On a single, base-data-type
    parameter that is exactly right and `SPCVAL` is where special values go —
    the element *is* the parameter, so `SNGVAL` has nothing to add. The
    distinction bites on every **compound** parameter:

    | Parameter | Why it is compound |
    | --- | --- |
    | `MAX()` greater than 1 | a list of elements |
    | `TYPE(ELEM-label)` | a list of parts, one `ELEM` each |
    | `TYPE(QUAL-label)` | a qualified name, one `QUAL` each |

    On any of those, `SPCVAL((*SAME))` says *each entry may be `*SAME`*, so
    `LIBL(*SAME QGPL)` and `LIBL(*SAME *SAME)` are both accepted. `SNGVAL`
    ("single value") is the one that means **this value may only appear alone**,
    which is what `*SAME`, `*NONE`, `*ALL` and their like almost always want.
  - **A list of BASE-DATA-TYPE elements arrives as a 2-byte binary count
    followed by the elements, each at its FULL declared length.** Fixed-length
    `*CHAR`, `*NAME` and decimal elements are padded to `LEN()`, so the stride is
    constant and the structure maps directly — in RPG as a `dim()` array behind
    the count, in CL as `%BIN` plus `%SST` or a `STG(*DEFINED)` overlay:

    ```rpgle
    dcl-ds xxx_libl_t  template qualified inz;
      count          Int(5);
      library        Char(10) dim(250);
    end-ds;
    ```

    A `VARY` element does not lay out this way — each carries its own length — so
    do not assume a constant stride for one.
  - **`MAX()` over `ELEM` or `QUAL` is a DIFFERENT structure. Do not reach for a
    `dim()` array.** The elements are not contiguous; the parameter opens with a
    count and then an **offset table**, and each entry carries its own element
    count before its components:

    | Offset | Content |
    | --- | --- |
    | 1–2 | number of entries passed (2-byte binary) |
    | 3 … | one **2-byte offset** per entry, relative to the start of the parameter |
    | *per entry, at its offset* | 2-byte count of elements supplied, then the components at their declared lengths |

    `QCLSRC/INF2XLSX.CLLE` is the worked reference — `PARM KWD(ATR) TYPE(EATR)
    MAX(50)` with `ELEM` lengths 50 and 256. It walks the offset table with a
    based pointer, advancing `%OFS(&ATROFSPTR)` by 2 per entry and setting the
    entry pointer to `%OFS(&ATRPTR) + &ATROFS`. The declared sizes confirm the
    layout: entry = 2 + 50 + 256 = 308; 50 offsets × 2 = 100, plus 50 × 308 =
    15,400, giving the `LEN(15502)` = 2 + 15,500 on the receiving variable.

    **The offset table is the authority on where an entry is — never compute
    it.** The entries have been observed loaded **back to front**: the first
    offset points at the *last* entry in storage, so walking the offsets forward
    walks backwards through the array. That is an observation rather than
    documented behaviour, which is exactly the point — the arrangement is not
    something to depend on in either direction, and reading the offsets is what
    makes it not matter. Stride arithmetic would land on the wrong entry even
    with every length correct.

    **Confirm the layout before writing against it.** The above is verified for
    `ELEM`; a `QUAL` inside a list is not, and IBM documents these structures per
    parameter type rather than as one rule. The widths in particular are easy to
    get wrong — 2 bytes, not the 4 the shape suggests.
  - **The CPP must bound every loop by the COUNT**, never by the declared
    dimension. The command materialises the elements it was
    given, not `MAX()` of them, so the array past the count is not blank and is
    not reliably even this parameter. Probed with one `*SAME` in each of two
    lists followed by a `MODE` constant:

    ```text
    LIBL   n=00001 [1]=*SAME [2]= <attr>*SAME
    MRGENV n=00001 [1]=*SAME [2]=*RSTD
    MODE   = *RSTD
    ```

    `MRGENV` element 2 returned `*RSTD` — the value of the **`MODE` parameter
    that follows it**. Reading past the count reads adjacent parameter data,
    which looks like a plausible name and would be written to the table as one.
    **What lies past the count is the call stack**, so this is not a tidy-up: it
    is reading storage that belongs to something else, and the value it returns
    changes with the caller.
  - **`RSTD(*YES)` restricts which values are accepted, not how many**, so it is
    no substitute for `SNGVAL` — `MAX()` governs the count independently.
  - **`CONSTANT` requires `MAX(1)`** — `CPD6228`. A list parameter cannot be
    locked with it, so a shared-CPP command that must pass a list parameter it
    has no use for declares it with `SNGVAL` and a `DFT` instead.

**`VARY(*YES *INT2)` is for long text, and it is a cost to justify.** A varying
parameter arrives as a 2-byte length followed by the data. RPG receives that as a
`Varchar` and nothing more is needed. **CL has no varying type**, so a CL CPP must
take the parameter apart by hand — a base variable plus two `STG(*DEFINED)`
overlays, and an `%SST` to extract:

```text
             DCL        VAR(&RCPV) TYPE(*CHAR) LEN(10242)
               DCL        VAR(&RCPL) TYPE(*INT) STG(*DEFINED) LEN(2) +
                            DEFVAR(&RCPV 1)
               DCL        VAR(&RCPD) TYPE(*CHAR) STG(*DEFINED) +
                            LEN(10240) DEFVAR(&RCPV 3)
   ...
             CHGVAR     VAR(&RCP) VALUE(%SST(&RCPD 1 &RCPL))
```

Three declarations per parameter, and most CPPs are CL. So:

| Field | Form |
| --- | --- |
| Tens of bytes — a description, a name, a subject | fixed `TYPE(*CHAR) LEN(n) CASE(*MIXED)` |
| Hundreds of bytes or more — a note body, a recipient list, an SQL statement | add `VARY(*YES *INT2)` |
| Any length, where the CPP is **RPG** and the value maps to a `VARCHAR` column typed with `like()` | add `VARY(*YES *INT2)` — one shape from command to table |

The test is whether the CPP genuinely benefits from being **told** the length. At
50 bytes it does not: `%TRIMR` is free and the buffer is trivial, so the overlays
buy nothing. At 5,000 or 10,000 they buy something real.

**Existing `VARY` parameters stay as they are — not violations, and not tracked
for revision.** The cumbersomeness is its own filter: nobody writes three overlay
declarations per parameter by accident, so where `VARY` is already in place
someone had a reason. Changing it would land on a working CPP for no behavioural
gain. This rule governs new parameters.

This rule was rewritten 08/17/26. It previously read `VARY(*YES *INT2)` flatly for
every mixed-case text parameter, generalized from four commands — three of which
share one **RPG** CPP (`TMACRUSR`, 50-byte parameters against `VARCHAR(50)`
columns), while the fourth (`SNDXLSX`, 10240/5000/255) is CL and pays nine `DCL`s
to receive three parameters. Meanwhile a dozen other commands already used fixed
`*CHAR` with `CASE(*MIXED)`. The stated rule was the minority practice.

- Every command ends with the hidden cross-reference parameter:

  ```text
               PARM       KWD(PGMXRF) TYPE(QPGMXRF) PGM(*YES)
   QPGMXRF:    QUAL       TYPE(*NAME) LEN(10) CONSTANT(<CPP name>)
               QUAL       TYPE(*NAME) LEN(10) CONSTANT(<command name>)
  ```

  The CPP receives it as a 20-byte qualified name (`pxPgmXrf` / `&PGMXRF`).

  **This parameter is what makes command usage cross-referenceable, and it is
  not optional.** No compiler records "this program used command X" — command
  invocation leaves no reference behind. `PGM(*YES)` on a qualified name does:
  the compiler records it as a **program reference**, and because the two
  constants are *CPP first, command second*, the reference arrives with the CPP
  in the object field and **the command name in the library field**. A cross
  reference build detects that pairing and turns it into a command reference.

  Omit the parameter and the command becomes invisible to the cross reference —
  "what uses this command" answers nothing, and nobody can tell whether it is
  safe to change. Get the two constants the wrong way round and the pairing does
  not match, with the same result and no error to say so.

  **There is no recovering this after the fact.** Command invocation leaves no
  compiled reference of any kind, so nothing can be derived later — establishing
  usage would mean parsing source, which is not a thing anyone is going to do.
  The parameter at build time is the only record that will ever exist.

  And the failure is in the dangerous direction: a command with no callers in the
  cross reference looks *unused*, which is indistinguishable from one that is
  used everywhere by programs the tool could not see. This convention is the only
  thing standing between that and a deletion.

---

## 6. Panel groups (QPNLSRC)

- Header: `.*` purpose comment, `MODIFICATIONS:` log, `.*>` BLDOBJ directives.
- Open with `:PNLGRP ENBGUI=YES.` and `:COPYR.(c) Copyright Godsend
  Consulting, <years>`.
- **Reuse shared help:** `:IMPORT NAME='*' PNLGRP='TMHLP'.` and `:IMHELP` the
  shared modules (`TMHLP/<PARM>/REQ`) instead of retyping parameter help.
- **`:HELP` titles stay on one line:** the descriptive text that follows
  `:HELP NAME='…'.` cannot wrap to the next line, and must not be abbreviated to
  fit — let the line run long (up to the 134 hard limit) rather than shorten the
  wording.
- Command-help members define this fixed set of help IDs, in order:
  1. `'<CMD>/ALL'` — aggregate of all sections (for full-command help)
  2. `'<CMD>'` — extended description
  3. `'<CMD>/<PARM>'` — one per parameter, titled
     `<Prompt> (<KWD>) - Help`
  4. `'<CMD>/COMMAND/EXAMPLES'` — numbered examples in `:XMP.` blocks with a
     prose explanation per example
  5. `'<CMD>/ERROR/MESSAGES'` — message text pulled live via
     `&msg(MSGID,MSGF,*LIBL,nosub).`, one `:DL COMPACT.` list per message
     *type*, each introduced by a highlighted paragraph rather than a list term:

     ```text
     :P.:HP3.*ESCAPE &msg(CPX0006,QCPFMSG).:EHP3.
     :DL COMPACT.
     :DT.ENV0001
     :DD.&msg(ENV0001,XFMSG,*LIBL,nosub).
     :EDL.
     ```

- **Let the tags do the formatting.** UIM renders text according to the tag that
  contains it — lists, definition terms, parameter values and keywords all carry
  their own appearance. **Tag the text correctly and the highlighting takes care
  of itself.**

  `:HPn.` is for **headings**, plus the occasional term or special reference
  inside running prose. Reaching for it to make tagged content *look* right is a
  sign the wrong tag was used — and it is **not valid inside `:PV.`, `:PK.` or
  `:DT.`** at all, because those take a bare term and already render it.

  The two forms that are idiomatic here, and the only ones needed in practice:

  ```text
  :P.:HP2.Example 1: Simple Command Example:EHP2.
  :P.:HP3.*ESCAPE &msg(CPX0006,QCPFMSG).:EHP3.
  ```

  Getting the invalid nesting wrong compiles nowhere, and it is easy to write by
  analogy from HTML or Markdown, where nesting emphasis inside anything is fine:

  | Want | Write | Not |
  | --- | --- | --- |
  | A variable value | `:PT.:PV.environment-name:EPV.` | `:PV.:HP2.…:EHP2.:EPV.` |
  | A special value | `:PT.:PK.*ALL:EPK.` | `:PT.:PV.*ALL:EPV.` |
  | The **default** value | `:PT.:PK DEF.*YES:EPK.` | — |
  | A message-group heading | `:P.:HP3.*ESCAPE …:EHP3.` | `:DT.:HP4.…:EHP4.` |

  `:PV.` is a *variable* — something the user substitutes, like
  `environment-name`. `:PK.` is a *keyword* — a literal special value such as
  `*ALL`. Only `:PK.` takes the `DEF` attribute, which underlines the value to
  mark it as the parameter default; `:PV.` has no equivalent, so a default that
  is a variable cannot be marked and does not need to be.
- Work-with (inquiry) panels declare, in separate banner-labeled sections:
  classes (`cls<type><len>`, e.g. `clsname10`, `clsyesno` with `:TL.` truth
  labels), variables (lowercase, matching the RPG DS subfields), `:VARRCD`s
  (`header`, `detail`, `csrrcd`, `cmdlin`), `:LISTDEF`s (`dtllist` with
  `EMPHASIS` columns), conditions, and key lists — the names must match the
  `@…_PNLID` / `@…_VARRCD` / `@…_LSTNAM` constants in the RPG `…H` copybook.

---

## 7. Display files (QDDSSRC)

- Standard header applies: `A*` comment lines carrying the purpose,
  `MODIFICATIONS:` log, and `*>` build directives (`CRTDSPF`, continued
  with `-`).
- **Record formats are named `FMnn?`** — `FM`, a two-digit number `nn`
  (01–99), and a type suffix. Formats that work together (a subfile and its
  control, a window and the records displayed in it) share the same `nn`:

  | Suffix | Format |
  | --- | --- |
  | *(none)* | Plain record |
  | `S` | Subfile record (`SFL`) |
  | `C` | Subfile control (`SFLCTL`) |
  | `F` | Footer |
  | `B` | Blank |
  | `W` | Window |

- Note: these repos hold only a handful of display files from a much larger
  code base, so local DSPF members are weak precedent. Follow the naming rule
  as stated here rather than patterns inferred from the few local examples.

---

## 8. Messages

### 8.1 Message identifiers

A message id is a **3-character prefix and a 4-character number**. Compose the
prefix as a **2-character module id plus a type letter**, following IBM's own
scheme in `QCPFMSG`:

| Letter | Type | IBM's |
| --- | --- | --- |
| `A` | Action — inquiry messages expecting a reply | `CPA` |
| `C` | Completion | `CPC` |
| `D` | Diagnostic | `CPD` |
| `I` | Informational — including `*STATUS` | `CPI` |
| `X` | Text — titles, help text, NLS and cultural values | `CPX` |
| `F` | Everything else — escape, notify | `CPF` |

So the Cross Reference module sends `XFF*`, `XFC*`, `XFD*` and `XFI*`. (IBM's
`F` stands for *facility*; `CPF` as a whole is System/38 compatibility. The
letter is worth keeping anyway, because a module needs a bucket for the messages
that are not one of the named types.)

**Match the letter to the send type**: `*COMP` is `C`, `*DIAG` is `D`, and both
`*INFO` and `*STATUS` are `I` — a status message is informational, not an
"everything else".

**But the letter records what the message IS, not every way it is ever sent** —
and the test is where it could have ORIGINATED. `*DIAG` is the one send type
that may be an escape in transit: forwarding an escape as a diagnostic is
routine, and is exactly what the `FWDMSGH` pattern of section 3.4 does. So a
message sent `*ESCAPE` in one place and `*DIAG` in another stays an `F` message
being used as a diagnostic.

That is also why `*STATUS` is unambiguous where `*DIAG` is not. A `*STATUS`
message is never sent as `*ESCAPE` and never arrives by being forwarded from one,
so it has no other origin to weigh — it is `I` and nothing else.

**Number by area within the prefix**, so related messages read together:
`XFF0nnn` for the build, `XFF1nnn` for environment definition. The number is
hexadecimal — `A`–`F` are legal digits — but **do not use them in user-defined
ids**. Reserve that for a custom version of an IBM message whose id already
contains them.

### 8.2 One module id per module

**Every message a module owns carries the same 2-character module id.** Only the
type letter varies.

**This exists because messages are monitored by prefix group.** `MONMSG
MSGID(CPF0000)` catches every `CPF` message; a module that spreads its messages
across unrelated prefixes forces every caller to name each one:

```text
             MONMSG     MSGID(... TSK0000 OBJ0000 LOC0000 DEP0000 +
                          EXC0000 UIM0000) EXEC(GOTO CMDLBL(STDERR))
```

Six prefixes for one module's failures, and a caller that names five of them
misses the sixth **silently** — the escape is simply not caught, and the failure
surfaces somewhere else as something else.

**Splitting by type letter does not reintroduce the problem**, which is the point
of putting the type in the prefix rather than in the number range. Only escapes
are monitored, and escapes are all `F`, so a single `xxF0000` covers what a
`MONMSG` needs. Completion, diagnostic and informational messages are read, not
trapped.

**Task Manager is the standing exception**, not a model. `TMMSG` predates this
rule and uses `TSK*`, `OBJ*`, `LOC*`, `DEP*`, `EXC*` and `UIM*`. It is left alone
because the remapping is genuinely hard — the areas hold colliding numbers, so
they cannot simply be re-prefixed — and it is tracked in
`GCUTL/QRPGLESRC/READMETM.MD` rather than done piecemeal. New modules follow the
rule.

### 8.3 Sending

- Product messages live in one message file per product (`XFMSG`, `TMMSG`), built
  from a `QREXSRC` REXX member.
- Programs send message IDs, not hardcoded text, wherever a message exists;
  status messages use `CPDA0FF`.
- **Keep a `*STATUS` message to 76 characters assembled.** That is the text plus
  the *declared width* of every replacement value, not the width of what a
  particular caller happens to pass. Longer messages are truncated, and possibly
  not shown at all — either way the tail is lost, and the tail is usually the
  part that says what the program is doing.

  Measure it when the message is written: literal text with the `&n` tokens
  removed, plus each value's `FMT` length. `'Building cross reference &1.  &2'`
  with `(*CHAR 10) (*CHAR 30)` is 28 + 10 + 30 = 68.

- **`MSGDTA` must supply exactly the bytes the `FMT` declares.** A short
  `MSGDTA` leaves later replacement values reading whatever follows in storage,
  which shows as stray characters rather than as an error. Concatenating a
  10-byte variable with a shorter expression is the easy way to get this wrong:

  ```text
             CHGVAR     VAR(&STSTXT) VALUE('Scanning' *BCAT &LIB)
             SNDPGMMSG  MSGID(XFI0007) MSGF(XFMSG) MSGDTA(&ENV *CAT +
                          &STSTXT) TOPGMQ(*EXT) MSGTYPE(*STATUS)
  ```

  `&STSTXT` is declared at the `FMT` width, so the total is right whatever the
  text inside it happens to be.
- Escapes propagate (FWDMSGH pattern / `%target('*PGMBDY': 1)`) so the original
  failure reaches the user.

---

## 9. Cross-cutting rules

- **Self-documenting builds:** if it can't be rebuilt from its BLDOBJ
  directives, it isn't done.
- **Re-runnable everything:** DDL re-creates, programs clean up QTEMP, handled
  messages are removed from the joblog.
- **No duplicate knowledge:** lengths via `like()`, help via `IMHELP`, message
  text via `&msg(...)`, schema via `DFTRDBCOL` resolution. One source of truth
  each.
- **Order dependencies are documented at both ends** — e.g. the build-order
  `CASE` in `RUNTSKTM` and `TMOBJWRK`'s sort carry matching "keep in sync"
  comments. Do the same for any new coupled logic.
- **Coded values are numeric, not mnemonic.** This governs *codes* — values
  where a character stands in for a word the reader has to know: status,
  option, scope, selector. It has nothing to say about values that are already
  words, such as IBM-style special values (`*LIBL`, `*MERGE`) or text labels
  (`STEP07`); those are names and stay as they are. Codes store digits. A
  single letter is ambiguous the
  moment someone other than its author reads it: `C` is Continue, Confirmed,
  Cancel, … A digit makes no false promise, so the reader goes to the column
  text or the panel for the meaning instead of guessing wrong.
  - Number from 1 in the natural progression of the thing, and reserve **9 for
    the error or terminal state**, leaving room for states added later.
  - Where the values are nested scopes rather than distinct states, number them
    in widening order so the ordering itself carries meaning.
  - Keep the column `CHAR(1)` holding a digit — it is a coded value, not
    arithmetic — and spell every value out in `LABEL ON COLUMN … TEXT IS` so the
    decode travels with the table.
  - Write that legend as `value=Description`, description in **sentence case**,
    values separated by **comma + space**:
    `Status: 1=Running, 2=Complete, 9=Error`. Column `TEXT` caps at **50
    characters** — abbreviate the descriptions to fit and keep the authoritative
    decode in the design document; do not let the legend run past the cap and
    truncate mid-word, which is how IBM's own `QADSPPGM` legends ended up
    unreadable.
  - No `UPPER()` normalization for these columns in the `<table>T1` trigger;
    it is dead code once the domain is numeric.
  - The readable form belongs at the **command layer**, spelled out in full:
    `SPCVAL((*STDIP 1) (*DEVIP 2) (*ALL 3))`. The user types the special value,
    never the digit.

---

## 10. Legacy and scratch code

- **Scratch:** `JUNK*` members are experiments. Git-ignores them going forward;
  never reference or promote them, and don't cite them as precedent.
- **Third-party:** members with external authorship headers — Carsten
  Flensburg's `CPYMSGD*`, Giuseppe Costagliola's `SQL2XLSX*`, Scott Klement's
  YAJL/JDBCR4 material — keep their original style and attribution. Fix bugs;
  don't restyle.

  The reason is practical, not ceremonial: their style is the upstream author's,
  so restyling makes the next version harder to take up and makes a local defect
  harder to tell from an upstream one. **Where that reason has expired, so has
  the exemption.**

- **Forks that have diverged are house code with an attribution.** A member
  branched from someone else's work and then rewritten over years is no longer
  tracking an upstream. Nobody is going to merge a new release into it, so
  nothing is being protected by holding it to the original author's conventions
  — the exemption just leaves a permanent inconsistency in the middle of the
  library.

  `BLDOBJ` is the worked example. It began as a branch of Klement's BUILD tool
  in 2019 and has drifted a long way since. **The `@author` line stays** — the
  origin is a fact and the credit is owed — but house standards apply to the
  code. The test is not "was this written elsewhere" but "is there still an
  upstream we intend to follow." Keep the attribution, drop the exemption.
- **Legacy fixed-form:** don't expand fixed-form code. Small fix = match the
  existing style locally; real enhancement = convert to `**FREE` first (add a
  MODIFICATIONS entry for the conversion).

- **Embedded 5250 display attributes become a single space.** Old source can
  carry EBCDIC **x'20'–x'3F'** — the 5250 field attribute bytes. They are there
  because the comment or heading was laid out on a green screen, where an
  attribute byte turned highlighting or colour on and off. Converted off the
  platform they surface as Unicode C1 controls, mostly `U+0080`–`U+009F`.

  **Replace each with exactly one space.** An attribute byte occupies one display
  position on a 5250 — it is not zero-width — so one space is what preserves the
  column alignment the original author was looking at. That is the whole
  justification, and it is why the two obvious alternatives are both wrong:

  - **Leaving them** means the next tool to read the member decides for you. One
    that cannot decode the byte writes `U+FFFD` in its place, which is silent
    corruption that survives review because it still looks like a character.
  - **Deleting them** closes up the line. `NOTE:` + attribute + `WHEN` becomes
    `NOTE:WHEN`, and in CL it can be worse than cosmetic — an attribute sitting
    before a `+` continuation is holding the blank that separates it from the
    preceding keyword, so removing it changes what the compiler reads.

  Byte-count matters as much as appearance here: source is fixed-width
  (see §1.4), so a substitution that is not one-for-one shifts everything after
  it.

  **They do not all land in the C1 range — match on the whole set.** EBCDIC
  x'20'–x'3F' converts to a scatter of Unicode code points, not a contiguous
  block: most become C1 controls (`U+0080`–`U+009F`), but x'26' becomes
  `U+0017`, x'2F' becomes `U+0007`, x'3F' becomes `U+001A`, and several more
  land in C0. A pattern written against `U+0080`–`U+009F` alone looks like it
  works and quietly leaves the C0 ones behind. Match **C0 except tab/LF/CR, all
  of C1, and `U+FFFD`**:

  ```text
  [\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u0080-\u009F\uFFFD]
  ```

  x'25' is the one to leave alone — it converts to `U+000A`, a real line
  ending.

  **Do not widen this to "any non-ASCII".** A handful of members genuinely
  contain extended characters — a few across a thousand-plus — and those are
  content, not artefacts. The rule is scoped to control code points precisely so
  a sweep cannot eat them.
- **Write new source in ASCII, and treat anything outside it as needing a
  reason.** Source reaches the system through the IFS and is translated to
  EBCDIC on the way in. A character with no equivalent in the target CCSID is
  replaced with the substitution character, **x'3F'** — silently, with no
  warning and no way to recover what it was.

  Most non-ASCII in source is a *choice* rather than a requirement, and the
  choice is free to make differently: an em-dash where a hyphen reads the same,
  `≫` where `>>` does. Use the ASCII form. **The test is whether an ASCII
  alternative conveys the same thing, not whether one exists.**

  Occasionally it does not — a visual marker or a simulated bullet that no
  ASCII character stands in for. Those are content and stay, as above. Verify
  one survives the round trip on the system rather than assuming it will.

  **x'3F' hides inside the display-attribute sweep.** It falls within
  x'20'–x'3F', so the rule above replaces it with a space along with the
  genuine attribute bytes — erasing the evidence that a character was lost in
  translation, and leaving the two indistinguishable afterwards. Check a member
  for substitution characters *before* sweeping attributes, not after.

  This is worth a check rather than a habit, since nothing surfaces it: a byte
  scan for anything above 127 across the source directories catches it before
  the member ever reaches the system.
- **The standard applies to each repository on its own merit.** It travels to
  every Godsend IBM i repo, but says nothing about the relationship *between*
  them. Nothing here requires two repos to hold identical members, and
  divergence between them is not a standards violation — a developer library
  drifts from a curated one as a matter of course, work gets tested and
  abandoned, and other hands change production. Where a change is made because
  of a standard and belongs in more than one repo, **apply it in each repo
  separately, judged against that repo's own code**. Never reconcile one repo by
  copying from another on the strength of this document.

  What *is* kept identical is this document. Edit the canonical copy in
  `IBMI-STANDARDS`, run `sync-standards.ps1`, and commit the refreshed copy
  everywhere it lands. How a particular pair of repositories relate — which is
  authoritative for what, what is being migrated where — is that project's
  business and belongs in that project's own documentation.
