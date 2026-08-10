#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → Cortex-KakIskat.ps1 (один скрипт на раздел, не гоняй два).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Cortex-KakIskat.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] CortexCheck.ps1 → Cortex-KakIskat.ps1 (раздел Cortex)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
