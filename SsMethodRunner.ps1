#Requires -Version 5.1
<#
.SYNOPSIS
  SS method launcher — pick a check or run pack order.
  by Schwarzahn · Excellence Screenshare
#>

$ErrorActionPreference = 'Continue'

# --- SS FULL LOG (Desktop\Schwarzahn-SS-Logs) ---
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
    Write-Host '[*] Консоль кратко · файл на Desktop = полный лог для SS' -ForegroundColor DarkGray
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

$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Excellence Screenshare'
$script:RawBase = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main'

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
    param([string]$Subtitle = 'Method Runner')
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
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}
function Write-BloodFoot {
    param([string]$Subtitle = '')
    # brand once in banner — no footer spam
    Write-Host ''
}


$script:Methods = @(
    @{ Id = 0; Name = 'DriveFsQuick'; File = 'DriveFsQuick.ps1'; Note = 'NTFS/FAT32 base' },
    @{ Id = 14; Name = 'SafeModeDetector'; File = 'SafeModeDetector.ps1'; Note = 'SafeBoot + spare MC' },
    @{ Id = 1;  Name = 'Service-Enabler';     File = 'Service-Enabler.ps1';     Note = 'Heal cured services' }
    @{ Id = 2;  Name = 'Services';             File = 'Services.ps1';             Note = 'Service pulse' }
    @{ Id = 3;  Name = 'BamViewer';            File = 'BamViewer.ps1';            Note = 'BAM' }
    @{ Id = 4;  Name = 'PrefetchScanner';      File = 'PrefetchScanner.ps1';      Note = 'Prefetch' }
    @{ Id = 5;  Name = 'UsnWipeScanner';       File = 'UsnWipeScanner.ps1';       Note = 'USN wipe' }
    @{ Id = 6;  Name = 'Streams';              File = 'Streams.ps1';              Note = 'ADS / Zone.Identifier' }
    @{ Id = 7;  Name = 'PcaSvcScanner';       File = 'PcaSvcScanner.ps1';       Note = 'PcaSvc / jars' }
    @{ Id = 8;  Name = 'AmcacheQuick';        File = 'AmcacheQuick.ps1';        Note = 'Amcache.hve' }
    @{ Id = 9;  Name = 'ShimcacheQuick';      File = 'ShimcacheQuick.ps1';      Note = 'AppCompatCache' }
    @{ Id = 10; Name = 'ModAnalyzer';         File = 'ModAnalyzer.ps1';         Note = 'Mods' }
    @{ Id = 11; Name = 'DoomsDayDetector';    File = 'DoomsDayDetector.ps1';    Note = 'DoomsDay' }
    @{ Id = 12; Name = 'Ghost-KakIskat';    File = 'Ghost-KakIskat.ps1';    Note = 'Ghost file hints' }
    @{ Id = 13; Name = 'FilelessDetector';    File = 'FilelessDetector.ps1';    Note = 'Fileless / PS' }
    @{ Id = 14; Name = 'BrowserSurface';      File = 'BrowserSurface.ps1';      Note = 'Downloads surface' }
    @{ Id = 15; Name = 'UsbJournal';          File = 'UsbJournal.ps1';          Note = 'USB events' }
    @{ Id = 16; Name = 'HotspotLogs';         File = 'HotspotLogs.ps1';         Note = 'Hotspot' }
    @{ Id = 17; Name = 'ManualTasks';         File = 'ManualTasks.ps1';         Note = 'Tasks' }
    @{ Id = 18; Name = 'AdvancedArtifacts';   File = 'AdvancedArtifacts.ps1';   Note = 'RFC/SRUM/Shim/VM' }
    @{ Id = 19; Name = 'CommonDirectories';   File = 'CommonDirectories.ps1';   Note = 'Paths snapshot' }
    @{ Id = 20; Name = 'SignaturesParser';    File = 'SignaturesParser.ps1';    Note = 'Signatures' }
    @{ Id = 21; Name = 'KillScreenProcesses'; File = 'KillScreenProcesses.ps1'; Note = 'Capture kill' }
)

function Invoke-MethodScript {
    param([hashtable]$Method)
    $local = Join-Path $PSScriptRoot $Method.File
    if (-not (Test-Path -LiteralPath $local)) {
        $local = Join-Path (Get-Location) $Method.File
    }
    Write-Host ''
    Write-Host (">>> {0} — {1}" -f $Method.Name, $Method.Note) -ForegroundColor Cyan
    if (Test-Path -LiteralPath $local) {
        Write-Host ("Local: {0}" -f $local) -ForegroundColor DarkGray
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $local
        return
    }
    $url = "$($script:RawBase)/$($Method.File)?cb=$([guid]::NewGuid())"
    Write-Host ("Remote: {0}" -f $url) -ForegroundColor DarkGray
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod '$url')"
}

function Show-Menu {
    Write-Host 'Methods (number = run one, A = pack order, Q = quit):' -ForegroundColor DarkGray
    foreach ($m in $script:Methods) {
        Write-Host ("  {0,2}. {1,-22} {2}" -f $m.Id, $m.Name, $m.Note)
    }
    Write-Host '   A. Run pack (1→21 playbook order)'
    Write-Host '   Q. Quit'
}

# ===== START =====
Start-SsReport 'SsMethodRunner'
Write-BloodBanner -Subtitle 'SS Method Runner'

$packOrder = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21)

# Non-interactive: -Method Id or Name via args
$arg = $args | Select-Object -First 1
if ($arg) {
    if ("$arg" -match '^(?i)all|a$') {
        foreach ($id in $packOrder) {
            $m = $script:Methods | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($m) { Invoke-MethodScript -Method $m }
        }
        Write-BloodFoot
        return
    }
    if ("$arg" -match '^\d+$') {
        $m = $script:Methods | Where-Object { $_.Id -eq [int]$arg } | Select-Object -First 1
        if ($m) { Invoke-MethodScript -Method $m }
        else { Write-Host "Unknown id $arg" -ForegroundColor Red }
        Write-BloodFoot
        return
    }
    $m = $script:Methods | Where-Object { $_.Name -eq "$arg" -or $_.File -eq "$arg" } | Select-Object -First 1
    if ($m) { Invoke-MethodScript -Method $m }
    else { Write-Host "Unknown method $arg" -ForegroundColor Red }
    Write-BloodFoot
    return
}

while ($true) {
    Show-Menu
    $choice = Read-Host 'Select'
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }
    if ($choice -match '^(?i)q|quit|exit$') { break }
    if ($choice -match '^(?i)a|all$') {
        foreach ($id in $packOrder) {
            $m = $script:Methods | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($m) { Invoke-MethodScript -Method $m }
        }
        continue
    }
    if ($choice -match '^\d+$') {
        $m = $script:Methods | Where-Object { $_.Id -eq [int]$choice } | Select-Object -First 1
        if ($m) { Invoke-MethodScript -Method $m }
        else { Write-Host 'Unknown number' -ForegroundColor Yellow }
        continue
    }
    Write-Host 'Invalid selection' -ForegroundColor Yellow
}

Stop-SsReport
Write-BloodFoot -Subtitle 'SS Method Runner'
