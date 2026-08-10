#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → полный FilelessDetector (не нужен отдельный light-check).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/FilelessDetector.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] FilelessCheck → FilelessDetector (всё в одном)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
