#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Windows ScreenShare Tool — Fileless + AMSI-bypass detector
  by Schwarzahn

  Detects (does NOT bypass):
  - PowerShell / WMI / mshta / rundll32 suspicious cmdlines
  - Event log hits (Windows PowerShell + Operational)
  - ScriptBlock / Module logging state
  - AMSI provider / policy hints
  - ConsoleHost_history patterns
  - "# password" style log-suppression trick awareness

  RAM dump still needed for some bypasses that wipe Event Viewer.
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Fileless / Bypass Detector'
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
    param([string]$Subtitle = 'Fileless detector')
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
    param([string]$Subtitle = 'Fileless detector')
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
function Write-Ok([string]$t){ Write-Host "[+] $t" -ForegroundColor Green }
function Write-Warn([string]$t){ Write-Host "[!] $t" -ForegroundColor Yellow; $script:WarnHits++ }
function Write-Bad([string]$t){
    Write-Host "[x] $t" -ForegroundColor Red
    $script:SusHits++
    if ($script:Hits.Count -lt 200) { [void]$script:Hits.Add($t) }
}
function Write-Info([string]$t){ Write-Host "[*] $t" -ForegroundColor DarkGray }

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Detector build — bump so you can see cache bust worked
$script:DetectorBuild = 'v3-2026-08-09'

# REAL fileless / injector signals (short junk like "etw"/"bypass" intentionally absent)
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
    'powershell -w hidden','-WindowStyle Hidden',
    '# password','#password',
    'ReflectiveLoader','reflective dll'
)

# Self / SS / this script's 4104 dump (needle arrays live in the script text)
$script:IgnoreSubstrings = @(
    'Windows-ScreenShare-Tool','FilelessDetector','DoomsDayDetector','AdvancedArtifacts',
    'Service-Enabler','Schwarzahn','ScreenShare-Tool-by-Schwarzahn',
    'raw.githubusercontent.com/Schwarzahn',
    'Fileless / Bypass Detector','Fileless + AMSI',
    'NeedleStrong','NeedleWeak','IgnoreSubstrings','DetectorBuild'
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
Write-KV 'Build' $script:DetectorBuild 'Cyan'
Write-Info 'Fileless = mostly RAM. Disk logs help; wiped logs → RAM dump.'
Write-Info 'Ignores: SS irm|iex launcher, own 4104 dump, Defender __cmdletization noise.'
Write-Info 'If Build missing/old → GitHub CDN cache; re-run with ?cb=rand on the URL.'

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
        Write-Warn 'ScriptBlockLogging OFF/missing — weaker fileless visibility'
    }
} catch { Write-Warn 'Cannot read ScriptBlockLogging policy' }

try {
    $ml = Get-ItemProperty $modKey -ErrorAction SilentlyContinue
    if ($ml -and $ml.EnableModuleLogging -eq 1) { Write-Ok 'ModuleLogging = ON' }
    else { Write-Info 'ModuleLogging off (optional)' }
} catch {}

try {
    $tr = Get-ItemProperty $transKey -ErrorAction SilentlyContinue
    if ($tr -and $tr.EnableTranscripting -eq 1) {
        Write-Ok ("Transcription ON  dir={0}" -f $tr.OutputDirectory)
    } else { Write-Info 'Transcription off' }
} catch {}

# Execution policy (informational)
try {
    $ep = Get-ExecutionPolicy -List | Where-Object Scope -eq 'LocalMachine'
    Write-KV 'ExecutionPolicy (LM)' ("{0}" -f $ep.ExecutionPolicy)
} catch {}

# ----- AMSI providers -----
Write-Section 'AMSI / DEFENDER SURFACE'
$amsiKey = 'HKLM:\SOFTWARE\Microsoft\AMSI\Providers'
if (Test-Path $amsiKey) {
    $prov = Get-ChildItem $amsiKey -ErrorAction SilentlyContinue
    if ($prov) {
        Write-Ok ("AMSI providers registered: {0}" -f $prov.Count)
        foreach ($p in $prov) { Write-Info $p.PSChildName }
    } else {
        Write-Warn 'AMSI Providers key empty'
    }
} else {
    Write-Warn 'AMSI Providers key missing'
}

try {
    $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($mp) {
        Write-KV 'Defender RealTime' ("{0}" -f $mp.RealTimeProtectionEnabled) $(if ($mp.RealTimeProtectionEnabled){'Green'}else{'Red'})
        Write-KV 'AMSI / Antispyware' ("{0}" -f $mp.AntispywareEnabled)
        if (-not $mp.RealTimeProtectionEnabled) { Write-Bad 'Defender RealTime OFF — common pre-fileless step' }
    } else {
        Write-Info 'Get-MpComputerStatus unavailable (no Defender / third-party AV)'
    }
} catch { Write-Info 'Defender status unreadable' }

# ----- Live processes -----
Write-Section 'LIVE PROCESS CMDLINES'
$watch = @('powershell','pwsh','powershell_ise','wscript','cscript','mshta','rundll32','regsvr32','wmic','cmd')
try {
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $n = $_.Name.ToLowerInvariant(); $watch | Where-Object { $n -like "$_*" } }
    if (-not $procs) {
        Write-Info 'No watched LOLBin processes right now'
    } else {
        foreach ($p in $procs) {
            $cmd = [string]$p.CommandLine
            if (Test-IsNoise $cmd) {
                Write-Info ("PID={0} {1} :: (SS/launcher — ignored)" -f $p.ProcessId, $p.Name)
                continue
            }
            $matched = Test-SuspiciousText $cmd
            $line = "PID=$($p.ProcessId) $($p.Name) :: $(Format-Clip $cmd 120)"
            if ($matched.Count -gt 0) {
                Write-Bad ("LIVE [{0}] {1}" -f ($matched -join ','), $line)
            } else {
                Write-Info $line
            }
        }
    }
} catch {
    Write-Warn ("Process scan failed: {0}" -f $_.Exception.Message)
}

# ----- Event logs -----
Write-Section 'EVENT LOGS (PowerShell)'
Write-Info 'IDs: 400/403/600/800 (Windows PowerShell) + 4103/4104 (Operational ScriptBlock)'
$events = @()
try {
    $events += Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = 400, 403, 600, 800 } -MaxEvents 120 -ErrorAction SilentlyContinue
} catch {}
try {
    $events += Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4103, 4104, 4105, 4106 } -MaxEvents 150 -ErrorAction SilentlyContinue
} catch {}

if (-not $events -or $events.Count -eq 0) {
    Write-Warn 'No PowerShell events — logging disabled, cleared, or no activity'
} else {
    Write-Ok ("Pulled {0} events (recent slice)" -f $events.Count)
    $shown = 0
    foreach ($e in ($events | Sort-Object TimeCreated -Descending)) {
        $msg = $e.Message
        $matched = Test-SuspiciousText $msg
        if ($matched.Count -eq 0) { continue }
        $shown++
        if ($shown -gt 40) { break }
        Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  {1} ID={2}  [{3}]  {4}" -f `
            $e.TimeCreated, $e.LogName, $e.Id, ($matched -join ','), (Format-Clip $msg 110))
    }
    if ($shown -eq 0) {
        Write-Ok 'Events present but no needle matches in this slice'
    }
}

# Security 4688 if available (process creation)
Write-Section 'SECURITY 4688 (process create)'
try {
    $sec = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4688 } -MaxEvents 80 -ErrorAction SilentlyContinue
    if (-not $sec) {
        Write-Info 'No 4688 (audit process creation off / no access)'
    } else {
        $n = 0
        foreach ($e in $sec) {
            $msg = $e.Message
            if ($msg -notmatch 'powershell|pwsh|mshta|wscript|cscript|rundll32|regsvr32|wmic') { continue }
            $matched = Test-SuspiciousText $msg
            if ($matched.Count -eq 0 -and $msg -notmatch '-enc|EncodedCommand|FromBase64|IEX|DownloadString') { continue }
            $n++
            if ($n -gt 25) { break }
            Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  4688  [{1}]  {2}" -f $e.TimeCreated, ($matched -join ','), (Format-Clip $msg 110))
        }
        if ($n -eq 0) { Write-Info '4688 present; no hot powershell/LOLBin cmdlines in slice' }
    }
} catch { Write-Info 'Security log unread (need audit policy)' }

# ----- Console history -----
Write-Section 'POWERSHELL CONSOLE HISTORY'
$histPaths = @(
    (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'),
    (Join-Path $env:USERPROFILE 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
)
# also other users if admin
try {
    Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $histPaths += (Join-Path $_.FullName 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
    }
} catch {}

$histPaths = $histPaths | Select-Object -Unique
$anyHist = $false
foreach ($hp in $histPaths) {
    if (-not (Test-Path -LiteralPath $hp)) { continue }
    $anyHist = $true
    Write-Ok ("History: {0}" -f $hp)
    try {
        $lines = Get-Content -LiteralPath $hp -ErrorAction Stop -Tail 400
        foreach ($ln in $lines) {
            $matched = Test-SuspiciousText $ln
            if ($matched.Count -gt 0) {
                Write-Bad ("HIST [{0}] {1}" -f ($matched -join ','), (Format-Clip $ln 130))
            }
            if ($ln -match '(?i)#\s*password') {
                Write-Bad 'HIST: "# password" pattern — may suppress console/event logging'
            }
        }
    } catch {
        Write-Warn ("Cannot read history: {0}" -f $_.Exception.Message)
    }
}
if (-not $anyHist) {
    Write-Warn 'No ConsoleHost_history.txt found (cleared / never used / other profile)'
}

# ----- Prefetch for LOLBins (execution corroboration) -----
Write-Section 'PREFETCH LOLBIN TRACE'
$pfDir = 'C:\Windows\Prefetch'
if (Test-Path $pfDir) {
    $names = @('POWERSHELL*.pf','PWSH*.pf','MSHTA*.pf','WSCRIPT*.pf','CSCRIPT*.pf','RUNDLL32*.pf','REGSVR32*.pf','WMIC*.pf')
    $found = $false
    foreach ($pat in $names) {
        Get-ChildItem $pfDir -Filter $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3 | ForEach-Object {
            $found = $true
            Write-Info ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $_.LastWriteTime, $_.Name)
        }
    }
    if (-not $found) { Write-Info 'No LOLBin Prefetch in top hits (or Prefetch off)' }
} else {
    Write-Warn 'Prefetch folder missing / disabled'
}

# ----- Guidance -----
Write-Section 'IF LOGS EMPTY / WIPED'
Write-Info 'Password-in-cmdline bypass & some AMSI tricks leave little in Event Viewer'
Write-Info 'Next: RAM dump (FTK) or Kernel live dump → Spokwn KernelLiveDumpTool'
Write-Info 'Orbdiff Fileless: https://github.com/Orbdiff/Fileless'
Write-Info 'Also run: AdvancedArtifacts.ps1  +  Services.ps1'

Write-Section 'VERDICT'
Write-KV 'Suspicious hits' "$script:SusHits" $(if ($script:SusHits -gt 0){'Red'}else{'Green'})
Write-KV 'Warnings' "$script:WarnHits" $(if ($script:WarnHits -gt 0){'Yellow'}else{'Green'})

if ($script:SusHits -ge 5) {
    Write-Bad 'Strong fileless / bypass signals — correlate timestamps with freeze / Doomsday window'
} elseif ($script:SusHits -ge 1) {
    Write-Warn 'Some signals — confirm with Prefetch/BAM/SRUM + RAM if needed'
} else {
    Write-Ok 'No hot automated hits in this pass — does NOT clear advanced RAM-only loaders'
    Write-Info 'Clean logs ≠ clean box when ScriptBlockLogging was off or history wiped'
}

if ($script:Hits.Count -gt 0) {
    Write-Section 'HIT SUMMARY (first lines)'
    $script:Hits | Select-Object -First 15 | ForEach-Object { Write-Host ("  · {0}" -f $_) -ForegroundColor DarkRed }
}

Write-BloodFoot -Subtitle $script:ToolName
