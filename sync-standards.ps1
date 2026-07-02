<#
.SYNOPSIS
Copies the canonical CODING-STANDARDS.md into every sibling IBM i repository.

.DESCRIPTION
An IBM i repository is any sibling directory (same parent as this repo) that
contains a QRPGLESRC, QCLSRC, or QSQLSRC source directory. Each one gets an
identical copy of CODING-STANDARDS.md at its root so the standard travels with
the code.

Edit the canonical file in this repository, run this script, then commit the
refreshed copy in each affected repo.

.PARAMETER Check
Report which repos are in sync or drifted; make no changes.

.EXAMPLE
./sync-standards.ps1
Sync all sibling IBM i repos from the canonical copy.

.EXAMPLE
./sync-standards.ps1 -Check
List repos whose copy differs from the canonical without changing anything.
#>
param([switch]$Check)

$canonical = Join-Path $PSScriptRoot 'CODING-STANDARDS.md'
if (-not (Test-Path $canonical)) {
    throw "Canonical file not found: $canonical"
}
$canonicalHash = (Get-FileHash $canonical).Hash
$parent = Split-Path -Parent $PSScriptRoot

foreach ($repo in Get-ChildItem $parent -Directory | Where-Object { $_.FullName -ne $PSScriptRoot }) {
    $srcDirs = @('QRPGLESRC', 'QCLSRC', 'QSQLSRC') |
        Where-Object { Test-Path (Join-Path $repo.FullName $_) }
    if (-not $srcDirs) { continue }

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
