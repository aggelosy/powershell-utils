#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Live System Process Dashboard for Windows
.DESCRIPTION
    Real-time console dashboard displaying top CPU and RAM consuming processes,
    system vitals (uptime, CPU load, RAM usage), and per-process metrics.
    Refreshes every 2 seconds with color-coded severity indicators.
.AUTHOR
    Aggelos Y
.COPYRIGHT
    © 2026 Aggelos Y. All rights reserved.
.NOTES
    Version    : 1.0
    Created    : 2026-03-02
    Platform   : Windows 10 / 11
    PowerShell : 5.1+
    Admin      : Required (for full process detail access)
#>

param(
    [int]$RefreshSeconds  = 2,
    [int]$TopProcessCount = 15,
    [switch]$NoClear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ─────────────────────────────────────────────────────────────────────────────
# REGION: THRESHOLDS
# ─────────────────────────────────────────────────────────────────────────────
$CPU_WARN     = 30   # % per process — yellow
$CPU_CRIT     = 70   # % per process — red
$RAM_WARN_MB  = 500  # MB per process — yellow
$RAM_CRIT_MB  = 1500 # MB per process — red

# ─────────────────────────────────────────────────────────────────────────────
# REGION: HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Get-CPUColor([double]$pct) {
    if ($pct -ge $CPU_CRIT)  { return "Red" }
    if ($pct -ge $CPU_WARN)  { return "Yellow" }
    return "Green"
}

function Get-RAMColor([double]$mb) {
    if ($mb -ge $RAM_CRIT_MB) { return "Red" }
    if ($mb -ge $RAM_WARN_MB) { return "Yellow" }
    return "Green"
}

function Get-Uptime {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    return "{0}d {1:D2}h {2:D2}m {3:D2}s" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
}

function Get-TotalRAMUsagePct {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
    return [math]::Round(($used / $os.TotalVisibleMemorySize) * 100, 1)
}

function Get-TotalRAMGB {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $free  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $used  = [math]::Round($total - $free, 1)
    return $total, $used, $free
}

function Draw-Bar([double]$pct, [int]$width = 20) {
    $filled = [math]::Round(($pct / 100) * $width)
    $empty  = $width - $filled
    $filled = [math]::Max(0, [math]::Min($filled, $width))
    $empty  = [math]::Max(0, $empty)
    return ("█" * $filled) + ("░" * $empty)
}

function Get-CPULoadPercent {
    $cpu = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
    return [math]::Round($cpu.Average, 1)
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: PROCESS SAMPLER (CPU requires 2 samples delta)
# ─────────────────────────────────────────────────────────────────────────────
function Get-TopProcesses {
    $procs = Get-Process | Where-Object { $_.CPU -ne $null } |
        Select-Object Id, Name,
            @{N="CPU_s"; E={ [math]::Round($_.CPU, 2) }},
            @{N="RAM_MB"; E={ [math]::Round($_.WorkingSet64 / 1MB, 1) }},
            @{N="Threads"; E={ $_.Threads.Count }},
            @{N="User"; E={
                try { $_.GetOwner().User } catch { "—" }
            }}

    # Sort by RAM for display (CPU seconds is cumulative, not %)
    return $procs | Sort-Object RAM_MB -Descending | Select-Object -First $TopProcessCount
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: DRAW DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────
function Draw-Dashboard {
    $timestamp  = Get-Date -Format "yyyy-MM-dd  HH:mm:ss"
    $uptime     = Get-Uptime
    $cpuLoad    = Get-CPULoadPercent
    $ramPct     = Get-TotalRAMUsagePct
    $total, $used, $free = Get-TotalRAMGB
    $processes  = Get-TopProcesses

    $cpuBar     = Draw-Bar $cpuLoad
    $ramBar     = Draw-Bar $ramPct
    $cpuColor   = if ($cpuLoad -ge 70) { "Red" } elseif ($cpuLoad -ge 40) { "Yellow" } else { "Green" }
    $ramColor   = if ($ramPct  -ge 80) { "Red" } elseif ($ramPct  -ge 60) { "Yellow" } else { "Green" }

    if (-not $NoClear) { Clear-Host }

    # ── Header ───────────────────────────────────────────────────────────────
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       ⚡ LIVE PROCESS DASHBOARD  —  Windows 11                      ║" -ForegroundColor Cyan
    Write-Host ("║       🕒 {0,-58}  ║" -f $timestamp) -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    # ── System Vitals ─────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  SYSTEM VITALS" -ForegroundColor White
    Write-Host ("  {"  + "─" * 68 + "}") -ForegroundColor DarkGray

    Write-Host ("  Uptime  : {0}" -f $uptime) -ForegroundColor Gray
    Write-Host ("  Host    : {0}  |  OS: {1}" -f $env:COMPUTERNAME, (Get-CimInstance Win32_OperatingSystem).Caption) -ForegroundColor Gray

    Write-Host ""
    Write-Host ("  CPU Load : [{0}] " -f $cpuBar) -NoNewline -ForegroundColor $cpuColor
    Write-Host ("{0,5}%" -f $cpuLoad) -ForegroundColor $cpuColor

    Write-Host ("  RAM Used : [{0}] " -f $ramBar) -NoNewline -ForegroundColor $ramColor
    Write-Host ("{0,5}%  ({1} GB used / {2} GB total)" -f $ramPct, $used, $total) -ForegroundColor $ramColor

    # ── Process Table ─────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  TOP $TopProcessCount PROCESSES BY RAM USAGE" -ForegroundColor White
    Write-Host ("  {"  + "─" * 68 + "}") -ForegroundColor DarkGray
    Write-Host ("  {0,-6} {1,-30} {2,10} {3,10} {4,8}" -f "PID", "Name", "RAM (MB)", "CPU (s)", "Threads") -ForegroundColor DarkCyan
    Write-Host ("  " + "─" * 68) -ForegroundColor DarkGray

    foreach ($p in $processes) {
        $ramColor2 = Get-RAMColor $p.RAM_MB
        $row = "  {0,-6} {1,-30} {2,10} {3,10} {4,8}" -f $p.Id, ($p.Name -replace ".{28}\K.*","…"), $p.RAM_MB, $p.CPU_s, $p.Threads
        Write-Host $row -ForegroundColor $ramColor2
    }

    # ── Footer ────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host ("  ─────────────────────────────────────────────────────────────────────") -ForegroundColor DarkGray
    Write-Host ("  Refreshing every {0}s  |  Press CTRL+C to exit" -f $RefreshSeconds) -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: MAIN LOOP
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "Starting Live Process Dashboard... (CTRL+C to stop)" -ForegroundColor Yellow
Start-Sleep -Seconds 1

try {
    while ($true) {
        Draw-Dashboard
        Start-Sleep -Seconds $RefreshSeconds
    }
} finally {
    Write-Host "`n  Dashboard stopped." -ForegroundColor Gray
}
