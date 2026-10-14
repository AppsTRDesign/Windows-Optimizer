# Windows Optimizer

[🇹🇷 Türkçe](README.tr.md) | **🇬🇧 English**

![Windows Optimizer](assets/banner.png)

A modular, open-source performance & privacy tool for Windows 10/11. It disables ads and telemetry, trims background activity and cleans RAM, with a live memory graph so you can **see** the effect of every optimization.

> **Version 3.0** — Game Mode, app remover, network tools, system health, disk analyzer, privacy report, Windows Update control, profiles, system tray and scheduled maintenance. Plus one-click recommended settings and reset to original, services analysis, startup manager, disk cleaner, 49 optimizations including privacy permissions and gaming performance, live RAM monitoring and a safe in-app updater with a progress bar.

## ✨ Features

| Page | What it does |
|------|--------------|
| 🏠 **Overview** | Live CPU / RAM / disk usage with sparklines, system info, optimization score and quick actions |
| ⚡ **Optimizations** | 49 tweaks in 7 categories (including Windows Update control). Each setting's **current state is read from the system**; turning it off restores the Windows default |
| 🧠 **Memory (RAM)** | Live 2-minute stacked graph (in use / modified / standby), one-click cleaning, before/after results, top memory consumers, auto-clean by usage threshold |
| 🎮 **Game Mode** | One click: RAM cleanup, temporary Ultimate Performance plan, silenced notifications and closing selected background apps; everything is restored afterwards |
| 🚀 **Startup** | Every program that runs at boot (registry, Startup folder, scheduled tasks) with icon, publisher and command line; toggle with one click. Compatible with Task Manager |
| 🔧 **Services** | Scans all Windows services and separates Windows components, third-party and unnecessary ones. Explains every suggestion, applies the safe ones in one click, every change can be undone |
| 🧹 **Disk Cleanup** | Capacity cards for all drives; scans temp files, Windows Update cache, browser caches, crash dumps, shader cache and Recycle Bin, shows sizes and cleans the selected ones |
| 🗺️ **Disk Analyzer** | Treemap of folders by size (click to drill in) and the 50 largest files |
| 📦 **Apps** | Remove unnecessary preinstalled apps (News, Clipchamp, Solitaire, Teams…); critical packages are never listed, removed apps can be reinstalled from the Store |
| 🌐 **Network** | Adapter details, DNS speed test with real queries and one-click DNS switching (Cloudflare, Google, Quad9, AdGuard…), DNS flush / IP renew / network reset |
| 🩺 **Health** | Disk SMART info (temperature, SSD wear, power-on hours), 30-day stability summary, SFC and DISM repair with live progress |
| 🔍 **Privacy Report** | Which app accessed the camera, microphone, location and screen capture, and when; live indicator while in use |
| ↩️ **Reset** | The original value of every setting is recorded before its first change; return to the original state or to Windows defaults in one click |
| ⚙️ **Settings** | Profile export/import, system tray and start with Windows, weekly scheduled maintenance, language (TR/EN), update check, shortcut repair, system restore point, log file |

### Optimization categories

- **Ads & Privacy:** File Explorer ads, lock screen tips, Settings suggestions, Windows tips, Welcome Experience, "Finish setting up" nag, Start menu ads & silent app installs, suggested notifications, advertising ID, tailored experiences, activity history
- **Privacy Permissions:** Location, microphone, camera, access to personal data (contacts, calendar, call history, email, messages), app diagnostics, online speech recognition, typing personalization
- **Search, Edge & Copilot:** Bing results in Start search, Edge search bar, Edge suggestions/shopping/sidebar, Windows Copilot, Widgets / News and interests
- **System & Telemetry:** Telemetry (incl. DiagTrack service), Cortana, consumer features, feedback requests, Windows Error Reporting
- **Performance:** Edge background mode & Startup Boost, startup app delay, menu show delay, background Store apps, visual effects, transparency, hibernation, P2P update sharing
- **Gaming Performance:** Game Mode, high CPU/GPU priority for games (MMCSS), Ultimate Performance power plan, hardware-accelerated GPU scheduling, fullscreen optimizations, mouse acceleration, Xbox Game DVR

Settings marked **RECOMMENDED** are safe for most users. **Apply Recommended** on the Overview page enables all of them at once.

### RAM cleaning

Uses the same Windows APIs as RAMMap / MemReduct; no external tools are downloaded.

| Option | Effect |
|--------|--------|
| Empty working sets | Removes pages that processes are not using |
| Flush modified list | Writes pending pages to disk and frees them |
| Purge standby list | Clears the whole cache (biggest effect) |
| Low-priority standby only | Gentler; keeps frequently used cache |
| Flush system file cache | Resets the file system cache |

> Windows uses free RAM as cache (standby), which is normal. Cleaning is most useful before launching a game or heavy app, or when memory is tight.

## 🚀 One-click install

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
```

The installer:
- downloads every file to a temporary folder and verifies it before touching your installation,
- installs to `%USERPROFILE%\Windows-Optimizer` (your `settings.json` is preserved),
- creates **Desktop** and **Start menu** shortcuts that run as administrator without a console window,
- starts the app.

## 🔄 Updating

When a new version is available, a card appears in the sidebar. Click **Update now**:

1. Files are downloaded with a progress bar and verified,
2. the app closes, the new files are copied over the old ones,
3. shortcuts are recreated and the app restarts automatically.

If anything fails, your current installation is left untouched. The update log is written to `%TEMP%\WindowsOptimizer-update.log`.

## 🗑️ Uninstall

```powershell
Remove-Item "$env:USERPROFILE\Windows-Optimizer" -Recurse -Force -ErrorAction SilentlyContinue
```
```powershell
Remove-Item "$([Environment]::GetFolderPath('Desktop'))\Windows Optimizer.lnk", "$([Environment]::GetFolderPath('Programs'))\Windows Optimizer.lnk" -Force -ErrorAction SilentlyContinue
```

Optimizations stay applied after uninstalling. To revert them, turn the toggles off in the app before uninstalling.

## 📁 Project structure

```
Windows-Optimizer/
├── WindowsOptimizer.ps1     # Main app (WPF interface)
├── install.ps1              # Installer / updater for older versions
├── version.json             # Version, release notes, file list
├── config.json              # Author and links
├── assets/
│   ├── logo.png
│   └── banner.png
└── modules/
    ├── Tweaks.ps1           # Optimization catalog + apply/revert engine
    ├── RamCleaner.ps1       # Live memory measurement + cleaning (native API)
    ├── Startup.ps1          # Startup apps manager
    ├── DiskCleaner.ps1      # Drive capacity + junk file cleanup
    ├── Services.ps1         # Background services analysis
    └── Network.ps1          # Network adapters and DNS
pages/                       # Self-contained pages (own UI + logic)
    ├── Game.ps1, Analyzer.ps1, Apps.ps1, Network.ps1
    ├── Health.ps1, Privacy.ps1
    └── Extras.ps1           # Profiles, system tray, scheduled maintenance
    └── Updater.ps1          # Version check, download, shortcuts
```

## ⚠️ Notes

- Requires Windows 10/11 and Windows PowerShell 5.1 (built in). The app asks for administrator rights.
- Creating a **system restore point** (Overview → Quick Actions) before making changes is recommended.
- Some settings take effect after restarting Explorer (the app offers this) or after signing out.
- Logs: `%TEMP%\WindowsOptimizer.log`

## 🔗 Links

- **GitHub:** [AppsTRDesign](https://github.com/AppsTRDesign)
- **Instagram:** [@oztasonur1](https://instagram.com/oztasonur1)
- **Website:** [worldofwar.site](https://worldofwar.site)

---

Made by **AppsTRDesign**
