#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive launcher for Snaffler.exe with auto-generated output filenames.

.DESCRIPTION
    Collects switch values from the user and launches Snaffler.exe.
    Output filename is auto-generated in the format: yyyyMMdd-HHmm-<target>.log

.EXAMPLE
    .\Invoke-Snaffler.ps1
    .\Invoke-Snaffler.ps1 -SnafflerPath "C:\Tools\Snaffler.exe"
#>

[CmdletBinding()]
param (
    [string]$SnafflerPath = ".\Snaffler.exe"
)

# ---------------------------------------------
#  Helpers
# ---------------------------------------------

function Write-Banner {
    Write-Host ""
    Write-Host "  =================================================" -ForegroundColor DarkYellow
    Write-Host "    ____             __________                    " -ForegroundColor Yellow
    Write-Host "   / __/__  ___ ____/ _/ / ___/__  ____           " -ForegroundColor Yellow
    Write-Host "  _\ \/ _ \/ _ '/ _/ _/ / -_) __/  __/           " -ForegroundColor DarkYellow
    Write-Host " /___/_//_/\_,_/_/ /_//_/\__/_/  \___/            " -ForegroundColor DarkYellow
    Write-Host "  =================================================" -ForegroundColor DarkYellow
    Write-Host "  Snaffler Interactive Launcher" -ForegroundColor Cyan
    Write-Host ""
}

function Prompt-Value {
    param (
        [string]$Label,
        [string]$Description,
        [string]$Default,
        [string]$Flag
    )

    Write-Host "  [$Flag]" -ForegroundColor Cyan -NoNewline
    Write-Host " $Label" -ForegroundColor White
    Write-Host "      $Description" -ForegroundColor DarkGray

    if ($Default) {
        Write-Host "      Default : " -ForegroundColor DarkGray -NoNewline
        Write-Host $Default -ForegroundColor DarkGreen
    }

    Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
    $input = Read-Host
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($input) -and $Default) {
        return $Default
    }
    return $input.Trim()
}

# ---------------------------------------------
#  Defaults
# ---------------------------------------------

$defaultVerbosity  = "1"
$defaultMaxThreads = "30"

# ---------------------------------------------
#  UI
# ---------------------------------------------

Clear-Host
Write-Banner

# -- Working directory ----------------------------------------------------
Write-Host "  Working directory : " -NoNewline -ForegroundColor DarkGray
Write-Host (Get-Location) -ForegroundColor Cyan
Write-Host "  Change directory? (press Enter to keep, or type a new path)" -ForegroundColor DarkGray
Write-Host "  Path    : " -ForegroundColor DarkGray -NoNewline
$newDir = (Read-Host).Trim()
if (-not [string]::IsNullOrWhiteSpace($newDir)) {
    Set-Location $newDir
    Write-Host "  [*] Working directory changed to: $(Get-Location)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "  -- Required ----------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# -n  Target(s)
$targets = Prompt-Value `
    -Flag "-n" `
    -Label "Target(s)" `
    -Description "Comma-separated list of targets (hostnames, IPs, or CIDR ranges)" `
    -Default ""

if ([string]::IsNullOrWhiteSpace($targets)) {
    Write-Host "  [!] At least one target is required (-n). Exiting." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------
#  Auto-generate output filename
# ---------------------------------------------

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$autoPath  = ".\Output\$timestamp.txt"

Write-Host "  -- Output ------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# -o  Output file
$outputFile = Prompt-Value `
    -Flag "-o" `
    -Label "Output file path" `
    -Description "Log file for results (press Enter to accept auto-generated name)" `
    -Default $autoPath

# ---------------------------------------------
#  Optional switches
# ---------------------------------------------

Write-Host "  -- Optional (press Enter to accept defaults) -------------------" -ForegroundColor DarkGray
Write-Host ""

# -v  Verbosity
$verbosityInput = Prompt-Value `
    -Flag "-v" `
    -Label "Verbosity level" `
    -Description "0=Data  1=Info  2=Debug  3=Trace" `
    -Default $defaultVerbosity

$verbosityMap = @{ "0" = "Data"; "1" = "Info"; "2" = "Debug"; "3" = "Trace" }
$verbosity = if ($verbosityMap.ContainsKey($verbosityInput)) { $verbosityMap[$verbosityInput] } else { $verbosityInput }

# -x  Max threads
$maxThreads = Prompt-Value `
    -Flag "-x" `
    -Label "Max threads" `
    -Description "Number of concurrent scanning threads" `
    -Default $defaultMaxThreads

# -i  File discovery path (optional)
$filePath = Prompt-Value `
    -Flag "-i" `
    -Label "File discovery path (optional)" `
    -Description "Path to perform file discovery. Leave blank to skip." `
    -Default ""

# -p  Custom ruleset path
Write-Host "  [-p]" -ForegroundColor Cyan -NoNewline
Write-Host " Custom ruleset path" -ForegroundColor White
Write-Host "      1 = ./rules  [default]" -ForegroundColor DarkGray
Write-Host "      2 = Enter custom path" -ForegroundColor DarkGray
Write-Host "      3 = None (use default rules)" -ForegroundColor DarkGray
Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
$rulesInput = (Read-Host).Trim()
Write-Host ""

switch ($rulesInput) {
    "2" {
        Write-Host "      Path    : " -ForegroundColor DarkGray -NoNewline
        $rulesPath = (Read-Host).Trim()
        Write-Host ""
    }
    "3" { $rulesPath = "" }
    default { $rulesPath = "./rules" }
}

# ---------------------------------------------
#  Ensure output directory exists
# ---------------------------------------------

$outputDir = Split-Path -Parent $outputFile
if ($outputDir -and -not (Test-Path $outputDir)) {
    Write-Host "  [*] Creating output directory: $outputDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# ---------------------------------------------
#  Build argument list
# ---------------------------------------------

$argList = @(
    "-n", $targets
    "-o", $outputFile
    "-v", $verbosity
    "-x", $maxThreads
    "-s"
    "-y"
)

if (-not [string]::IsNullOrWhiteSpace($filePath)) {
    $argList += "-i", $filePath
}

if (-not [string]::IsNullOrWhiteSpace($rulesPath)) {
    $argList += "-p", $rulesPath
}

# ---------------------------------------------
#  Summary & confirmation
# ---------------------------------------------

Write-Host "  -- Launch Summary ----------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Executable : " -NoNewline -ForegroundColor DarkGray; Write-Host $SnafflerPath -ForegroundColor White
Write-Host "  Targets    : " -NoNewline -ForegroundColor DarkGray; Write-Host $targets      -ForegroundColor Green
Write-Host "  Output     : " -NoNewline -ForegroundColor DarkGray; Write-Host $outputFile   -ForegroundColor Green
Write-Host "  Verbosity  : " -NoNewline -ForegroundColor DarkGray; Write-Host $verbosity    -ForegroundColor White
Write-Host "  Threads    : " -NoNewline -ForegroundColor DarkGray; Write-Host $maxThreads   -ForegroundColor White
if (-not [string]::IsNullOrWhiteSpace($filePath)) {
    Write-Host "  File Path  : " -NoNewline -ForegroundColor DarkGray; Write-Host $filePath  -ForegroundColor White
}
if (-not [string]::IsNullOrWhiteSpace($rulesPath)) {
    Write-Host "  Rules Path : " -NoNewline -ForegroundColor DarkGray; Write-Host $rulesPath -ForegroundColor White
}
Write-Host "  Flags      : " -NoNewline -ForegroundColor DarkGray; Write-Host "-s -y"       -ForegroundColor White
Write-Host ""
Write-Host "  Full command:" -ForegroundColor DarkGray
Write-Host "  $SnafflerPath $($argList -join ' ')" -ForegroundColor DarkCyan
Write-Host ""

$confirm = Read-Host "  Launch Snaffler? [Y/n]"
if ($confirm -match '^[Nn]') {
    Write-Host ""
    Write-Host "  [!] Aborted." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------
#  Validate Snaffler binary exists
# ---------------------------------------------

if (-not (Test-Path $SnafflerPath)) {
    Write-Host ""
    Write-Host "  [!] Snaffler.exe not found at: $SnafflerPath" -ForegroundColor Red
    Write-Host "      Use: .\Invoke-Snaffler.ps1 -SnafflerPath 'C:\path\to\Snaffler.exe'" -ForegroundColor DarkGray
    exit 1
}

# ---------------------------------------------
#  Launch
# ---------------------------------------------

Write-Host ""
Write-Host "  [*] Starting Snaffler..." -ForegroundColor Cyan
Write-Host ""

try {
    & $SnafflerPath @argList
    Write-Host ""
    Write-Host "  [+] Snaffler finished. Output saved to: $outputFile" -ForegroundColor Green
    Write-Host ""
    Read-Host "  Press Enter to exit"
}
catch {
    Write-Host ""
    Write-Host "  [!] Failed to launch Snaffler: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}
