# SS Playbook — live Windows

Operational notes for screenshares. Use with Schwarzahn scripts + [EXTERNAL-TOOLS.md](EXTERNAL-TOOLS.md).  
**Corroborate.** One hit rarely = instance.

---

## ADS (Alternate Data Streams)

NTFS can hide extra streams on a file. `Zone.Identifier` is normal after internet download (shows zone + often HostUrl). Bypass packs sometimes stash payloads in other named streams.

| Action | How |
|:--|:--|
| Quick scan | [`Streams.ps1`](../Streams.ps1) |
| Single file (CMD) | `dir /r` |
| Read Zone.Identifier | `Get-Content -Stream Zone.Identifier .\file.exe` |
| System-wide hunt | Velociraptor artifact `Windows.NTFS.ADSHunter` |
| MFT view | Filter column **Is ADS** (Zone.Identifier alone ≠ cheat) |

ADS presence ≠ execution. Confirm with Prefetch / BAM / SRUM / etc.

---

## WinRAR steganography (“open image with WinRAR”)

Exe packed into image/doc, opened via WinRAR → logs everywhere.

| Check | Detail |
|:--|:--|
| Registry | `HKCU\Software\WinRAR\ArcHistory` — non-archive extensions (`.png`, `.jpg`, `.pdf`…) = strong smell |
| Temp | `Rar$Ex*` under `%TEMP%` may still hold extracted exe |
| Prefetch | WinRAR `.pf` + nested exe names |

Covered in [`AdvancedArtifacts.ps1`](../AdvancedArtifacts.ps1) (ArcHistory section).

---

## DLL hijack

Replace a DLL next to a legit exe so launching the exe loads the cheat — no Process Hacker / injector UI.

| Trail | Note |
|:--|:--|
| Loaded modules | CSRSS / injection methods (see your SI workflow) |
| Crash dumps | Closing cheat often kills host → ReportArchive / crashdumps |
| Confirm DLL | DIE · BinText · VirusTotal — prove it isn’t the vendor library |

`regsvr32` / `rundll32` loaders still leave classic execution artifacts.

---

## Replace (file swap)

Common on **FAT32** (no USN Journal). On NTFS, journal reason codes cluster by method:

| Method | Typical USN reason pattern |
|:--|:--|
| Explorer | File Delete \| Close → Rename old/new → Close |
| Type 1 | Data Extend \| Data Truncation (+ Close) |
| Type 2 | Data Truncation → Data Extend \| Data Truncation |
| Copy 1 / 2 | Truncation + Extend + Overwrite ± Security/Basic Info Change |
| HEX 1 / 2 | Data Overwrite \| Data Extend (+ Close) |

Also check PowerShell history for `copy` / `type` / similar.  
FAT32: Prefetch, DiagTrack, FTK **file slack** strings.  
Virtual disks (OSFMount / Arsenal): tool execution + paths on a **drive letter that no longer exists**.

---

## Virtual machine

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Model, Manufacturer
```

Or `msinfo32` → System Manufacturer / System Model.  
Oracle · VirtualBox · VMware-style strings → treat as VM per your rules.  
Tool: [VMAware v2.6.0](https://github.com/kernelwernel/VMAware/releases/tag/v2.6.0) (newer may crash).

---

## Encrypted volumes

Live triage script (third-party):

```powershell
powershell -command "irm 'https://raw.githubusercontent.com/lea13245/decrypt-bitlocker/refs/heads/main/decrypt-bitlocker.ps1' | iex"
```

Flags BitLocker not FullyDecrypted, RAW / no-filesystem third-party crypto, access level.  
Does **not** find EFS/ZIP file crypto, hidden VeraCrypt, SED/OPAL, or real keys in RAM.

---

## Fileless & dumps

| Path | Use |
|:--|:--|
| Event Viewer | Windows PowerShell IDs **400 / 403 / 600 / 800**; Operational script-block logs |
| `# password` trick | May suppress console history / some logging → **RAM dump** |
| Orbdiff Fileless | https://github.com/Orbdiff/Fileless |
| RAM | FTK Imager → Capture Memory → analyze with Spokwn KernelLiveDumpTool |
| Kernel | System Informer → **System** (PID 4) → Create live dump (Full) → same analyzer |

**Important:** RAM / kernel hits alone usually **do not** confirm instance (browse hover residue, etc.). Prefer disk execution artifacts for bans. Avoid dumps on potato PCs (BSOD risk).

---

## Manual memory clear

Cheater opens Process Hacker / System Informer → process Memory → overwrites detection strings (`doomsday`, paths, …) with `nothing` / `hi` before you dump.

| Implication | |
|:--|:--|
| Clean process dump | May be sabotaged |
| String shows foreign PID | Possible edit trail |
| Response | Prefer Prefetch/BAM/USN/SRUM; don’t trust a single wiped `javaw` dump |

---

## Execution stack (short)

```
Prefetch · BAM · Amcache · RecentFileCache · Shimcache · SRUM · UserAssist
     ↑ corroborate ↑
ADS / ArcHistory / tasks / hotspot / mods = context
RAM / Kernel = last resort / fileless / advanced bypass
```

DPS stopped → SRUM dead. Optimized “debloat” images often kill telemetry you need — note it in the report.
