#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Включает компактный набор служб для скриншара + Prefetch.
  by Schwarzahn
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'

function Enable-AnsiConsole {
    if ($script:AnsiReady) { return }
    try {
        if (-not ('Native.ConsoleVT' -as [type])) {
            Add-Type -ErrorAction Stop -Namespace Native -Name ConsoleVT -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
        }
        $h = [Native.ConsoleVT]::GetStdHandle(-11)
        $mode = [uint32]0
        if ([Native.ConsoleVT]::GetConsoleMode($h, [ref]$mode)) {
            [void][Native.ConsoleVT]::SetConsoleMode($h, ($mode -bor 0x0004))
        }
        $script:AnsiReady = $true
    }
    catch { $script:AnsiReady = $false }
}

function Write-Ansi([string]$Text) { [Console]::Write($Text) }

function Get-BloodPalette {
    if ($script:BloodPalette) { return $script:BloodPalette }
    $script:BloodPalette = @{
        ShadowFar  = "$esc[38;2;35;0;0m"
        ShadowNear = "$esc[38;2;80;0;0m"
        Mid        = "$esc[38;2;150;0;0m"
        Blood      = "$esc[38;2;200;10;10m"
        Hot        = "$esc[38;2;255;35;35m"
        Glow       = "$esc[38;2;255;90;90m"
        Drip       = "$esc[38;2;130;0;0m"
        Dim        = "$esc[38;2;85;85;85m"
        Soft       = "$esc[38;2;170;170;170m"
        Reset      = "$esc[0m"
        Bold       = "$esc[1m"
    }
    return $script:BloodPalette
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = [Security.Principal.WindowsPrincipal]::new($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Write-BloodBanner {
    param(
        [string]$Subtitle = 'Service Enabler'
    )

    Enable-AnsiConsole
    $c = Get-BloodPalette

    # SCHWARZAHN — block art + 3D shadow stack
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
    # Far shadow
    foreach ($line in $art) { Write-Ansi ("   $($c.ShadowFar)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    # Near shadow
    foreach ($line in $art) { Write-Ansi ("  $($c.ShadowNear)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    # Main blood layer
    for ($i = 0; $i -lt $art.Count; $i++) {
        Write-Ansi ("$($grad[$i])$($art[$i])$($c.Reset)`n")
    }

    # Blood drips + underline slash
    Write-Ansi ("$($c.Drip)  ║  ║    ║║      ║   ║║║     ║  ║    ║║     ║  ║   ║$($c.Reset)`n")
    Write-Ansi ("$($c.Drip)  ┘  ░    ░░   ▄  ▘   ░░░  ▄  ▘  ░    ░░  ▄  ▘   ▘$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 72))$($c.Reset)`n")

    # Tagline: 3D "by Schwarzahn"
    $tag = "by $script:BrandName"
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}

function Write-BloodFoot {
    param([string]$Subtitle = '')
    Enable-AnsiConsole
    $c = Get-BloodPalette
    $tag = "by $script:BrandName"
    Write-Host ''
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 64))$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    if ($Subtitle) {
        Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    } else {
        Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)`n")
    }
    Write-Host ''
}

function Write-Section([string]$Text) {
    Enable-AnsiConsole
    $c = Get-BloodPalette
    $line = '─' * [Math]::Max(8, (58 - $Text.Length))
    Write-Host ''
    Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n")
}

function Write-BloodOk([string]$Text)   { Write-Host "[+] $Text" -ForegroundColor Green }
function Write-BloodWarn([string]$Text) { Write-Host "[!] $Text" -ForegroundColor Yellow }
function Write-BloodFail([string]$Text) { Write-Host "[-] $Text" -ForegroundColor Red }
function Write-BloodInfo([string]$Text) { Write-Host "[*] $Text" -ForegroundColor DarkGray }


function Get-StartTypeRu($StartType) {
    switch ("$StartType") {
        'Automatic' { 'Авто' }
        'Manual'    { 'Вручную' }
        'Disabled'  { 'Отключена' }
        'Boot'      { 'Загрузка' }
        'System'    { 'Система' }
        default     { "$StartType" }
    }
}

function Get-StatusRu($Status) {
    switch ("$Status") {
        'Running'  { 'Работает' }
        'Stopped'  { 'Остановлена' }
        default    { "$Status" }
    }
}

function Write-OK([string]$Text)   { Write-BloodOk $Text }
function Write-Warn([string]$Text) { Write-BloodWarn $Text }
function Write-Fail([string]$Text) { Write-BloodFail $Text }
function Write-Info([string]$Text) { Write-BloodInfo $Text }

$CriticalServices = [ordered]@{
    'EventLog'   = @{ Startup = 'Automatic'; Start = $true;  Note = 'Журнал событий Windows' }
    'SysMain'    = @{ Startup = 'Automatic'; Start = $true;  Note = 'SysMain' }
    'Schedule'   = @{ Startup = 'Automatic'; Start = $true;  Note = 'Планировщик задач' }
    'DPS'        = @{ Startup = 'Automatic'; Start = $true;  Note = 'Служба политики диагностики' }
    'DiagTrack'  = @{ Startup = 'Automatic'; Start = $true;  Note = 'Телеметрия' }
    'PcaSvc'     = @{ Startup = 'Automatic'; Start = $true;  Note = 'Помощник по совместимости программ' }
    'AppInfo'    = @{ Startup = 'Manual';    Start = $true;  Note = 'Сведения о приложении' }
    'PlugPlay'   = @{ Startup = 'Manual';    Start = $true;  Note = 'Plug and Play' }
    'DcomLaunch' = @{ Startup = 'Automatic'; Start = $true;  Note = 'Запуск процессов DCOM-сервера' }
    'CDPSvc'     = @{ Startup = 'Automatic'; Start = $true;  Note = 'Платформа подключенных устройств' }
    'DusmSvc'    = @{ Startup = 'Automatic'; Start = $true;  Note = 'Использование данных' }
    'WSearch'    = @{ Startup = 'Automatic'; Start = $true;  Note = 'Windows Search' }
    'Power'      = @{ Startup = 'Automatic'; Start = $true;  Note = 'Питание' }
}

Write-BloodBanner -Subtitle 'Service Enabler'

if (-not (Test-IsAdmin)) {
    Write-Section 'ERROR'
    Write-Fail 'Нужны права администратора.'
    Write-BloodFoot -Subtitle 'Service Enabler'
    return
}

Write-Info ("ПК: {0} | Юзер: {1} | {2}" -f $env:COMPUTERNAME, $env:USERNAME, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Write-Section 'ENABLE SERVICES'

$results = @()

foreach ($name in $CriticalServices.Keys) {
    $cfg = $CriticalServices[$name]
    $row = [pscustomobject]@{
        Service = $name
        Note    = $cfg.Note
        Before  = 'н/д'
        After   = 'н/д'
        Status  = 'Нет'
        Action  = ''
    }

    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) {
        $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -like "$name*" -or $_.Name -like "$name_*"
        } | Select-Object -First 1
    }

    if (-not $svc) {
        Write-Warn ("{0} — нет на этой системе" -f $name)
        $results += $row
        continue
    }

    $actualName = $svc.Name
    $row.Service = $actualName
    $row.Before  = '{0} / {1}' -f (Get-StartTypeRu $svc.StartType), (Get-StatusRu $svc.Status)

    try {
        Set-Service -Name $actualName -StartupType $cfg.Startup -ErrorAction Stop
        $row.Action = "Запуск -> $(Get-StartTypeRu $cfg.Startup)"

        if ($cfg.Start) {
            if ($svc.Status -ne 'Running') {
                Start-Service -Name $actualName -ErrorAction Stop
                $row.Action += '; запущена'
            } else {
                $row.Action += '; уже работает'
            }
        }

        $svc = Get-Service -Name $actualName
        $row.After  = '{0} / {1}' -f (Get-StartTypeRu $svc.StartType), (Get-StatusRu $svc.Status)
        $row.Status = 'OK'
        Write-OK ("{0} ({1}) => {2}" -f $actualName, $cfg.Note, $row.After)
    }
    catch {
        $row.Status = 'FAIL'
        $row.Action = $_.Exception.Message
        Write-Fail ("{0}: {1}" -f $actualName, $_.Exception.Message)
    }

    $results += $row
}

Write-Section 'BAM'

$bamPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam'
$startMapRu = @{ 0 = 'Загрузка'; 1 = 'Система'; 2 = 'Авто'; 3 = 'Вручную'; 4 = 'Отключена' }

if (Test-Path $bamPath) {
    try {
        $bp = Get-ItemProperty $bamPath
        $oldStart = [int]$bp.Start
        $oldRu = if ($startMapRu.ContainsKey($oldStart)) { $startMapRu[$oldStart] } else { "$oldStart" }

        $desired = 1
        Set-ItemProperty -Path $bamPath -Name 'Start' -Value $desired -Type DWord -Force

        $statePath = Join-Path $bamPath 'State'
        $userPath  = Join-Path $bamPath 'State\UserSettings'
        if (-not (Test-Path $statePath)) { New-Item -Path $statePath -Force | Out-Null }
        if (-not (Test-Path $userPath))  { New-Item -Path $userPath  -Force | Out-Null }

        $newRu = $startMapRu[$desired]
        Write-OK ("bam Start: {0} -> {1} (System)" -f $oldRu, $newRu)
        Write-OK 'Ключи State\UserSettings проверены/созданы'

        $sc = & sc.exe start bam 2>&1
        if ($LASTEXITCODE -eq 0 -or ("$sc" -match 'RUNNING|уже запущ|already')) {
            Write-OK 'sc start bam — ок / уже запущен'
        } else {
            Write-Info ("sc start bam: {0}" -f (($sc | Out-String).Trim()))
            Write-Info 'Kernel driver: полный старт может потребовать перезагрузки'
        }
    }
    catch {
        Write-Fail ("BAM: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Fail 'Ключ HKLM\SYSTEM\CurrentControlSet\Services\bam отсутствует'
}

Write-Section 'PREFETCH / SYSMAIN'

$prefetchPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
$prefetchKeys = @{
    EnablePrefetcher  = 3
    EnableSuperfetch  = 3
}

if (Test-Path $prefetchPath) {
    foreach ($key in $prefetchKeys.Keys) {
        try {
            $old = (Get-ItemProperty -Path $prefetchPath -Name $key -ErrorAction SilentlyContinue).$key
            Set-ItemProperty -Path $prefetchPath -Name $key -Value $prefetchKeys[$key] -Type DWord -Force
            Write-OK ("{0}: {1} -> {2}" -f $key, $old, $prefetchKeys[$key])
        }
        catch {
            Write-Fail ("{0}: {1}" -f $key, $_.Exception.Message)
        }
    }
} else {
    Write-Warn 'Ключ PrefetchParameters не найден'
}

$prefetchDir = Join-Path $env:SystemRoot 'Prefetch'
if (Test-Path $prefetchDir) {
    try {
        $item = Get-Item $prefetchDir -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReadOnly) {
            $item.Attributes = $item.Attributes -bxor [IO.FileAttributes]::ReadOnly
            Write-OK 'Снят ReadOnly с Prefetch'
        } else {
            Write-Info 'Атрибуты Prefetch в норме'
        }
    }
    catch {
        Write-Fail ("Папка Prefetch: {0}" -f $_.Exception.Message)
    }
}

Write-Section 'VERIFY'
$stillBad = New-Object System.Collections.Generic.List[string]
foreach ($name in $CriticalServices.Keys) {
    $cfg = $CriticalServices[$name]
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) {
        $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -like "$name*" -or $_.Name -like "$name_*"
        } | Select-Object -First 1
    }
    if (-not $svc) {
        [void]$stillBad.Add("$name (missing)")
        continue
    }
    if ($cfg.Start -and $svc.Status -ne 'Running') {
        [void]$stillBad.Add(("{0}={1}" -f $svc.Name, $svc.Status))
    }
    elseif ("$($svc.StartType)" -eq 'Disabled') {
        [void]$stillBad.Add(("{0}=Disabled" -f $svc.Name))
    }
}

if ($stillBad.Count -eq 0) {
    Write-OK 'Все целевые службы в норме после включения'
} else {
    Write-Warn ("Ещё проблемные: {0}" -f ($stillBad -join ', '))
}

Write-Section 'SUMMARY'
$results | Format-Table Service, Status, Before, After, Note -AutoSize

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
$ok     = @($results | Where-Object { $_.Status -eq 'OK' }).Count
Write-Host ''
Write-OK ("Включено/проверено: {0}" -f $ok)
if ($failed.Count -gt 0) {
    Write-Warn ("Ошибки: {0}" -f $failed.Count)
}

Write-BloodFoot -Subtitle 'Service Enabler'
Write-Info 'Готово. Проверь через Services.ps1'
Write-Host ''
