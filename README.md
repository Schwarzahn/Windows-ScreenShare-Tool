# ScreenShare Scripts by Schwarzahn

PowerShell-скрипты для скриншара в кровавом стиле **by Schwarzahn**.

Репозиторий: https://github.com/Schwarzahn/ScreenShare-Scripts

Запускать от **администратора** (где требуется).

## Core

| Файл | Назначение |
|------|------------|
| `Service-Enabler.ps1` | Включение критичных служб + Prefetch/BAM |
| `Services.ps1` | SERVICE STATUS, PS logging, BAM/Prefetch, verdict |
| `DoomsDayDetector.ps1` | Doomsday Client scanner (Prefetch) |

## Mods

| Файл | Назначение |
|------|------------|
| `ModAnalyzer.ps1` | Анализ модов (Meow + Habibi: Modrinth/Megabase/strings) |

## Forensics / SS utils

| Файл | Назначение |
|------|------------|
| `BamViewer.ps1` | BAM viewer |
| `SignaturesParser.ps1` | Парсер подписей файлов |
| `Streams.ps1` | Zone.Identifier / ADS streams |
| `CommonDirectories.ps1` | Частые директории (Minecraft/Discord/Recent/…) |
| `HotspotLogs.ps1` | Hotspot / ICS / WLAN event logs |
| `ManualTasks.ps1` | Ручные scheduled tasks текущего юзера |
| `KillScreenProcesses.ps1` | Детект/килл capture & forbidden процессов |

## Запуск (копируй)

**Services**
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/Services.ps1)
```

**Service-Enabler**
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/Service-Enabler.ps1)
```

**DoomsDayDetector**
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/DoomsDayDetector.ps1)
```

**ModAnalyzer**
```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/ModAnalyzer.ps1')"
```

**BamViewer**
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/BamViewer.ps1)
```

**SignaturesParser**
```powershell
powershell -command "irm 'https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/SignaturesParser.ps1' | iex"
```

**Streams**
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/Streams.ps1)
```

**CommonDirectories**
```powershell
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/CommonDirectories.ps1')"
```

**HotspotLogs**
```powershell
powershell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/HotspotLogs.ps1 | iex"
```

**ManualTasks**
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/ManualTasks.ps1')"
```

**KillScreenProcesses**
```powershell
powershell -command "irm 'https://raw.githubusercontent.com/Schwarzahn/ScreenShare-Scripts/refs/heads/main/KillScreenProcesses.ps1' | iex"
```

by Schwarzahn
