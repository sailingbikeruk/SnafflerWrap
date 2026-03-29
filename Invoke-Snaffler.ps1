#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive launcher for Snaffler.exe with auto-generated output filenames.

.DESCRIPTION
    Collects switch values from the user and launches Snaffler.exe.
    Output filename is auto-generated in the format: yyyyMMddHHmmss.txt

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
Write-Host "  Enter the directory containing Snaffler.exe (press Enter to keep current)" -ForegroundColor DarkGray
Write-Host "  Path    : " -ForegroundColor DarkGray -NoNewline
$newDir = (Read-Host).Trim()
if (-not [string]::IsNullOrWhiteSpace($newDir)) {
    Set-Location $newDir
    Write-Host "  [*] Working directory changed to: $(Get-Location)" -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------
#  Target / Scope selection
# ---------------------------------------------

Write-Host "  -- Target / Scope ----------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  How would you like to specify targets?" -ForegroundColor White
Write-Host ""
Write-Host "      1 = Discover domain automatically   [-d]" -ForegroundColor DarkGray
Write-Host "      2 = Comma-separated list of hosts   [-n]" -ForegroundColor DarkGray
Write-Host "      3 = CSV file containing hosts       [-n]" -ForegroundColor DarkGray
Write-Host "      4 = Local path (file discovery)     [-i]" -ForegroundColor DarkGray
Write-Host ""
Write-Host "      Choice  : " -ForegroundColor DarkGray -NoNewline
$targetMode = (Read-Host).Trim()
Write-Host ""

# Variables populated by each branch
$domainName   = ""
$dcFqdn       = ""
$hostList     = ""
$localPath    = ""

switch ($targetMode) {

    # ---- 1: Domain discovery ------------------------------------------------
    "1" {
        Write-Host "  [-d]" -ForegroundColor Cyan -NoNewline
        Write-Host " Domain name" -ForegroundColor White
        Write-Host "      If you would like to specify the domain enter it here, if left blank Snaffler will attempt to enumerate for you" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $domainName = (Read-Host).Trim()
        Write-Host ""

        Write-Host "  [-c]" -ForegroundColor Cyan -NoNewline
        Write-Host " Domain Controller (optional)" -ForegroundColor White
        Write-Host "      Enter the FQDN of a Domain Controller, or press Enter to skip" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $dcFqdn = (Read-Host).Trim()
        Write-Host ""
    }

    # ---- 2: Comma-separated host list ---------------------------------------
    "2" {
        Write-Host "  [-n]" -ForegroundColor Cyan -NoNewline
        Write-Host " Host list" -ForegroundColor White
        Write-Host "      Comma-separated hostnames, IPs, or CIDR ranges" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $rawHosts = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($rawHosts)) {
            Write-Host "  [!] At least one host is required. Exiting." -ForegroundColor Red
            exit 1
        }

        # Strip all spaces from the comma-separated list
        $hostList = ($rawHosts -replace '\s', '')
    }

    # ---- 3: CSV file of hosts -----------------------------------------------
    "3" {
        Write-Host "  [-n]" -ForegroundColor Cyan -NoNewline
        Write-Host " CSV file path" -ForegroundColor White
        Write-Host "      Path to a CSV file containing hostnames/IPs (one per line or comma-separated)" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $csvPath = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($csvPath)) {
            Write-Host "  [!] A file path is required. Exiting." -ForegroundColor Red
            exit 1
        }

        if (-not (Test-Path $csvPath)) {
            Write-Host "  [!] File not found: $csvPath. Exiting." -ForegroundColor Red
            exit 1
        }

        $hostList = $csvPath
        Write-Host "  [*] CSV file validated: $csvPath" -ForegroundColor Yellow
        Write-Host ""
    }

    # ---- 4: Local path for file discovery -----------------------------------
    "4" {
        Write-Host "  [-i]" -ForegroundColor Cyan -NoNewline
        Write-Host " Local discovery path" -ForegroundColor White
        Write-Host "      Path on the local host to perform file discovery" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $localPath = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($localPath)) {
            Write-Host "  [!] A path is required for local file discovery. Exiting." -ForegroundColor Red
            exit 1
        }
    }

    default {
        Write-Host "  [!] Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
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
    "-o", $outputFile
    "-v", $verbosity
    "-x", $maxThreads
    "-s"
    "-y"
)

switch ($targetMode) {
    "1" {
        if (-not [string]::IsNullOrWhiteSpace($domainName)) {
            $argList += "-d", $domainName
        }
        if (-not [string]::IsNullOrWhiteSpace($dcFqdn)) {
            $argList += "-c", $dcFqdn
        }
    }
    { $_ -in "2","3" } {
        $argList += "-n", $hostList
    }
    "4" {
        $argList += "-i", $localPath
    }
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

switch ($targetMode) {
    "1" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Domain Discovery" -ForegroundColor Green
        if (-not [string]::IsNullOrWhiteSpace($domainName)) {
            Write-Host "  Domain     : " -NoNewline -ForegroundColor DarkGray; Write-Host $domainName -ForegroundColor Green
        } else {
            Write-Host "  Domain     : " -NoNewline -ForegroundColor DarkGray; Write-Host "(auto-enumerate)" -ForegroundColor DarkGreen
        }
        if (-not [string]::IsNullOrWhiteSpace($dcFqdn)) {
            Write-Host "  DC (FQDN)  : " -NoNewline -ForegroundColor DarkGray; Write-Host $dcFqdn -ForegroundColor Green
        }
    }
    "2" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Host List" -ForegroundColor Green
        Write-Host "  Hosts      : " -NoNewline -ForegroundColor DarkGray; Write-Host $hostList -ForegroundColor Green
    }
    "3" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "CSV File" -ForegroundColor Green
        Write-Host "  Hosts      : " -NoNewline -ForegroundColor DarkGray; Write-Host $hostList -ForegroundColor Green
    }
    "4" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Local Path Discovery" -ForegroundColor Green
        Write-Host "  Path       : " -NoNewline -ForegroundColor DarkGray; Write-Host $localPath -ForegroundColor Green
    }
}

Write-Host "  Output     : " -NoNewline -ForegroundColor DarkGray; Write-Host $outputFile   -ForegroundColor Green
Write-Host "  Verbosity  : " -NoNewline -ForegroundColor DarkGray; Write-Host $verbosity    -ForegroundColor White
Write-Host "  Threads    : " -NoNewline -ForegroundColor DarkGray; Write-Host $maxThreads   -ForegroundColor White
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
