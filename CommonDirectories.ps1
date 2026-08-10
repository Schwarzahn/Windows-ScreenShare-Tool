#Requires -Version 5.1
<#
.SYNOPSIS
  ScreenShare Tool — common directories snapshot for screenshare.
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

Clear-Host
Write-BloodBanner -Subtitle 'Common Directories'
Write-Section 'PATHS'

$paths = [ordered]@{
    'Desktop'           = [Environment]::GetFolderPath('Desktop')
    'Downloads'         = (Join-Path $env:USERPROFILE 'Downloads')
    'Documents'         = [Environment]::GetFolderPath('MyDocuments')
    'Recent'            = [Environment]::GetFolderPath('Recent')
    'Temp'              = $env:TEMP
    'LocalAppData'      = $env:LOCALAPPDATA
    'RoamingAppData'    = $env:APPDATA
    'Prefetch'          = (Join-Path $env:SystemRoot 'Prefetch')
    'RecycleBin'        = 'C:\$Recycle.Bin'
    'MinecraftMods'     = (Join-Path $env:APPDATA '.minecraft\mods')
    'MinecraftVersions' = (Join-Path $env:APPDATA '.minecraft\versions')
    'MinecraftLogs'     = (Join-Path $env:APPDATA '.minecraft\logs')
    'TLauncher'         = (Join-Path $env:APPDATA '.tlauncher')
    'PrismLauncher'     = (Join-Path $env:APPDATA 'PrismLauncher')
    'LunarClient'       = (Join-Path $env:USERPROFILE '.lunarclient')
    'Badlion'           = (Join-Path $env:APPDATA 'Badlion Client')
    'Feather'           = (Join-Path $env:APPDATA '.feather')
    'Discord'           = (Join-Path $env:APPDATA 'discord')
    'Steam'             = (Join-Path ${env:ProgramFiles(x86)} 'Steam')
}

$rows = foreach ($name in $paths.Keys) {
    $p = $paths[$name]
    $exists = Test-Path -LiteralPath $p
    $count = 0
    $newest = $null
    if ($exists) {
        try {
            $items = @(Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue)
            $count = $items.Count
            $newest = ($items | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        } catch {}
    }
    [pscustomobject]@{
        Name   = $name
        Path   = $p
        Exists = $exists
        Items  = $count
        Newest = $newest
    }
}

foreach ($r in $rows) {
    if ($r.Exists) {
        $n = if ($r.Newest) { $r.Newest.ToString('yyyy-MM-dd HH:mm:ss') } else { '—' }
        Write-Host ("  {0,-18} {1,5} items  newest {2}" -f $r.Name, $r.Items, $n) -ForegroundColor Green
        Write-Host ("                     {0}" -f $r.Path) -ForegroundColor DarkGray
    } else {
        Write-Host ("  {0,-18} missing" -f $r.Name) -ForegroundColor DarkRed
        Write-Host ("                     {0}" -f $r.Path) -ForegroundColor DarkGray
    }
}

Write-Section 'OPEN'
Write-Host '  Out-GridView list (optional)...' -ForegroundColor DarkGray
$rows | Out-GridView -Title ("Common Directories — by {0}" -f $script:BrandName) -PassThru | ForEach-Object {
    if ($_.Exists) { Start-Process explorer.exe $_.Path }
}

Write-BloodFoot -Subtitle 'Common Directories'
