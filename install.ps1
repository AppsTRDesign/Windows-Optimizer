$ErrorActionPreference = "Stop"
$installDir = "$env:USERPROFILE\Windows-Optimizer"
$baseUrl    = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"

Write-Host "Windows Optimizer kuruluyor..." -ForegroundColor Cyan

# Ayar dosyalarını yedekle (varsa)
$preserve = @("backup.json","settings.json")
$backupTemp = @{}
foreach ($p in $preserve) {
    $src = Join-Path $installDir $p
    if (Test-Path $src) { $backupTemp[$p] = Get-Content $src -Raw -Encoding UTF8 }
}

if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

$files = @(
  "WindowsOptimizer.ps1",
  "config.json",
  "version.json",
  "assets/logo.png",
  "assets/banner.png",
  "modules/AdsBlocker.ps1",
  "modules/FeatureManager.ps1",
  "modules/RamCleaner.ps1",
  "modules/BackgroundManager.ps1"
)

foreach ($f in $files) {
    $rel  = $f -replace '/','\'
    $dest = Join-Path $installDir $rel
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    try {
        Invoke-WebRequest -Uri "$baseUrl/$f" -OutFile $dest -UseBasicParsing
        if ($f -match '\.(ps1|json)$') {
            $txt = [System.IO.File]::ReadAllText($dest, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($dest, $txt, (New-Object System.Text.UTF8Encoding $true))
        }
        Write-Host "  [OK] $f" -ForegroundColor Gray
    } catch { Write-Host "  [XX] $f ($($_.Exception.Message))" -ForegroundColor Red }
}

# Yedekleri geri koy
foreach ($p in $backupTemp.Keys) {
    [System.IO.File]::WriteAllText((Join-Path $installDir $p), $backupTemp[$p], (New-Object System.Text.UTF8Encoding $true))
}

# icon dönüşümü
$png = Join-Path $installDir "assets\logo.png"
$ico = Join-Path $installDir "assets\logo.ico"
if (Test-Path $png) {
    try {
        Add-Type -AssemblyName System.Drawing
        $src = [System.Drawing.Image]::FromFile($png)
        $bmp = New-Object System.Drawing.Bitmap($src, 256, 256)
        $hicon = $bmp.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($hicon)
        $fs = [System.IO.File]::Create($ico); $icon.Save($fs); $fs.Close()
        $src.Dispose(); $bmp.Dispose()
        Write-Host "  [OK] assets/logo.ico" -ForegroundColor Gray
    } catch { Write-Host "  [!!] logo.ico: $($_.Exception.Message)" -ForegroundColor Yellow }
}

try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force } catch {}

$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "Windows Optimizer.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath       = "powershell.exe"
$sc.Arguments        = "-NoExit -ExecutionPolicy Bypass -File `"$installDir\WindowsOptimizer.ps1`""
$sc.WorkingDirectory = $installDir
$sc.Description      = "Windows Optimizer - Modular Tweaker"
if (Test-Path $ico) { $sc.IconLocation = "$ico,0" }
$sc.Save()

Write-Host ""
Write-Host "Kurulum tamamlandi!" -ForegroundColor Green