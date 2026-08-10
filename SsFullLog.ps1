#Requires -Version 5.1
<#
.SYNOPSIS
  Общие хелперы полного SS-лога → Desktop\Schwarzahn-SS-Logs\
  Подключай в начале скрипта:  . { iex ... }  или копируй функции.
  by Schwarzahn · Excellence Screenshare
#>

function Get-SsLogDir {
    $dir = Join-Path $env:USERPROFILE 'Desktop\Schwarzahn-SS-Logs'
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    return $dir
}

function Start-SsReport {
    param([Parameter(Mandatory)][string]$Name)
    $dir = Get-SsLogDir
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:SsReportName = $Name
    $script:SsReportPath = Join-Path $dir ("{0}_{1}.log" -f $Name, $stamp)
    $script:SsReportCsv = Join-Path $dir ("{0}_{1}.csv" -f $Name, $stamp)
    $script:SsReportTxt = Join-Path $dir ("{0}_{1}.txt" -f $Name, $stamp)
    try {
        Start-Transcript -Path $script:SsReportPath -Force | Out-Null
    } catch {
        # already in transcript — append marker
        Add-Content -LiteralPath $script:SsReportPath -Value ("# resume {0}" -f (Get-Date)) -ErrorAction SilentlyContinue
    }
    Write-Host ("[*] FULL SS LOG → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
    Write-Host '[*] Консоль = кратко. Файл на Desktop = полный лог для SS.' -ForegroundColor DarkGray
}

function Stop-SsReport {
    try { Stop-Transcript | Out-Null } catch {}
    if ($script:SsReportPath -and (Test-Path -LiteralPath $script:SsReportPath)) {
        Write-Host ""
        Write-Host ("[*] FULL SS LOG SAVED → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
        Write-Host ("[*] Папка: {0}" -f (Get-SsLogDir)) -ForegroundColor Cyan
    }
}

function Export-SsTable {
    param(
        [Parameter(Mandatory)]$Data,
        [string]$Label = 'export'
    )
    if (-not $Data) { return $null }
    $dir = Get-SsLogDir
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = if ($script:SsReportName) { $script:SsReportName } else { 'Export' }
    $csv = Join-Path $dir ("{0}_{1}_{2}.csv" -f $name, $Label, $stamp)
    try {
        $Data | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
        Write-Host ("[*] CSV ({0} rows) → {1}" -f @($Data).Count, $csv) -ForegroundColor Cyan
        return $csv
    } catch {
        Write-Host ("[!] CSV fail: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        return $null
    }
}

# If run directly — explain
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch '^\s*\.') {
    Write-Host 'SsFullLog.ps1 — хелпер. Скрипты кита уже пишут лог в Desktop\Schwarzahn-SS-Logs\' -ForegroundColor DarkGray
    Write-Host ("Папка: {0}" -f (Get-SsLogDir)) -ForegroundColor Cyan
}
