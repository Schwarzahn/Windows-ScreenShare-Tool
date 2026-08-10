# Sources & credits

Schwarzahn Windows ScreenShare Tool is a **branded live kit**: original work, rewrites, and careful ports of community SS utilities. Detection logic from upstream scanners is preserved where noted; UI / branding / packaging are Schwarzahn.

| Script | Lineage |
|:--|:--|
| `Services.ps1` | Original Schwarzahn compact SERVICE STATUS + BAM/Prefetch/PS logging/verdict |
| `Service-Enabler.ps1` | Original Schwarzahn enabler + VERIFY |
| `BamViewer.ps1` | Based on **RedLotus** BAM parser — restyled / rebranded |
| `DoomsDayDetector.ps1` | Doomsday client scanner lineage (e.g. zedoonvm1-style) — detection flow kept, blood UI |
| `ModAnalyzer.ps1` | Merged **Meow** + **Habibi**-style Modrinth / Megabase / strings analysis |
| `SignaturesParser.ps1` | **Orbdiff**-related signatures parser lineage |
| `Streams.ps1` | Original Schwarzahn ADS / Zone.Identifier scanner |
| `CommonDirectories.ps1` | Rewritten SS directories snapshot (older public gists 404’d) |
| `HotspotLogs.ps1` | Rewritten hotspot / ICS / WLAN event triage |
| `ManualTasks.ps1` | Original user scheduled-tasks view |
| `KillScreenProcesses.ps1` | Original capture / forbidden process killer |
| `AdvancedArtifacts.ps1` | Original Schwarzahn wrapper around AppCompat / SRUM / Shim / ArcHistory / VM / PS events; drives Eric Zimmerman EXEs when present |

## External projects (not vendored)

| Project | Author / home | Used for |
|:--|:--|:--|
| Eric Zimmerman Tools | https://ericzimmerman.github.io | RFC / SRUM / Shimcache CSV |
| KernelLiveDumpTool | Spokwn — GitHub | RAM / kernel string triage |
| FTK Imager | AccessData / Exterro | Memory capture |
| System Informer | systeminformer.sourceforge.io | Process / dump workflows |
| Fileless | Orbdiff | Fileless Event/RAM helper |
| VMAware | kernelwernel | VM detection |
| decrypt-bitlocker | lea13245 | Encrypted volume triage |
| Velociraptor | Rapid7 / community | ADSHunter & DFIR hunting |

If you are an upstream author and want a different credit line or removal, open an issue on this repo.

## Linux sister kit

https://github.com/Schwarzahn/Linux-ScreenShare-Tool — original Schwarzahn bash checker (Mint / Nobara / Ubuntu-style).
