# Windows Optimizer

[🇹🇷 Türkçe](README.tr.md) | English

A modular, open-source optimization tool for Windows 10/11. Disable ads, manage unnecessary features, clean RAM, and control background processes — all with a single click.

![Windows Optimizer](assets/banner.png)

## ✨ Features

| Module | Description |
|--------|-------------|
| 🛡️ **Ads Blocker** | Disables ads in File Explorer, Lock Screen, Start Menu, Settings, and Notifications |
| 🔍 **Feature Manager** | Toggles Bing Search, Telemetry, Cortana, Consumer Features |
| 🧠 **RAM Cleaner** | Clears standby memory using Microsoft RAMMap |
| ⚙️ **Background Manager** | Disables unnecessary background apps |

## 🚀 One-Click Install

Open **PowerShell as Administrator** and run:

# Install
```powershell
irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
```
# Uninstall
```powershell
Remove-Item "$env:USERPROFILE\Windows-Optimizer" -Recurse -Force -ErrorAction SilentlyContinue
```
```powershell
Remove-Item "$env:USERPROFILE\Desktop\Windows Optimizer.lnk" -Force -ErrorAction SilentlyContinue
```
