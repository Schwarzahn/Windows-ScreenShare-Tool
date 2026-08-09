#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Fileless — PS logs, USN wipe (history/Prefetch), Defender surface.
  by Schwarzahn
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Fileless'
$script:SusHits = 0
$script:WarnHits = 0
$script:Hits = New-Object System.Collections.Generic.List[string]

function Enable-AnsiConsole {
    if ($script:AnsiReady) { return }
    try {
        if (-not ('Native.ConsoleVT' -as [type])) {
            Add-Type -ErrorAction Stop -Namespace Native -Name ConsoleVT -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll", SetLastError=true)] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll", SetLastError=true)] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@
        }
        $h = [Native.ConsoleVT]::GetStdHandle(-11); $m = [uint32]0
        if ([Native.ConsoleVT]::GetConsoleMode($h, [ref]$m)) { [void][Native.ConsoleVT]::SetConsoleMode($h, ($m -bor 4)) }
        $script:AnsiReady = $true
    } catch { $script:AnsiReady = $false }
}
function Write-Ansi([string]$t) { [Console]::Write($t) }
function Get-BloodPalette {
    if ($script:BloodPalette) { return $script:BloodPalette }
    $script:BloodPalette = @{
        ShadowFar="$esc[38;2;35;0;0m"; ShadowNear="$esc[38;2;80;0;0m"; Mid="$esc[38;2;150;0;0m"
        Blood="$esc[38;2;200;10;10m"; Hot="$esc[38;2;255;35;35m"; Glow="$esc[38;2;255;90;90m"
        Dim="$esc[38;2;85;85;85m"; Soft="$esc[38;2;170;170;170m"
        Reset="$esc[0m"; Bold="$esc[1m"
    }
    return $script:BloodPalette
}
function Write-BloodBanner {
    param([string]$Subtitle = 'Fileless')
    Enable-AnsiConsole; $c = Get-BloodPalette
    $art = @(
        '███████╗ ██████╗██╗  ██╗██╗    ██╗ █████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗███╗   ██╗',
        '██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗██╔══██╗╚══███╔╝██╔══██╗██║  ██║████╗  ██║',
        '███████╗██║     ███████║██║ █╗ ██║███████║██████╔╝  ███╔╝ ███████║███████║██╔██╗ ██║',
        '╚════██║██║     ██╔══██║██║███╗██║██╔══██║██╔══██╗ ███╔╝  ██╔══██║██╔══██║██║╚██╗██║',
        '███████║╚██████╗██║  ██║╚███╔███╔╝██║  ██║██║  ██║███████╗██║  ██║██║  ██║██║ ╚████║',
        '╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝'
    )
    $grad = @($c.Glow,$c.Hot,$c.Blood,$c.Blood,$c.Mid,$c.ShadowNear)
    Write-Host ''
    foreach ($l in $art) { Write-Ansi ("   $($c.ShadowFar)$l$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    foreach ($l in $art) { Write-Ansi ("  $($c.ShadowNear)$l$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    for ($i=0; $i -lt $art.Count; $i++) { Write-Ansi ("$($grad[$i])$($art[$i])$($c.Reset)`n") }
    Write-Ansi ("$($c.ShadowFar)  $($('═'*72))$($c.Reset)`n")
    $tag = "by $script:BrandName"
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}
function Write-BloodFoot {
    param([string]$Subtitle = 'Fileless')
    Enable-AnsiConsole; $c = Get-BloodPalette; $tag = "by $script:BrandName"
    Write-Host ''; Write-Ansi ("$($c.ShadowFar)  $($('═'*64))$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n"); Write-Host ''
}
function Write-Section([string]$Text) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    $line = '─' * [Math]::Max(8, (52 - $Text.Length))
    Write-Host ''; Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n")
}
function Write-KV([string]$K,[string]$V,[ConsoleColor]$Color='White') {
    Write-Host ("  {0,-32}" -f $K) -NoNewline -ForegroundColor DarkGray
    Write-Host $V -ForegroundColor $Color
}
# Color model: RED = detection only | GREEN = OK / noise ignored | YELLOW = soft caveat
function Write-Ok([string]$t){ Write-Host "[+] $t" -ForegroundColor Green }
function Write-Warn([string]$t){ Write-Host "[!] $t" -ForegroundColor Yellow; $script:WarnHits++ }
function Write-Bad([string]$t){
    Write-Host "[x] $t" -ForegroundColor Red
    $script:SusHits++
    if ($script:Hits.Count -lt 200) { [void]$script:Hits.Add($t) }
}
function Write-Info([string]$t){ Write-Host "[*] $t" -ForegroundColor Green }

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Detector build — bump so you can see cache bust worked
$script:DetectorBuild = 'v5-2026-08-09'

# REAL injector / wipe signals (no short junk like "etw" / "bypass" / WindowStyle alone)
$script:NeedleStrong = @(
    'FromBase64String','DownloadString','DownloadFile','DownloadData',
    'Net.WebClient','Start-BitsTransfer','bitsadmin ',
    '-EncodedCommand',' -enc ','Assembly.Load','Load([byte',
    'VirtualAlloc','WriteProcessMemory','CreateRemoteThread','Marshal::Copy',
    'AmsiUtils','amsiInitFailed','amsiContext','AmsiScanBuffer',
    'System.Management.Automation.AmsiUtils','EtwEventWrite',
    'Set-MpPreference -DisableRealtimeMonitoring','DisableRealtimeMonitoring $true',
    'Add-MpPreference -ExclusionPath','Add-MpPreference -ExclusionProcess',
    'mshta http','mshta https','hta:application',
    'regsvr32 /s /n /u /i:','scrobj.dll',
    'wmic process call create',
    '# password','#password',
    'ReflectiveLoader','reflective dll',
    'Clear-History','wevtutil cl','wevtutil clear-log','Clear-EventLog','Clear-WinEvent'
)

# Wipe targets in USN (filename only)
$script:WipeFileNames = @(
    'ConsoleHost_history.txt','ConsoleHost_history',
    'PowerShell_transcript','RecentFileCache.bcf',
    'Amcache.hve','SYSTEM.evtx','SECURITY.evtx',
    'PowerShell%4Operational.evtx','Windows PowerShell.evtx',
    'Microsoft-Windows-PowerShell%4Operational.evtx'
)

# Self / SS / this script's 4104 dump (needle arrays live in the script text)
$script:IgnoreSubstrings = @(
    'Windows-ScreenShare-Tool','FilelessDetector','DoomsDayDetector','AdvancedArtifacts',
    'Service-Enabler','Schwarzahn','ScreenShare-Tool-by-Schwarzahn',
    'raw.githubusercontent.com/Schwarzahn',
    'Write-BloodBanner','Write-Bad','Write-Ok','Write-Warn','Write-Section',
    'NeedleStrong','IgnoreSubstrings','DetectorBuild','WipeFileNames','Get-UsnWipeHits'
)

function Test-IsNoise([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    # Defender Get/Set-Mp* proxy definitions flood 4104 with ExclusionPath etc. — not real calls
    if ($Text.IndexOf('__cmdletization', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Text.IndexOf('Microsoft.PowerShell.Cmdletization', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    foreach ($x in $script:IgnoreSubstrings) {
        if ($Text.IndexOf($x, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    # SS one-liner: Bypass + IEX + IWR/IRM
    $isLauncher =
        ($Text.IndexOf('ExecutionPolicy', [StringComparison]::OrdinalIgnoreCase) -ge 0) -and
        ($Text.IndexOf('Invoke-Expression', [StringComparison]::OrdinalIgnoreCase) -ge 0) -and
        (
            ($Text.IndexOf('Invoke-RestMethod', [StringComparison]::OrdinalIgnoreCase) -ge 0) -or
            ($Text.IndexOf('Invoke-WebRequest', [StringComparison]::OrdinalIgnoreCase) -ge 0)
        )
    if ($isLauncher) { return $true }
    if ($Text -match '(?i)Invoke-Expression\s*\(\s*Invoke-RestMethod' -and
        $Text -notmatch '(?i)FromBase64String|DownloadString|AmsiUtils|VirtualAlloc|WriteProcessMemory') {
        return $true
    }
    return $false
}

function Test-SuspiciousText([string]$Text) {
    if (Test-IsNoise $Text) { return @() }

    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($n in $script:NeedleStrong) {
        if ($Text.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$hits.Add($n.Trim())
        }
    }
    return @($hits | Select-Object -Unique)
}

function Format-Clip([string]$s, [int]$Max = 140) {
    if ($null -eq $s) { return '' }
    $one = ($s -replace '\s+', ' ').Trim()
    if ($one.Length -gt $Max) { return $one.Substring(0, $Max) + '...' }
    return $one
}

function Test-IsWipeReason([string]$Reason) {
    if ([string]::IsNullOrWhiteSpace($Reason)) { return $false }
    return ($Reason -match '(?i)File delete|CLOSE\+DELETE|Close \+ File delete|FILE_DELETE|DATA_OVERWRITE|Security change|Rename')
}

function Test-IsWipeFileName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    $n = $Name.Trim()
    foreach ($w in $script:WipeFileNames) {
        if ($n.IndexOf($w, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    if ($n -match '(?i)\.pf$' -and $n -match '(?i)POWERSHELL|PWSH|MSHTA|RUNDLL32|REGSVR32|WSCRIPT|CSCRIPT|WMIC|CMD\.EXE') {
        return $true
    }
    return $false
}

function Get-UsnWipeHits {
    param([string[]]$DriveLetters = @('C'), [int]$MinutesBack = 60)
    $cutoff = (Get-Date).AddMinutes(-$MinutesBack)
    $hits = New-Object System.Collections.Generic.List[object]
    $pfDeletes = 0

    foreach ($driveLetter in $DriveLetters) {
        try {
            Write-Ok ("USN scan {0}: (last {1} min, wipe targets only)..." -f $driveLetter, $MinutesBack)
            $usnOutput = & fsutil usn readjournal "$driveLetter`:" 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $usnOutput) {
                Write-Warn ("USN unread on {0}: (disabled / FS not NTFS / locked)" -f $driveLetter)
                continue
            }

            $currentFile = ''
            $currentTime = $null
            foreach ($line in $usnOutput) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if ($line -match 'File name\s+:\s*(.+)$') {
                    $currentFile = $Matches[1].Trim()
                } elseif ($line -match 'Time stamp\s+:\s*(.+)$') {
                    try { $currentTime = [DateTime]::Parse($Matches[1].Trim()) } catch { $currentTime = $null }
                } elseif ($line -match 'Reason\s+:\s*(.+)$') {
                    $reason = $Matches[1].Trim()
                    if ($currentFile -and $currentTime -and $currentTime -gt $cutoff -and (Test-IsWipeReason $reason)) {
                        if (Test-IsWipeFileName $currentFile) {
                            [void]$hits.Add([pscustomobject]@{
                                Drive = $driveLetter
                                File  = $currentFile
                                Time  = $currentTime
                                Reason = $reason
                            })
                        } elseif ($currentFile -match '(?i)\.pf$') {
                            $pfDeletes++
                        }
                    }
                    $currentFile = ''
                    $currentTime = $null
                }
            }
        } catch {
            Write-Warn ("USN error {0}: {1}" -f $driveLetter, $_.Exception.Message)
        }
    }

    return @{ Hits = $hits; PrefetchDeleteCount = $pfDeletes }
}

# ===== START =====
Write-BloodBanner -Subtitle $script:ToolName

if (-not (Test-IsAdmin)) {
    Write-Section 'ERROR'
    Write-Bad 'Need Administrator'
    Write-BloodFoot
    return
}

Write-Section 'SYSTEM'
Write-KV 'PC' $env:COMPUTERNAME
Write-KV 'User' $env:USERNAME
Write-KV 'Now' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Write-KV 'Build' $script:DetectorBuild 'Green'

# ----- Logging posture -----
Write-Section 'POWERSHELL LOGGING STATE'
$sbKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
$modKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging'
$transKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
try {
    $sb = Get-ItemProperty $sbKey -ErrorAction SilentlyContinue
    if ($sb -and $sb.EnableScriptBlockLogging -eq 1) {
        Write-Ok 'ScriptBlockLogging = ON (4104 gold)'
    } else {
        Write-Warn 'ScriptBlockLogging OFF'
    }
} catch { Write-Warn 'Cannot read ScriptBlockLogging policy' }

try {
    $ml = Get-ItemProperty $modKey -ErrorAction SilentlyContinue
    if ($ml -and $ml.EnableModuleLogging -eq 1) { Write-Ok 'ModuleLogging = ON' }
    else { Write-Ok 'ModuleLogging off' }
} catch {}

try {
    $tr = Get-ItemProperty $transKey -ErrorAction SilentlyContinue
    if ($tr -and $tr.EnableTranscripting -eq 1) {
        Write-Ok ("Transcription ON  dir={0}" -f $tr.OutputDirectory)
    } else { Write-Ok 'Transcription off' }
} catch {}

try {
    $ep = Get-ExecutionPolicy -List | Where-Object Scope -eq 'LocalMachine'
    Write-KV 'ExecutionPolicy (LM)' ("{0}" -f $ep.ExecutionPolicy) 'Green'
} catch {}

# ----- AMSI providers -----
Write-Section 'DEFENDER / AMSI'
$amsiKey = 'HKLM:\SOFTWARE\Microsoft\AMSI\Providers'
if (Test-Path $amsiKey) {
    $prov = Get-ChildItem $amsiKey -ErrorAction SilentlyContinue
    if ($prov) {
        Write-Ok ("AMSI providers registered: {0}" -f $prov.Count)
        foreach ($p in $prov) { Write-Ok ("  provider {0}" -f $p.PSChildName) }
    } else {
        Write-Bad 'AMSI Providers key empty'
    }
} else {
    Write-Bad 'AMSI Providers key missing'
}

try {
    $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($mp) {
        Write-KV 'Defender RealTime' ("{0}" -f $mp.RealTimeProtectionEnabled) $(if ($mp.RealTimeProtectionEnabled){'Green'}else{'Red'})
        Write-KV 'AMSI / Antispyware' ("{0}" -f $mp.AntispywareEnabled) $(if ($mp.AntispywareEnabled){'Green'}else{'Red'})
        if (-not $mp.RealTimeProtectionEnabled) { Write-Bad 'Defender RealTime OFF' }
        else { Write-Ok 'Defender RealTime ON' }
    } else {
        Write-Ok 'Get-MpComputerStatus unavailable (no Defender / third-party AV)'
    }
} catch { Write-Ok 'Defender status unreadable' }

# ----- Wipe traces (USN + event clear) -----
Write-Section 'USN WIPE'
$sysDrive = ($env:SystemDrive -replace ':','')
if ([string]::IsNullOrWhiteSpace($sysDrive)) { $sysDrive = 'C' }
$usn = Get-UsnWipeHits -DriveLetters @($sysDrive) -MinutesBack 60
$wipeShown = 0
foreach ($h in ($usn.Hits | Sort-Object Time -Descending)) {
    $wipeShown++
    if ($wipeShown -gt 30) { break }
    Write-Bad ("USN WIPE  {0:yyyy-MM-dd HH:mm:ss}  {1}:\{2}  [{3}]" -f $h.Time, $h.Drive, $h.File, $h.Reason)
}
if ($usn.PrefetchDeleteCount -ge 8) {
    Write-Bad ("USN: mass Prefetch .pf deletes in window = {0} (likely Prefetch wipe)" -f $usn.PrefetchDeleteCount)
} elseif ($usn.PrefetchDeleteCount -gt 0) {
    Write-Ok ("USN: Prefetch .pf delete/rename noise = {0} (below mass threshold)" -f $usn.PrefetchDeleteCount)
}
if ($wipeShown -eq 0 -and $usn.PrefetchDeleteCount -lt 8) {
    Write-Ok 'No wipe-target USN deletes in last 60 min'
}

Write-Section 'LOG CLEARS'
$clears = @()
try {
    $clears += Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 1102 } -MaxEvents 15 -ErrorAction SilentlyContinue
} catch {}
try {
    $clears += Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 104 } -MaxEvents 15 -ErrorAction SilentlyContinue
} catch {}
if ($clears -and $clears.Count -gt 0) {
    foreach ($e in ($clears | Sort-Object TimeCreated -Descending | Select-Object -First 10)) {
        Write-Bad ("LOG CLEAR  {0:yyyy-MM-dd HH:mm:ss}  {1} ID={2}  {3}" -f $e.TimeCreated, $e.LogName, $e.Id, (Format-Clip $e.Message 100))
    }
} else {
    Write-Ok 'No log-clear events (1102/104)'
}

# ----- Live processes -----
Write-Section 'LIVE PROCESS CMDLINES'
$watch = @('powershell','pwsh','powershell_ise','wscript','cscript','mshta','rundll32','regsvr32','wmic','cmd')
try {
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $n = $_.Name.ToLowerInvariant(); $watch | Where-Object { $n -like "$_*" } }
    if (-not $procs) {
        Write-Ok 'No watched LOLBin processes right now'
    } else {
        $liveHits = 0
        foreach ($p in $procs) {
            $cmd = [string]$p.CommandLine
            if (Test-IsNoise $cmd) {
                Write-Ok ("PID={0} {1} :: launcher ignored" -f $p.ProcessId, $p.Name)
                continue
            }
            $matched = Test-SuspiciousText $cmd
            $line = "PID=$($p.ProcessId) $($p.Name) :: $(Format-Clip $cmd 120)"
            if ($matched.Count -gt 0) {
                $liveHits++
                Write-Bad ("LIVE [{0}] {1}" -f ($matched -join ','), $line)
            } else {
                Write-Ok $line
            }
        }
        if ($liveHits -eq 0) { Write-Ok 'No suspicious live cmdlines' }
    }
} catch {
    Write-Warn ("Process scan failed: {0}" -f $_.Exception.Message)
}

# ----- Event logs (skip 400/403/600 — engine lifecycle spam) -----
Write-Section 'EVENT LOGS'
$events = @()
try {
    $events += Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = 800 } -MaxEvents 80 -ErrorAction SilentlyContinue
} catch {}
try {
    $events += Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4103, 4104 } -MaxEvents 120 -ErrorAction SilentlyContinue
} catch {}

if (-not $events -or $events.Count -eq 0) {
    Write-Warn 'No PowerShell events (logging off / cleared / empty)'
} else {
    Write-Ok ("Events pulled: {0}" -f $events.Count)
    $shown = 0
    foreach ($e in ($events | Sort-Object TimeCreated -Descending)) {
        $msg = $e.Message
        if (Test-IsNoise $msg) { continue }
        $matched = @(Test-SuspiciousText $msg)
        # Tight wipe cmd only (no greedy .+ across whole scriptblock)
        if ($msg -match '(?i)Remove-Item\s+[^\r\n]{0,120}ConsoleHost_history') {
            $matched = @($matched + 'history-remove')
        }
        if ($matched.Count -eq 0) { continue }
        $shown++
        if ($shown -gt 20) { break }
        Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  ID={1}  [{2}]  {3}" -f `
            $e.TimeCreated, $e.Id, ($matched -join ','), (Format-Clip $msg 110))
    }
    if ($shown -eq 0) {
        Write-Ok 'No hits in event slice'
    }
}

# Security 4688
Write-Section 'SECURITY 4688'
try {
    $sec = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4688 } -MaxEvents 80 -ErrorAction SilentlyContinue
    if (-not $sec) {
        Write-Ok 'No 4688 (audit off / no access)'
    } else {
        $n = 0
        foreach ($e in $sec) {
            $msg = $e.Message
            if ($msg -notmatch 'powershell|pwsh|mshta|wscript|cscript|rundll32|regsvr32|wmic|wevtutil') { continue }
            $matched = @(Test-SuspiciousText $msg)
            if ($matched.Count -eq 0 -and $msg -match '(?i)wevtutil\s+cl') { $matched = @('wevtutil cl') }
            if ($matched.Count -eq 0 -and $msg -notmatch '(?i)-enc|EncodedCommand|FromBase64|DownloadString|wevtutil\s+cl') { continue }
            $n++
            if ($n -gt 20) { break }
            Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  4688  [{1}]  {2}" -f $e.TimeCreated, ($matched -join ','), (Format-Clip $msg 110))
        }
        if ($n -eq 0) { Write-Ok '4688 OK — no hot cmdlines' }
    }
} catch { Write-Ok 'Security log unread' }

# ----- Console history -----
Write-Section 'CONSOLE HISTORY'
$histPaths = @(
    (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'),
    (Join-Path $env:USERPROFILE 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
)
try {
    Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $histPaths += (Join-Path $_.FullName 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
    }
} catch {}

$histPaths = $histPaths | Select-Object -Unique
$anyHist = $false
$histNeedle = 0
foreach ($hp in $histPaths) {
    if (-not (Test-Path -LiteralPath $hp)) { continue }
    $anyHist = $true
    $fi = Get-Item -LiteralPath $hp -ErrorAction SilentlyContinue
    Write-Ok ("History present: {0}  ({1} bytes, mtime {2:yyyy-MM-dd HH:mm:ss})" -f $hp, $fi.Length, $fi.LastWriteTime)
    if ($fi.Length -eq 0) {
        Write-Bad ("History EMPTY (0 bytes) — likely wiped: {0}" -f $hp)
    }
    try {
        $lines = Get-Content -LiteralPath $hp -ErrorAction Stop -Tail 400
        foreach ($ln in $lines) {
            $matched = @(Test-SuspiciousText $ln)
            if ($matched.Count -gt 0) {
                $histNeedle++
                Write-Bad ("HIST [{0}] {1}" -f ($matched -join ','), (Format-Clip $ln 130))
            }
            if ($ln -match '(?i)#\s*password') {
                $histNeedle++
                Write-Bad 'HIST: # password'
            }
            if ($ln -match '(?i)(Remove-Item|del |erase |rm ).*ConsoleHost_history|Clear-History|wevtutil\s+cl') {
                $histNeedle++
                Write-Bad ("HIST WIPE CMD  {0}" -f (Format-Clip $ln 130))
            }
        }
    } catch {
        Write-Warn ("Cannot read history: {0}" -f $_.Exception.Message)
    }
}
if (-not $anyHist) {
    $usnHist = @($usn.Hits | Where-Object { $_.File -match '(?i)ConsoleHost_history' })
    if ($usnHist.Count -gt 0) {
        Write-Bad 'History missing + USN delete = wiped'
    } else {
        Write-Ok 'No ConsoleHost_history.txt'
    }
} elseif ($histNeedle -eq 0) {
    Write-Ok 'History clean'
}

# ----- Prefetch -----
Write-Section 'PREFETCH'
$pfDir = 'C:\Windows\Prefetch'
if (Test-Path $pfDir) {
    $names = @('POWERSHELL*.pf','PWSH*.pf','MSHTA*.pf','WSCRIPT*.pf','CSCRIPT*.pf','RUNDLL32*.pf','REGSVR32*.pf','WMIC*.pf')
    $found = 0
    foreach ($pat in $names) {
        Get-ChildItem $pfDir -Filter $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 2 | ForEach-Object {
            $found++
            Write-Ok ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $_.LastWriteTime, $_.Name)
        }
    }
    if ($found -eq 0) { Write-Ok 'No LOLBin Prefetch hits' }
} else {
    Write-Bad 'Prefetch folder missing / disabled'
}

Write-Section 'VERDICT'
Write-KV 'Hits' "$script:SusHits" $(if ($script:SusHits -gt 0){'Red'}else{'Green'})
Write-KV 'Warns' "$script:WarnHits" $(if ($script:WarnHits -gt 0){'Yellow'}else{'Green'})

if ($script:SusHits -ge 1) {
    Write-Bad ('Hits: {0} — смотри красные строки' -f $script:SusHits)
} else {
    Write-Ok 'Hits: 0'
}

if ($script:Hits.Count -gt 0) {
    Write-Section 'HITS'
    $script:Hits | Select-Object -First 20 | ForEach-Object { Write-Host ("  · {0}" -f $_) -ForegroundColor Red }
}

Write-BloodFoot -Subtitle $script:ToolName
