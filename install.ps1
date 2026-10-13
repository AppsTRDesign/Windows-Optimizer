$ErrorActionPreference = "Stop"
$installDir = "$env:USERPROFILE\Windows-Optimizer"
$baseUrl    = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"

Write-Host "Windows Optimizer kuruluyor..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# 1) Dosyaları indir
$files = @(
  "WindowsOptimizer.ps1",
  "config.json",
  "icon.png",
  "Modules\AdsBlocker.ps1",
  "Modules\FeatureManager.ps1",
  "Modules\RamCleaner.ps1",
  "Modules\BackgroundManager.ps1"
)
foreach ($f in $files) {
    $dest = Join-Path $installDir $f
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    try {
        Invoke-WebRequest -Uri "$baseUrl/$($f -replace '\\','/')" -OutFile $dest -UseBasicParsing
        Write-Host "  ✓ $f" -ForegroundColor Gray
    } catch { Write-Host "  ✗ $f  ($($_.Exception.Message))" -ForegroundColor Red }
}

# 2) icon.png -> icon.ico dönüşümü
$png = Join-Path $installDir "icon.png"
$ico = Join-Path $installDir "icon.ico"
if (Test-Path $png) {
    try {
        Add-Type -AssemblyName System.Drawing
        $src  = [System.Drawing.Image]::FromFile($png)
        $bmp  = New-Object System.Drawing.Bitmap($src, 256, 256)
        $hicon= $bmp.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($hicon)
        $fs   = [System.IO.File]::Create($ico)
        $icon.Save($fs); $fs.Close()
        $src.Dispose(); $bmp.Dispose()
        Write-Host "  ✓ icon.ico oluşturuldu" -ForegroundColor Gray
    } catch { Write-Host "  ! icon.ico oluşturulamadı: $($_.Exception.Message)" -ForegroundColor Yellow }
}

# 3) Execution Policy (kullanıcı seviyesi)
try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force } catch {}

# 4) Masaüstü kısayolu (icon.ico ile!)
$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "Windows Optimizer.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath       = "powershell.exe"
$sc.Arguments        = "-NoExit -ExecutionPolicy Bypass -File `"$installDir\WindowsOptimizer.ps1`""
$sc.WorkingDirectory = $installDir
$sc.Description      = "Windows Optimizer - Modular Tweaker"
if (Test-Path $ico) { $sc.IconLocation = $ico }
$sc.Save()

Write-Host ""
Write-Host "✅ Kurulum tamamlandı!" -ForegroundColor Green
Write-Host "Masaüstündeki 'Windows Optimizer' kısayolundan açabilirsiniz." -ForegroundColor Yellow
Write-Host "(İlk açılışta UAC izni isteyecek - Evet deyin.)" -ForegroundColor DarkGray