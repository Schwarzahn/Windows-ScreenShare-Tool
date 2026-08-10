#Requires -Version 5.1
<#
.SYNOPSIS
  ScreenShare Tool — detect/kill capture & forbidden processes.
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
        ShadowFar  = "$esc[38;2;35;0;0m"
        ShadowNear = "$esc[38;2;80;0;0m"
        Mid        = "$esc[38;2;150;0;0m"
        Blood      = "$esc[38;2;200;10;10m"
        Hot        = "$esc[38;2;255;35;35m"
        Glow       = "$esc[38;2;255;90;90m"
        Drip       = "$esc[38;2;130;0;0m"
        Dim        = "$esc[38;2;85;85;85m"
        Soft       = "$esc[38;2;170;170;170m"
        Green      = "$esc[38;2;80;220;120m"
        Reset      = "$esc[0m"
        Bold       = "$esc[1m"
    }
    return $script:BloodPalette
}

function Write-BloodBanner {
    param([string]$Subtitle = 'ScreenShare Tool')
    Enable-AnsiConsole
    $c = Get-BloodPalette
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
    foreach ($line in $art) { Write-Ansi ("   $($c.ShadowFar)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    foreach ($line in $art) { Write-Ansi ("  $($c.ShadowNear)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    for ($i = 0; $i -lt $art.Count; $i++) { Write-Ansi ("$($grad[$i])$($art[$i])$($c.Reset)`n") }
    Write-Ansi ("$($c.Drip)  ║  ║    ║║      ║   ║║║     ║  ║    ║║     ║  ║   ║$($c.Reset)`n")
    Write-Ansi ("$($c.Drip)  ┘  ░    ░░   ▄  ▘   ░░░  ▄  ▘  ░    ░░  ▄  ▘   ▘$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 72))$($c.Reset)`n")
    $tag = "by $script:BrandName"
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}

function Write-BloodFoot {
    param([string]$Subtitle = 'ScreenShare Tool')
    Enable-AnsiConsole
    $c = Get-BloodPalette
    $tag = "by $script:BrandName"
    Write-Host ''
    Write-Ansi ("$($c.ShadowFar)  $($('═' * 64))$($c.Reset)`n")
    Write-Ansi ("$($c.ShadowFar)   $tag$($c.Reset)`n")
    Write-Ansi ("$esc[1A$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Dim)$Subtitle$($c.Reset)`n")
    Write-Host ''
}

function Write-Section([string]$Text) {
    Enable-AnsiConsole
    $c = Get-BloodPalette
    $line = '─' * [Math]::Max(8, (58 - $Text.Length))
    Write-Host ''
    Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n")
}

Clear-Host
$forbiddenProcesses = @(
    "chrome","firefox","msedge","opera","opera_gx","brave","vivaldi",
    "browser","waterfox","librewolf","palemoon","tor","torbrowser",
    "chromium","ungoogled-chromium","epicbrowser","slimjet","comodo",

    "obs","obs32","obs64","streamlabs","camtasia","bandicam","xsplit",
    "fraps","action","dxtory","sharex","screenrec","flashback", "bdcam",

    "gamebar","xboxgamebar","gamebarpresencewriter","broadcastdvr",
    "discord","discordcanary","discordptb","steam","steamwebhelper",
    "overwolf","teams","riotclientservices","epicgameslauncher",

    "nvcontainer","nvdisplay.container","nvidiashare","nvbackend",
    "nvsphelper64","nvstreamer","nvtray","nvtelemetry","nvfbc","nvifrex",

    "amdsoftware","radeonsoftware","amdxcapture","amdenc","amddvr"
)

Clear-Host
Write-BloodBanner -Subtitle 'Kill Screen Processes'
Write-Section 'DETECT'
$detected = @{}
$allProcs = Get-Process -ErrorAction SilentlyContinue

foreach ($proc in $allProcs) {
    try {
        $name = $proc.Name.ToLower()
        $isForbidden = $forbiddenProcesses -contains $name
        $isCapture = $false

        $modules = $proc.Modules.ModuleName
        if (
            $modules -contains "Windows.Graphics.Capture.dll" -or
            $modules -match "graphicscapture" -or
            $modules -match "nvencodeapi" -or
            $modules -match "amdenc|amf"
        ) {
            $isCapture = $true
        }

        if (($isForbidden -or $isCapture) -and -not $detected.ContainsKey($name)) {
            $detected[$name] = @{
                Name = $proc.Name
                Type = if ($isForbidden -and $isCapture) {
                    "Capture + Forbidden"
                } elseif ($isCapture) {
                    "Screen Capture"
                } else {
                    "Forbidden Process"
                }
            }
        }
    } catch {}
}

if ($detected.Count -eq 0) {
    Write-Host "[+] No forbidden or capture processes detected." -ForegroundColor Green
    exit
}

Write-Host "[!] Detected processes:" -ForegroundColor Yellow
Write-Host ""

foreach ($item in $detected.Values) {
    Write-Host ("  - {0}.exe [{1}]" -f $item.Name, $item.Type) -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[A] Kill all detected processes."
Write-Host "[B] Kill 1 specific process."
Write-Host "[C] Kill all except 1 process."
Write-Host ""

$choice = Read-Host "Select option (A / B / C)"

switch ($choice.ToUpper()) {

    "A" {
        foreach ($item in $detected.Values) {
            Get-Process -Name $item.Name -ErrorAction SilentlyContinue |
                Stop-Process -Force
            Write-Host "[Terminated] $($item.Name).exe" -ForegroundColor Red
        }
    }

    "B" {
        $target = Read-Host "Enter process name (example: chrome or chrome.exe)"
        $target = $target.ToLower().Replace(".exe","")

        if ($detected.ContainsKey($target)) {
            Get-Process -Name $target -ErrorAction SilentlyContinue |
                Stop-Process -Force
            Write-Host "[Terminated] $target.exe" -ForegroundColor Red
        } else {
            Write-Host "[Error] Process not found." -ForegroundColor Red
        }
    }

    "C" {
        $exclude = Read-Host "Enter process name to keep alive (example: chrome or chrome.exe)"
        $exclude = $exclude.ToLower().Replace(".exe","")

        if (-not $detected.ContainsKey($exclude)) {
            Write-Host "[Error] Process not found." -ForegroundColor Red
            exit
        }

        foreach ($key in $detected.Keys) {
            if ($key -ne $exclude) {
                Get-Process -Name $key -ErrorAction SilentlyContinue |
                    Stop-Process -Force
                Write-Host "[Terminated] $key.exe" -ForegroundColor Red
            }
        }

        Write-Host "[+] Kept alive: $exclude.exe" -ForegroundColor Green
    }
}

Write-BloodFoot -Subtitle 'Kill Screen Processes'
