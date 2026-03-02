#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Bloatware Detector & Removal Tool
.DESCRIPTION
    Detects pre-installed bloatware by category and severity, reports findings,
    and optionally removes selected apps. Safe by default — no changes without confirmation.
.AUTHOR
    Aggelos Y
.COPYRIGHT
    © 2026 Aggelos Y. All rights reserved.
.NOTES
    Version   : 2.0
    Created   : 2026-03-02
    Property of: Aggelos Y
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ─────────────────────────────────────────────────────────────────────────────
# REGION: BLOATWARE DEFINITIONS
# Each entry: PackageName (wildcard-friendly), Category, Severity (1=Low 3=High)
# ─────────────────────────────────────────────────────────────────────────────
$BloatwareList = @(
    # ── Microsoft Ads / Spyware ──────────────────────────────────────────────
    [PSCustomObject]@{ Name="Microsoft.549981C3F5F10";         Category="Cortana / Search";    Severity=3; Description="Cortana standalone app" }
    [PSCustomObject]@{ Name="Microsoft.BingNews";              Category="Ads / News Feed";     Severity=3; Description="MSN News (ad-supported)" }
    [PSCustomObject]@{ Name="Microsoft.BingWeather";           Category="Ads / News Feed";     Severity=2; Description="MSN Weather widget" }
    [PSCustomObject]@{ Name="Microsoft.BingSearch";            Category="Ads / News Feed";     Severity=3; Description="Bing Search integration" }
    [PSCustomObject]@{ Name="Microsoft.BingFinance";           Category="Ads / News Feed";     Severity=2; Description="MSN Finance" }
    [PSCustomObject]@{ Name="Microsoft.BingSports";            Category="Ads / News Feed";     Severity=2; Description="MSN Sports" }
    [PSCustomObject]@{ Name="Microsoft.BingTranslator";        Category="Ads / News Feed";     Severity=1; Description="Bing Translator" }
    # ── Microsoft Gaming / Xbox ──────────────────────────────────────────────
    [PSCustomObject]@{ Name="Microsoft.XboxApp";               Category="Xbox / Gaming";       Severity=2; Description="Xbox app" }
    [PSCustomObject]@{ Name="Microsoft.XboxGameOverlay";       Category="Xbox / Gaming";       Severity=2; Description="Xbox Game Bar overlay" }
    [PSCustomObject]@{ Name="Microsoft.XboxGamingOverlay";     Category="Xbox / Gaming";       Severity=2; Description="Xbox Game Bar" }
    [PSCustomObject]@{ Name="Microsoft.XboxIdentityProvider";  Category="Xbox / Gaming";       Severity=2; Description="Xbox Identity Provider" }
    [PSCustomObject]@{ Name="Microsoft.XboxSpeechToTextOverlay"; Category="Xbox / Gaming";     Severity=1; Description="Xbox Speech overlay" }
    [PSCustomObject]@{ Name="Microsoft.XboxTCUI";              Category="Xbox / Gaming";       Severity=2; Description="Xbox Title-Callable UI" }
    [PSCustomObject]@{ Name="Microsoft.Xbox.TCUI";             Category="Xbox / Gaming";       Severity=2; Description="Xbox TCUI (alt)" }
    [PSCustomObject]@{ Name="Microsoft.GamingApp";             Category="Xbox / Gaming";       Severity=2; Description="Microsoft Gaming (Xbox)" }
    # ── Microsoft Office Promos ──────────────────────────────────────────────
    [PSCustomObject]@{ Name="Microsoft.MicrosoftOfficeHub";    Category="Office Promo";        Severity=3; Description="Office Hub (upsell app)" }
    [PSCustomObject]@{ Name="Microsoft.Office.OneNote";        Category="Office Promo";        Severity=1; Description="OneNote (pre-installed)" }
    [PSCustomObject]@{ Name="Microsoft.OutlookForWindows";     Category="Office Promo";        Severity=2; Description="New Outlook (replaces Mail)" }
    # ── Microsoft Teams / Communication ─────────────────────────────────────
    [PSCustomObject]@{ Name="MicrosoftTeams";                  Category="Communication";       Severity=3; Description="Microsoft Teams (consumer)" }
    [PSCustomObject]@{ Name="Microsoft.Todos";                 Category="Communication";       Severity=1; Description="Microsoft To Do" }
    [PSCustomObject]@{ Name="microsoft.windowscommunicationsapps"; Category="Communication";   Severity=1; Description="Mail & Calendar apps" }
    # ── Entertainment / Streaming ────────────────────────────────────────────
    [PSCustomObject]@{ Name="SpotifyAB.SpotifyMusic";          Category="Entertainment";       Severity=2; Description="Spotify (pre-installed)" }
    [PSCustomObject]@{ Name="Disney.37853D22215B2";            Category="Entertainment";       Severity=2; Description="Disney+" }
    [PSCustomObject]@{ Name="Amazon.com.Amazon";               Category="Entertainment";       Severity=2; Description="Amazon Shopping" }
    [PSCustomObject]@{ Name="AmazonVideo.PrimeVideo";          Category="Entertainment";       Severity=2; Description="Prime Video" }
    [PSCustomObject]@{ Name="AppleInc.iTunes";                 Category="Entertainment";       Severity=2; Description="iTunes (OEM bundled)" }
    [PSCustomObject]@{ Name="Netflix";                         Category="Entertainment";       Severity=2; Description="Netflix" }
    [PSCustomObject]@{ Name="Hulu.HuluApp";                    Category="Entertainment";       Severity=2; Description="Hulu" }
    [PSCustomObject]@{ Name="TikTok";                          Category="Entertainment";       Severity=3; Description="TikTok" }
    [PSCustomObject]@{ Name="Facebook.Facebook";               Category="Entertainment";       Severity=3; Description="Facebook" }
    [PSCustomObject]@{ Name="Instagram.Instagram";             Category="Entertainment";       Severity=3; Description="Instagram" }
    [PSCustomObject]@{ Name="BytedancePte.TikTok";             Category="Entertainment";       Severity=3; Description="TikTok (alt)" }
    # ── Microsoft Built-in Clutter ───────────────────────────────────────────
    [PSCustomObject]@{ Name="Microsoft.MixedReality.Portal";   Category="MS Clutter";          Severity=3; Description="Mixed Reality Portal" }
    [PSCustomObject]@{ Name="Microsoft.3DBuilder";             Category="MS Clutter";          Severity=2; Description="3D Builder" }
    [PSCustomObject]@{ Name="Microsoft.3DViewer";              Category="MS Clutter";          Severity=1; Description="3D Viewer" }
    [PSCustomObject]@{ Name="Microsoft.Print3D";               Category="MS Clutter";          Severity=2; Description="Print 3D" }
    [PSCustomObject]@{ Name="Microsoft.MSPaint";               Category="MS Clutter";          Severity=1; Description="Paint (legacy)" }
    [PSCustomObject]@{ Name="Microsoft.Paint";                 Category="MS Clutter";          Severity=1; Description="Paint (new)" }
    [PSCustomObject]@{ Name="Microsoft.WindowsMaps";           Category="MS Clutter";          Severity=1; Description="Windows Maps" }
    [PSCustomObject]@{ Name="Microsoft.WindowsFeedbackHub";    Category="MS Clutter";          Severity=2; Description="Feedback Hub (telemetry)" }
    [PSCustomObject]@{ Name="Microsoft.GetHelp";               Category="MS Clutter";          Severity=1; Description="Get Help app" }
    [PSCustomObject]@{ Name="Microsoft.Getstarted";            Category="MS Clutter";          Severity=2; Description="Tips (nag screen)" }
    [PSCustomObject]@{ Name="Microsoft.Messaging";             Category="MS Clutter";          Severity=1; Description="Messaging app" }
    [PSCustomObject]@{ Name="Microsoft.People";                Category="MS Clutter";          Severity=1; Description="People app" }
    [PSCustomObject]@{ Name="Microsoft.SkypeApp";              Category="MS Clutter";          Severity=2; Description="Skype (pre-installed)" }
    [PSCustomObject]@{ Name="Microsoft.WindowsSoundRecorder";  Category="MS Clutter";          Severity=1; Description="Sound Recorder" }
    [PSCustomObject]@{ Name="Microsoft.ZuneMusic";             Category="MS Clutter";          Severity=2; Description="Groove Music (defunct)" }
    [PSCustomObject]@{ Name="Microsoft.ZuneVideo";             Category="MS Clutter";          Severity=2; Description="Movies & TV" }
    [PSCustomObject]@{ Name="Microsoft.Wallet";                Category="MS Clutter";          Severity=2; Description="Microsoft Wallet" }
    [PSCustomObject]@{ Name="Microsoft.MicrosoftSolitaireCollection"; Category="Games";        Severity=2; Description="Solitaire Collection (ads)" }
    [PSCustomObject]@{ Name="Microsoft.MicrosoftMahjong";      Category="Games";               Severity=1; Description="Microsoft Mahjong" }
    [PSCustomObject]@{ Name="Microsoft.MicrosoftSudoku";       Category="Games";               Severity=1; Description="Microsoft Sudoku" }
    [PSCustomObject]@{ Name="Microsoft.MicrosoftJigsaw";       Category="Games";               Severity=1; Description="Microsoft Jigsaw" }
    [PSCustomObject]@{ Name="Microsoft.MinecraftEducationEdition"; Category="Games";           Severity=1; Description="Minecraft Education" }
    [PSCustomObject]@{ Name="Microsoft.Clipchamp";             Category="MS Clutter";          Severity=1; Description="Clipchamp video editor" }
    [PSCustomObject]@{ Name="MicrosoftCorporationII.QuickAssist"; Category="MS Clutter";       Severity=1; Description="Quick Assist (remote)" }
    [PSCustomObject]@{ Name="Microsoft.PowerAutomateDesktop";  Category="MS Clutter";          Severity=1; Description="Power Automate Desktop" }
    [PSCustomObject]@{ Name="MSTeams";                         Category="Communication";       Severity=3; Description="Teams Chat (taskbar)" }
)

# ─────────────────────────────────────────────────────────────────────────────
# REGION: UI HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Write-Header {
    Clear-Host
    $banner = @"
╔══════════════════════════════════════════════════════════════╗
║        Windows 11 Bloatware Detector  v2.0                   ║
║        Running as Administrator — Safe Scan Mode             ║
║        Property of: Aggelos Y                                ║
║        © 2026 — All Rights Reserved                          ║
╚══════════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Write-SeverityColor([int]$sev) {
    switch ($sev) {
        3 { return "Red" }
        2 { return "Yellow" }
        1 { return "Green" }
        default { return "White" }
    }
}

function Write-SeverityLabel([int]$sev) {
    switch ($sev) {
        3 { return "[HIGH  ]" }
        2 { return "[MEDIUM]" }
        1 { return "[LOW   ]" }
        default { return "[?     ]" }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: DETECTION ENGINE
# ─────────────────────────────────────────────────────────────────────────────
function Get-InstalledBloatware {
    Write-Host "`n[*] Scanning installed AppX packages..." -ForegroundColor DarkCyan

    $installedPackages   = Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName, Version, IsFramework
    $provisionedPackages = Get-AppxProvisionedPackage -Online | Select-Object DisplayName, PackageName

    $found = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($entry in $BloatwareList) {
        $matches = $installedPackages | Where-Object { $_.Name -like "$($entry.Name)*" -and -not $_.IsFramework }
        foreach ($pkg in $matches) {
            $isProvisioned = ($provisionedPackages | Where-Object { $_.DisplayName -like "$($entry.Name)*" }) -ne $null
            $found.Add([PSCustomObject]@{
                DisplayName   = $entry.Description
                PackageName   = $pkg.Name
                FullName      = $pkg.PackageFullName
                Version       = $pkg.Version
                Category      = $entry.Category
                Severity      = $entry.Severity
                IsProvisioned = $isProvisioned
                Status        = "Installed"
            })
        }
    }

    return $found | Sort-Object Severity -Descending
}

function Get-SuspiciousStartupItems {
    Write-Host "[*] Checking startup entries..." -ForegroundColor DarkCyan
    $startupPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    $suspiciousKeywords = @("candy","bubble","farm","casino","games","coupon","deal","save","offer","toolbar","search","updater","helper","notif")
    $suspicious = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($path in $startupPaths) {
        if (Test-Path $path) {
            $entries = Get-ItemProperty -Path $path
            $entries.PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty" -and $_.Name -notmatch "^PS" } | ForEach-Object {
                $name = $_.Name
                $val  = $_.Value
                foreach ($kw in $suspiciousKeywords) {
                    if ($name -match $kw -or $val -match $kw) {
                        $suspicious.Add([PSCustomObject]@{
                            Name    = $name
                            Command = $val
                            Source  = ($path -split "\\")[-1]   # ✅ Fixed line
                        })
                        break
                    }
                }
            }
        }
    }
    return $suspicious
}

function Get-HighImpactStartupApps {
    Write-Host "[*] Querying startup impact via WMI..." -ForegroundColor DarkCyan
    try {
        $startupApps = Get-CimInstance -ClassName Win32_StartupCommand |
            Select-Object Name, Command, Location, User
        return $startupApps
    } catch {
        return @()
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: REPORT PRINTER
# ─────────────────────────────────────────────────────────────────────────────
function Show-BloatwareReport($bloatware, $suspiciousStartup) {
    Write-Host "`n" + ("═" * 65) -ForegroundColor DarkGray
    Write-Host "  BLOATWARE SCAN RESULTS" -ForegroundColor White
    Write-Host ("═" * 65) -ForegroundColor DarkGray

    if ($bloatware.Count -eq 0) {
        Write-Host "`n  ✔  No known bloatware detected. System looks clean!" -ForegroundColor Green
    } else {
        $categories = $bloatware | Select-Object -ExpandProperty Category -Unique | Sort-Object

        foreach ($cat in $categories) {
            Write-Host "`n  ▶ $cat" -ForegroundColor Magenta
            Write-Host ("  " + "─" * 55) -ForegroundColor DarkGray

            $bloatware | Where-Object { $_.Category -eq $cat } | ForEach-Object {
                $color = Write-SeverityColor $_.Severity
                $label = Write-SeverityLabel $_.Severity
                $prov  = if ($_.IsProvisioned) { " [PROVISIONED]" } else { "" }
                Write-Host ("  {0} {1,-35} v{2}{3}" -f $label, $_.DisplayName, $_.Version, $prov) -ForegroundColor $color
                Write-Host ("          Package: {0}" -f $_.PackageName) -ForegroundColor DarkGray
            }
        }

        $high   = ($bloatware | Where-Object { $_.Severity -eq 3 }).Count
        $medium = ($bloatware | Where-Object { $_.Severity -eq 2 }).Count
        $low    = ($bloatware | Where-Object { $_.Severity -eq 1 }).Count

        Write-Host "`n" + ("═" * 65) -ForegroundColor DarkGray
        Write-Host ("  SUMMARY:  Total={0}   " -f $bloatware.Count) -NoNewline -ForegroundColor White
        Write-Host ("HIGH={0} " -f $high)     -NoNewline -ForegroundColor Red
        Write-Host ("MEDIUM={0} " -f $medium) -NoNewline -ForegroundColor Yellow
        Write-Host ("LOW={0}" -f $low)        -ForegroundColor Green
        Write-Host ("═" * 65) -ForegroundColor DarkGray
    }

    if ($suspiciousStartup.Count -gt 0) {
        Write-Host "`n  ⚠  SUSPICIOUS STARTUP ENTRIES FOUND:" -ForegroundColor Red
        $suspiciousStartup | ForEach-Object {
            Write-Host ("  [STARTUP] {0,-25} → {1}" -f $_.Name, $_.Command) -ForegroundColor Yellow
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: REMOVAL ENGINE
# ─────────────────────────────────────────────────────────────────────────────
function Remove-SelectedBloatware($bloatware) {
    Write-Host "`n[!] REMOVAL MODE — Enter package numbers to remove (comma-separated)" -ForegroundColor Red
    Write-Host "    Type 'HIGH' to select all HIGH severity, 'ALL' for everything, or 'CANCEL' to exit`n" -ForegroundColor Yellow

    $indexed = $bloatware | ForEach-Object -Begin { $i = 1 } -Process {
        $color = Write-SeverityColor $_.Severity
        $label = Write-SeverityLabel $_.Severity
        Write-Host ("  [{0:D2}] {1} {2}" -f $i, $label, $_.DisplayName) -ForegroundColor $color
        $_ | Add-Member -NotePropertyName Index -NotePropertyValue $i -PassThru
        $i++
    }

    Write-Host ""
    $input = Read-Host "Selection"

    $toRemove = switch ($input.ToUpper().Trim()) {
        "CANCEL" { return }
        "ALL"    { $indexed }
        "HIGH"   { $indexed | Where-Object { $_.Severity -eq 3 } }
        default  {
            $nums = $input -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\d+$" }
            $indexed | Where-Object { $_.Index -in $nums }
        }
    }

    if (-not $toRemove) {
        Write-Host "`n  No valid selection made." -ForegroundColor Yellow
        return
    }

    Write-Host "`n[!] The following packages will be PERMANENTLY REMOVED:" -ForegroundColor Red
    $toRemove | ForEach-Object { Write-Host ("  - {0} ({1})" -f $_.DisplayName, $_.PackageName) -ForegroundColor Yellow }

    $confirm = Read-Host "`n  Type 'YES' to confirm removal, anything else to abort"
    if ($confirm -ne "YES") {
        Write-Host "`n  Aborted. No changes made." -ForegroundColor Green
        return
    }

    $log = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($pkg in $toRemove) {
        Write-Host "`n  Removing: $($pkg.DisplayName)..." -NoNewline -ForegroundColor Cyan
        try {
            Get-AppxPackage -AllUsers -Name "$($pkg.PackageName)*" | Remove-AppxPackage -AllUsers
            if ($pkg.IsProvisioned) {
                Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "$($pkg.PackageName)*" } |
                    Remove-AppxProvisionedPackage -Online | Out-Null
            }
            Write-Host " REMOVED ✔" -ForegroundColor Green
            $log.Add([PSCustomObject]@{ Package=$pkg.DisplayName; Status="Removed"; Time=Get-Date })
        } catch {
            Write-Host " FAILED ✖ — $_" -ForegroundColor Red
            $log.Add([PSCustomObject]@{ Package=$pkg.DisplayName; Status="Failed: $_"; Time=Get-Date })
        }
    }

    $logPath = "$env:USERPROFILE\Desktop\BloatwareRemoval_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $log | Export-Csv -Path $logPath -NoTypeInformation
    Write-Host "`n  [✔] Removal log saved to: $logPath" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: EXPORT REPORT
# ─────────────────────────────────────────────────────────────────────────────
function Export-ScanReport($bloatware, $suspicious) {
    $reportPath = "$env:USERPROFILE\Desktop\BloatwareScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $allResults = $bloatware | Select-Object DisplayName, PackageName, Version, Category, Severity, IsProvisioned, Status
    $allResults | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "`n  [✔] Scan report exported to: $reportPath" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: MAIN MENU
# ─────────────────────────────────────────────────────────────────────────────
Write-Header

$bloatware       = Get-InstalledBloatware
$suspiciousStart = Get-SuspiciousStartupItems

Show-BloatwareReport $bloatware $suspiciousStart

Write-Host "`n  OPTIONS:" -ForegroundColor White
Write-Host "  [1] Export scan report to CSV (Desktop)" -ForegroundColor Cyan
Write-Host "  [2] Remove selected bloatware (Interactive)" -ForegroundColor Red
Write-Host "  [3] Exit" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Choose an option"

switch ($choice) {
    "1" { Export-ScanReport $bloatware $suspiciousStart }
    "2" {
        if ($bloatware.Count -eq 0) {
            Write-Host "`n  Nothing to remove — system is clean!" -ForegroundColor Green
        } else {
            Remove-SelectedBloatware $bloatware
        }
    }
    "3" { Write-Host "`n  Goodbye!" -ForegroundColor Gray; exit }
    default { Write-Host "`n  No action taken. Exiting." -ForegroundColor Gray }
}

Write-Host "`nDone. Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
