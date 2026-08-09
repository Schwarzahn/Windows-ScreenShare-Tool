# External tools (EXE & labs)

Schwarzahn scripts stay lightweight. For deep parse / dumps, use these **official** builds.  
Do not redistribute cracked copies — download from authors.

---

## Eric Zimmerman (CSV parsers)

Index: https://ericzimmerman.github.io/#!index.md

| Tool | Artifact | Command |
|:--|:--|:--|
| **RecentFileCacheParser** | `C:\Windows\AppCompat\Programs\RecentFileCache.bcf` | `RecentFileCacheParser.exe -f "C:\Windows\AppCompat\Programs\RecentFileCache.bcf" --csv .` |
| **SrumECmd** | `C:\Windows\System32\sru\SRUDB.dat` | `SrumECmd.exe -f "C:\Windows\System32\sru\SRUDB.dat" --csv .` |
| **AppCompatCacheParser** | Shimcache (registry) | `AppCompatCacheParser.exe --csv .` |
| Prefetch / Amcache / etc. | classic stack | see Zimmerman index |

**RecentFileCache** — short FIFO execution cache; great corroboration when Prefetch/BAM wiped.  
**SRUM** — ~30–60 days process/network/focus; times are **UTC**. Needs **DPS** running. Review `AppTimelineProvider_Output` CSV.  
**Shimcache** — path / size / last modified; often refreshes on reboot.

[`AdvancedArtifacts.ps1`](../AdvancedArtifacts.ps1) auto-detects these EXEs if placed on Desktop, Downloads, `C:\Tools`, or next to the script.

Direct (net9 example):  
https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip

---

## Spokwn — KernelLiveDumpTool

https://github.com/spokwn/kernellivedumptool/releases

Analyzes **kernel `.dmp`** and **RAM `.mem`**. Default filters: answer `n` when asked for custom strings → read `Results\*.txt`.

| Dump type | How to capture | Confirms instance? |
|:--|:--|:--|
| RAM | FTK Imager → File → Capture Memory | Usually **no** alone |
| Kernel | System Informer (Admin) → process **System** PID 4 → Create live dump → **Full** | Usually **no** alone |

Disable AV if the tool is blocked. Don’t dump on weak PCs.

---

## FTK Imager (RAM)

https://accessdata-ftk-imager.software.informer.com/download/  
(or current AccessData / Exterro distribution)

File → **Capture Memory** → choose output folder → wait for `.mem`.

---

## System Informer

https://systeminformer.sourceforge.io/ (or your pinned build)

Needed for: live process view, kernel-mode driver (when your SOP requires it), CSRSS memory export workflows, kernel live dump.

---

## Velociraptor

Artifact: **Windows.NTFS.ADSHunter** — lists ADS system-wide. Presence ≠ execution.

---

## Orbdiff — Fileless

https://github.com/Orbdiff/Fileless  
Event Viewer + optional RAM scan for fileless patterns.

Related: [`SignaturesParser.ps1`](../SignaturesParser.ps1) lineage / Orbdiff ecosystem.

---

## VMAware

https://github.com/kernelwernel/VMAware/releases/tag/v2.6.0  
Prefer **v2.6.0** if newer builds crash.

Quick native check (also in AdvancedArtifacts):

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Model, Manufacturer
```

---

## Encrypted disk triage

```powershell
powershell -command "irm 'https://raw.githubusercontent.com/lea13245/decrypt-bitlocker/refs/heads/main/decrypt-bitlocker.ps1' | iex"
```

Upstream: https://github.com/lea13245/decrypt-bitlocker

---

## Suggested folder layout on the SS box

```
C:\SS\
  Zimmerman\     RecentFileCacheParser, SrumECmd, AppCompatCacheParser, ...
  Spokwn\        KernelLiveDumpTool.exe
  dumps\         .mem / .dmp / Results\
```

Then run Schwarzahn `AdvancedArtifacts.ps1` — it will find parsers under common paths.
