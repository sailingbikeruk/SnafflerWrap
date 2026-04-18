#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive launcher for Snaffler.exe with auto-generated output filenames.

.DESCRIPTION
    Collects switch values from the user and launches Snaffler.exe.
    Output filename is auto-generated in the format: yyyyMMdd-HHmm-<target>.log

.EXAMPLE
    .\Invoke-Snaffler.ps1
#>

[CmdletBinding()]
param ()

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

# -- Snaffler setup -------------------------------------------------------
Write-Host "  Download the latest Snaffler release? [Y/n] : " -ForegroundColor DarkGray -NoNewline
$downloadChoice = (Read-Host).Trim()
Write-Host ""

if ($downloadChoice -notmatch '^[Nn]') {

    # ---- Download latest release from GitHub --------------------------------
    $snafflerDir  = "C:\Snaffler"
    $SnafflerPath = "$snafflerDir\Snaffler.exe"

    Write-Host "  [*] Fetching latest Snaffler release from GitHub..." -ForegroundColor Cyan

    try {
        $releaseUrl  = "https://api.github.com/repos/SnaffCon/Snaffler/releases/latest"
        $releaseInfo = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
        $asset       = $releaseInfo.assets | Where-Object { $_.name -eq "Snaffler.exe" } | Select-Object -First 1

        if (-not $asset) {
            Write-Host "  [!] Could not find Snaffler.exe in the latest release assets." -ForegroundColor Red
            Read-Host "  Press Enter to exit"
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        Write-Host "  [*] Latest release : $($releaseInfo.tag_name)" -ForegroundColor Cyan
        Write-Host "  [*] Download URL   : $downloadUrl"             -ForegroundColor DarkGray

        if (-not (Test-Path $snafflerDir)) {
            Write-Host "  [*] Creating directory: $snafflerDir" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $snafflerDir -Force | Out-Null
        }

        Write-Host "  [*] Downloading Snaffler.exe to $SnafflerPath..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $SnafflerPath -UseBasicParsing

        Write-Host "  [+] Download complete: $SnafflerPath" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  [!] Failed to download Snaffler: $_" -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit 1
    }

} else {

    # ---- Locate existing Snaffler.exe ---------------------------------------
    Write-Host "  Enter the directory where Snaffler is installed : " -ForegroundColor DarkGray -NoNewline
    $snafflerDir = (Read-Host).Trim()
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($snafflerDir)) {
        Write-Host "  [!] No directory provided. Exiting." -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit 1
    }

    $SnafflerPath = Join-Path $snafflerDir "Snaffler.exe"

    if (-not (Test-Path $SnafflerPath)) {
        Write-Host "  [!] Snaffler.exe was not found at: $SnafflerPath" -ForegroundColor Red
        Write-Host "      Please check the path and ensure Snaffler.exe is present before continuing." -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }

    Write-Host "  [+] Snaffler.exe found: $SnafflerPath" -ForegroundColor Green
    Write-Host ""
}

Set-Location (Split-Path -Parent $SnafflerPath)

# ---------------------------------------------
#  Target / Scope selection
# ---------------------------------------------

Write-Host "  -- Target / Scope ----------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  How would you like to specify targets?" -ForegroundColor White
Write-Host ""
Write-Host "      1 = Domain discovery (Snaffler auto-discovers the domain)" -ForegroundColor DarkGray
Write-Host "      2 = Named domain [-d] with optional DC [-c]"               -ForegroundColor DarkGray
Write-Host "      3 = Comma-separated host list or CSV file path [-n]"       -ForegroundColor DarkGray
Write-Host "      4 = Local file path [-i]"                                  -ForegroundColor DarkGray
Write-Host ""
Write-Host "      Choice  : " -ForegroundColor DarkGray -NoNewline
$targetMode = (Read-Host).Trim()
Write-Host ""

$domainName = ""
$dcFqdn     = ""
$hostList   = ""
$localPath  = ""

switch ($targetMode) {

    # ---- 1: Auto domain discovery -------------------------------------------
    "1" {
        Write-Host "  [*] Snaffler will automatically discover the domain." -ForegroundColor Cyan
        Write-Host ""
    }

    # ---- 2: Named domain + optional DC --------------------------------------
    "2" {
        Write-Host "  [-d]" -ForegroundColor Cyan -NoNewline
        Write-Host " Domain name" -ForegroundColor White
        Write-Host "      Enter the domain name to target" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $domainName = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($domainName)) {
            Write-Host "  [!] A domain name is required for this option. Exiting." -ForegroundColor Red
            Read-Host "  Press Enter to exit"
            exit 1
        }

        Write-Host "  [-c]" -ForegroundColor Cyan -NoNewline
        Write-Host " Domain Controller (optional)" -ForegroundColor White
        Write-Host "      Enter the FQDN of a DC to use for enumeration, or press Enter to skip" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $dcFqdn = (Read-Host).Trim()
        Write-Host ""
    }

    # ---- 3: Host list or CSV ------------------------------------------------
    "3" {
        Write-Host "  [-n]" -ForegroundColor Cyan -NoNewline
        Write-Host " Hosts" -ForegroundColor White
        Write-Host "      Enter a comma-separated list of hostnames/IPs, or a path to a CSV file" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $hostList = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($hostList)) {
            Write-Host "  [!] A host list or CSV path is required. Exiting." -ForegroundColor Red
            Read-Host "  Press Enter to exit"
            exit 1
        }
    }

    # ---- 4: Local file path -------------------------------------------------
    "4" {
        Write-Host "  [-i]" -ForegroundColor Cyan -NoNewline
        Write-Host " Local file path" -ForegroundColor White
        Write-Host "      Enter the local path to perform file discovery on" -ForegroundColor DarkGray
        Write-Host "      Value   : " -ForegroundColor DarkGray -NoNewline
        $localPath = (Read-Host).Trim()
        Write-Host ""

        if ([string]::IsNullOrWhiteSpace($localPath)) {
            Write-Host "  [!] A local path is required. Exiting." -ForegroundColor Red
            Read-Host "  Press Enter to exit"
            exit 1
        }
    }

    default {
        Write-Host "  [!] Invalid choice. Exiting." -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

# ---------------------------------------------
#  Auto-generate output filename
# ---------------------------------------------

$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$autoPath  = ".\Output\$timestamp-$($env:COMPUTERNAME).txt"

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
        # No target flags — Snaffler auto-discovers
    }
    "2" {
        $argList += "-d", $domainName
        if (-not [string]::IsNullOrWhiteSpace($dcFqdn)) {
            $argList += "-c", $dcFqdn
        }
    }
    "3" { $argList += "-n", $hostList }
    "4" { $argList += "-i", $localPath }
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
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Auto domain discovery" -ForegroundColor Green
    }
    "2" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Named domain" -ForegroundColor Green
        Write-Host "  Domain     : " -NoNewline -ForegroundColor DarkGray; Write-Host $domainName -ForegroundColor Green
        if (-not [string]::IsNullOrWhiteSpace($dcFqdn)) {
            Write-Host "  DC (FQDN)  : " -NoNewline -ForegroundColor DarkGray; Write-Host $dcFqdn -ForegroundColor Green
        }
    }
    "3" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Host list / CSV" -ForegroundColor Green
        Write-Host "  Hosts      : " -NoNewline -ForegroundColor DarkGray; Write-Host $hostList -ForegroundColor Green
    }
    "4" {
        Write-Host "  Mode       : " -NoNewline -ForegroundColor DarkGray; Write-Host "Local path" -ForegroundColor Green
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
#  Launch
# ---------------------------------------------

Write-Host ""
Write-Host "  [*] Starting Snaffler..." -ForegroundColor Cyan
Write-Host "  [*] Executable will be removed from disk on exit." -ForegroundColor DarkGray
Write-Host ""

$process = $null

try {
    # Build a quoted argument string so paths with spaces are handled correctly
    $argString = ($argList | ForEach-Object {
        if ($_ -match '\s') { "`"$_`"" } else { $_ }
    }) -join ' '

    $process = Start-Process -FilePath $SnafflerPath -ArgumentList $argString -PassThru -NoNewWindow
    Write-Host "  [*] Snaffler running  (PID: $($process.Id))" -ForegroundColor Cyan
    Write-Host ""

    $process.WaitForExit()
    $exitCode = $process.ExitCode

    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "  [+] Snaffler finished (exit code: $exitCode). Output saved to: $outputFile" -ForegroundColor Green
    } else {
        Write-Host "  [!] Snaffler exited with code: $exitCode" -ForegroundColor Yellow
        Write-Host "      Output (if any) saved to: $outputFile" -ForegroundColor DarkGray
    }
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "  [!] Failed to launch Snaffler: $_" -ForegroundColor Red
    Write-Host ""
}
finally {
    # Remove executable from disk regardless of outcome
    if (Test-Path $SnafflerPath) {
        try {
            Remove-Item -Path $SnafflerPath -Force -ErrorAction Stop
            Write-Host "  [*] Removed executable: $SnafflerPath" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "  [!] Could not remove $SnafflerPath : $_" -ForegroundColor Yellow
        }
    }
}

Read-Host "  Press Enter to exit"