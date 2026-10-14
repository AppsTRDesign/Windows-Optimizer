# Windows Optimizer - Kurulum / Guncelleme
# Kullanim:  irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
# Klasoru SILMEZ: once gecici klasore indirir, dogrular, sonra uzerine yazar. Ayarlar korunur.

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installDir = Join-Path $env:USERPROFILE "Windows-Optimizer"
$baseUrl    = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"
$stage      = Join-Path $env:TEMP "WO-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$obsolete   = @("modules/AdsBlocker.ps1", "modules/FeatureManager.ps1", "modules/BackgroundManager.ps1")
$files      = @(
    "WindowsOptimizer.ps1", "config.json", "version.json",
    "assets/logo.png", "assets/banner.png",
    "modules/Tweaks.ps1", "modules/RamCleaner.ps1", "modules/Updater.ps1",
    "modules/Startup.ps1", "modules/DiskCleaner.ps1"
)

Write-Host ""
Write-Host "  WINDOWS OPTIMIZER - Kurulum" -ForegroundColor Magenta
Write-Host "  ---------------------------" -ForegroundColor DarkGray

# Uzak dosya listesi (varsa)
try {
    $info = Invoke-RestMethod -Uri "$baseUrl/version.json?t=$([DateTime]::UtcNow.Ticks)" -UseBasicParsing -TimeoutSec 15
    if ($info.files) { $files = @($info.files) }
    Write-Host "  Surum: v$($info.version)" -ForegroundColor Gray
} catch {}

# 1) Calisan eski kopyalari kapat (klasor kilidini birakir; eski surumlerde guncelleme bu yuzden yarida kaliyordu)
try {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction Stop |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like "*WindowsOptimizer.ps1*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 800
} catch {}

# 2) Gecici klasore indir + dogrula
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$stage = (Get-Item -LiteralPath $stage).FullName   # %TEMP% kisa (8.3) yol olabilir
$utf8Bom = New-Object Text.UTF8Encoding $true
$failed = @()
$i = 0
foreach ($f in $files) {
    $i++
    $pct = [int](100 * $i / $files.Count)
    Write-Progress -Activity "Windows Optimizer indiriliyor" -Status "$f ($i/$($files.Count))" -PercentComplete $pct
    $dest = Join-Path $stage ($f -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    try {
        Invoke-WebRequest -Uri "$baseUrl/$f`?t=$([DateTime]::UtcNow.Ticks)" -OutFile $dest -UseBasicParsing -TimeoutSec 30
        if ($f -match '\.(ps1|json)$') {
            $txt = [IO.File]::ReadAllText($dest, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
            if ($f -like '*.ps1') {
                $errs = $null
                [void][Management.Automation.Language.Parser]::ParseInput($txt, [ref]$null, [ref]$errs)
                if ($errs.Count -gt 0) { throw "Bozuk betik: $($errs[0].Message)" }
            }
            [IO.File]::WriteAllText($dest, $txt, $utf8Bom)
        }
        Write-Host "  [OK] $f" -ForegroundColor DarkGray
    } catch {
        $failed += $f
        Write-Host "  [XX] $f  ($($_.Exception.Message))" -ForegroundColor Red
    }
}
Write-Progress -Activity "Windows Optimizer indiriliyor" -Completed

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "  Kurulum iptal edildi, mevcut kurulum DEGISTIRILMEDI." -ForegroundColor Yellow
    Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
    return
}

# 3) Yerine koy (silmeden uzerine yaz; settings.json korunur)
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Get-ChildItem -LiteralPath $stage -Recurse -File | ForEach-Object {
    $rel  = $_.FullName.Substring($stage.Length).TrimStart('\')
    $dest = Join-Path $installDir $rel
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    for ($k = 0; $k -lt 10; $k++) {
        try { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force -ErrorAction Stop; break }
        catch { Start-Sleep -Milliseconds 500; if ($k -eq 9) { Write-Host "  [!!] $rel yazilamadi: $($_.Exception.Message)" -ForegroundColor Yellow } }
    }
}
foreach ($o in $obsolete) { Remove-Item (Join-Path $installDir ($o -replace '/', '\')) -Force -ErrorAction SilentlyContinue }
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue

# 4) Kisayollar (Masaustu + Baslat menusu; yonetici olarak, konsolsuz)
try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue } catch {}
try {
    . (Join-Path $installDir "modules\Updater.ps1")
    $made = New-WoShortcut $installDir
    foreach ($m in $made) { Write-Host "  [OK] Kisayol: $m" -ForegroundColor DarkGray }
} catch { Write-Host "  [!!] Kisayol olusturulamadi: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Kurulum tamamlandi! Uygulama baslatiliyor..." -ForegroundColor Green
Start-Process powershell.exe -WindowStyle Hidden -WorkingDirectory $installDir -ArgumentList @(
    "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", "`"$installDir\WindowsOptimizer.ps1`""
)
