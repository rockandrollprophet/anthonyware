# Repo diff checker (PowerShell)
# Compares expected file list to actual files

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

# Build expected list from git; fallback to scanning
$expected = @()
if (Get-Command git -ErrorAction SilentlyContinue) {
    $expected = git -C $repoRoot ls-files | ForEach-Object { $_.Trim() } | Sort-Object
}
if (-not $expected) {
    $expected = Get-ChildItem -File -Recurse -Depth 5 | ForEach-Object {
        ($_.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/').Trim()
    } | Sort-Object
}

# Actual files (bounded depth, normalized paths)
$actual = Get-ChildItem -File -Recurse -Depth 5 | ForEach-Object {
    ($_.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/').Trim()
} | Sort-Object

$missing = $expected | Where-Object { $_ -notin $actual }
$extra   = $actual   | Where-Object { $_ -notin $expected }

Write-Host "=== Anthonyware Repo Diff Checker (PowerShell) ==="
Write-Host "Repo:" $repoRoot

Write-Host "`n--- Missing files (expected but not found) ---"
if ($missing) { $missing | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (none)" }

Write-Host "`n--- Extra files (present but not in expected list) ---"
if ($extra) { $extra | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (none)" }

Write-Host "`n=== Repo diff check complete ==="