#Requires -Version 5.1
<#
.SYNOPSIS
  ScreenShare Tool — Zone.Identifier / ADS streams scanner.
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
Write-BloodBanner -Subtitle 'Streams / ADS'
Write-Section 'SCAN'

$response = Read-Host "Do you want to search recursively in subdirectories? (y/n)"
$Folder = (Get-Location).Path


if ($response -match '^(y|yes)$') {
    $levels = Read-Host "How many levels of subdirectories do you want to search? Enter a number or type 'all' for all subdirectories"
    if ($levels -match '^(all)$') {
        $Files = Get-ChildItem -Path $Folder -Recurse -ErrorAction Ignore
    } elseif ($levels -match '^\d+$') {
        $Files = Get-ChildItem -Path $Folder -Recurse -Depth ([int]$levels) -ErrorAction Ignore
    } else {
        Write-Host "Invalid input. Proceeding with unlimited recursion." -ForegroundColor Yellow
        $Files = Get-ChildItem -Path $Folder -Recurse -ErrorAction Ignore
    }
} else {
    $Files = Get-ChildItem -Path $Folder -ErrorAction Ignore
}

$i = 0

$results = ForEach ($File in $Files) {
    $i++
    try {
        $Stream = (Get-Item -LiteralPath $File.FullName -Stream *).Stream | Out-String | ConvertFrom-String -PropertyNames St1, St2, St3, St4, St5
    } catch {
        $Stream = ""
    }

    try {
        $Zone = Get-Content -Stream Zone.Identifier -LiteralPath $File.FullName -ErrorAction Ignore | Out-String | ConvertFrom-String -PropertyNames Z1, Z2, Z3, Z4, Z5
    } catch {
        $Zone = ""
    }

    try {
        $hashMD5 = (Get-FileHash -LiteralPath $File.FullName -Algorithm MD5 -ErrorAction Ignore).Hash
    } catch {
        $hashMD5 = ""
    }

    Write-Progress -Activity "Collecting information for File: $File" -Status "File $i of $($Files.Count)" -PercentComplete (($i / $Files.Count) * 100)

    [PSCustomObject]@{ 
        Path                  = Split-Path -LiteralPath $File.FullName 
        'File/Directory Name' = $File.Name
        'MD5 Hash (File Hash only)' = $hashMD5
        'Owner (name/sid)'    = (Get-Acl -LiteralPath $File.FullName).Owner
        Length                = (Get-ChildItem -LiteralPath $File.FullName -Force).Length
        LastAccessTime        = (Get-ItemProperty -LiteralPath $File.FullName).LastAccessTime
        LastWriteTime         = (Get-ItemProperty -LiteralPath $File.FullName).LastWriteTime
        Attributes            = (Get-ItemProperty -LiteralPath $File.FullName).Mode
        Stream1               = $Stream.St1
        Stream2               = $Stream.St2
        Stream3               = $Stream.St3
        Stream4               = $Stream.St4
        ZoneId1               = $Zone.Z2
        ZoneId2               = $Zone.Z3
        ZoneId3               = $Zone.Z4
        ZoneId4               = $Zone.Z5
    }
}

$finalOutput = $results | Out-GridView -PassThru -Title "Zone.Identifier stream contents for files in folder $Folder"

[gc]::Collect()

Write-BloodFoot -Subtitle 'Streams / ADS'
