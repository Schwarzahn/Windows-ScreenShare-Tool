```
███████╗ ██████╗██╗  ██╗██╗    ██╗ █████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗███╗   ██╗
██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗██╔══██╗╚══███╔╝██╔══██╗██║  ██║████╗  ██║
███████╗██║     ███████║██║ █╗ ██║███████║██████╔╝  ███╔╝ ███████║███████║██╔██╗ ██║
╚════██║██║     ██╔══██║██║███╗██║██╔══██║██╔══██╗ ███╔╝  ██╔══██║██╔══██║██║╚██╗██║
███████║╚██████╗██║  ██║╚███╔███╔╝██║  ██║██║  ██║███████╗██║  ██║██║  ██║██║ ╚████║
╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

# Windows ScreenShare Tool

**by Schwarzahn** — Windows screenshare kit (Minecraft / game SS).

Blood console. One-liners. Порядок: services → BAM/Prefetch → ADS → mods → advanced artifacts.

| | |
|:--|:--|
| **Platform** | Windows 10 / 11 |
| **Runtime** | PowerShell 5.1+ (Admin where marked) |
| **Sister kit** | [Linux ScreenShare Tool](https://github.com/Schwarzahn/Linux-ScreenShare-Tool) |
| **Docs** | [Playbook](docs/PLAYBOOK.md) · [External tools](docs/EXTERNAL-TOOLS.md) · [Sources](docs/SOURCES.md) |

---

## Quick start

**CMD as Administrator** (так и вставляй):

```bat
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Services.ps1')"
```

Heal cured / disabled critical services first (when needed):

```bat
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Service-Enabler.ps1')"
```

Fileless:

```bat
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod ('https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/FilelessDetector.ps1?cb=' + [guid]::NewGuid()))"
```

**Tools hub** — лучше `.exe` (GUI):

1. Скачай [SchwarzahnTools.exe](https://github.com/Schwarzahn/Windows-ScreenShare-Tool/releases/latest/download/SchwarzahnTools.exe)
2. Запусти **от Администратора**

Или PowerShell-версия:

```bat
powershell -NoProfile -STA -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/SchwarzahnTools.ps1')"
```

Шаблон для любого скрипта из репо:

```bat
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/ИМЯ.ps1')"
```

---

## Arsenal

### Tools hub

| Script | Role | Admin | CMD one-liner |
|:--|:--|:--:|:--|
| [`SchwarzahnTools.ps1`](SchwarzahnTools.ps1) + [`ToolsCatalog.json`](ToolsCatalog.json) | GUI hub: download/launch OrbDiff·Spokwn·Zimmerman·NirSoft + Schwarzahn scripts | yes | STA one-liner above |

### Core triage

| Script | Role | Admin | CMD one-liner |
|:--|:--|:--:|:--|
| [`Services.ps1`](Services.ps1) | Compact **SERVICE STATUS**, disks, BAM/Prefetch, PowerShell logging, events, verdict | yes | `…/Services.ps1` |
| [`Service-Enabler.ps1`](Service-Enabler.ps1) | Enable critical SS services + Prefetch, then VERIFY | yes | `…/Service-Enabler.ps1` |
| [`BamViewer.ps1`](BamViewer.ps1) | Full BAM path / time / exists / signature view | yes | `…/BamViewer.ps1` |

### Execution & client

| Script | Role | Admin | CMD one-liner |
|:--|:--|:--:|:--|
| [`DoomsDayDetector.ps1`](DoomsDayDetector.ps1) | Doomsday-style client scanner (USN / Prefetch traces) | — | `…/DoomsDayDetector.ps1` |
| [`ModAnalyzer.ps1`](ModAnalyzer.ps1) | Mods: Modrinth / Megabase / string hits | — | `…/ModAnalyzer.ps1` |
| [`SignaturesParser.ps1`](SignaturesParser.ps1) | Signature / hash style parsing for SS | yes | `…/SignaturesParser.ps1` |

### Artifacts & surface

| Script | Role | Admin | CMD one-liner |
|:--|:--|:--:|:--|
| [`Streams.ps1`](Streams.ps1) | **ADS** / Zone.Identifier scanner | — | `…/Streams.ps1` |
| [`AdvancedArtifacts.ps1`](AdvancedArtifacts.ps1) | RecentFileCache · SRUM · Shimcache · ArcHistory · VM | yes | `…/AdvancedArtifacts.ps1` |
| [`FilelessDetector.ps1`](FilelessDetector.ps1) | PS logs, USN wipe (history/Prefetch), Defender, 4688. Red=hit | yes | `…/FilelessDetector.ps1` |
| [`CommonDirectories.ps1`](CommonDirectories.ps1) | Common SS directories snapshot | — | `…/CommonDirectories.ps1` |
| [`HotspotLogs.ps1`](HotspotLogs.ps1) | Mobile Hotspot / ICS / WLAN events | yes | `…/HotspotLogs.ps1` |
| [`ManualTasks.ps1`](ManualTasks.ps1) | Scheduled tasks for current user | — | `…/ManualTasks.ps1` |
| [`KillScreenProcesses.ps1`](KillScreenProcesses.ps1) | Capture / forbidden process detect & kill | — | `…/KillScreenProcesses.ps1` |

> One-liner =  
> `powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/<file>')"`  
> Подставь имя файла вместо `<file>`.

---

## Suggested SS order

```
1  Service-Enabler   (if services look cured / Prefetch off)
2  Services          (pulse + verdict)
3  BamViewer         (execution corroboration)
4  Streams           (ADS / Zone.Identifier)
5  ModAnalyzer       (client / mods)
6  DoomsDayDetector  (when client suspicion)
7  FilelessDetector  (PS / USN wipe / Defender)
8  AdvancedArtifacts (RFC / SRUM / Shim / ArcHistory / VM)
9  External EXE      → docs/EXTERNAL-TOOLS.md  (Zimmerman, dumps…)
```

Corroborate. One artifact ≠ instance. Prefetch + BAM + RFC beats a single string in RAM.

---

## What this repo is / isn’t

| Is | Isn’t |
|:--|:--|
| Live screenshare triage | Full disk image lab |
| Helpers to correlate artifacts | Auto RAM / kernel dump (BSOD risk) |
| Open PowerShell you can read | Closed cheat / injector |

External parsers (Eric Zimmerman, Spokwn, System Informer, FTK, …) — links only, not re-hosted: [EXTERNAL-TOOLS.md](docs/EXTERNAL-TOOLS.md).

---

## Docs

| Doc | Contents |
|:--|:--|
| [docs/PLAYBOOK.md](docs/PLAYBOOK.md) | ADS · WinRAR stego · DLL hijack · replace/USN · VM · dumps |
| [docs/EXTERNAL-TOOLS.md](docs/EXTERNAL-TOOLS.md) | Zimmerman, dumps, EXE map |
| [docs/SOURCES.md](docs/SOURCES.md) | Credits |


---

## Linux

Mint / Nobara / Ubuntu-style checks live here:

**https://github.com/Schwarzahn/Linux-ScreenShare-Tool**

```bash
curl -fsSL https://raw.githubusercontent.com/Schwarzahn/Linux-ScreenShare-Tool/main/Linux-SS-Checker.sh | bash
```

---

## Disclaimer

Authorized screenshares / training only. Your laws, your server rules. One string in RAM ≠ ban.

---

<p align="center"><b>SCHWARZAHN</b></p>
