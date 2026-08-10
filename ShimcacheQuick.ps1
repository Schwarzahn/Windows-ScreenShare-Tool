#Requires -Version 5.1
<#
.SYNOPSIS
  AppCompatCache / Shimcache quick surface
  by Schwarzahn · Excellence Screenshare
#>

$ErrorActionPreference = 'Continue'
$esc = [char]27
$script:BrandName = 'Schwarzahn'
$script:ToolName = 'Excellence Screenshare'
$script:Hits = 0
$script:Warns = 0

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
        Warn="$esc[38;2;230;180;50m"; Ice="$esc[38;2;120;170;190m"; Reset="$esc[0m"; Bold="$esc[1m"
    }
    return $script:BloodPalette
}
function Write-BloodBanner {
    param([string]$Subtitle = 'Method')
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

function Write-Section([string]$Text) {
    Enable-AnsiConsole; $c = Get-BloodPalette
    $line = '─' * [Math]::Max(8, (52 - $Text.Length))
    Write-Host ''; Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n")
}
function Write-Ok([string]$t) { Write-Host "[+] $t" -ForegroundColor Green }
function Write-Warn([string]$t) { Write-Host "[!] $t" -ForegroundColor Yellow; $script:Warns++ }
function Write-Bad([string]$t) { Write-Host "[x] $t" -ForegroundColor Red; $script:Hits++ }
function Write-Info([string]$t) { Write-Host "[*] $t" -ForegroundColor DarkGray }
function Write-KV([string]$K, [string]$V) {
    Write-Host ("  {0,-28}" -f $K) -NoNewline -ForegroundColor DarkGray
    Write-Host $V -ForegroundColor White
}
function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Get-BootTime {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $b = $os.LastBootUpTime
        if ($b -is [DateTime]) { return $b }
        return [Management.ManagementDateTimeConverter]::ToDateTime($b)
    } catch { return (Get-Date).AddHours(-24) }
}
function Write-Verdict {
    Write-Section 'VERDICT'
    Write-KV 'Hits' "$script:Hits"
    Write-KV 'Warns' "$script:Warns"
    if ($script:Hits -gt 0) { Write-Bad ("Hits: {0} — corroborate, not auto-ban" -f $script:Hits) }
    else { Write-Ok 'Hits: 0' }
}

$sub = 'Shimcache'
Write-BloodBanner -Subtitle $sub

if (-not (Test-IsAdmin)) {
    Write-Section 'ERROR'
    Write-Bad 'Need Administrator'
    Write-BloodFoot -Subtitle $sub
    return
}


Write-Section 'APPCOMPATCACHE'
$keys = @(
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatibility'
)
foreach ($k in $keys) {
    if (Test-Path $k) {
        Write-Ok $k
        try {
            $item = Get-ItemProperty $k -ErrorAction Stop
            $names = $item.PSObject.Properties.Name | Where-Object { $_ -notmatch '^PS' }
            Write-KV 'Values' ("{0}" -f @($names).Count)
            foreach ($n in $names) {
                if ($n -match '(?i)AppCompatCache|Cache') {
                    $blob = $item.$n
                    if ($blob -is [byte[]]) { Write-KV $n ("blob {0:N0} bytes — parse with AppCompatCacheParser / Shimcache tool" -f $blob.Length) }
                    else { Write-Info ("{0} = {1}" -f $n, $blob) }
                }
            }
        } catch { Write-Warn ("Read fail: {0}" -f $_.Exception.Message) }
    } else { Write-Warn "Missing $k" }
}

Write-Section 'HINT'
Write-Info 'Full parse: Zimmerman AppCompatCacheParser / Detect tools'
$sus = @('java','javaw','powershell','mshta','doomsday','cortex','vape')
Write-Info ("Look for: {0}" -f ($sus -join ', '))


Write-Verdict
Write-BloodFoot -Subtitle $sub
