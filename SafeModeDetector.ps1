#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Safe / spare Minecraft detector — Windows SafeBoot + dual javaw close-on-SS.
  Сценарий: чит-клиент + «запасной» майн; при вызове SS закрывают чит.
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'

function Get-SsLogDir {
    $dir = Join-Path $env:USERPROFILE 'Desktop\Schwarzahn-SS-Logs'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}
function Start-SsReport([string]$Name) {
    $dir = Get-SsLogDir
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:SsReportName = $Name
    $script:SsReportPath = Join-Path $dir ("{0}_{1}.log" -f $Name, $stamp)
    try { Start-Transcript -Path $script:SsReportPath -Force | Out-Null } catch {}
    Write-Host ("[*] FULL SS LOG → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
}
function Stop-SsReport {
    try { Stop-Transcript | Out-Null } catch {}
    if ($script:SsReportPath -and (Test-Path -LiteralPath $script:SsReportPath)) {
        Write-Host ("[*] FULL SS LOG SAVED → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
    }
}
function Export-SsTable($Data, [string]$Label = 'export') {
    if (-not $Data) { return $null }
    $dir = Get-SsLogDir
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = if ($script:SsReportName) { $script:SsReportName } else { 'Export' }
    $csv = Join-Path $dir ("{0}_{1}_{2}.csv" -f $name, $Label, $stamp)
    try {
        $Data | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
        Write-Host ("[*] CSV ({0} rows) → {1}" -f @($Data).Count, $csv) -ForegroundColor Cyan
        return $csv
    } catch { return $null }
}

$script:Hits = 0
$script:Warns = 0
$script:Rows = New-Object System.Collections.Generic.List[object]
function Ok($t) { Write-Host "[+] $t" -ForegroundColor Green }
function Bad($t) {
    Write-Host "[x] $t" -ForegroundColor Red
    $script:Hits++
    [void]$script:Rows.Add([pscustomobject]@{ Level = 'HIT'; Text = $t; When = (Get-Date).ToString('s') })
}
function Warn($t) {
    Write-Host "[!] $t" -ForegroundColor Yellow
    $script:Warns++
    [void]$script:Rows.Add([pscustomobject]@{ Level = 'WARN'; Text = $t; When = (Get-Date).ToString('s') })
}
function Info($t) { Write-Host "[*] $t" -ForegroundColor DarkGray }
function Sec($t) { Write-Host ""; Write-Host "══ $t ══" -ForegroundColor DarkRed }

function Get-BootTime {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $b = $os.LastBootUpTime
        if ($b -is [DateTime]) { return $b }
        return [Management.ManagementDateTimeConverter]::ToDateTime($b)
    } catch { return (Get-Date).AddHours(-24) }
}

function Get-PfList([string]$Filter) {
    $pf = Join-Path $env:SystemRoot 'Prefetch'
    if (-not (Test-Path $pf)) { return @() }
    return @(Get-ChildItem -LiteralPath $pf -Filter $Filter -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
}

Start-SsReport 'SafeModeDetector'
Write-Host ""
Write-Host "SCHWARZAHN · Safe / Spare MC Detector" -ForegroundColor Red
Write-Host "SafeBoot Windows + dual javaw / close-on-SS (не автобан)" -ForegroundColor DarkGray

$boot = Get-BootTime
$now = Get-Date
Sec 'SYSTEM'
Info ("Boot {0:yyyy-MM-dd HH:mm:ss}  Now {1:yyyy-MM-dd HH:mm:ss}" -f $boot, $now)

# ——— 1. Windows Safe Mode ———
Sec '1) Windows SafeBoot'
$safeNow = $false
try {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $bu = [string]$cs.BootupState
    Info ("BootupState: {0}" -f $bu)
    if ($bu -match '(?i)safe') { Bad ("Сейчас Safe Mode: {0}" -f $bu); $safeNow = $true }
    else { Ok 'Не в Safe Mode сейчас' }
} catch { Warn 'BootupState недоступен' }

$opt = 'HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option'
if (Test-Path $opt) {
    try {
        $o = Get-ItemProperty -LiteralPath $opt -ErrorAction Stop
        Bad ("SafeBoot\\Option существует OptionValue={0}" -f $o.OptionValue)
        $safeNow = $true
    } catch { Warn 'SafeBoot Option не читается' }
} else {
    Ok 'Нет HKLM\\...\\SafeBoot\\Option (обычная загрузка)'
}

# Event / Prefetch hints for past Safe Mode
$safePf = @(Get-PfList 'SAFEBOOT*.pf') + @(Get-PfList '*SAFE*MODE*.pf')
foreach ($f in $safePf) {
    Warn ("Prefetch safe-ish: {0:yyyy-MM-dd HH:mm}  {1}" -f $f.LastWriteTime, $f.Name)
}

try {
    $ev = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 12; StartTime = $boot } -MaxEvents 5 -ErrorAction SilentlyContinue
    # not definitive
} catch {}

# ——— 2. Live Java / Minecraft ———
Sec '2) Живые java / javaw'
$java = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '(?i)^(java|javaw|javaw\.exe|java\.exe)$' })
if ($java.Count -eq 0) {
    Warn 'Сейчас нет java/javaw — могли закрыть перед SS'
} else {
    Ok ("Живых java-процессов: {0}" -f $java.Count)
    if ($java.Count -ge 2) {
        Bad ("Несколько java одновременно ({0}) — возможен чит + запасной" -f $java.Count)
    }
    foreach ($p in $java) {
        $st = $null
        try { $st = $p.ConvertToDateTime($p.CreationDate) } catch {
            try { $st = [Management.ManagementDateTimeConverter]::ToDateTime($p.CreationDate) } catch {}
        }
        $cmd = [string]$p.CommandLine
        if ($cmd.Length -gt 160) { $cmd = $cmd.Substring(0, 160) + '...' }
        $line = ("PID={0}  start={1:yyyy-MM-dd HH:mm:ss}  {2}" -f $p.ProcessId, $st, $p.ExecutablePath)
        Info $line
        if ($cmd) { Info ("  cmd: {0}" -f $cmd) }
        [void]$script:Rows.Add([pscustomobject]@{
                Level = 'JAVA'; Text = $line; When = if ($st) { $st.ToString('s') } else { '' }
            })
    }
}

# ——— 3. Prefetch JAVA / launchers ———
Sec '3) Prefetch JAVA / лаунчеры'
$pfFocus = @()
foreach ($pat in @('JAVAW*.pf', 'JAVA*.pf', 'MINECRAFT*.pf', 'LUNAR*.pf', 'BADLION*.pf', 'FEATHER*.pf', 'PRISM*.pf', 'MULTIMC*.pf', 'SKLAUNCHER*.pf', 'TL*.pf', 'HMCL*.pf')) {
    $pfFocus += Get-PfList $pat
}
$pfFocus = @($pfFocus | Sort-Object FullName -Unique | Sort-Object LastWriteTime -Descending)
if ($pfFocus.Count -eq 0) {
    Warn 'Нет JAVA/MC Prefetch'
} else {
    $javawPf = @($pfFocus | Where-Object { $_.Name -match '(?i)^JAVAW' })
    Ok ("Prefetch focus файлов: {0} (JAVAW*.pf = {1})" -f $pfFocus.Count, $javawPf.Count)
    if ($javawPf.Count -ge 2) {
        Bad ("Несколько разных JAVAW-*.pf ({0}) — разные java/пути/клиенты" -f $javawPf.Count)
    }
    foreach ($f in $pfFocus) {
        $ageH = ($now - $f.LastWriteTime).TotalHours
        $line = ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $f.LastWriteTime, $f.Name)
        if ($ageH -le 6) { Info $line } else { Ok $line }
        [void]$script:Rows.Add([pscustomobject]@{ Level = 'PF'; Text = $line; When = $f.LastWriteTime.ToString('s') })
    }
    Export-SsTable ($pfFocus | ForEach-Object {
            [pscustomobject]@{ LastWrite = $_.LastWriteTime.ToString('s'); Name = $_.Name; Path = $_.FullName }
        }) 'prefetch-java' | Out-Null
}

# ——— 4. Remote SS session tools vs JAVA close ———
Sec '4) SS-сессия vs закрытие JAVA'
$ssNames = @('ANYDESK', 'DISCORD', 'TEAMVIEWER', 'RUSTDESK', 'PARSEC', 'AEROADMIN', 'SUPREMO', 'RMS_', 'QUICKASSIST')
$ssPf = @()
foreach ($n in $ssNames) {
    $ssPf += Get-PfList ($n + '*.pf')
}
$ssPf = @($ssPf | Sort-Object LastWriteTime -Descending)
$ssLive = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '(?i)anydesk|discord|teamviewer|rustdesk|parsec|aeroadmin|supremo'
    })
if ($ssLive.Count -gt 0) {
    Ok ("Живые SS/remote: {0}" -f (($ssLive.ProcessName | Select-Object -Unique) -join ', '))
} else {
    Info 'Живых AnyDesk/Discord/TV не видно (или другие имена)'
}

$ssTimes = New-Object System.Collections.Generic.List[datetime]
foreach ($p in $ssLive) {
    try { [void]$ssTimes.Add($p.StartTime) } catch {}
}
foreach ($f in ($ssPf | Select-Object -First 12)) {
    Info ("SS Prefetch {0:yyyy-MM-dd HH:mm:ss}  {1}" -f $f.LastWriteTime, $f.Name)
    [void]$ssTimes.Add($f.LastWriteTime)
}

$javaPfRecent = @($pfFocus | Where-Object { $_.Name -match '(?i)^JAVAW|^JAVA' -and $_.LastWriteTime -ge $now.AddHours(-12) })
if ($ssTimes.Count -gt 0 -and $javaPfRecent.Count -gt 0) {
    $ssAnchor = ($ssTimes | Sort-Object -Descending | Select-Object -First 1)
    Info ("Якорь SS/remote (max): {0:yyyy-MM-dd HH:mm:ss}" -f $ssAnchor)
    foreach ($jf in $javaPfRecent) {
        $deltaMin = [math]::Abs(($jf.LastWriteTime - $ssAnchor).TotalMinutes)
        # Prefetch LastWrite ~ last run; if JAVA pf updated within ±15 min of SS tool = interesting
        # Close-on-call: JAVA stopped near SS start → often pf write near that time, then only "safe" client left
        if ($deltaMin -le 20) {
            Bad ("JAVA Prefetch ↔ SS в пределах {0:N0} мин: {1:HH:mm:ss} {2}  vs SS {3:HH:mm:ss}" -f `
                    $deltaMin, $jf.LastWriteTime, $jf.Name, $ssAnchor)
        } elseif ($deltaMin -le 60) {
            Warn ("JAVA Prefetch ↔ SS ~{0:N0} мин: {1} / {2:HH:mm}" -f $deltaMin, $jf.Name, $ssAnchor)
        }
    }
    # If live java started AFTER ss session and older javaw pf exists → switched to spare
    if ($java.Count -ge 1 -and $javawPf.Count -ge 1) {
        $liveStart = @()
        foreach ($p in $java) {
            try {
                $st = $p.ConvertToDateTime($p.CreationDate)
                $liveStart += $st
            } catch {}
        }
        if ($liveStart.Count -gt 0) {
            $newestLive = ($liveStart | Sort-Object -Descending | Select-Object -First 1)
            $olderPf = @($javawPf | Where-Object { $_.LastWriteTime -lt $newestLive.AddMinutes(-2) -and $_.LastWriteTime -gt $now.AddHours(-12) })
            # Also: pf newer than live start can mean another instance ran/closed after
            $closedAfterSs = @($javawPf | Where-Object {
                    $_.LastWriteTime -ge $ssAnchor.AddMinutes(-5) -and
                    ($liveStart | Where-Object { $_ -gt $_.LastWriteTime }).Count -ge 0
                })
            if ($java.Count -eq 1 -and $javawPf.Count -ge 2) {
                Bad 'Сейчас 1 javaw, а JAVAW-*.pf ≥ 2 за сессию — типичный «закрыли чит, оставили запасной»'
            }
            if ($newestLive -gt $ssAnchor.AddMinutes(-2) -and $javawPf.Count -ge 2) {
                Warn ("Живой java стартовал {0:HH:mm:ss} около/после SS-якоря — проверь второй клиент в Prefetch/BAM" -f $newestLive)
            }
        }
    }
} else {
    Info 'Мало данных для тайминга SS↔JAVA (нет SS prefetch/process или свежего JAVA pf)'
}

# ——— 5. BAM java / minecraft paths ———
Sec '5) BAM (java / minecraft / лаунчеры)'
$bamRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings'
$bamHits = New-Object System.Collections.Generic.List[object]
$needles = @('javaw', 'java.exe', 'minecraft', 'lunar', 'badlion', 'feather', 'prism', 'multimc', 'sklauncher', 'tlauncher', 'hmcl', '.minecraft')
if (Test-Path $bamRoot) {
    Get-ChildItem $bamRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $sid = $_.PSChildName
        try {
            $props = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Name -match '^PS') { continue }
                $path = [string]$p.Name
                $hit = $false
                foreach ($n in $needles) {
                    if ($path.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $hit = $true; break }
                }
                if ($hit) {
                    [void]$bamHits.Add([pscustomobject]@{ SID = $sid; Path = $path })
                    Info ("BAM  {0}" -f $path)
                }
            }
        } catch {}
    }
    $paths = @($bamHits.Path | Select-Object -Unique)
    Ok ("BAM java/MC путей: {0}" -f $paths.Count)
    if ($paths.Count -ge 3) {
        Bad ("Много разных java/MC путей в BAM ({0}) — несколько клиентов/лаунчеров" -f $paths.Count)
    }
    Export-SsTable $bamHits 'bam-java' | Out-Null
} else {
    Warn 'BAM недоступен'
}

# ——— 6. .minecraft folders ———
Sec '6) Папки .minecraft / лаунчеры'
$mcDirs = New-Object System.Collections.Generic.List[string]
$candidates = @(
    (Join-Path $env:APPDATA '.minecraft'),
    (Join-Path $env:USERPROFILE '.lunarclient'),
    (Join-Path $env:APPDATA '.badlion'),
    (Join-Path $env:APPDATA 'Feather'),
    (Join-Path $env:APPDATA 'PrismLauncher'),
    (Join-Path $env:APPDATA 'PolyMC'),
    (Join-Path $env:APPDATA 'com.modrinth.App')
)
try {
    Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $candidates += (Join-Path $_.FullName 'AppData\Roaming\.minecraft')
        $candidates += (Join-Path $_.FullName '.lunarclient')
    }
} catch {}
foreach ($d in ($candidates | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $d) {
        $i = Get-Item -LiteralPath $d
        [void]$mcDirs.Add($d)
        Info ("{0:yyyy-MM-dd HH:mm}  {1}" -f $i.LastWriteTime, $d)
    }
}
if ($mcDirs.Count -ge 2) {
    Warn ("Несколько MC-корней ({0}) — сверь версии/mods между ними" -f $mcDirs.Count)
} elseif ($mcDirs.Count -eq 1) {
    Ok 'Один основной MC-корень найден'
} else {
    Warn 'Типичных MC-папок не видно'
}

# latest.log mtimes
foreach ($root in $mcDirs) {
    $logs = @()
    foreach ($rel in @('logs\latest.log', 'logs\launcher_log.txt', 'launcher_log.txt')) {
        $lp = Join-Path $root $rel
        if (Test-Path -LiteralPath $lp) { $logs += Get-Item -LiteralPath $lp }
    }
    Get-ChildItem -LiteralPath $root -Recurse -Filter 'latest.log' -ErrorAction SilentlyContinue |
        Select-Object -First 8 | ForEach-Object { $logs += $_ }
    foreach ($l in ($logs | Sort-Object FullName -Unique)) {
        Info ("log {0:yyyy-MM-dd HH:mm:ss}  {1}" -f $l.LastWriteTime, $l.FullName)
    }
}

# ——— 7. Process exit 4689 (optional) ———
Sec '7) Security 4689 (java exit) с boot'
try {
    $exits = @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4689; StartTime = $boot } -MaxEvents 400 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match '(?i)\\java(w)?\.exe' })
    if ($exits.Count -eq 0) {
        Info '4689 java не найдено (нет аудита или нет выходов)'
    } else {
        Warn ("4689 java exits: {0}" -f $exits.Count)
        foreach ($e in ($exits | Select-Object -First 25)) {
            $msg = ($e.Message -replace '\s+', ' ').Trim()
            if ($msg.Length -gt 140) { $msg = $msg.Substring(0, 140) + '...' }
            Info ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $e.TimeCreated, $msg)
            [void]$script:Rows.Add([pscustomobject]@{ Level = '4689'; Text = $msg; When = $e.TimeCreated.ToString('s') })
        }
        Export-SsTable ($exits | ForEach-Object {
                [pscustomobject]@{ Time = $_.TimeCreated.ToString('s'); Message = (($_.Message -replace '\s+', ' ').Trim()) }
            }) 'java-4689' | Out-Null
    }
} catch {
    Info '4689 недоступен (нужны права/аудит Process Termination)'
}

# ——— Verdict ———
Sec 'СВЯЗКА / ВЕРДИКТ'
Info 'Один hit ≠ бан. Ищи: 2+ JAVAW.pf / 2+ java + закрытие около AnyDesk/Discord.'
Info 'Дальше: WinPrefetchView++ по каждому JAVAW.pf · BAM · SI на живой javaw.'
Info 'Windows SafeBoot — отдельно от «safe» запасного майнклиента.'
Write-Host ("Hits={0}  Warns={1}" -f $script:Hits, $script:Warns) -ForegroundColor $(if ($script:Hits -gt 0) { 'Red' } else { 'Green' })
Export-SsTable $script:Rows 'hits' | Out-Null
Write-Host ""
Stop-SsReport
