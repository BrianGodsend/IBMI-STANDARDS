<#
.SYNOPSIS
Checks -- and optionally repairs -- ILEDoc @param tags in IBM i repos.

.DESCRIPTION
CODING-STANDARDS section 2.3 requires "@param var Description". VS Code's
Code for i renders the variable name twice, which invites dropping it, and
dropping it is silent: the extension binds tags to parameters BY POSITION and
compares nothing, so a doc block that falls out of step with its parameter
list re-attaches every later description to the wrong parameter and reads
perfectly well while doing it.

Nothing else catches that, which is why this exists. It reports two things:

  UNNAMED   a @param whose first word is not the parameter it documents
  MISMATCH  a doc block whose tag count differs from its parameter count

A MISMATCH means descriptions are attached to the wrong parameters TODAY. It
is never repaired automatically -- the alignment cannot be inferred, and
guessing is how a doc block starts lying. Fix those by hand, then re-run.

Only members whose first line is **FREE are read. Fixed-form source would
parse wrong, and quietly.

.PARAMETER Path
One repo or directory to check. Defaults to the current directory.

.PARAMETER All
Check every sibling IBM i repo instead, using the same rule as
sync-standards.ps1: a directory beside this one containing QRPGLESRC, QCLSRC,
or QSQLSRC and a .git.

Reporting on them is fine; sweeping them is not. BSLIB is developer scratch,
and RBUTL is production -- where a documentation-only change means either a
mass recompile nobody will run for a comment, or source left drifted from the
objects for the next developer to stumble onto. Read the report and stop.

.PARAMETER Fix
Insert the parameter name into every UNNAMED tag, and reflow that tag's text
to 76 columns. Blocks reported as MISMATCH are left untouched. Only tags that
actually change are rewritten -- a block already correct is not reflowed, so
the diff stays the size of the repair.

.EXAMPLE
./check-iledoc.ps1
Report unnamed tags and mismatches in the current repo.

.EXAMPLE
./check-iledoc.ps1 -All
Report across every sibling IBM i repo. A report, not a work list.

.EXAMPLE
./check-iledoc.ps1 -Path ..\BSLIB -Fix
Name and reflow the unnamed tags in one repo, holding back any mismatch.
#>
param([string]$Path, [switch]$All, [switch]$Fix)

$WIDTH = 76           # CODING-STANDARDS 1.4: RBUTL practice, well under 100
$CONT  = '//      '   # the house continuation indent

# ---------------------------------------------------------------------------
# Wrap one tag's text, first line under "// @param ", the rest indented.
# ---------------------------------------------------------------------------
function Format-Tag([string]$text) {
    $lead = '// @param '
    $out  = @()
    $cur  = $lead
    foreach ($w in ($text -split '\s+' | Where-Object { $_ -ne '' })) {
        if ($cur -ne $lead -and $cur -ne $CONT -and
            ($cur.Length + 1 + $w.Length) -gt $WIDTH) {
            $out += $cur
            $cur  = $CONT + $w
        } elseif ($cur -eq $lead -or $cur -eq $CONT) {
            $cur += $w
        } else {
            $cur += ' ' + $w
        }
    }
    if ($cur -ne $lead -and $cur -ne $CONT) { $out += $cur }
    return $out
}

# ---------------------------------------------------------------------------
# The parameter names of the declaration that follows a doc block.
#
# The block may precede a dcl-pr, or a dcl-proc whose dcl-pi carries the
# names. Parameters are separated by ';' and not by lines -- one can span
# several -- so the list is accumulated as text and split on the semicolon.
# ---------------------------------------------------------------------------
function Get-ParamName([string[]]$L, [int]$close) {
    $j = $close + 1
    while ($j -lt $L.Count -and $L[$j] -match '^\s*$') { $j++ }
    if ($j -ge $L.Count) { return $null }

    if     ($L[$j] -match '^\s*dcl-pr\s+(\S+)')   { $kind = 'pr'  ; $name = $Matches[1] }
    elseif ($L[$j] -match '^\s*dcl-proc\s+(\S+)') { $kind = 'proc'; $name = $Matches[1] }
    else   { return $null }
    $name = $name -replace ';$', ''

    $k = $j
    if ($kind -eq 'proc') {
        $k++
        while ($k -lt $L.Count -and $L[$k] -notmatch '(?i)\bdcl-pi\b') { $k++ }
        if ($k -ge $L.Count) { return $null }
    }
    $end  = if ($kind -eq 'pr') { 'end-pr' } else { 'end-pi' }
    $text = ''
    $line = $L[$k] -replace '(?i)^.*?\bdcl-p[ri]\b\s*([A-Za-z*][\w*]*)?', ''
    while ($true) {
        $seg = $line -replace '//.*$', ''
        if ($seg -match "(?i)\b$end\b") {
            $text += ' ' + ($seg -replace "(?i)\b$end\b.*$", '')
            break
        }
        $text += ' ' + $seg
        $k++
        if ($k -ge $L.Count) { break }
        $line = $L[$k]
    }
    $parts = $text -split ';'
    $names = @()
    for ($x = 1; $x -lt $parts.Count; $x++) {
        if ($parts[$x] -match '([A-Za-z#$@][\w#$@]*)') { $names += $Matches[1] }
    }
    return [pscustomobject]@{ Proc = $name; Names = $names }
}

# ---------------------------------------------------------------------------
# One member.
# ---------------------------------------------------------------------------
function Test-Member([string]$file, [string]$label) {
    $L = [System.IO.File]::ReadAllLines($file)
    if ($L.Count -eq 0 -or $L[0] -notmatch '(?i)^\s*\*\*FREE') { return }

    #  collect the @param groups of every doc block
    $blocks = @()
    $tags   = @()
    $in     = $false
    for ($i = 0; $i -lt $L.Count; $i++) {
        if ($L[$i] -match '^\s*///\s*$') {
            if ($in) {
                if ($tags.Count) { $blocks += ,@($i, $tags) }
                $in = $false; $tags = @()
            } else { $in = $true; $tags = @() }
            continue
        }
        if (-not $in) { continue }
        if ($L[$i] -match '^\s*//\s*@param\s+(.*)$') {
            $tags += [pscustomobject]@{ First = $i; Last = $i; Text = $Matches[1] }
        } elseif ($tags.Count -and $L[$i] -match '^\s*//\s{2,}(\S.*)$' -and
                  $L[$i] -notmatch '^\s*//\s*@' -and
                  $tags[-1].Last -eq $i - 1) {
            $tags[-1].Last  = $i
            $tags[-1].Text += ' ' + $Matches[1]
        }
    }

    #  rewrite bottom-up so earlier line numbers stay valid
    $unnamed = 0
    $lines   = [System.Collections.ArrayList]::new($L)
    for ($b = $blocks.Count - 1; $b -ge 0; $b--) {
        $close = $blocks[$b][0]
        $t     = $blocks[$b][1]
        $decl  = Get-ParamName $L $close
        if ($null -eq $decl) { continue }

        if ($t.Count -ne $decl.Names.Count) {
            Write-Host ("MISMATCH {0,-10} {1} ({2})  {3} tag{4}, {5} param{6}" -f
                $label, (Split-Path $file -Leaf), $decl.Proc,
                $t.Count, $(if ($t.Count -eq 1) {''} else {'s'}),
                $decl.Names.Count, $(if ($decl.Names.Count -eq 1) {''} else {'s'}))
            $script:mismatch++
            continue
        }

        $need = @()
        for ($x = 0; $x -lt $t.Count; $x++) {
            $body = $t[$x].Text.TrimStart()
            if ($body -notmatch ('(?i)^' + [regex]::Escape($decl.Names[$x]) + '(\s|$)')) {
                $need += $x
            }
        }
        if (-not $need.Count) { continue }
        $unnamed += $need.Count
        if (-not $Fix) { continue }

        for ($x = $t.Count - 1; $x -ge 0; $x--) {
            $body = ($t[$x].Text -replace '\s+', ' ').Trim()
            if ($body -notmatch ('(?i)^' + [regex]::Escape($decl.Names[$x]) + '(\s|$)')) {
                $body = $decl.Names[$x] + ' ' + $body
            }
            $new = Format-Tag $body
            $lines.RemoveRange($t[$x].First, $t[$x].Last - $t[$x].First + 1)
            $lines.InsertRange($t[$x].First, [string[]]$new)
        }
    }

    if ($unnamed) {
        if ($Fix) {
            [System.IO.File]::WriteAllLines($file, $lines.ToArray())
            Write-Host ("NAMED    {0,-10} {1}  {2} tag{3}" -f $label,
                (Split-Path $file -Leaf), $unnamed,
                $(if ($unnamed -eq 1) {''} else {'s'}))
        } else {
            Write-Host ("UNNAMED  {0,-10} {1}  {2} tag{3}" -f $label,
                (Split-Path $file -Leaf), $unnamed,
                $(if ($unnamed -eq 1) {''} else {'s'}))
        }
    }
    return $unnamed
}

# ---------------------------------------------------------------------------
# What to check.
# ---------------------------------------------------------------------------
$targets = @()
if (-not $All) {
    #  ONE REPO BY DEFAULT.  Sweeping every sibling is the thing not to
    #  do:  BSLIB is scratch and RBUTL is production, where a
    #  documentation-only change means either a mass recompile nobody
    #  will run for a comment, or source left drifted from the objects
    #  for the next developer to find.  -All still reports on them; it
    #  is the acting on it that is wrong.
    $root = if ($Path) { (Resolve-Path $Path).Path } else { (Get-Location).Path }
    $targets += [pscustomobject]@{ Label = (Split-Path $root -Leaf); Root = $root }
} else {
    $parent = Split-Path -Parent $PSScriptRoot
    foreach ($d in Get-ChildItem $parent -Directory) {
        $hasSrc = @('QRPGLESRC','QCLSRC','QSQLSRC') |
                  Where-Object { Test-Path (Join-Path $d.FullName $_) }
        if ($hasSrc -and (Test-Path (Join-Path $d.FullName '.git'))) {
            $targets += [pscustomobject]@{ Label = $d.Name; Root = $d.FullName }
        }
    }
}

$total = 0
$script:mismatch = 0
foreach ($t in $targets) {
    $src = Join-Path $t.Root 'QRPGLESRC'
    if (-not (Test-Path $src)) {
        if (-not $All) { Write-Host ("SKIP     {0,-10} no QRPGLESRC" -f $t.Label) }
        continue
    }
    $n = 0
    foreach ($f in Get-ChildItem $src -File -Include *.RPGLE,*.SQLRPGLE -Recurse) {
        $r = Test-Member $f.FullName $t.Label
        if ($r) { $n += $r }
    }
    if ($n -eq 0) { Write-Host ("OK       {0,-10} no unnamed @param" -f $t.Label) }
    $total += $n
}
Write-Host ""
Write-Host ("{0}: {1} tag{2}" -f $(if ($Fix) {'NAMED'} else {'UNNAMED'}), $total,
    $(if ($total -eq 1) {''} else {'s'}))
if ($script:mismatch) {
    #  Tags inside a mismatched block are NOT in the count above.  They
    #  cannot be repaired without knowing the alignment, so counting them
    #  would report work this script is not offering to do.
    Write-Host ("MISMATCH: {0} block{1} held back, fix by hand" -f
        $script:mismatch, $(if ($script:mismatch -eq 1) {''} else {'s'}))
}
