#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → Ghost-KakIskat.ps1 (один скрипт на раздел, не гоняй два).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Ghost-KakIskat.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] GhostOthersCheck.ps1 → Ghost-KakIskat.ps1 (раздел Ghost)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
