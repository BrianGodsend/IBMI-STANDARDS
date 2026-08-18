<#
.SYNOPSIS
Refreshes everything derived from the canonical CODING-STANDARDS.md.

.DESCRIPTION
CODING-STANDARDS.md in this repository is the canonical standard. Two things are
derived from it and must never lag behind it:

  1. CODING-STANDARDS.html in this repository -- the styled render, rebuilt with
     pandoc (see README.md).
  2. CODING-STANDARDS.md in every sibling IBM i repository -- an identical copy,
     so the standard travels with the code.

Both are refreshed here rather than by hand, because a derivative that is only
updated when someone remembers is a derivative that goes stale. The render is
rebuilt FIRST: if pandoc fails there is no reason to start propagating.

An IBM i repository is any sibling directory (same parent as this repo) that
contains a QRPGLESRC, QCLSRC, or QSQLSRC source directory AND is a git
repository. Source directories alone are not enough: a reference-only checkout
has nowhere to carry the standard to. Those are reported as SKIP rather than
passed over in silence, so a repository that is missing its .git by accident is
still visible.

The HTML is NOT propagated -- it exists only here, for offline reading.

Edit the canonical file, run this script, then commit the refreshed files: the
markdown and the HTML here, the markdown in each affected sibling.

.PARAMETER Check
Report what is stale or drifted; make no changes.

.PARAMETER NoHtml
Skip the render and only propagate the markdown. For the case where pandoc is
not available and the copy still needs to go out -- the HTML is then left stale
on purpose, which the summary says out loud.

.EXAMPLE
./sync-standards.ps1
Rebuild the render, then sync all sibling IBM i repos from the canonical copy.

.EXAMPLE
./sync-standards.ps1 -Check
Report a stale render and any drifted repo copies, changing nothing.
#>
param([switch]$Check, [switch]$NoHtml)

$canonical = Join-Path $PSScriptRoot 'CODING-STANDARDS.md'
if (-not (Test-Path $canonical)) {
    throw "Canonical file not found: $canonical"
}
$canonicalHash = (Get-FileHash $canonical).Hash
$parent  = Split-Path -Parent $PSScriptRoot
$htmlOut = Join-Path $PSScriptRoot 'CODING-STANDARDS.html'
$stale   = $false

# ---------------------------------------------------------------------------
# 1. The render.
#
# Rebuilt only when the markdown is newer, so an otherwise no-op run does not
# leave a modified file in the working tree for no reason.
# ---------------------------------------------------------------------------
if ($NoHtml) {
    Write-Host "SKIP    CODING-STANDARDS.html (-NoHtml)"
    $stale = $true
} else {
    $needsRender = (-not (Test-Path $htmlOut)) -or
        ((Get-Item $canonical).LastWriteTime -gt (Get-Item $htmlOut).LastWriteTime)

    if (-not $needsRender) {
        Write-Host "OK      CODING-STANDARDS.html"
    } elseif ($Check) {
        Write-Host "STALE   CODING-STANDARDS.html"
        $stale = $true
    } elseif (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
        # Not fatal: the copies are still worth propagating, and refusing to
        # sync because a rendering tool is missing helps nobody. But say so
        # plainly -- a silently stale render is the whole problem this solves.
        Write-Warning "pandoc not found; CODING-STANDARDS.html left STALE. Run pandoc_setup.cmd."
        $stale = $true
    } else {
        $template = Join-Path $PSScriptRoot 'github-markdown.html'
        $css      = Join-Path $env:APPDATA 'pandoc\github-markdown.css'
        pandoc --from gfm --to html5 --standalone --embed-resources --mathjax `
            --template $template --css $css --syntax-highlighting tango `
            --metadata title="IBM i Coding Standards" `
            --output $htmlOut $canonical
        if ($LASTEXITCODE -ne 0) {
            throw "pandoc failed ($LASTEXITCODE); nothing propagated."
        }
        Write-Host "RENDER  CODING-STANDARDS.html"
    }
}

# ---------------------------------------------------------------------------
# 2. The sibling copies.
# ---------------------------------------------------------------------------
foreach ($repo in Get-ChildItem $parent -Directory | Where-Object { $_.FullName -ne $PSScriptRoot }) {
    $srcDirs = @('QRPGLESRC', 'QCLSRC', 'QSQLSRC') |
        Where-Object { Test-Path (Join-Path $repo.FullName $_) }
    if (-not $srcDirs) { continue }

    # A reference-only checkout has nowhere to carry the standard to, so skip
    # anything that is not a git repository -- but say so, since a silently
    # skipped repo is how one gets left behind.
    if (-not (Test-Path (Join-Path $repo.FullName '.git'))) {
        Write-Host "SKIP    $($repo.Name) (not a git repository)"
        continue
    }

    $target = Join-Path $repo.FullName 'CODING-STANDARDS.md'
    $inSync = (Test-Path $target) -and ((Get-FileHash $target).Hash -eq $canonicalHash)

    if ($inSync) {
        Write-Host "OK      $($repo.Name)"
    } elseif ($Check) {
        Write-Host "DRIFT   $($repo.Name)"
    } else {
        Copy-Item $canonical $target -Force
        Write-Host "SYNCED  $($repo.Name)"
    }
}

if ($stale) {
    Write-Host ""
    Write-Host "CODING-STANDARDS.html is stale -- regenerate before committing."
}
