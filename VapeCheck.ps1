#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → Vape-KakIskat.ps1 (один скрипт на раздел, не гоняй два).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Vape-KakIskat.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] VapeCheck.ps1 → Vape-KakIskat.ps1 (раздел Vape)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
