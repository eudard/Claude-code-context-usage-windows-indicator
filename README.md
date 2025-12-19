# Claude Code StatusLine for Windows

A PowerShell statusline script extension for Claude Code that displays context usage with a color-coded progress bar.

![Demo](https://img.shields.io/badge/PowerShell-5.1%2B-blue) ![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)

## Prerequisites

- **Claude Code** — This script extends an existing Claude Code installation. [Install Claude Code](https://claude.com/claude-code) if you haven't already.
- **Windows 10/11** with PowerShell 5.1+ (pre-installed) or PowerShell Core 7+
- **Windows Terminal** (recommended for best color support)
- **Git** (optional, for branch display)

## Features

- **Color-coded progress bar** — Green → Yellow → Orange → Red as context fills up
- **Model badge** — Color-coded display for Sonnet, Opus, and Haiku models
- **Token usage** — Shows current tokens vs context limit (e.g., `45% (90k/200k)`)
- **Git branch** — Displays current branch when in a git repository
- **Working directory** — Shows current path with `~` shorthand for home

## Installation

### Step 1: Copy the script to Claude's config directory

```powershell
# Create the config directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude"

# Copy the script (adjust source path as needed)
Copy-Item "simple-statusline.ps1" "$env:USERPROFILE\.claude\"
```

### Step 2: Fix file encoding

The script uses Unicode block characters that require UTF-8 BOM encoding:

```powershell
$file = "$env:USERPROFILE\.claude\simple-statusline.ps1"
$content = Get-Content $file -Raw
[System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($true))
```

### Step 3: Configure Claude Code

Edit or create `%USERPROFILE%\.claude\settings.json` and add the statusline configuration:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%\\.claude\\simple-statusline.ps1\""
  }
}
```

### Step 4: Restart Claude Code

Close and reopen Claude Code to activate the statusline.

## Testing

You can test the script manually to verify it works:

```powershell
# Show color scale demo (static)
& "$env:USERPROFILE\.claude\simple-statusline.ps1" -ShowScale -Mode mid

# Show animated demo
& "$env:USERPROFILE\.claude\simple-statusline.ps1" -ShowScale -Mode animate

# Press Ctrl+C to stop the animation
```

### Expected Output

```
Color Scale Demo (showing range with midpoint value):

  0-  9%: ████████████████████████████████████████████████████
 10- 19%: ████████████████████████████████████████████████████
 20- 29%: ████████████████████████████████████████████████████
 ...
 90-100%: ████████████████████████████████████████████████████
```

The bars should show a gradient from dark green (0%) to red (100%).

## Troubleshooting

### Characters display as `â–ˆ` or similar garbage

The file encoding is incorrect. Follow Step 3 above to re-save with UTF-8 BOM.

### No colors / ANSI codes visible as text

Your terminal doesn't support ANSI colors. Solutions:
- Use [Windows Terminal](https://aka.ms/terminal) instead of cmd.exe
- Use VS Code's integrated terminal
- Enable Virtual Terminal in legacy PowerShell:
  ```powershell
  Set-ItemProperty HKCU:\Console VirtualTerminalLevel -Type DWORD 1
  ```

### Script doesn't run / execution policy error

Run this command once to allow local scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### StatusLine not appearing in Claude Code

1. Verify the settings.json path is correct
2. Check for JSON syntax errors in settings.json
3. Ensure the script path uses `%USERPROFILE%` or the full path
4. Restart Claude Code completely

### "No input received" message

This is normal when running the script directly. The script expects JSON input from Claude Code via stdin. Use `-ShowScale` for manual testing.

## Customization

### Progress bar width

Edit the script and change `$BAR_RATIO`:

```powershell
$BAR_RATIO = 0.5   # 50 characters wide (default)
$BAR_RATIO = 1.0   # 100 characters wide
$BAR_RATIO = 0.3   # 30 characters wide
```

### Colors

The color scheme is defined in `Get-ColorsForPercentage`. Colors use RGB values via ANSI escape codes:

```powershell
$colors.bar = "$ESC[38;2;R;G;Bm"  # Foreground color
```

## Original Script

This is a PowerShell port of the original bash script by [srb3](https://github.com/srb3). The bash version works on Linux/macOS/WSL.

## License

MIT