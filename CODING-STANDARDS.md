# IBM i Coding Standards

Baseline standards for RPGLE/SQLRPGLE, CL/CLLE, SQL, CMD, PNLGRP, and DDS source
in **all Godsend Consulting IBM i repositories** — BSLIB, RBUTL, and any future
project. They were derived from the current best practice in these libraries —
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
- A change spanning several days may show the extra date(s) on the continuation
  line(s), aligned under the first date.
- One entry may describe several changes made together; start each on its own
  continuation line.
- The `@@` line terminates the log. Never remove it.
- `@TODO` lines may follow the log (before the build directives) to record known
  future work.

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

### 1.4 Layout

- **Line width:** target ≤ 80 characters everywhere. Hard limits:
  - `**FREE` RPG: code starts in column 1; the server source files give 100 data
    columns, so 100 is the hard maximum — but stay ≤ 80 for readability (RBUTL
    practice is ~76).
  - Hybrid RPG (no `**FREE`): fixed-form specs are, well, fixed — their columns
    aren't a style choice. The line-length rule governs the free-form lines,
    which must fit **columns 8–80**: the compiler does not read free-form code
    past column 80, so a line extending beyond it may cause compiler errors.
    80 is a hard limit for `/FREE` lines.
  - CL, CMD, SQL: keep within 80.
  - PNLGRP: 134 is the hard maximum (the source file permits it); prefer ≤ 80
    for readability. A `:HELP` title that would exceed 80 stays on one line
    (see §6) rather than wrapping or being abbreviated.
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
- Every copybook starts with an include guard:

  ```rpgle
  **FREE
  /IF DEFINED(TMXXXWRKH)
  /EOF
  /ENDIF
  /DEFINE TMXXXWRKH
  ```

- A copybook contains, in order: nested `/copy` of its dependencies, named
  constants, data-structure templates, then prototypes. Terminate each group with
  a separator rule.
- Shared IBM API prototypes live in the `QAPIH` (QUS*/QMH* APIs), `QILEH` (ILE
  CEE/QSN), and `QUIMH` (UIM) copybooks — extend those rather than redeclaring
  APIs inline.
- Document every prototype with a `///` doc block in **ILEDoc format**:
  one-line summary, `@param` per parameter, `@return` when a value is
  returned. Doc commands are lowercase (`@param`, `@return`); use `@return` —
  `@returns` (with an s) is not supported.

### 2.4 Declarations

- **Constants:** SCREAMING_SNAKE_CASE prefixed with `@` (C-style), grouped by
  topic: `dcl-c @QUIM_FNCKEY_ENTER 1;`, `dcl-c @SQLCODE_NODATA 100;`
- **Templates:** all-lowercase name with a `_t` suffix — "My Template
  Variable" becomes `mytemplatevariable_t` — declared `template qualified inz`:

  ```rpgle
  dcl-ds usrlste_t   template qualified inz;
    opt            Int(5);
    usrPrf         Char(10);
  end-ds;
  ```

  Instances: `dcl-ds usrLstE likeds(usrlste_t) inz(*LIKEDS);`
- **External-file templates:** one per table, used for `like()` typing and fetch
  buffers:

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
  `getItemHeader`, `loadList`, `sndStsMsg`, `exitPgm`.
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

- Prefer modern expression forms: `if x in %list(a: b: c);`, `%char(%date():
  *ISO0)`, `snd-msg`.
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
- Test `sqlcode` against named constants (`@SQLCODE_SUCCESS`, `@SQLCODE_NODATA`)
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
- Classic SEU columns: labels start column 2 on their own line; commands start
  column 14; keyword continuations break with `+` and align under the first
  keyword. Stay within 80 columns.
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

- Task Manager programs add `DEP0000 EXC0000 LOC0000 OBJ0000 TSK0000 UIM0000`
  to the MSGID list.
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
- Optional parameters: `IF COND(%PARMS *GE n *AND %ADDR(&VAR) *NE *NULL)`.
- Work files live in `QTEMP`; inline SQL uses `RUNSQL ... COMMIT(*NONE)`;
  file repositioning uses `OVRDBF ... POSITION(*RRN &N) SECURE(*YES)` followed by
  `DLTOVR` — always scope and remove overrides.

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

- **Long descriptive names** with `FOR COLUMN` short (≤10) system names.
- Identity `BIGINT` primary key named `<entity>_id`.
- `NOT NULL DEFAULT` on business columns; `CHECK` constraints where the domain
  is enumerable.
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
  - Mixed-case text parameters: `TYPE(*CHAR) VARY(*YES *INT2) CASE(*MIXED)`.
  - Special values via `SPCVAL((*NONE ' '))` mapping to storable values.
  - Selection lists via `CHOICE(*PGM) CHOICEPGM(<…CHC program>)`.
  - Shared-CPP commands pass their mode as
    `PARM KWD(MODE) TYPE(*CHAR) CONSTANT('*ADD')`.
- Every command ends with the hidden cross-reference parameter:

  ```text
               PARM       KWD(PGMXRF) TYPE(QPGMXRF) PGM(*YES)
   QPGMXRF:    QUAL       TYPE(*NAME) LEN(10) CONSTANT(<CPP name>)
               QUAL       TYPE(*NAME) LEN(10) CONSTANT(<command name>)
  ```

  The CPP receives it as a 20-byte qualified name (`pxPgmXrf` / `&PGMXRF`).

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
  5. `'<CMD>/ERROR/MESSAGES'` — `:DL COMPACT.` list, message text pulled live
     via `&msg(MSGID,MSGF,*LIBL,nosub).`
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

- Product messages live in one message file (`TMMSG`), built from
  `QREXSRC/TMMSG.REXX`; IDs are grouped by prefix (`TSK*`, `OBJ*`, `LOC*`,
  `DEP*`, `EXC*`, `UIM*`).
- Programs send message IDs, not hardcoded text, wherever a message exists;
  status messages use `CPDA0FF`.
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

---

## 10. Legacy and scratch code

- **Scratch:** `JUNK*` members are experiments. Git-ignores them going forward;
  never reference or promote them, and don't cite them as precedent.
- **Third-party:** members with external authorship headers (e.g. Carsten
  Flensburg's `CPYMSGD*`, Giuseppe Costagliola's `SQL2XLSX*`, Scott Klement's
  YAJL/JDBCR4 material; `BLDOBJ` is a branched fork of Klement's BUILD tool)
  keep their original style and attribution. Fix bugs; don't restyle.
- **Legacy fixed-form:** don't expand fixed-form code. Small fix = match the
  existing style locally; real enhancement = convert to `**FREE` first (add a
  MODIFICATIONS entry for the conversion).
- **BSLIB vs RBUTL duplicates:** members shared by both repos are expected to be
  byte-identical (verify with `scripts/refresh-commit.ps1` workflows). When they
  drift, RBUTL is authoritative for TM/RB members; reconcile promptly.
