```
███████╗ ██████╗██╗  ██╗██╗    ██╗ █████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗███╗   ██╗
██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗██╔══██╗╚══███╔╝██╔══██╗██║  ██║████╗  ██║
███████╗██║     ███████║██║ █╗ ██║███████║██████╔╝  ███╔╝ ███████║███████║██╔██╗ ██║
╚════██║██║     ██╔══██║██║███╗██║██╔══██║██╔══██╗ ███╔╝  ██╔══██║██╔══██║██║╚██╗██║
███████║╚██████╗██║  ██║╚███╔███╔╝██║  ██║██║  ██║███████╗██║  ██║██║  ██║██║ ╚████║
╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

# Windows ScreenShare Tool

**by Schwarzahn** — live Windows triage kit for Minecraft / game screenshares.

Blood console UI. One-liner run. Corroboration-first: services → BAM/Prefetch → ADS → mods → advanced artifacts.

| | |
|:--|:--|
| **Platform** | Windows 10 / 11 |
| **Runtime** | PowerShell 5.1+ (Admin where marked) |
| **Sister kit** | [Linux ScreenShare Tool](https://github.com/Schwarzahn/Linux-ScreenShare-Tool) |
| **Docs** | [Playbook](docs/PLAYBOOK.md) · [External EXE](docs/EXTERNAL-TOOLS.md) · [Sources](docs/SOURCES.md) |

---

## Quick start

Open **PowerShell as Administrator**, then paste:

```powershell
# Core — services, Prefetch/BAM pulse, PS logging, verdict
irm https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Services.ps1 | iex
```

Heal cured / disabled critical services first (when needed):

```powershell
irm https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Service-Enabler.ps1 | iex
```

---

## Arsenal

### Core triage

| Script | Role | Admin | One-liner |
|:--|:--|:--:|:--|
| [`Services.ps1`](Services.ps1) | Compact **SERVICE STATUS**, disks, BAM/Prefetch, PowerShell logging, events, verdict | yes | `irm .../Services.ps1 \| iex` |
| [`Service-Enabler.ps1`](Service-Enabler.ps1) | Enable critical SS services + Prefetch, then VERIFY | yes | `irm .../Service-Enabler.ps1 \| iex` |
| [`BamViewer.ps1`](BamViewer.ps1) | Full BAM path / time / exists / signature view | yes | `irm .../BamViewer.ps1 \| iex` |

### Execution & client

| Script | Role | Admin | One-liner |
|:--|:--|:--:|:--|
| [`DoomsDayDetector.ps1`](DoomsDayDetector.ps1) | Doomsday-style client scanner (USN / Prefetch traces) | — | `irm .../DoomsDayDetector.ps1 \| iex` |
| [`ModAnalyzer.ps1`](ModAnalyzer.ps1) | Mods: Modrinth / Megabase / string hits | — | `irm .../ModAnalyzer.ps1 \| iex` |
| [`SignaturesParser.ps1`](SignaturesParser.ps1) | Signature / hash style parsing for SS | yes | `irm .../SignaturesParser.ps1 \| iex` |

### Artifacts & surface

| Script | Role | Admin | One-liner |
|:--|:--|:--:|:--|
| [`Streams.ps1`](Streams.ps1) | **ADS** / Zone.Identifier scanner | — | `irm .../Streams.ps1 \| iex` |
| [`AdvancedArtifacts.ps1`](AdvancedArtifacts.ps1) | RecentFileCache · SRUM · Shimcache · PS fileless hints · WinRAR ArcHistory · VM | yes | `irm .../AdvancedArtifacts.ps1 \| iex` |
| [`CommonDirectories.ps1`](CommonDirectories.ps1) | Common SS directories snapshot | — | `irm .../CommonDirectories.ps1 \| iex` |
| [`HotspotLogs.ps1`](HotspotLogs.ps1) | Mobile Hotspot / ICS / WLAN events | yes | `irm .../HotspotLogs.ps1 \| iex` |
| [`ManualTasks.ps1`](ManualTasks.ps1) | Scheduled tasks for current user | — | `irm .../ManualTasks.ps1 \| iex` |
| [`KillScreenProcesses.ps1`](KillScreenProcesses.ps1) | Capture / forbidden process detect & kill | — | `irm .../KillScreenProcesses.ps1 \| iex` |

> Replace `...` with  
> `https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main`

---

## Suggested SS order

```
1  Service-Enabler   (if services look cured / Prefetch off)
2  Services          (pulse + verdict)
3  BamViewer         (execution corroboration)
4  Streams           (ADS / Zone.Identifier)
5  ModAnalyzer       (client / mods)
6  DoomsDayDetector  (when client suspicion)
7  AdvancedArtifacts (RFC / SRUM / Shim / ArcHistory / VM / fileless)
8  External EXE      → docs/EXTERNAL-TOOLS.md  (Zimmerman, dumps, Velociraptor…)
```

Corroborate. One artifact ≠ instance. Prefetch + BAM + RFC beats a single string in RAM.

---

## What this repo is / isn’t

| Is | Isn’t |
|:--|:--|
| Live screenshare triage | Full disk image lab |
| Corroboration helpers | Auto RAM / kernel dump (too heavy / BSOD risk) |
| Blood-branded console UX | Generic “purple SaaS” UI |
| Open PowerShell you can read | Closed cheat / injector |

External parsers (Eric Zimmerman, Spokwn, System Informer, FTK, …) stay **linked**, not re-hosted — see [EXTERNAL-TOOLS.md](docs/EXTERNAL-TOOLS.md).

---

## Docs

| Doc | Contents |
|:--|:--|
| [docs/PLAYBOOK.md](docs/PLAYBOOK.md) | ADS · stego/WinRAR · DLL hijack · replace/USN · VM · encrypted volumes · memory clear |
| [docs/EXTERNAL-TOOLS.md](docs/EXTERNAL-TOOLS.md) | EXE downloads, exact commands, what confirms instance |
| [docs/SOURCES.md](docs/SOURCES.md) | Upstream credits & rewrites |

---

## Linux

Mint / Nobara / Ubuntu-style checks live here:

**https://github.com/Schwarzahn/Linux-ScreenShare-Tool**

```bash
curl -fsSL https://raw.githubusercontent.com/Schwarzahn/Linux-ScreenShare-Tool/main/Linux-SS-Checker.sh | bash
```

---

## Disclaimer

For authorized screenshares / DFIR training only. You are responsible for local law and server rules. Findings must be interpreted in context — volatile memory and browse residue are not automatic bans.

---

<p align="center">
  <b>SCHWARZAHN</b><br>
  <sub>Windows ScreenShare Tool · this era’s live triage</sub>
</p>
