#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Автоматизация заметки «Как искать DoomsDay» — диск/BAM/Prefetch (SI Memory — вручную).
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
Write-Host "SCHWARZAHN · Как искать · DoomsDay" -ForegroundColor Red
Write-Host "Зеркало Obsidian-заметки (автоматизируемые шаги)" -ForegroundColor DarkGray

# ——— 1. Живой MC / SI (не автоматизируем dump) ———
Sec '1) System Informer (вручную)'
Info 'Открой SI Admin → javaw → Strings / Modules'
$si = @('doomsday', 'mz42dq', 'VURwU', 'JavaLauncher')
foreach ($s in $si) { Info ("Ищи строку: {0}" -f $s) }
Info 'Модули: чужие .dll / лоадер рядом по времени'

# ——— 2. Файловый поиск (Everything-аналог) ———
Sec '2) Файлы exe/jar (как Everything)'
$needles = @('doomsday', 'DoomsDay', 'mz42dq', 'VURwU', 'JavaLauncher')
$roots = @()
foreach ($r in @(
    $env:USERPROFILE,
    (Join-Path $env:USERPROFILE 'Downloads'),
    (Join-Path $env:USERPROFILE 'Desktop'),
    (Join-Path $env:APPDATA '.minecraft'),
    $env:TEMP,
    'C:\'
)) {
    if ($r -eq 'C:\') { continue } # too heavy full C
    if (Test-Path $r) { $roots += $r }
}
# also other users Downloads
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
            ($_.Extension -match '(?i)\.(exe|jar|dll|zip|7z|rar)$' -or $_.Name -match '(?i)doomsday|javalauncher|mz42')
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
if ($foundPaths.Count -eq 0) { Ok 'Файлов по иглам не найдено (45д, ограниченные корни)' }

# ——— 3. BAM ———
Sec '3) BAM (тот же путь / иглы)'
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
                    if ($path.IndexOf($fp, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $match = $true }
                    $leaf = [IO.Path]::GetFileName($fp)
                    if ($leaf -and $path.IndexOf($leaf, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $match = $true }
                }
                if ($match) {
                    Bad ("BAM  {0}  SID={1}" -f $path, $sid)
                    $bamHits++
                }
            }
        } catch {}
    }
    if ($bamHits -eq 0) { Ok 'BAM: нет путей с иглами / найденными файлами' }
} else { Warn 'BAM ключ недоступен' }
Info 'BamDeletedKeys (spokwn) — если ключи чистили'

# ——— 4. Prefetch ———
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
            if ($ageH -le 12 -or ($n -match '(?i)doomsday|javalauncher|mz42')) { Bad $line } else { Ok $line }
            $pfShown++
        }
    }
    if ($pfShown -eq 0) { Ok 'Prefetch: нет совпадений по иглам/java' }
} else { Bad 'Prefetch папка отсутствует' }

# ——— 5. После wipe ———
Sec '5) После wipe — чеклист'
Info 'Self Destruct → файла может не быть. Смотри дальше:'
Info '  Prefetch (выше) · BAM · BamDeletedKeys · Amcache · USN · ShellBags/Recent'
$am = Join-Path $env:SystemRoot 'AppCompat\Programs\Amcache.hve'
if (Test-Path $am) {
    $i = Get-Item $am
    Ok ("Amcache.hve mtime {0:yyyy-MM-dd HH:mm}" -f $i.LastWriteTime)
} else { Warn 'Amcache.hve не найден' }
$recent = [Environment]::GetFolderPath('Recent')
if (Test-Path $recent) {
    $rh = 0
    Get-ChildItem $recent -Filter '*.lnk' -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 80 | ForEach-Object {
        foreach ($n in $needles) {
            if ($_.Name.IndexOf($n, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                Bad ("Recent  {0:yyyy-MM-dd HH:mm}  {1}" -f $_.LastWriteTime, $_.Name)
                $rh++
            }
        }
    }
    if ($rh -eq 0) { Ok 'Recent: нет lnk с иглами' }
}


Sec '6) Службы + полный детектор'
$pca = Get-Service PcaSvc -EA SilentlyContinue
if ($pca -and $pca.Status -eq 'Running') { Ok 'PcaSvc Running' } else { Bad 'PcaSvc не Running — строки jar слабее' }
$mods = Join-Path $env:APPDATA '.minecraft\mods'
if (Test-Path $mods) {
    Get-ChildItem $mods -File -EA SilentlyContinue | Where-Object { $_.Name -match '(?i)optifine|doomsday' } | ForEach-Object {
        Warn ("mods  {0}  (проверь Montegs / строки)" -f $_.Name)
    }
}


Sec 'Связка / вердикт'
Info 'Строка в javaw ИЛИ файл в BAM/Prefetch + время ≈ Minecraft. Один Everything-хит мало.'
Write-Host ("Hits={0}  Warns={1}" -f $script:Hits, $script:Warns) -ForegroundColor $(if ($script:Hits -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

Sec '7) DoomsDayDetector (авто)'
Info 'Тяну полный DoomsDayDetector — один прогон, без второго one-liner'
try {
    $dd = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/DoomsDayDetector.ps1?cb=' + [guid]::NewGuid().ToString()
    Invoke-Expression (Invoke-RestMethod $dd)
} catch {
    Warn ("Не скачался DoomsDayDetector: {0}" -f $_.Exception.Message)
    Info 'Локально: DoomsDayDetector.ps1 / Meow Doomsday Fucker'
}
