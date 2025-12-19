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

### Step 1: Download the script

1. Download `simple-statusline.ps1` from this repository
2. Save it somewhere you can find it (like your Downloads folder)

### Step 2: Open PowerShell

1. Press `Windows Key + X` on your keyboard
2. Click **"Windows PowerShell"** or **"Terminal"** from the menu
3. A window with text will open - this is PowerShell

### Step 3: Copy the script to the right place

Copy and paste these commands into PowerShell **one at a time**, pressing Enter after each:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude"
```

This creates a folder called `.claude` in your user folder.

Now copy the script file. **Change the path** if you saved it somewhere other than Downloads:

```powershell
Copy-Item "$env:USERPROFILE\Downloads\simple-statusline.ps1" "$env:USERPROFILE\.claude\"
```

### Step 4: Fix the file so it displays correctly

Copy and paste this command into PowerShell and press Enter:

```powershell
$file = "$env:USERPROFILE\.claude\simple-statusline.ps1"
$content = Get-Content $file -Raw
[System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($true))
```

This fixes the file encoding so the progress bar displays correctly.

### Step 5: Tell Claude Code to use the statusline

1. Copy this text to your clipboard:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%\\.claude\\simple-statusline.ps1\""
  }
}
```

2. Open File Explorer and paste this into the address bar, then press Enter:
   ```
   %USERPROFILE%\.claude
   ```

3. Look for a file called `settings.json`:
   - **If it exists:** Open it with Notepad, and add the `"statusLine"` section to the existing settings
   - **If it doesn't exist:** Right-click in the folder → New → Text Document, name it `settings.json`, open it with Notepad, and paste the text from step 1

4. Save the file (Ctrl+S) and close Notepad

### Step 6: Restart Claude Code

1. Completely close Claude Code (right-click the icon in your taskbar and click Close, or press Alt+F4)
2. Open Claude Code again
3. You should now see the colorful statusline at the bottom

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