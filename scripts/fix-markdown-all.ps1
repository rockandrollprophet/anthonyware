# fix-markdown-all.ps1 - Automatically fix common markdown linting issues
# Fixes: MD031, MD022, MD032, MD026, MD034, MD040, MD060

param(
    [string]$Path = ".."
)

$ErrorActionPreference = "Continue"

Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ Markdown Linting Fixer (PowerShell)                 ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$repoRoot = Resolve-Path $Path
Write-Host "Scanning: $repoRoot" -ForegroundColor Yellow
Write-Host ""

# Find all markdown files
$markdownFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse -File | 
    Where-Object { $_.FullName -notmatch 'node_modules|\.git|build|dist' }

$fileCount = $markdownFiles.Count
Write-Host "Found $fileCount markdown files" -ForegroundColor Green
Write-Host ""

$fixedCount = 0

foreach ($file in $markdownFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor White
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Fix MD026: Remove trailing punctuation from headings
    $content = $content -replace '(^#{1,6} .+)[:.!?]$', '$1'
    
    # Fix MD034: Wrap bare URLs in angle brackets
    $content = $content -replace '(?m)^(- \*\*[^*]+\*\*:\s+)(https?://[^\s<>]+)$', '$1<$2>'
    $content = $content -replace '(?m)^(\s+)(https?://[^\s<>]+)$', '$1<$2>'
    
    # Split into lines for more complex operations
    $lines = $content -split "`r?`n"
    $newLines = @()
    $modified = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $prevLine = if ($i -gt 0) { $lines[$i - 1] } else { "" }
        $nextLine = if ($i -lt $lines.Count - 1) { $lines[$i + 1] } else { "" }
        
        # MD022: Add blank line before headings (except at start)
        if ($line -match '^#{1,6} ' -and $i -gt 0 -and $prevLine.Trim() -ne "" -and $prevLine -notmatch '^-+$') {
            if ($newLines.Count -gt 0 -and $newLines[$newLines.Count - 1] -ne "") {
                $newLines += ""
                $modified = $true
            }
        }
        
        $newLines += $line
        
        # MD022: Add blank line after headings
        if ($line -match '^#{1,6} ' -and $nextLine.Trim() -ne "" -and $nextLine -notmatch '^-+$') {
            if ($i -lt $lines.Count - 1) {
                $peek = $lines[$i + 1]
                if ($peek -ne "") {
                    $newLines += ""
                    $modified = $true
                }
            }
        }
        
        # MD031: Add blank line before fenced code blocks
        if ($line -match '^\s*```' -and -not ($prevLine -match '^\s*```')) {
            if ($prevLine.Trim() -ne "" -and $newLines.Count -gt 0) {
                # Check if we just added this line
                if ($newLines[$newLines.Count - 1] -ne $line) {
                    # Remove last line and add blank line before it
                    $newLines = $newLines[0..($newLines.Count - 2)]
                    if ($newLines[$newLines.Count - 1] -ne "") {
                        $newLines += ""
                        $modified = $true
                    }
                    $newLines += $line
                }
            }
        }
        
        # MD031: Add blank line after fenced code blocks  
        if ($line -match '^\s*```' -and $prevLine -match '^\s*```') {
            # This is closing fence, add blank after if next line isn't blank
            if ($nextLine.Trim() -ne "") {
                $newLines += ""
                $modified = $true
            }
        }
        
        # MD032: Add blank line before lists
        if ($line -match '^\d+\.\s' -or $line -match '^[-*+]\s') {
            if ($prevLine.Trim() -ne "" -and $prevLine -notmatch '^\d+\.\s' -and $prevLine -notmatch '^[-*+]\s' -and $prevLine -notmatch '^#{1,6} ') {
                # Remove last added line and add blank before it
                if ($newLines.Count -gt 0 -and $newLines[$newLines.Count - 1] -ne "") {
                    $newLines = $newLines[0..($newLines.Count - 2)]
                    $newLines += ""
                    $newLines += $line
                    $modified = $true
                }
            }
        }
    }
    
    $content = $newLines -join "`n"
    
    # Fix MD060: Add spaces in table separators
    $content = $content -replace '\|(-+)\|', '| $1 |'
    
    # Check if file was modified
    if ($content -ne $originalContent) {
        # Write back to file
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        
        $fixedCount++
        Write-Host "  ✓ Fixed" -ForegroundColor Green
    } else {
        Write-Host "  - No changes needed" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ Markdown Linting Fix Complete                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total files:  $fileCount" -ForegroundColor White
Write-Host "  Files fixed:  $fixedCount" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Some complex issues may require manual fixes." -ForegroundColor Yellow
Write-Host "      Run markdownlint in VS Code to verify remaining issues." -ForegroundColor Yellow
Write-Host ""
