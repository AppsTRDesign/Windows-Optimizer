# install.ps1 - Tek tıkla kurulum betiği
# Kullanım: irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex

$ErrorActionPreference = "Stop"
$installDir = "$env:USERPROFILE\Windows-Optimizer"

Write-Host "Windows Optimizer kuruluyor..." -ForegroundColor Cyan

# 1. Klasörü oluştur
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 2. Modülleri ve config dosyasını indir
$baseUrl = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"
$files = @(
    "modules/AdsBlocker.ps1",
    "modules/FeatureManager.ps1",
    "modules/RamCleaner.ps1",
    "modules/BackgroundManager.ps1",
    "config.json"
)

foreach ($file in $files) {
    $url = "$baseUrl/$file"
    $dest = Join-Path $installDir $file
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Host "  $file indirildi." -ForegroundColor Gray
}

# 3. Masaüstü kısayolu oluştur
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Windows Optimizer.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\modules\AdsBlocker.ps1`""
$Shortcut.WorkingDirectory = $installDir
$Shortcut.Save()

Write-Host "Kurulum tamamlandı! Masaüstündeki kısayoldan çalıştırabilirsiniz." -ForegroundColor Green
