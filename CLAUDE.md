# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SnafflerWrap is a single-file PowerShell interactive launcher for [Snaffler](https://github.com/SnaffCon/Snaffler), a tool used in security assessments to find interesting files on network shares. The wrapper handles Snaffler download/location, target scoping, output naming, and argument construction through a guided CLI prompt flow.

## Running the script

```powershell
.\Invoke-Snaffler.ps1
```

Requires PowerShell 5.1+. Must be run on Windows (launches `Snaffler.exe`). No build step or dependencies beyond PowerShell itself.

## Architecture

The entire script is `Invoke-Snaffler.ps1` — a linear, interactive flow with no modules or dot-sourced files:

1. **Download or locate** `Snaffler.exe` — either fetches the latest release from the GitHub API (`SnaffCon/Snaffler`) to `C:\Snaffler\`, or prompts for an existing install path.
2. **Target/scope selection** — four modes driven by a numeric menu:
   - `1` = auto domain discovery (no flags passed)
   - `2` = named domain (`-d`) + optional DC (`-c`)
   - `3` = comma-separated hosts or CSV path (`-n`)
   - `4` = local file path (`-i`)
3. **Output filename** — auto-generated as `.\Output\yyyyMMdd-HHmm-<COMPUTERNAME>.txt`; user can override.
4. **Optional parameters** — verbosity (`-v`, default `1`/Info), max threads (`-x`, default `30`), custom rules path (`-p`, default `./rules`).
5. **Fixed flags** — `-s` (stdout) and `-y` (TAB-separated output, compatible with [SnafflerParser](https://github.com/zh54321/SnafflerParser)) are always appended.
6. **Summary + confirmation** — prints the full command and prompts before launching.

### Helper functions

- `Write-Banner` — renders the ASCII art header.
- `Prompt-Value` — reusable interactive prompt with label, description, default, and flag display.

## Key conventions

- Verbosity is collected as a numeric string (`0`–`3`) and mapped to Snaffler's named levels (`Data`, `Info`, `Debug`, `Trace`) before being passed as `-v`.
- The script `Set-Location` to the directory containing `Snaffler.exe` before building the argument list, so relative paths (e.g. `./rules`) resolve against the Snaffler directory.
- Output directory is created automatically if it doesn't exist.
- Not all Snaffler switches are exposed — the README notes that missing options should be requested via issues or PRs.
