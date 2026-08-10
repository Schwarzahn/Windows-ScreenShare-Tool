#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Alias → Troxil-KakIskat.ps1 (один скрипт на раздел, не гоняй два).
  by Schwarzahn · Excellence Screenshare
#>
$ErrorActionPreference = 'Continue'
$url = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main/Troxil-KakIskat.ps1?cb=' + [guid]::NewGuid().ToString()
Write-Host '[*] TroxilCheck.ps1 → Troxil-KakIskat.ps1 (раздел Troxil)' -ForegroundColor DarkGray
Invoke-Expression (Invoke-RestMethod $url)
