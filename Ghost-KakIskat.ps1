#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Автоматизация «Как искать Ghost / другие» — диск/BAM/Prefetch (SI Memory — вручную).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$script:Hits = 0
$script:Warns = 0
function Ok($t) { Write-Host "[+] $t" -ForegroundColor Green }
function Bad($t) { Write-Host "[x] $t" -ForegroundColor Red; $script:Hits++ }
function Warn($t) { Write-Host "[!] $t" -ForegroundColor Yellow; $script:Warns++ }
function Info($t) { Write-Host "[*] $t" -ForegroundColor DarkGray }
function Sec($t) { Write-Host ""; Write-Host "══ $t ══" -ForegroundColor DarkRed }

Write-Host ""
Write-Host "SCHWARZAHN · Как искать · Ghost / others" -ForegroundColor Red
Write-Host "Зеркало Obsidian: один прогон (файлы · BAM · Prefetch)" -ForegroundColor DarkGray

Sec '1) System Informer (вручную)'
Info 'Открой SI Admin → javaw → Strings / Modules'
$si = @('slinky','novoware','nursultan','wexside','melonity','celestial','ntfloader')
foreach ($s in $si) { Info ("Ищи строку: {0}" -f $s) }

Sec '2) Файлы (имя / путь)'
$needles = @('slinky','novoware','nursultan','wexside','melonity','celestial','ntfloader','wexaid')
$roots = @()
foreach ($r in @(
    $env:USERPROFILE,
    (Join-Path $env:USERPROFILE 'Downloads'),
    (Join-Path $env:USERPROFILE 'Desktop'),
    (Join-Path $env:APPDATA '.minecraft'),
    (Join-Path $env:USERPROFILE 'AppData\LocalLow'),
    $env:TEMP
)) { if (Test-Path $r) { $roots += $r } }
try {
    Get-ChildItem 'C:\Users' -Directory -EA SilentlyContinue | ForEach-Object {
        $d = Join-Path $_.FullName 'Downloads'
        if (Test-Path $d) { $roots += $d }
    }
} catch {}
$roots = $roots | Select-Object -Unique
$foundPaths = New-Object System.Collections.Generic.List[string]
$cutoff = (Get-Date).AddDays(-45)
foreach ($root in $roots) {
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -EA SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -ge $cutoff -and
            ($_.Extension -match '(?i)\.(exe|jar|dll|zip|7z|rar)$' -or $_.Name -match '(?i)slinky|novo|nursultan|wex|melon|celestial|ntf')
        } |
        Select-Object -First 4000 |
        ForEach-Object {
            $hit = $false
            foreach ($n in $needles) {
                if ($_.Name.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                    $_.FullName.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $hit = $true; break
                }
            }
            if ($hit) {
                Bad ("{0:yyyy-MM-dd HH:mm}  {1}" -f $_.LastWriteTime, $_.FullName)
                [void]$foundPaths.Add($_.FullName)
            }
        }
}
if ($foundPaths.Count -eq 0) { Ok 'Файлов по иглам не найдено (45д)' }

$ntf = Join-Path $env:USERPROFILE 'AppData\LocalLow\NTFLoader'
if (Test-Path -LiteralPath $ntf) { Bad ("NTFLoader: {0}" -f $ntf) } else { Ok 'Нет AppData\LocalLow\NTFLoader' }

Sec '3) BAM'
$bamRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings'
$bamHits = 0
if (Test-Path $bamRoot) {
    Get-ChildItem $bamRoot -EA SilentlyContinue | ForEach-Object {
        $sid = $_.PSChildName
        try {
            $props = Get-ItemProperty -LiteralPath $_.PSPath -EA Stop
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Name -match '^PS') { continue }
                $path = [string]$p.Name
                $match = $false
                foreach ($n in $needles) {
                    if ($path.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $match = $true; break }
                }
                foreach ($fp in $foundPaths) {
                    $leaf = [IO.Path]::GetFileName($fp)
                    if ($leaf -and $path.IndexOf($leaf, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $match = $true }
                }
                if ($match) { Bad ("BAM  {0}  SID={1}" -f $path, $sid); $bamHits++ }
            }
        } catch {}
    }
    if ($bamHits -eq 0) { Ok 'BAM: нет путей с иглами' }
} else { Warn 'BAM ключ недоступен' }

Sec '4) Prefetch'
$pf = Join-Path $env:SystemRoot 'Prefetch'
if (Test-Path $pf) {
    $pfShown = 0
    Get-ChildItem $pf -Filter '*.pf' -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | ForEach-Object {
        $n = $_.Name
        $interesting = $false
        foreach ($x in $needles) { if ($n.IndexOf($x, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $interesting = $true } }
        if ($n -match '(?i)^JAVAW|^JAVA|^POWERSHELL|^PWSH') { $interesting = $true }
        foreach ($fp in $foundPaths) {
            $leaf = [IO.Path]::GetFileNameWithoutExtension($fp)
            if ($leaf.Length -ge 3 -and $n.IndexOf($leaf, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $interesting = $true }
        }
        if ($interesting) {
            $ageH = ((Get-Date) - $_.LastWriteTime).TotalHours
            $line = ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $_.LastWriteTime, $n)
            if ($ageH -le 12) { Bad $line } else { Ok $line }
            $pfShown++
        }
    }
    if ($pfShown -eq 0) { Ok 'Prefetch: нет совпадений' }
} else { Bad 'Prefetch папка отсутствует' }

Sec '5) После wipe'
Info 'Prefetch · BAM · BamDeletedKeys · Amcache · USN · ShellBags/Recent'
$am = Join-Path $env:SystemRoot 'AppCompat\Programs\Amcache.hve'
if (Test-Path $am) { Ok ("Amcache.hve mtime {0:yyyy-MM-dd HH:mm}" -f (Get-Item $am).LastWriteTime) }

Sec 'Связка'
Info 'Строка в javaw ИЛИ BAM/Prefetch + время ≈ MC. Один filename-хит мало.'
Info 'Cortex/Vape/Troxil/DoomsDay — свои разделы (отдельный one-liner).'
Write-Host ("Hits={0}  Warns={1}" -f $script:Hits, $script:Warns) -ForegroundColor $(if ($script:Hits -gt 0) { 'Red' } else { 'Green' })
Write-Host ""
