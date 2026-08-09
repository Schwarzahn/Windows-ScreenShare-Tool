#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Windows ScreenShare Tool — Advanced artifacts quick check
  RecentFileCache.bcf / SRUM / AppCompatCache / PowerShell fileless hints
  by Schwarzahn

  Does NOT auto-dump RAM/Kernel (heavy, BSOD risk). Prints ready commands.
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Windows ScreenShare Tool / Advanced'

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
        Dim="$esc[38;2;85;85;85m"; Soft="$esc[38;2;170;170;170m"; Green="$esc[38;2;80;220;120m"
        Reset="$esc[0m"; Bold="$esc[1m"
    }
    return $script:BloodPalette
}
function Write-BloodBanner {
    param([string]$Subtitle = 'Advanced artifacts')
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
    param([string]$Subtitle = 'Advanced artifacts')
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
    Write-Host ("  {0,-28}" -f $K) -NoNewline -ForegroundColor DarkGray
    Write-Host $V -ForegroundColor $Color
}
function Write-Ok([string]$t){ Write-Host "[+] $t" -ForegroundColor Green }
function Write-Warn([string]$t){ Write-Host "[!] $t" -ForegroundColor Yellow }
function Write-Bad([string]$t){ Write-Host "[x] $t" -ForegroundColor Red }
function Write-Info([string]$t){ Write-Host "[*] $t" -ForegroundColor DarkGray }

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FileMeta([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $i = Get-Item -LiteralPath $Path -Force
    [pscustomobject]@{
        Path = $i.FullName
        Size = $i.Length
        Created = $i.CreationTime
        Modified = $i.LastWriteTime
        Accessed = $i.LastAccessTime
    }
}

function Find-Tool([string]$Name) {
    $candidates = @(
        (Join-Path $PSScriptRoot $Name),
        (Join-Path $env:USERPROFILE "Desktop\$Name"),
        (Join-Path $env:USERPROFILE "Downloads\$Name"),
        (Join-Path $env:TEMP $Name),
        (Join-Path 'C:\Tools' $Name),
        (Join-Path 'C:\SS' $Name)
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return (Resolve-Path $c).Path }
    }
    $hit = Get-ChildItem -Path @($env:USERPROFILE,'C:\') -Filter $Name -Recurse -ErrorAction SilentlyContinue -Depth 4 |
        Select-Object -First 1
    if ($hit) { return $hit.FullName }
    return $null
}

$script:SusHits = 0
$script:WarnHits = 0

function Test-SusPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $p = $Path.ToLowerInvariant()
    $needles = @(
        'xclicker','autoclick','clicker','jnativehook','inject','loader','cheat',
        'wurst','meteor','impact','aristois','liquidbounce','ghostclient',
        'temp\','appdata\local\temp','downloads\'
    )
    foreach ($n in $needles) { if ($p -like "*$n*") { return $true } }
    return $false
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
Write-Info 'UTC note: SRUM CSV times are UTC — convert for freeze timeline'

# ----- RecentFileCache.bcf -----
Write-Section 'RECENTFILECACHE.BCF'
$rfc = 'C:\Windows\AppCompat\Programs\RecentFileCache.bcf'
$amc = 'C:\Windows\AppCompat\Programs\Amcache.hve'
$meta = Get-FileMeta $rfc
if ($meta) {
    Write-Ok ("Present  size={0:N0} bytes" -f $meta.Size)
    Write-KV 'Modified' ($meta.Modified.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-KV 'Created'  ($meta.Created.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Info 'FIFO short-term execution cache — corroborates Prefetch/BAM'
} else {
    Write-Bad 'RecentFileCache.bcf MISSING'
    $script:SusHits++
}
$am = Get-FileMeta $amc
if ($am) {
    Write-KV 'Amcache.hve' ("present  mtime={0:yyyy-MM-dd HH:mm:ss}" -f $am.Modified) Green
} else {
    Write-Warn 'Amcache.hve missing'
    $script:WarnHits++
}

$rfcParser = Find-Tool 'RecentFileCacheParser.exe'
if ($rfcParser -and $meta) {
    Write-Ok "Parser found: $rfcParser"
    $outDir = Join-Path $env:TEMP ("RFC_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    Write-Info "Parsing to $outDir ..."
    try {
        & $rfcParser -f $rfc --csv $outDir 2>&1 | Out-Host
        $csv = Get-ChildItem $outDir -Filter *.csv -ErrorAction SilentlyContinue | Select-Object -First 3
        foreach ($f in $csv) {
            Write-Ok ("CSV: {0}" -f $f.FullName)
            Import-Csv $f.FullName -ErrorAction SilentlyContinue | Select-Object -First 40 | ForEach-Object {
                $line = ($_ | Out-String)
                $pathProp = $_.PSObject.Properties | Where-Object { $_.Name -match 'path|executable|file' } | Select-Object -First 1
                $val = if ($pathProp) { [string]$pathProp.Value } else { $line }
                if (Test-SusPath $val) {
                    Write-Bad ("RFC HIT: {0}" -f $val)
                    $script:SusHits++
                }
            }
        }
        if (-not $csv) { Write-Warn 'Parser ran but no CSV found' }
    } catch {
        Write-Warn ("Parser error: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Warn 'RecentFileCacheParser.exe not found nearby'
    Write-Info 'Download: https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip'
    Write-Host '  RecentFileCacheParser.exe -f "C:\Windows\AppCompat\Programs\RecentFileCache.bcf" --csv .' -ForegroundColor DarkGray
}

# ----- SRUM -----
Write-Section 'SRUM (SRUDB.dat)'
$dps = Get-Service DPS -ErrorAction SilentlyContinue
if ($dps) {
    if ($dps.Status -eq 'Running') {
        Write-Ok ("DPS = Running (SRUM can update) StartType={0}" -f $dps.StartType)
    } else {
        Write-Bad ("DPS = {0} — SRUM may be dead/stale" -f $dps.Status)
        $script:SusHits++
        Write-Info 'Enable via Service-Enabler.ps1 / set DPS Automatic+Start'
    }
} else {
    Write-Warn 'DPS service not found'
}

$sru = 'C:\Windows\System32\sru\SRUDB.dat'
$sruMeta = Get-FileMeta $sru
if ($sruMeta) {
    Write-Ok ("SRUDB.dat present  size={0:N1} MB" -f ($sruMeta.Size/1MB))
    Write-KV 'Modified' ($sruMeta.Modified.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Info 'History often ~30-60 days; AppTimelineProvider_Output = proof-of-execution (UTC)'
} else {
    Write-Bad 'SRUDB.dat MISSING (optimized Windows / DPS off / wiped?)'
    $script:SusHits++
}

$srum = Find-Tool 'SrumECmd.exe'
if ($srum -and $sruMeta) {
    Write-Ok "SrumECmd found: $srum"
    $outDir = Join-Path $env:TEMP ("SRUM_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    Write-Info "Parsing SRUM (can take a bit) -> $outDir"
    try {
        & $srum -f $sru --csv $outDir 2>&1 | Out-Host
        $appTl = Get-ChildItem $outDir -Filter '*AppTimeline*' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($appTl) {
            Write-Ok ("Focus CSV: {0}" -f $appTl.FullName)
            Write-Info 'Open in Timeline Explorer / Excel — correlate UTC with freeze'
        } else {
            Write-Warn 'No AppTimeline* CSV — check other outputs in folder'
            Get-ChildItem $outDir -Filter *.csv | Select-Object -First 10 Name | ForEach-Object { Write-Info $_.Name }
        }
    } catch {
        Write-Warn ("SrumECmd error: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Warn 'SrumECmd.exe not found'
    Write-Info 'Tools index: https://ericzimmerman.github.io/#!index.md'
    Write-Host '  SrumECmd.exe -f "C:\Windows\System32\sru\SRUDB.dat" --csv .' -ForegroundColor DarkGray
}

# ----- AppCompatCache / Shimcache -----
Write-Section 'APPCOMPATCACHE (Shimcache)'
$accPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache'
if (Test-Path $accPath) {
    try {
        $prop = Get-ItemProperty $accPath -ErrorAction Stop
        $blob = $prop.AppCompatCache
        if ($blob) {
            Write-Ok ("AppCompatCache value present  bytes={0:N0}" -f $blob.Length)
            Write-Info 'Updates often on reboot — complementary to Prefetch/BAM'
        } else {
            Write-Warn 'Key exists but AppCompatCache value empty'
            $script:WarnHits++
        }
    } catch {
        Write-Warn 'Cannot read AppCompatCache value'
    }
} else {
    Write-Bad 'AppCompatCache key missing'
    $script:SusHits++
}

$accParser = Find-Tool 'AppCompatCacheParser.exe'
if ($accParser) {
    Write-Ok "Parser found: $accParser"
    $outDir = Join-Path $env:TEMP ("ACC_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    try {
        & $accParser --csv $outDir 2>&1 | Out-Host
        $csv = Get-ChildItem $outDir -Filter *.csv | Select-Object -First 1
        if ($csv) {
            Write-Ok ("CSV: {0}" -f $csv.FullName)
            Import-Csv $csv.FullName -ErrorAction SilentlyContinue | Select-Object -First 50 | ForEach-Object {
                $pathProp = $_.PSObject.Properties | Where-Object { $_.Name -match 'path|file|executable' } | Select-Object -First 1
                if ($pathProp -and (Test-SusPath ([string]$pathProp.Value))) {
                    Write-Bad ("SHIM HIT: {0}" -f $pathProp.Value)
                    $script:SusHits++
                }
            }
        }
    } catch {
        Write-Warn ("AppCompatCacheParser error: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Warn 'AppCompatCacheParser.exe not found'
    Write-Host '  AppCompatCacheParser.exe --csv .' -ForegroundColor DarkGray
}

# ----- PowerShell fileless hints -----
Write-Section 'FILELESS HINTS (Event Viewer / PowerShell)'
Write-Info 'IDs of interest: 400, 403, 600, 800 (+ Operational script block if enabled)'
Write-Info 'Password-in-cmdline bypass may hide from console history / some logs — RAM dump then'
$ids = 400, 403, 600, 800
$psEvents = @()
try {
    $psEvents += Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = $ids } -MaxEvents 80 -ErrorAction SilentlyContinue
} catch {}
try {
    $psEvents += Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4103, 4104, 4105, 4106 } -MaxEvents 80 -ErrorAction SilentlyContinue
} catch {}

if (-not $psEvents -or $psEvents.Count -eq 0) {
    Write-Warn 'No PowerShell events returned (logging disabled / cleared / no access)'
    $script:WarnHits++
} else {
    Write-Ok ("Pulled {0} PowerShell-related events (recent slice)" -f $psEvents.Count)
    $needles = 'FromBase64String','IEX','Invoke-Expression','DownloadString','DownloadFile','Net.WebClient','bitstransfer','-enc ','-EncodedCommand','Reflection.Assembly','VirtualAlloc','AmsiUtils','bypass'
    foreach ($e in ($psEvents | Sort-Object TimeCreated -Descending | Select-Object -First 60)) {
        $msg = $e.Message
        if (-not $msg) { continue }
        $hit = $false
        foreach ($n in $needles) {
            if ($msg -like "*$n*") { $hit = $true; break }
        }
        if ($hit) {
            $one = (($msg -split "`n")[0])
            if ($one.Length -gt 110) { $one = $one.Substring(0,110) + '...' }
            Write-Bad ("{0:yyyy-MM-dd HH:mm:ss}  Log={1} ID={2}  {3}" -f $e.TimeCreated, $e.LogName, $e.Id, $one)
            $script:SusHits++
        }
    }
}
Write-Info 'Manual: eventvwr -> Application and Services Logs -> Windows PowerShell'
Write-Info 'Orbdiff Fileless tool: https://github.com/Orbdiff/Fileless'

# ----- Dump guidance (no auto dump) -----
Write-Section 'RAM / KERNEL DUMP (manual — not auto)'
Write-Warn 'Do NOT auto-dump here (CPU/RAM heavy, BSOD risk on weak PCs)'
Write-Info 'RAM: FTK Imager -> File -> Capture Memory -> .mem'
Write-Info 'Analyze: Spokwn KernelLiveDumpTool (answer n for default filters)'
Write-Info '  https://github.com/spokwn/kernellivedumptool/releases'
Write-Info 'Kernel: System Informer (admin) -> System PID4 -> Create live dump -> Full'
Write-Info 'Put .dmp next to KernelLiveDumpTool, run admin, n, check Results\*.txt'
Write-Warn 'RAM/Kernel hits alone usually do NOT confirm instance (volatile / browse residue)'

Write-Section 'QUICK COMMANDS'
Write-Host '  RecentFileCacheParser.exe -f "C:\Windows\AppCompat\Programs\RecentFileCache.bcf" --csv .' -ForegroundColor DarkGray
Write-Host '  SrumECmd.exe -f "C:\Windows\System32\sru\SRUDB.dat" --csv .' -ForegroundColor DarkGray
Write-Host '  AppCompatCacheParser.exe --csv .' -ForegroundColor DarkGray

Write-Section 'VERDICT'
Write-KV 'Suspicious hits' "$script:SusHits" $(if ($script:SusHits -gt 0){'Red'}else{'Green'})
Write-KV 'Warnings' "$script:WarnHits" $(if ($script:WarnHits -gt 0){'Yellow'}else{'Green'})
if ($script:SusHits -ge 3) {
    Write-Bad 'Strong signals — dig RFC/SRUM CSVs + PowerShell events vs freeze time'
} elseif ($script:SusHits -ge 1) {
    Write-Warn 'Some signals — corroborate with Prefetch/BAM/Services.ps1'
} else {
    Write-Ok 'No high automated hits — still run Zimmerman parsers for full CSV timeline'
}

Write-BloodFoot -Subtitle 'Advanced artifacts'
