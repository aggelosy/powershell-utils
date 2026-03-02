#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Full PowerShell Environment & Security Diagnostics Tool
.DESCRIPTION
    Performs a comprehensive audit of PowerShell execution policies, AppLocker rules,
    Group Policy restrictions, Software Restriction Policies, Task Scheduler service
    state, all installed PowerShell versions, and live execution tests.
    Saves a full timestamped report and opens it automatically.
.AUTHOR
    Aggelos Y
.COPYRIGHT
    © 2026 Aggelos Y. All rights reserved.
.NOTES
    Version    : 1.0
    Created    : 2026-03-02
    Platform   : Windows 10 / 11
    PowerShell : 5.1+
    Admin      : Required
#>

param(
    [string]$OutputFolder = "$env:USERPROFILE\Desktop",
    [switch]$NoAutoOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = Join-Path $OutputFolder "PSdiagnostics_$timestamp.txt"
$results    = [System.Collections.Generic.List[string]]::new()

# ─────────────────────────────────────────────────────────────────────────────
# REGION: OUTPUT HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Write-Section([string]$Title) {
    $line = "═" * 72
    $block = "`n$line`n  $Title`n$line"
    Write-Host $block -ForegroundColor Cyan
    $results.Add($block)
}

function Write-Item([string]$label, $value, [string]$color = "White") {
    $flag  = if ($value -match "Bypass|Unrestricted|Disabled|Not Configured|Allow|Enabled") { "⚠ " } else { "  " }
    $line  = "  $flag{0,-38} : {1}" -f $label, $value
    Write-Host $line -ForegroundColor $color
    $results.Add($line)
}

function Write-Note([string]$text, [string]$color = "Gray") {
    Write-Host "  → $text" -ForegroundColor $color
    $results.Add("  → $text")
}

function Write-Pass([string]$text) {
    Write-Host "  ✔  $text" -ForegroundColor Green
    $results.Add("  [PASS] $text")
}

function Write-Fail([string]$text) {
    Write-Host "  ✖  $text" -ForegroundColor Red
    $results.Add("  [FAIL] $text")
}

function Write-Warn([string]$text) {
    Write-Host "  ⚠  $text" -ForegroundColor Yellow
    $results.Add("  [WARN] $text")
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: BANNER
# ─────────────────────────────────────────────────────────────────────────────
Clear-Host
$header = @"
╔══════════════════════════════════════════════════════════════════════════╗
║       🔍 PowerShell Environment & Security Diagnostics  v1.0           ║
║       Property of: Aggelos Y                                            ║
║       © 2026 — All Rights Reserved                                      ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
Write-Host $header -ForegroundColor Cyan
$results.Add($header)
Write-Host ("  Report will be saved to: $reportFile`n") -ForegroundColor DarkGray

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: SYSTEM INFO
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "SYSTEM INFORMATION"
$os   = Get-CimInstance Win32_OperatingSystem
$comp = Get-CimInstance Win32_ComputerSystem

Write-Item "Hostname"         $env:COMPUTERNAME
Write-Item "Current User"     "$env:USERDOMAIN\$env:USERNAME"
Write-Item "OS"               $os.Caption
Write-Item "OS Build"         $os.BuildNumber
Write-Item "OS Architecture"  $os.OSArchitecture
Write-Item "Total RAM (GB)"   ([math]::Round($comp.TotalPhysicalMemory / 1GB, 2))
Write-Item "Domain / Workgroup" $comp.Domain
Write-Item "Report Generated" (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: POWERSHELL VERSIONS
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "POWERSHELL INSTALLATIONS"

# PowerShell 5.x (Windows PowerShell)
$ps5 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
if (Test-Path $ps5) {
    $ver = (& $ps5 -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null)
    Write-Pass "Windows PowerShell 5.x found: v$ver"
    Write-Item "Path" $ps5
} else {
    Write-Fail "Windows PowerShell 5.x NOT found"
}

# PowerShell 7.x (pwsh)
$ps7paths = @(
    "$env:ProgramFiles\PowerShell\7\pwsh.exe",
    "$env:ProgramFiles\PowerShell\7-preview\pwsh.exe"
)
$ps7found = $false
foreach ($p in $ps7paths) {
    if (Test-Path $p) {
        $ver = (& $p -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null)
        Write-Pass "PowerShell 7.x found: v$ver"
        Write-Item "Path" $p
        $ps7found = $true
    }
}
if (-not $ps7found) { Write-Warn "PowerShell 7.x not installed" }

Write-Item "Current Session Version" $PSVersionTable.PSVersion.ToString()
Write-Item "Current Session Edition" $PSVersionTable.PSEdition
Write-Item "Current Host"            $Host.Name

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: EXECUTION POLICIES
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "EXECUTION POLICIES (All Scopes)"

$scopes = @("MachinePolicy","UserPolicy","Process","CurrentUser","LocalMachine")
foreach ($scope in $scopes) {
    $pol = Get-ExecutionPolicy -Scope $scope
    $color = switch ($pol) {
        "Bypass"       { "Red" }
        "Unrestricted" { "Yellow" }
        "RemoteSigned" { "Green" }
        "AllSigned"    { "Cyan" }
        "Restricted"   { "Magenta" }
        default        { "Gray" }
    }
    Write-Item "  $scope" $pol $color
}

$effective = Get-ExecutionPolicy
Write-Item "Effective Policy" $effective

switch ($effective) {
    "Restricted"   { Write-Fail "Scripts CANNOT run. No .ps1 files are executed." }
    "AllSigned"    { Write-Warn "Only signed scripts run. Unsigned local scripts blocked." }
    "RemoteSigned" { Write-Pass "Remote scripts must be signed. Local scripts can run." }
    "Unrestricted" { Write-Warn "All scripts run. Remote scripts prompt for confirmation." }
    "Bypass"       { Write-Warn "BYPASS — Nothing blocked, no warnings. (Risky)" }
    default        { Write-Note "Policy is: $effective" }
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4: GROUP POLICY / REGISTRY RESTRICTIONS
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "GROUP POLICY & REGISTRY RESTRICTIONS"

$gpKeys = @(
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell";              Name="EnableScripts";          Label="GPO: Enable Scripts" }
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell";              Name="ExecutionPolicy";        Label="GPO: Execution Policy" }
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"; Name="EnableScriptBlockLogging"; Label="GPO: Script Block Logging" }
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"; Name="EnableModuleLogging";   Label="GPO: Module Logging" }
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"; Name="EnableTranscripting";   Label="GPO: Transcription" }
    @{ Path="HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell";              Name="ExecutionPolicy";        Label="GPO User: Execution Policy" }
    @{ Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRoot";     Name="SystemRoot";             Label="SystemRoot" }
)

foreach ($key in $gpKeys) {
    if (Test-Path $key.Path) {
        $val = (Get-ItemProperty -Path $key.Path -Name $key.Name -ErrorAction SilentlyContinue).($key.Name)
        if ($null -ne $val) {
            Write-Item $key.Label $val "Yellow"
        } else {
            Write-Item $key.Label "Not Set" "Gray"
        }
    } else {
        Write-Item $key.Label "(Key not found)" "DarkGray"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5: APPLOCKER
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "APPLOCKER POLICY"

try {
    $applockerService = Get-Service -Name "AppIDSvc" -ErrorAction Stop
    Write-Item "AppLocker Service (AppIDSvc)" $applockerService.Status

    $policy = Get-AppLockerPolicy -Effective -ErrorAction Stop
    $ruleCollections = $policy.RuleCollections

    if ($ruleCollections.Count -eq 0) {
        Write-Pass "No AppLocker rules found — scripts not restricted by AppLocker"
    } else {
        foreach ($rc in $ruleCollections) {
            Write-Item "Rule Collection: $($rc.RuleCollectionType)" "($($rc.Count) rules)" "Yellow"
            foreach ($rule in $rc) {
                Write-Note "$($rule.Action): $($rule.Name)" "Gray"
            }
        }
    }
} catch {
    Write-Note "AppLocker not configured or not accessible: $_" "DarkGray"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6: SOFTWARE RESTRICTION POLICIES
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "SOFTWARE RESTRICTION POLICIES (SRP)"

$srpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers"
if (Test-Path $srpPath) {
    $defaultLevel = (Get-ItemProperty -Path $srpPath -Name "DefaultLevel" -ErrorAction SilentlyContinue).DefaultLevel
    $srpLabel = switch ($defaultLevel) {
        0x00000 { "Disallowed (0) — BLOCKS all scripts" }
        0x20000 { "Basic User (131072)" }
        0x40000 { "Power User (262144)" }
        0x1000  { "Untrusted (4096)" }
        default { "Unknown ($defaultLevel)" }
    }
    Write-Item "SRP Default Level" $srpLabel "Yellow"
} else {
    Write-Pass "No Software Restriction Policies configured"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7: TASK SCHEDULER
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "TASK SCHEDULER SERVICE"

$svc = Get-Service -Name "Schedule" -ErrorAction SilentlyContinue
if ($svc) {
    Write-Item "Task Scheduler Service" $svc.Status
    Write-Item "Start Type"            $svc.StartType
    if ($svc.Status -eq "Running") {
        Write-Pass "Task Scheduler is running — PS scripts can be scheduled"
    } else {
        Write-Fail "Task Scheduler is NOT running — scheduled scripts will fail"
    }
} else {
    Write-Fail "Task Scheduler service not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8: CONSTRAINED LANGUAGE MODE
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "LANGUAGE MODE"

$langMode = $ExecutionContext.SessionState.LanguageMode
Write-Item "Current Language Mode" $langMode

switch ($langMode) {
    "FullLanguage"        { Write-Pass "Full Language Mode — all PowerShell features available" }
    "ConstrainedLanguage" { Write-Fail "CONSTRAINED Language Mode — Add-Type, COM objects, .NET blocked" }
    "RestrictedLanguage"  { Write-Fail "RESTRICTED Language Mode — only basic cmdlets allowed" }
    "NoLanguage"          { Write-Fail "NO Language Mode — only native commands run" }
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 9: LIVE EXECUTION TEST
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "LIVE EXECUTION TESTS"

# Test 1: Basic command
try {
    $test1 = Invoke-Expression "1 + 1"
    if ($test1 -eq 2) { Write-Pass "Basic expression eval (1+1=2)" }
    else              { Write-Fail "Expression eval returned unexpected result" }
} catch { Write-Fail "Expression eval FAILED: $_" }

# Test 2: Script block
try {
    $sb = [scriptblock]::Create('return "OK"')
    $r  = & $sb
    if ($r -eq "OK") { Write-Pass "Script block execution" }
    else             { Write-Fail "Script block returned unexpected result" }
} catch { Write-Fail "Script block FAILED: $_" }

# Test 3: CIM/WMI access
try {
    $cim = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    Write-Pass "CIM / WMI access (Win32_BIOS)"
} catch { Write-Fail "CIM/WMI access FAILED: $_" }

# Test 4: File write access
try {
    $testFile = Join-Path $env:TEMP "PSdiag_test_$timestamp.tmp"
    "test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item $testFile -Force
    Write-Pass "File write access to TEMP folder"
} catch { Write-Fail "File write FAILED: $_" }

# Test 5: Registry read
try {
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName"
    Write-Pass "Registry read (HKLM): $($reg.ProductName)"
} catch { Write-Fail "Registry read FAILED: $_" }

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 10: ANTIVIRUS / DEFENDER
# ─────────────────────────────────────────────────────────────────────────────
Write-Section "ANTIVIRUS & DEFENDER STATUS"

try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    Write-Item "Real-Time Protection"  $defender.RealTimeProtectionEnabled
    Write-Item "Antivirus Enabled"     $defender.AntivirusEnabled
    Write-Item "Behavior Monitor"      $defender.BehaviorMonitorEnabled
    Write-Item "IOAV Protection"       $defender.IoavProtectionEnabled
    Write-Item "Antivirus Sig Version" $defender.AntivirusSignatureVersion
    Write-Item "Last Quick Scan"       $defender.QuickScanStartTime

    if ($defender.RealTimeProtectionEnabled) {
        Write-Warn "Real-Time Protection ON — may block unsigned/new scripts"
    } else {
        Write-Pass "Real-Time Protection OFF"
    }
} catch {
    Write-Note "Windows Defender status not accessible: $_"
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: SAVE & OPEN REPORT
# ─────────────────────────────────────────────────────────────────────────────
$footer = @"

══════════════════════════════════════════════════════════════════════════
  Report generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  Host: $env:COMPUTERNAME  |  User: $env:USERNAME
  PowerShell Diagnostics v1.0  |  Property of: Aggelos Y
══════════════════════════════════════════════════════════════════════════
"@
Write-Host $footer -ForegroundColor DarkGray
$results.Add($footer)

$results | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host ("`n  [✔] Full report saved to: $reportFile") -ForegroundColor Green

if (-not $NoAutoOpen) {
    Write-Host "  [*] Opening report in Notepad..." -ForegroundColor DarkGray
    Start-Process notepad.exe -ArgumentList $reportFile
}

Write-Host "`nDiagnostics complete. Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
