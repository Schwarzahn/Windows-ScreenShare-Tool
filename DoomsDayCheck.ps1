#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → DoomsDay-KakIskat.ps1 (один скрипт на раздел, не гоняй два).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/DoomsDay-KakIskat.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] DoomsDayCheck.ps1 → DoomsDay-KakIskat.ps1 (раздел DoomsDay + Detector)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
