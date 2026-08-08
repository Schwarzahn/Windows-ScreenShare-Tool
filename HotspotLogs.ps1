#Requires -RunAsAdministrator
<#
.SYNOPSIS
  ScreenShare Tool — Mobile Hotspot / ICS / WLAN related event logs.
  by Schwarzahn
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'ScreenShare Tool'

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
        ShadowFar="$esc[38;2;35;0;0m"; ShadowNear="$esc[38;2;80;0;0m"; Mid="$esc[38;2;150;0;0m"
        Blood="$esc[38;2;200;10;10m"; Hot="$esc[38;2;255;35;35m"; Glow="$esc[38;2;255;90;90m"
        Drip="$esc[38;2;130;0;0m"; Dim="$esc[38;2;85;85;85m"; Soft="$esc[38;2;170;170;170m"
        Green="$esc[38;2;80;220;120m"; Reset="$esc[0m"; Bold="$esc[1m"
    }
    return $script:BloodPalette
}
function Write-BloodBanner {
    param([string]$Subtitle='ScreenShare Tool')
    Enable-AnsiConsole; $c=Get-BloodPalette
    $art=@(
        '███████╗ ██████╗██╗  ██╗██╗    ██╗ █████╗ ██████╗ ███████╗ █████╗ ██╗  ██╗███╗   ██╗',
        '██╔════╝██╔════╝██║  ██║██║    ██║██╔══██╗██╔══██╗╚══███╔╝██╔══██╗██║  ██║████╗  ██║',
        '███████╗██║     ███████║██║ █╗ ██║███████║██████╔╝  ███╔╝ ███████║███████║██╔██╗ ██║',
        '╚════██║██║     ██╔══██║██║███╗██║██╔══██║██╔══██╗ ███╔╝  ██╔══██║██╔══██║██║╚██╗██║',
        '███████║╚██████╗██║  ██║╚███╔███╔╝██║  ██║██║  ██║███████╗██║  ██║██║  ██║██║ ╚████║',
        '╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝'
    )
    $grad=@($c.Glow,$c.Hot,$c.Blood,$c.Blood,$c.Mid,$c.ShadowNear)
    Write-Host ''
    foreach($l in $art){Write-Ansi("   $($c.ShadowFar)$l$($c.Reset)`n")}
    Write-Ansi("$esc[$($art.Count)A")
    foreach($l in $art){Write-Ansi("  $($c.ShadowNear)$l$($c.Reset)`n")}
    Write-Ansi("$esc[$($art.Count)A")
    for($i=0;$i -lt $art.Count;$i++){Write-Ansi("$($grad[$i])$($art[$i])$($c.Reset)`n")}
    Write-Ansi("$($c.Drip)  ║  ║    ║║      ║   ║║║     ║  ║    ║║     ║  ║   ║$($c.Reset)`n")
    Write-Ansi("$($c.ShadowFar)  $($('═'*72))$($c.Reset)`n")
    $tag="by $script:BrandName"
    Write-Ansi("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}
function Write-BloodFoot { param([string]$Subtitle='ScreenShare Tool'); Enable-AnsiConsole; $c=Get-BloodPalette; $tag="by $script:BrandName"; Write-Host ''; Write-Ansi("$($c.ShadowFar)  $($('═'*64))$($c.Reset)`n"); Write-Ansi("$($c.ShadowFar)   $tag$($c.Reset)`n"); Write-Ansi("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n"); Write-Host '' }
function Write-Section([string]$Text){ Enable-AnsiConsole; $c=Get-BloodPalette; $line='─'*[Math]::Max(8,(58-$Text.Length)); Write-Host ''; Write-Ansi("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n") }

function Get-WinEventsSafe {
    param($FilterHashtable, [int]$MaxEvents = 40)
    try { Get-WinEvent -FilterHashtable $FilterHashtable -MaxEvents $MaxEvents -ErrorAction Stop }
    catch { @() }
}

Clear-Host
Write-BloodBanner -Subtitle 'Hotspot Logs'

Write-Section 'HOTSPOT SERVICE'
$svcNames = @('icssvc', 'SharedAccess', 'WlanSvc', 'dot3svc')
foreach ($n in $svcNames) {
    $s = Get-Service -Name $n -ErrorAction SilentlyContinue
    if ($s) {
        $color = if ($s.Status -eq 'Running') { 'Green' } else { 'DarkGray' }
        Write-Host ("  {0,-14} {1,-12} {2}" -f $s.Name, $s.Status, $s.StartType) -ForegroundColor $color
    } else {
        Write-Host ("  {0,-14} missing" -f $n) -ForegroundColor DarkRed
    }
}

Write-Section 'EVENT LOGS'
$queries = @(
    @{ Name = 'WLAN-AutoConfig'; Log = 'Microsoft-Windows-WLAN-AutoConfig/Operational'; Ids = $null }
    @{ Name = 'NetworkProfile'; Log = 'Microsoft-Windows-NetworkProfile/Operational'; Ids = $null }
    @{ Name = 'HostedNetwork'; Log = 'Microsoft-Windows-NCSI/Operational'; Ids = $null }
    @{ Name = 'System ICS/Hotspot hints'; Log = 'System'; Ids = @(7023, 7024, 7036, 7040) }
)

$all = @()
foreach ($q in $queries) {
    Write-Host ("  [*] {0}" -f $q.Name) -ForegroundColor DarkGray
    if ($q.Ids) {
        $ev = Get-WinEventsSafe -FilterHashtable @{ LogName = $q.Log; Id = $q.Ids } -MaxEvents 30
    } else {
        $ev = Get-WinEventsSafe -FilterHashtable @{ LogName = $q.Log } -MaxEvents 25
    }
    if (-not $ev -or $ev.Count -eq 0) {
        Write-Host '      (no events / log unavailable)' -ForegroundColor DarkGray
        continue
    }
    foreach ($e in ($ev | Select-Object -First 8)) {
        $msg = (($e.Message -split "`n")[0])
        if ($msg.Length -gt 90) { $msg = $msg.Substring(0, 90) + '...' }
        $hit = ($msg -match 'hotspot|hosted network|mobile hotspot|ics|sharing|tethering')
        $color = if ($hit) { 'Red' } else { 'Gray' }
        Write-Host ("      {0:yyyy-MM-dd HH:mm:ss}  ID={1,-5}  {2}" -f $e.TimeCreated, $e.Id, $msg) -ForegroundColor $color
        $all += [pscustomobject]@{ Source = $q.Name; Time = $e.TimeCreated; Id = $e.Id; Message = $msg; Hot = [bool]$hit }
    }
}

Write-Section 'SUMMARY'
$hot = @($all | Where-Object { $_.Hot })
if ($hot.Count -gt 0) {
    Write-Host ("  Hotspot-related hits: {0}" -f $hot.Count) -ForegroundColor Red
} else {
    Write-Host '  No obvious hotspot keywords in recent events.' -ForegroundColor Green
}

if ($all.Count -gt 0) {
    $all | Sort-Object Time -Descending | Out-GridView -Title ("Hotspot Logs — by {0}" -f $script:BrandName)
}

Write-BloodFoot -Subtitle 'Hotspot Logs'
