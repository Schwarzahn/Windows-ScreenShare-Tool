#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → полный FilelessDetector (один скрипт на всю заметку «Как искать»).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/FilelessDetector.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] Fileless-KakIskat → FilelessDetector (всё в одном)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
