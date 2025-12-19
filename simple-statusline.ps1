<# 
.SYNOPSIS
    Simple Claude Code StatusLine Script (PowerShell Version)
    Shows only context usage/progress information

.DESCRIPTION
    Add to your .claude/settings.json (global or project):
    {
      "statusLine": {
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%\\.claude\\simple-statusline.ps1\""
      }
    }
#>

param(
    [switch]$ShowScale,
    [ValidateSet("min", "max", "mid", "animate")]
    [string]$Mode
)

# Force UTF-8 output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Configure the progress bar ratio (1.0 = 100 chars, 0.5 = 50 chars, etc.)
$BAR_RATIO = 0.5

# Block character for progress bar
$BLOCK = [char]0x2588  # █

# ANSI escape character
$ESC = [char]0x1B

# Get colors for given percentage - returns hashtable with bar_color and empty_block_color
function Get-ColorsForPercentage {
    param([int]$Pct)
    
    $colors = @{}
    
    if ($Pct -lt 10) {
        $colors.bar = "$ESC[38;2;24;53;34m"      # RGB(24,53,34) - dark green
        $colors.empty = "$ESC[38;5;235m"
    } elseif ($Pct -lt 20) {
        $colors.bar = "$ESC[38;2;21;62;33m"      # RGB(21,62,33) - dark green
        $colors.empty = "$ESC[38;5;235m"
    } elseif ($Pct -lt 30) {
        $colors.bar = "$ESC[38;2;16;70;32m"      # RGB(16,70,32) - green
        $colors.empty = "$ESC[38;5;235m"
    } elseif ($Pct -lt 40) {
        $colors.bar = "$ESC[38;2;11;78;28m"      # RGB(11,78,28) - green
        $colors.empty = "$ESC[38;5;235m"
    } elseif ($Pct -lt 50) {
        $colors.bar = "$ESC[38;2;6;87;22m"       # RGB(6,87,22) - bright green
        $colors.empty = "$ESC[38;5;235m"
    } elseif ($Pct -lt 60) {
        $colors.bar = "$ESC[38;2;46;89;0m"       # RGB(46,89,0) - yellow-green
        $colors.empty = "$ESC[38;5;236m"
    } elseif ($Pct -lt 70) {
        $colors.bar = "$ESC[38;2;93;79;0m"       # RGB(93,79,0) - olive/yellow
        $colors.empty = "$ESC[38;5;237m"
    } elseif ($Pct -lt 80) {
        $colors.bar = "$ESC[38;2;131;58;0m"      # RGB(131,58,0) - orange
        $colors.empty = "$ESC[38;5;238m"
    } elseif ($Pct -lt 90) {
        $colors.bar = "$ESC[38;2;161;7;0m"       # RGB(161,7,0) - red-orange
        $colors.empty = "$ESC[38;5;238m"
    } else {
        $colors.bar = "$ESC[38;2;179;0;0m"       # RGB(179,0,0) - red
        $colors.empty = "$ESC[38;5;238m"
    }
    
    return $colors
}

# Get model badge color based on model name
function Get-ModelColor {
    param([string]$Model)
    
    if ($Model -like "*Sonnet*") {
        return "$ESC[48;2;163;190;140m$ESC[1m$ESC[38;2;46;52;64m"  # a3be8c bg
    } elseif ($Model -like "*Opus*") {
        return "$ESC[48;2;208;135;112m$ESC[1m$ESC[38;2;46;52;64m"  # d08770 bg
    } elseif ($Model -like "*Haiku*") {
        return "$ESC[48;2;129;161;193m$ESC[1m$ESC[38;2;46;52;64m"  # 81a1c1 bg
    } else {
        return "$ESC[48;2;216;222;233m$ESC[1m$ESC[38;2;46;52;64m"  # d8dee9 bg
    }
}

# Create a string of repeated block characters
function Get-Blocks {
    param([int]$Count)
    
    if ($Count -le 0) { return "" }
    
    $result = ""
    for ($i = 0; $i -lt $Count; $i++) {
        $result += $BLOCK
    }
    return $result
}

# Center text in a fixed width field (16 characters)
function Center-Text {
    param([string]$Text)
    
    $width = 16
    $textLen = $Text.Length
    $padding = [math]::Floor(($width - $textLen) / 2)
    $rightPadding = $width - $textLen - $padding
    
    return (" " * $padding) + $Text + (" " * $rightPadding)
}

# Get formatted cwd and git branch suffix
function Get-CwdSuffix {
    param([string]$Cwd)
    
    if ([string]::IsNullOrEmpty($Cwd)) {
        return ""
    }
    
    # Shorten home directory to ~
    $cwdShort = $Cwd -replace [regex]::Escape($env:USERPROFILE), "~"
    
    # Get git branch if in a git repo
    $gitBranch = $null
    try {
        $originalLocation = Get-Location
        Set-Location $Cwd -ErrorAction Stop
        $gitBranch = git branch --show-current 2>$null
        Set-Location $originalLocation
    } catch {
        # Not a git repo or git not available
    }
    
    if ($gitBranch) {
        return " $cwdShort [$gitBranch]"
    } else {
        return " $cwdShort"
    }
}

# Show scale demo
function Show-Scale {
    param(
        [int]$Min,
        [int]$Max,
        [string]$ScaleMode
    )
    
    $pct = switch ($ScaleMode) {
        "min" { $Min }
        "max" { $Max }
        "mid" { [math]::Floor(($Min + $Max) / 2) }
    }
    
    $barLength = [math]::Round(100 * $BAR_RATIO)
    $filledBlocks = [math]::Round($pct * $BAR_RATIO)
    $emptyBlocks = $barLength - $filledBlocks
    
    $colors = Get-ColorsForPercentage -Pct $pct
    $reset = "$ESC[0m"
    
    $filled = Get-Blocks -Count $filledBlocks
    $empty = Get-Blocks -Count $emptyBlocks
    
    $progressBar = $colors.bar + $filled + $colors.empty + $empty + $reset
    
    Write-Host ("{0,3}-{1,3}%: {2}" -f $Min, $Max, $progressBar)
}

# Show single animated bar
function Show-SingleBar {
    param([int]$Pct)
    
    $barLength = [math]::Round(100 * $BAR_RATIO)
    $filledBlocks = [math]::Round($Pct * $BAR_RATIO)
    $emptyBlocks = $barLength - $filledBlocks
    
    $colors = Get-ColorsForPercentage -Pct $Pct
    $reset = "$ESC[0m"
    
    $filled = Get-Blocks -Count $filledBlocks
    $empty = Get-Blocks -Count $emptyBlocks
    
    $progressBar = $colors.bar + $filled + $colors.empty + $empty + $reset
    
    Write-Host ("`r{0,3}%: {1}" -f $Pct, $progressBar) -NoNewline
}

# Display scale demo mode
function Display-Mode {
    param([string]$DisplayMode)
    
    $header = switch ($DisplayMode) {
        "min" { "Color Scale Demo (showing range with minimum value):" }
        "max" { "Color Scale Demo (showing range with maximum value):" }
        "mid" { "Color Scale Demo (showing range with midpoint value):" }
    }
    
    Write-Host $header
    Write-Host ""
    
    Show-Scale -Min 0 -Max 9 -ScaleMode $DisplayMode
    Show-Scale -Min 10 -Max 19 -ScaleMode $DisplayMode
    Show-Scale -Min 20 -Max 29 -ScaleMode $DisplayMode
    Show-Scale -Min 30 -Max 39 -ScaleMode $DisplayMode
    Show-Scale -Min 40 -Max 49 -ScaleMode $DisplayMode
    Show-Scale -Min 50 -Max 59 -ScaleMode $DisplayMode
    Show-Scale -Min 60 -Max 69 -ScaleMode $DisplayMode
    Show-Scale -Min 70 -Max 79 -ScaleMode $DisplayMode
    Show-Scale -Min 80 -Max 89 -ScaleMode $DisplayMode
    Show-Scale -Min 90 -Max 100 -ScaleMode $DisplayMode
}

# Handle --ShowScale argument
if ($ShowScale) {
    if ($Mode -eq "animate" -or [string]::IsNullOrEmpty($Mode)) {
        # Animate mode
        try {
            while ($true) {
                for ($pct = 0; $pct -le 100; $pct++) {
                    Show-SingleBar -Pct $pct
                    Start-Sleep -Milliseconds 100
                }
                Start-Sleep -Milliseconds 500
            }
        } finally {
            Write-Host ""
        }
    } else {
        Display-Mode -DisplayMode $Mode
    }
    exit 0
}

# Main functionality - read JSON from stdin
$jsonInput = @($Input) -join "`n"

if ([string]::IsNullOrWhiteSpace($jsonInput)) {
    Write-Host "No input received"
    exit 1
}

try {
    $data = $jsonInput | ConvertFrom-Json
    
    $modelName = if ($data.model.display_name) { $data.model.display_name } else { "Claude" }
    $transcriptPath = $data.transcript_path
    $cwd = $data.cwd
    
    # Determine context limit based on model
    if ($modelName -like "*Opus*") {
        $contextLimit = 200000
    } elseif ($modelName -like "*Sonnet*") {
        $contextLimit = 200000
    } else {
        $contextLimit = 200000
    }
    
    $totalTokens = 0
    
    # Parse transcript file if it exists
    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        $lines = Get-Content $transcriptPath -Encoding UTF8 -ErrorAction SilentlyContinue
        
        $mostRecentUsage = $null
        $mostRecentTimestamp = $null
        
        foreach ($line in $lines) {
            try {
                $entry = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
                
                # Skip sidechain entries
                if ($entry.isSidechain) { continue }
                
                # Check for usage data
                if ($entry.message.usage) {
                    $timestamp = $entry.timestamp
                    if ($timestamp -and (!$mostRecentTimestamp -or $timestamp -gt $mostRecentTimestamp)) {
                        $mostRecentTimestamp = $timestamp
                        $mostRecentUsage = $entry.message.usage
                    }
                }
            } catch {
                continue
            }
        }
        
        if ($mostRecentUsage) {
            $inputTokens = if ($mostRecentUsage.input_tokens) { [int]$mostRecentUsage.input_tokens } else { 0 }
            $cacheRead = if ($mostRecentUsage.cache_read_input_tokens) { [int]$mostRecentUsage.cache_read_input_tokens } else { 0 }
            $cacheCreate = if ($mostRecentUsage.cache_creation_input_tokens) { [int]$mostRecentUsage.cache_creation_input_tokens } else { 0 }
            $totalTokens = $inputTokens + $cacheRead + $cacheCreate
        }
    }
    
    # Get colors and format output
    $modelColor = Get-ModelColor -Model $modelName
    $reset = "$ESC[0m"
    $textColor = "$ESC[38;5;250m"
    
    # Handle case where no usage data available yet
    if ($totalTokens -eq 0 -and $transcriptPath) {
        $suffix = Get-CwdSuffix -Cwd $cwd
        $centeredName = Center-Text -Text $modelName
        Write-Host "$modelColor$centeredName$reset ${textColor}context size N/A$suffix$reset"
        exit 0
    }
    
    # Calculate percentage
    $progressPct = [math]::Min(100, [math]::Floor($totalTokens * 100 / $contextLimit))
    
    # Format token counts
    $formattedTokens = "{0}k" -f [math]::Floor($totalTokens / 1000)
    $formattedLimit = "{0}k" -f [math]::Floor($contextLimit / 1000)
    
    # Create progress bar
    $barLength = [math]::Round(100 * $BAR_RATIO)
    $filledBlocks = [math]::Round($progressPct * $BAR_RATIO)
    $emptyBlocks = $barLength - $filledBlocks
    
    $colors = Get-ColorsForPercentage -Pct $progressPct
    $centeredName = Center-Text -Text $modelName
    $suffix = Get-CwdSuffix -Cwd $cwd
    
    $filled = Get-Blocks -Count $filledBlocks
    $empty = Get-Blocks -Count $emptyBlocks
    
    $progressBar = $modelColor + $centeredName + $reset
    $progressBar += $colors.bar + $filled
    $progressBar += $colors.empty + $empty
    $progressBar += $reset + $textColor
    $progressBar += " $progressPct% ($formattedTokens/$formattedLimit)"
    $progressBar += $suffix + $reset
    
    Write-Host $progressBar
    
} catch {
    Write-Host "Error: $_"
    exit 1
}