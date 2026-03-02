<div align="center">

<!-- BANNER -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f0c29,50:302b63,100:24243e&height=200&section=header&text=PowerShell%20Utilities%20Toolkit&fontSize=52&fontColor=ffffff&fontAlignY=38&desc=Automation%20%7C%20System%20Management%20%7C%20Utilities&descAlignY=58&descSize=18" width="100%"/>

<!-- BADGES -->
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207.x-blue?style=for-the-badge&logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen?style=for-the-badge)
![Scripts](https://img.shields.io/badge/Scripts-Growing-orange?style=for-the-badge&logo=github)

<br/>

> **A curated collection of production-ready PowerShell scripts for Windows automation,**
> **system management, diagnostics, and developer productivity.**

<br/>

[📋 Scripts](#-scripts) • [🚀 Getting Started](#-getting-started)

</div>

## 📋 Scripts

| # | Script | Category | Description | Parameters | Admin Required |
|---|--------|----------|-------------|------------|:--------------:|
| 01 | [`BloatwareDetector.ps1`](./BloatwareDetector/) | 🛡️ System Cleanup | Detects & removes Windows 11 pre-installed bloatware with severity scoring, startup scan & CSV export | — | ✅ |
| 02 | [`ProcessDashboard.ps1`](./ProcessDashboard/) | 📊 Monitoring | Live real-time console dashboard of top CPU/RAM processes with color-coded thresholds & system vitals | `-RefreshSeconds` `-TopProcessCount` `-NoClear` | ✅ |
| 03 | [`PowerShellDiagnostics.ps1`](./PowerShellDiagnostics/) | 🔍 Diagnostics | Full audit of execution policies, AppLocker, Group Policy, SRP, Defender, language mode & live execution tests | `-OutputFolder` `-NoAutoOpen` | ✅ |
| 04 | *(coming soon)* | ⚙️ Automation | — | — | — |

> More scripts added regularly. ⭐ **Star this repo** to stay updated.


---

## 🚀 Getting Started

### Prerequisites

- Windows 10 / 11
- PowerShell **5.1** or **7.x** (recommended)
- Some scripts require **Administrator privileges** (noted in the table above)

### Clone the Repository

```powershell
git clone https://github.com/aggelosy/powershell-utils.git
cd powershell-utils
