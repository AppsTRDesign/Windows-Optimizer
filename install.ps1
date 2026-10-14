$ErrorActionPreference = "Stop"
$installDir = "$env:USERPROFILE\Windows-Optimizer"
$baseUrl    = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"

Write-Host "Windows Optimizer kuruluyor..." -ForegroundColor Cyan

# Eski kurulumu temizle
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# 1) Dosyaları indir
$files = @(
  "WindowsOptimizer.ps1",
  "config.json",
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

        # >>> KRİTİK: PS 5.1 için UTF-8 BOM'lu olarak yeniden yaz <<<
        if ($f -match '\.(ps1|json)$') {
            $txt = [System.IO.File]::ReadAllText($dest, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($dest, $txt, (New-Object System.Text.UTF8Encoding $true))
        }
        Write-Host "  [OK] $f" -ForegroundColor Gray
    } catch {
        Write-Host "  [XX] $f  ($($_.Exception.Message))" -ForegroundColor Red
    }
}

# 2) assets/logo.png  ->  assets/logo.ico   (DÜZELTİLDİ)
$png = Join-Path $installDir "assets\logo.png"
$ico = Join-Path $installDir "assets\logo.ico"

if (Test-Path $png) {
    try {
        Add-Type -AssemblyName System.Drawing
        $src   = [System.Drawing.Image]::FromFile($png)

        # PNG'yi 256x256'ya ölçekle (ico için ideal)
        $bmp   = New-Object System.Drawing.Bitmap($src, 256, 256)
        $hicon = $bmp.GetHicon()
        $icon  = [System.Drawing.Icon]::FromHandle($hicon)

        $fs = [System.IO.File]::Create($ico)
        $icon.Save($fs)
        $fs.Close()

        $src.Dispose(); $bmp.Dispose()
        Write-Host "  [OK] assets/logo.ico olusturuldu" -ForegroundColor Gray
    } catch {
        Write-Host "  [!!] logo.ico olusturulamadi: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [!!] assets/logo.png bulunamadi" -ForegroundColor Yellow
}

# 3) Execution Policy
try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force } catch {}

# 4) Masaüstü kısayolu (DÜZELTİLDİ - icon index eklendi)
$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "Windows Optimizer.lnk"

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath       = "powershell.exe"
$sc.Arguments        = "-NoExit -ExecutionPolicy Bypass -File `"$installDir\WindowsOptimizer.ps1`""
$sc.WorkingDirectory = $installDir
$sc.Description      = "Windows Optimizer - Modular Tweaker"

# Icon path + index (",0" şart!)
if (Test-Path $ico) {
    $sc.IconLocation = "$ico,0"
    Write-Host "  [OK] Kisayol ikonu: logo.ico" -ForegroundColor Gray
} else {
    Write-Host "  [!!] Kisayol ikonu atanamadi (ico yok)" -ForegroundColor Yellow
}
$sc.Save()

Write-Host ""
Write-Host "Kurulum tamamlandi!" -ForegroundColor Green
Write-Host "Masaustundeki 'Windows Optimizer' kisayolundan acabilirsiniz." -ForegroundColor Yellow
Write-Host "(Ilk acilista UAC izni isteyecek - Evet deyin.)" -ForegroundColor DarkGray
