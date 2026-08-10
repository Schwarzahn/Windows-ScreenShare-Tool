#Requires -Version 5.1
<#
.SYNOPSIS
  База SS: какие буквы дисков и какая ФС (NTFS / FAT32 / exFAT).
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

function Ok($t) { Write-Host "[+] $t" -ForegroundColor Green }
function Bad($t) { Write-Host "[x] $t" -ForegroundColor Red }
function Warn($t) { Write-Host "[!] $t" -ForegroundColor Yellow }
function Info($t) { Write-Host "[*] $t" -ForegroundColor DarkGray }
function Sec($t) { Write-Host ""; Write-Host "══ $t ══" -ForegroundColor DarkRed }

Start-SsReport 'DriveFsQuick'
Write-Host ""
Write-Host "SCHWARZAHN · Drive FS (NTFS / FAT32 / exFAT)" -ForegroundColor Red
Write-Host "База: сначала ФС тома, потом Journal / replace" -ForegroundColor DarkGray

Sec 'VOLUMES'
$rows = @()
try {
    $rows = @(Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter } |
        Sort-Object DriveLetter |
        Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus,
            @{n='SizeGB';e={[math]::Round(($_.Size/1GB),1)}},
            @{n='FreeGB';e={[math]::Round(($_.SizeRemaining/1GB),1)}})
} catch {
    Warn 'Get-Volume failed — fallback Win32_LogicalDisk'
}

if (-not $rows -or $rows.Count -eq 0) {
    Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
        $fs = $_.FileSystem
        $line = ("{0}  FS={1}  {2}  size={3:N0}MB free={4:N0}MB" -f $_.DeviceID, $fs, $_.VolumeName, ($_.Size/1MB), ($_.FreeSpace/1MB))
        if ($fs -match '(?i)^NTFS$') { Ok $line }
        elseif ($fs -match '(?i)FAT|exFAT') { Warn $line }
        else { Info $line }
    }
} else {
    foreach ($r in $rows) {
        $fs = [string]$r.FileSystem
        $line = ("{0}:  [{1}]  label={2}  {3}/{4} GB  {5}" -f $r.DriveLetter, $fs, $r.FileSystemLabel, $r.FreeGB, $r.SizeGB, $r.HealthStatus)
        if ($fs -match '(?i)^NTFS$') { Ok $line }
        elseif ($fs -match '(?i)FAT|exFAT') { Warn $line }
        elseif ([string]::IsNullOrWhiteSpace($fs)) { Bad ("{0}:  FS=UNKNOWN/RAW" -f $r.DriveLetter) }
        else { Info $line }
    }
}

Sec 'HINTS'
Info 'NTFS → JournalTrace++ / MFT / ADS ок'
Info 'FAT32/exFAT → USN нет; Prefetch+BAM по букве + осмотр тома; replace часто тут'
Info 'Мануал: Windows/Мануалы/Windows/Основы/Файловые системы.md'

$fat = @()
try {
    $fat = @(Get-Volume -EA SilentlyContinue | Where-Object { $_.DriveLetter -and $_.FileSystem -match '(?i)FAT' })
} catch {}
if ($fat.Count -gt 0) {
    Bad ("FAT/exFAT томов: {0} — не жди USN на них" -f $fat.Count)
} else {
    Ok 'Среди букв нет FAT/exFAT (или Get-Volume пуст)'
}

Write-Host ""
Stop-SsReport
