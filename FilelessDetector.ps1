#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Fileless — PS logs, USN wipe (since boot), Defender.
  by Schwarzahn
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Fileless'
$script:SusHits = 0
$script:WarnHits = 0
$script:Hits = New-Object System.Collections.Generic.List[string]
$script:DetectorBuild = 'v7-2026-08-09'

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
        ShadowFar  = "$esc[38;2;28;0;0m"
        ShadowNear = "$esc[38;2;70;0;0m"
        Mid        = "$esc[38;2;140;8;8m"
        Blood      = "$esc[38;2;190;12;12m"
        Hot        = "$esc[38;2;255;40;40m"
        Glow       = "$esc[38;2;255;110;95m"
        Ember      = "$esc[38;2;255;140;60m"
        Bone       = "$esc[38;2;220;210;195m"
        Ash        = "$esc[38;2;110;105;100m"
        Dim        = "$esc[38;2;70;70;70m"
        Soft       = "$esc[38;2;175;170;165m"
        Ok         = "$esc[38;2;70;190;110m"
        OkDim      = "$esc[38;2;40;120;70m"
        Warn       = "$esc[38;2;230;180;50m"
        Ice        = "$esc[38;2;120;170;190m"
        Reset      = "$esc[0m"
        Bold       = "$esc[1m"
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
    $grad = @($c.Glow, $c.Hot, $c.Blood, $c.Blood, $c.Mid, $c.ShadowNear)
    Write-Host ''
    foreach ($l in $art) { Write-Ansi ("   $($c.ShadowFar)$l$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    foreach ($l in $art) { Write-Ansi ("  $($c.ShadowNear)$l$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    for ($i = 0; $i -lt $art.Count; $i++) { Write-Ansi ("$($grad[$i])$($art[$i])$($c.Reset)`n") }
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 72))$($c.Reset)`n")
    $tag = "by $script:BrandName"
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Ember)$Subtitle$($c.Reset)  $($c.Ash)·$($c.Reset)  $($c.Ice)$script:DetectorBuild$($c.Reset)`n")
    Write-Host ''
}

function Write-BloodFoot {
    param([string]$Subtitle = 'Fileless')
    Enable-AnsiConsole; $c = Get-BloodPalette; $tag = "by $script:BrandName"
    Write-Host ''
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 64))$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Ember)$Subtitle$($c.Reset)`n")
    Write-Host ''
}

function Write-Section([string]$Text) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    $pad = [Math]::Max(4, 48 - $Text.Length)
    Write-Host ''
    Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Bold)$($c.Bone)$Text$($c.Reset) $($c.Dim)$('─' * $pad)$($c.Hot)·$($c.Reset)`n")
}

function Write-KV([string]$K, [string]$V, [string]$Tone = 'soft') {
    Enable-AnsiConsole; $c = Get-BloodPalette
    $vc = switch ($Tone) {
        'ok'   { $c.Ok }
        'bad'  { $c.Hot }
        'warn' { $c.Warn }
        'ice'  { $c.Ice }
        'hot'  { $c.Ember }
        default { $c.Bone }
    }
    Write-Ansi ("  $($c.Ash)$("{0,-28}" -f $K)$($c.Reset)$vc$V$($c.Reset)`n")
}

function Write-Ok([string]$t) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    Write-Ansi ("$($c.OkDim)[$($c.Ok)+$($c.OkDim)]$($c.Reset) $($c.Ok)$t$($c.Reset)`n")
}
function Write-Warn([string]$t) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    Write-Ansi ("$($c.Ash)[$($c.Warn)!$($c.Ash)]$($c.Reset) $($c.Warn)$t$($c.Reset)`n")
    $script:WarnHits++
}
function Write-Bad([string]$t) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    Write-Ansi ("$($c.Mid)[$($c.Hot)x$($c.Mid)]$($c.Reset) $($c.Hot)$t$($c.Reset)`n")
    $script:SusHits++
    if ($script:Hits.Count -lt 200) { [void]$script:Hits.Add($t) }
}
function Write-Info([string]$t) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    Write-Ansi ("$($c.Dim)[$($c.Ice)*$($c.Dim)]$($c.Reset) $($c.Soft)$t$($c.Reset)`n")
}

function Write-LoadBar {
    param(
        [string]$Label,
        [double]$Percent = -1,
        [string]$Detail = '',
        [switch]$Done
    )
    Enable-AnsiConsole; $c = Get-BloodPalette
    $w = 24
    if ($Percent -lt 0) {
        $tick = [Math]::Abs([int]([Diagnostics.Stopwatch]::GetTimestamp() / 150000)) % $w
        $bar = (('░' * $tick) + '▓' + ('░' * ($w - $tick - 1)))
        if ($bar.Length -gt $w) { $bar = $bar.Substring(0, $w) }
        $pctTxt = '···'
    } else {
        if ($Percent -gt 100) { $Percent = 100 }
        if ($Percent -lt 0) { $Percent = 0 }
        $fill = [int][Math]::Floor($w * ($Percent / 100.0))
        if ($fill -gt $w) { $fill = $w }
        $bar = ('█' * $fill) + ('░' * ($w - $fill))
        $pctTxt = '{0,3:N0}%' -f $Percent
    }
    $plain = ("{0,-10} {1} {2}  {3}" -f $Label, $bar, $pctTxt, $Detail)
    if ($plain.Length -lt 100) { $plain = $plain + (' ' * (100 - $plain.Length)) }
    else { $plain = $plain.Substring(0, 100) }
    Write-Ansi ("$esc[2K`r$($c.Ash)$("{0,-10}" -f $Label)$($c.Reset) $($c.Blood)$bar$($c.Reset) $($c.Ember)$pctTxt$($c.Reset)  $($c.Ice)$Detail$($c.Reset)")
    # wipe rest of line
    Write-Ansi ("$esc[K")
    if ($Done -or ($Percent -ge 100 -and $Percent -ge 0)) {
        Write-Host ''
    }
}

function Write-UsnProgress {
    param(
        [long]$Lines,
        [double]$Sec,
        [int]$WipeHits,
        [switch]$Done
    )
    $rate = 0
    if ($Sec -gt 0.15) { $rate = [int]($Lines / $Sec) }
    $linesTxt = if ($Lines -ge 1000000) { '{0:N2}M' -f ($Lines / 1000000.0) }
        elseif ($Lines -ge 1000) { '{0:N0}k' -f ($Lines / 1000.0) }
        else { "$Lines" }
    $pct = if ($Done) { 100 } else { [Math]::Min(99, [int](($Lines / 60000) % 100)) }
    $detail = ("{0} ln  {1}/s  hit={2}  {3:N0}s" -f $linesTxt, $rate, $WipeHits, $Sec)
    Write-LoadBar -Label 'USN' -Percent $pct -Detail $detail -Done:$Done
}

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-BootCutoff {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $boot = $os.LastBootUpTime
        if ($boot -is [DateTime]) { return $boot }
        return [Management.ManagementDateTimeConverter]::ToDateTime($boot)
    } catch {
        return (Get-Date).AddHours(-24)
    }
}

# Hard fileless / injector / wipe — alone = hit
$script:NeedleHard = @(
    'DownloadString', 'DownloadFile', 'DownloadData',
    'Net.WebClient', 'Start-BitsTransfer', 'bitsadmin ',
    '-EncodedCommand', ' -enc ', 'Assembly.Load', 'Load([byte',
    'VirtualAlloc', 'WriteProcessMemory', 'CreateRemoteThread', 'Marshal::Copy',
    'AmsiUtils', 'amsiInitFailed', 'amsiContext', 'AmsiScanBuffer',
    'System.Management.Automation.AmsiUtils', 'EtwEventWrite',
    'Set-MpPreference -DisableRealtimeMonitoring', 'DisableRealtimeMonitoring $true',
    'Add-MpPreference -ExclusionPath', 'Add-MpPreference -ExclusionProcess',
    'mshta http', 'mshta https', 'hta:application',
    'regsvr32 /s /n /u /i:', 'scrobj.dll',
    'wmic process call create',
    '# password', '#password',
    'ReflectiveLoader', 'reflective dll',
    'Clear-History', 'wevtutil cl', 'wevtutil clear-log', 'Clear-EventLog', 'Clear-WinEvent'
)

# Soft — only with a hard partner (FromBase64 alone = crypto noise)
$script:NeedleSoft = @('FromBase64String')

$script:WipeFileNames = @(
    'ConsoleHost_history.txt', 'ConsoleHost_history',
    'PowerShell_transcript', 'RecentFileCache.bcf',
    'Amcache.hve', 'SYSTEM.evtx', 'SECURITY.evtx',
    'PowerShell%4Operational.evtx', 'Windows PowerShell.evtx',
    'Microsoft-Windows-PowerShell%4Operational.evtx'
)

$script:IgnoreSubstrings = @(
    'Windows-ScreenShare-Tool', 'FilelessDetector', 'DoomsDayDetector', 'AdvancedArtifacts',
    'Service-Enabler', 'Schwarzahn', 'ScreenShare-Tool-by-Schwarzahn',
    'raw.githubusercontent.com/Schwarzahn',
    'Write-BloodBanner', 'Write-Bad', 'Write-Ok', 'Write-Warn', 'Write-Section', 'Write-LoadBar', 'Write-UsnProgress',
    'NeedleHard', 'NeedleSoft', 'IgnoreSubstrings', 'DetectorBuild', 'WipeFileNames', 'Get-UsnWipeHits'
)

function Test-IsNoise([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    if ($Text.IndexOf('__cmdletization', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Text.IndexOf('Microsoft.PowerShell.Cmdletization', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    # DPAPI / cert noise: Add-Type System.Security + FromBase64 without loader APIs
    if ($Text -match '(?i)Add-Type\s+-AssemblyName\s+System\.Security' -and
        $Text -notmatch '(?i)AmsiUtils|VirtualAlloc|WriteProcessMemory|Assembly\.Load|DownloadString|Invoke-Expression\s*\(|IEX\s*\(') {
        return $true
    }
    foreach ($x in $script:IgnoreSubstrings) {
        if ($Text.IndexOf($x, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
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

    $hard = New-Object System.Collections.Generic.List[string]
    foreach ($n in $script:NeedleHard) {
        if ($Text.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$hard.Add($n.Trim())
        }
    }
    $soft = @()
    foreach ($n in $script:NeedleSoft) {
        if ($Text.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $soft += $n.Trim()
        }
    }

    if ($hard.Count -gt 0) {
        foreach ($s in $soft) { [void]$hard.Add($s) }
        return @($hard | Select-Object -Unique)
    }
    # soft alone = ignore (FromBase64 crypto / DPAPI spam)
    return @()
}

function Format-Clip([string]$s, [int]$Max = 140) {
    if ($null -eq $s) { return '' }
    $one = ($s -replace '\s+', ' ').Trim()
    if ($one.Length -gt $Max) { return $one.Substring(0, $Max) + '...' }
    return $one
}

function Test-IsWipeReason([string]$Reason) {
    if ([string]::IsNullOrWhiteSpace($Reason)) { return $false }
    # IndexOf faster than regex on millions of USN reasons
    if ($Reason.IndexOf('File delete', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Reason.IndexOf('CLOSE+DELETE', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Reason.IndexOf('FILE_DELETE', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Reason.IndexOf('DATA_OVERWRITE', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Reason.IndexOf('Rename', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    if ($Reason.IndexOf('Security change', [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    return $false
}

function Test-IsWipeFileName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    $n = $Name.Trim()
    foreach ($w in $script:WipeFileNames) {
        if ($n.IndexOf($w, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    if ($n.EndsWith('.pf', [StringComparison]::OrdinalIgnoreCase)) {
        if ($n -match '(?i)POWERSHELL|PWSH|MSHTA|RUNDLL32|REGSVR32|WSCRIPT|CSCRIPT|WMIC|CMD\.EXE') { return $true }
    }
    return $false
}

function Get-UsnWipeHits {
    param(
        [string[]]$DriveLetters = @('C'),
        [DateTime]$Cutoff
    )
    $hits = New-Object System.Collections.Generic.List[object]
    $pfDeletes = 0

    foreach ($driveLetter in $DriveLetters) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $lines = [long]0
        $currentFile = ''
        $currentTime = $null
        $proc = $null
        try {
            Write-Info ("USN stream {0}: (live parse, no full dump into RAM)" -f $driveLetter)
            Write-UsnProgress -Lines 0 -Sec 0 -WipeHits 0

            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = 'fsutil.exe'
            $psi.Arguments = "usn readjournal ${driveLetter}:"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            [void]$proc.Start()
            $reader = $proc.StandardOutput
            $lastUi = [datetime]::MinValue

            while ($null -ne ($line = $reader.ReadLine())) {
                $lines++
                # UI ~8 Hz — don't redraw every line
                if (((Get-Date) - $lastUi).TotalMilliseconds -ge 120) {
                    $lastUi = Get-Date
                    Write-UsnProgress -Lines $lines -Sec $sw.Elapsed.TotalSeconds -WipeHits $hits.Count
                }

                if ([string]::IsNullOrWhiteSpace($line)) { continue }

                # Fast path: fsutil lines look like "File name    : xxx"
                $colon = $line.IndexOf(':')
                if ($colon -lt 1) { continue }
                $key = $line.Substring(0, $colon).Trim()
                $val = $line.Substring($colon + 1).Trim()

                if ($key.Equals('File name', [StringComparison]::OrdinalIgnoreCase)) {
                    $currentFile = $val
                } elseif ($key.Equals('Time stamp', [StringComparison]::OrdinalIgnoreCase)) {
                    try { $currentTime = [DateTime]::Parse($val) } catch { $currentTime = $null }
                } elseif ($key.Equals('Reason', [StringComparison]::OrdinalIgnoreCase)) {
                    if ($currentFile -and $currentTime -and $currentTime -ge $Cutoff -and (Test-IsWipeReason $val)) {
                        if (Test-IsWipeFileName $currentFile) {
                            [void]$hits.Add([pscustomobject]@{
                                Drive  = $driveLetter
                                File   = $currentFile
                                Time   = $currentTime
                                Reason = $val
                            })
                        } elseif ($currentFile.EndsWith('.pf', [StringComparison]::OrdinalIgnoreCase)) {
                            $pfDeletes++
                        }
                    }
                    $currentFile = ''
                    $currentTime = $null
                }
            }

            $proc.WaitForExit(120000) | Out-Null
            Write-UsnProgress -Lines $lines -Sec $sw.Elapsed.TotalSeconds -WipeHits $hits.Count -Done
            if ($lines -eq 0) {
                Write-Warn ("USN empty/unread on {0}:" -f $driveLetter)
            } else {
                Write-Ok ("USN done: {0:N0} lines in {1:N1}s" -f $lines, $sw.Elapsed.TotalSeconds)
            }
        } catch {
            Write-Host ''
            Write-Warn ("USN error {0}: {1}" -f $driveLetter, $_.Exception.Message)
        } finally {
            if ($proc -and -not $proc.HasExited) {
                try { $proc.Kill() } catch {}
            }
            if ($proc) { $proc.Dispose() }
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

$boot = Get-BootCutoff
$uptime = (Get-Date) - $boot
$uptimeTxt = '{0}d {1:hh\:mm\:ss}' -f [int]$uptime.TotalDays, $uptime

Write-Section 'SYSTEM'
Write-KV 'PC' $env:COMPUTERNAME 'ice'
Write-KV 'User' $env:USERNAME 'soft'
Write-KV 'Now' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 'soft'
Write-KV 'Boot' ($boot.ToString('yyyy-MM-dd HH:mm:ss')) 'hot'
Write-KV 'Uptime' $uptimeTxt 'ember'
Write-KV 'Build' $script:DetectorBuild 'ok'
Write-Info 'USN = stream since boot (bar = lines/s, not fake 1% dump wait)'

Write-Section 'POWERSHELL LOGGING'
$sbKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
$modKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging'
$transKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
try {
    $sb = Get-ItemProperty $sbKey -ErrorAction SilentlyContinue
    if ($sb -and $sb.EnableScriptBlockLogging -eq 1) { Write-Ok 'ScriptBlockLogging ON' }
    else { Write-Warn 'ScriptBlockLogging OFF' }
} catch { Write-Warn 'ScriptBlockLogging unreadable' }

try {
    $ml = Get-ItemProperty $modKey -ErrorAction SilentlyContinue
    if ($ml -and $ml.EnableModuleLogging -eq 1) { Write-Ok 'ModuleLogging ON' }
    else { Write-Ok 'ModuleLogging off' }
} catch {}

try {
    $tr = Get-ItemProperty $transKey -ErrorAction SilentlyContinue
    if ($tr -and $tr.EnableTranscripting -eq 1) { Write-Ok ("Transcription ON  {0}" -f $tr.OutputDirectory) }
    else { Write-Ok 'Transcription off' }
} catch {}

try {
    $ep = Get-ExecutionPolicy -List | Where-Object Scope -eq 'LocalMachine'
    Write-KV 'ExecutionPolicy LM' ("{0}" -f $ep.ExecutionPolicy) 'soft'
} catch {}

Write-Section 'DEFENDER / AMSI'
$amsiKey = 'HKLM:\SOFTWARE\Microsoft\AMSI\Providers'
if (Test-Path $amsiKey) {
    $prov = Get-ChildItem $amsiKey -ErrorAction SilentlyContinue
    if ($prov) {
        Write-Ok ("AMSI providers: {0}" -f $prov.Count)
        foreach ($p in $prov) { Write-Info ("provider {0}" -f $p.PSChildName) }
    } else { Write-Bad 'AMSI Providers empty' }
} else { Write-Bad 'AMSI Providers missing' }

try {
    $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($mp) {
        Write-KV 'RealTime' ("{0}" -f $mp.RealTimeProtectionEnabled) $(if ($mp.RealTimeProtectionEnabled) { 'ok' } else { 'bad' })
        Write-KV 'Antispyware' ("{0}" -f $mp.AntispywareEnabled) $(if ($mp.AntispywareEnabled) { 'ok' } else { 'bad' })
        if (-not $mp.RealTimeProtectionEnabled) { Write-Bad 'Defender RealTime OFF' }
        else { Write-Ok 'Defender RealTime ON' }
    } else { Write-Ok 'Defender status N/A' }
} catch { Write-Ok 'Defender unread' }

Write-Section 'USN WIPE'
$sysDrive = ($env:SystemDrive -replace ':', '')
if ([string]::IsNullOrWhiteSpace($sysDrive)) { $sysDrive = 'C' }
Write-KV 'Scan from' ($boot.ToString('yyyy-MM-dd HH:mm:ss')) 'hot'
Write-KV 'Drive' ("{0}:" -f $sysDrive) 'ice'
$usn = Get-UsnWipeHits -DriveLetters @($sysDrive) -Cutoff $boot
$wipeShown = 0
foreach ($h in ($usn.Hits | Sort-Object Time -Descending)) {
    $wipeShown++
    if ($wipeShown -gt 40) { break }
    Write-Bad ("USN  {0:yyyy-MM-dd HH:mm:ss}  {1}:\{2}  [{3}]" -f $h.Time, $h.Drive, $h.File, $h.Reason)
}
if ($usn.PrefetchDeleteCount -ge 8) {
    Write-Bad ("USN mass Prefetch .pf deletes = {0}" -f $usn.PrefetchDeleteCount)
} elseif ($usn.PrefetchDeleteCount -gt 0) {
    Write-Ok ("USN Prefetch .pf noise = {0}" -f $usn.PrefetchDeleteCount)
}
if ($wipeShown -eq 0 -and $usn.PrefetchDeleteCount -lt 8) {
    Write-Ok 'No wipe-target USN deletes since boot (in journal)'
}

Write-Section 'LOG CLEARS'
$clears = @()
try { $clears += Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 1102 } -MaxEvents 20 -ErrorAction SilentlyContinue } catch {}
try { $clears += Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 104 } -MaxEvents 20 -ErrorAction SilentlyContinue } catch {}
if ($clears -and $clears.Count -gt 0) {
    foreach ($e in ($clears | Sort-Object TimeCreated -Descending | Select-Object -First 12)) {
        Write-Bad ("CLEAR  {0:yyyy-MM-dd HH:mm:ss}  {1} ID={2}  {3}" -f $e.TimeCreated, $e.LogName, $e.Id, (Format-Clip $e.Message 90))
    }
} else { Write-Ok 'No 1102/104 clears' }

Write-Section 'LIVE PROCESSES'
$watch = @('powershell', 'pwsh', 'powershell_ise', 'wscript', 'cscript', 'mshta', 'rundll32', 'regsvr32', 'wmic', 'cmd')
try {
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $n = $_.Name.ToLowerInvariant(); $watch | Where-Object { $n -like "$_*" } }
    if (-not $procs) {
        Write-Ok 'No watched LOLBins'
    } else {
        $liveHits = 0
        foreach ($p in $procs) {
            $cmd = [string]$p.CommandLine
            if (Test-IsNoise $cmd) {
                Write-Ok ("PID={0} {1} :: launcher ignored" -f $p.ProcessId, $p.Name)
                continue
            }
            $matched = Test-SuspiciousText $cmd
            $line = "PID=$($p.ProcessId) $($p.Name) :: $(Format-Clip $cmd 110)"
            if ($matched.Count -gt 0) {
                $liveHits++
                Write-Bad ("LIVE [{0}] {1}" -f ($matched -join ','), $line)
            } else {
                Write-Ok $line
            }
        }
        if ($liveHits -eq 0) { Write-Ok 'No suspicious live cmdlines' }
    }
} catch { Write-Warn ("Process scan failed: {0}" -f $_.Exception.Message) }

Write-Section 'EVENT LOGS'
$events = @()
Write-LoadBar -Label 'Events' -Percent 15 -Detail 'WinPS 800...'
try { $events += Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = 800 } -MaxEvents 100 -ErrorAction SilentlyContinue } catch {}
Write-LoadBar -Label 'Events' -Percent 60 -Detail 'Operational...'
try { $events += Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4103, 4104 } -MaxEvents 150 -ErrorAction SilentlyContinue } catch {}
Write-LoadBar -Label 'Events' -Percent 100 -Detail ("{0} pulled" -f @($events).Count) -Done

if (-not $events -or $events.Count -eq 0) {
    Write-Warn 'No PowerShell events'
} else {
    Write-Ok ("Events: {0}" -f $events.Count)
    $shown = 0
    $ei = 0
    $et = $events.Count
    $lastNeedleUi = [datetime]::MinValue
    foreach ($e in ($events | Sort-Object TimeCreated -Descending)) {
        $ei++
        if ($ei -eq $et -or (($ei % 20 -eq 0) -and ((Get-Date) - $lastNeedleUi).TotalMilliseconds -ge 100)) {
            $lastNeedleUi = Get-Date
            Write-LoadBar -Label 'Scan' -Percent (($ei * 100.0) / $et) -Detail ("{0}/{1}" -f $ei, $et) -Done:($ei -eq $et)
        }
        $msg = $e.Message
        if (Test-IsNoise $msg) { continue }
        $matched = @(Test-SuspiciousText $msg)
        if ($msg -match '(?i)Remove-Item\s+[^\r\n]{0,120}ConsoleHost_history') {
            $matched = @($matched + 'history-remove')
        }
        if ($matched.Count -eq 0) { continue }
        # clear progress line before red hit so lines don't merge
        Write-Ansi ("$esc[2K`r")
        $shown++
        if ($shown -gt 20) { break }
        Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  ID={1}  [{2}]  {3}" -f `
            $e.TimeCreated, $e.Id, ($matched -join ','), (Format-Clip $msg 100))
    }
    if ($shown -eq 0) { Write-Ok 'No event hits' }
}

Write-Section 'SECURITY 4688'
try {
    $sec = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4688 } -MaxEvents 100 -ErrorAction SilentlyContinue
    if (-not $sec) {
        Write-Ok 'No 4688'
    } else {
        $n = 0
        foreach ($e in $sec) {
            $msg = $e.Message
            if ($msg -notmatch 'powershell|pwsh|mshta|wscript|cscript|rundll32|regsvr32|wmic|wevtutil') { continue }
            $matched = @(Test-SuspiciousText $msg)
            if ($matched.Count -eq 0 -and $msg -match '(?i)wevtutil\s+cl') { $matched = @('wevtutil cl') }
            if ($matched.Count -eq 0 -and $msg -notmatch '(?i)-enc|EncodedCommand|DownloadString|wevtutil\s+cl|AmsiUtils|VirtualAlloc') { continue }
            $n++
            if ($n -gt 15) { break }
            Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  4688  [{1}]  {2}" -f $e.TimeCreated, ($matched -join ','), (Format-Clip $msg 100))
        }
        if ($n -eq 0) { Write-Ok '4688 clean' }
    }
} catch { Write-Ok 'Security unread' }

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
    Write-Ok ("History: {0}  ({1}b, {2:yyyy-MM-dd HH:mm})" -f $hp, $fi.Length, $fi.LastWriteTime)
    if ($fi.Length -eq 0) { Write-Bad ("History EMPTY: {0}" -f $hp) }
    try {
        $lines = Get-Content -LiteralPath $hp -ErrorAction Stop -Tail 400
        foreach ($ln in $lines) {
            $matched = @(Test-SuspiciousText $ln)
            if ($matched.Count -gt 0) {
                $histNeedle++
                Write-Bad ("HIST [{0}] {1}" -f ($matched -join ','), (Format-Clip $ln 120))
            }
            if ($ln -match '(?i)#\s*password') {
                $histNeedle++
                Write-Bad 'HIST: # password'
            }
            if ($ln -match '(?i)(Remove-Item|del |erase |rm ).*ConsoleHost_history|Clear-History|wevtutil\s+cl') {
                $histNeedle++
                Write-Bad ("HIST WIPE  {0}" -f (Format-Clip $ln 120))
            }
        }
    } catch { Write-Warn ("History read fail: {0}" -f $_.Exception.Message) }
}
if (-not $anyHist) {
    $usnHist = @($usn.Hits | Where-Object { $_.File -match '(?i)ConsoleHost_history' })
    if ($usnHist.Count -gt 0) { Write-Bad 'History missing + USN delete = wiped' }
    else { Write-Ok 'No ConsoleHost_history.txt' }
} elseif ($histNeedle -eq 0) {
    Write-Ok 'History clean'
}

Write-Section 'PREFETCH'
$pfDir = 'C:\Windows\Prefetch'
if (Test-Path $pfDir) {
    $names = @('POWERSHELL*.pf', 'PWSH*.pf', 'MSHTA*.pf', 'WSCRIPT*.pf', 'CSCRIPT*.pf', 'RUNDLL32*.pf', 'REGSVR32*.pf', 'WMIC*.pf')
    $found = 0
    foreach ($pat in $names) {
        Get-ChildItem $pfDir -Filter $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 2 | ForEach-Object {
            $found++
            Write-Ok ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $_.LastWriteTime, $_.Name)
        }
    }
    if ($found -eq 0) { Write-Ok 'No LOLBin Prefetch' }
} else {
    Write-Bad 'Prefetch missing'
}

Write-Section 'VERDICT'
Write-KV 'Hits' "$script:SusHits" $(if ($script:SusHits -gt 0) { 'bad' } else { 'ok' })
Write-KV 'Warns' "$script:WarnHits" $(if ($script:WarnHits -gt 0) { 'warn' } else { 'ok' })
Write-KV 'USN from' ($boot.ToString('yyyy-MM-dd HH:mm')) 'ice'

if ($script:SusHits -ge 1) {
    Write-Bad ("Hits: {0}" -f $script:SusHits)
} else {
    Write-Ok 'Hits: 0'
}

if ($script:Hits.Count -gt 0) {
    Write-Section 'HITS'
    $script:Hits | Select-Object -First 20 | ForEach-Object {
        Enable-AnsiConsole; $c = Get-BloodPalette
        Write-Ansi ("  $($c.Mid)·$($c.Reset) $($c.Glow)$_$($c.Reset)`n")
    }
}

Write-BloodFoot -Subtitle $script:ToolName
