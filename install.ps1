# Windows Optimizer - Kurulum / Guncelleme
# Kullanim:  irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
# Klasoru SILMEZ: once gecici klasore indirir, dogrular, sonra uzerine yazar. Ayarlar korunur.

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installDir = Join-Path $env:USERPROFILE "Windows-Optimizer"
$baseUrl    = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"
$stage      = Join-Path $env:TEMP "WO-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$obsolete   = @("modules/AdsBlocker.ps1", "modules/FeatureManager.ps1", "modules/BackgroundManager.ps1")
# Imza dogrulamasi icin acik anahtar (ozel anahtar yalnizca gelistiricide; tools\release.ps1)
$publicKey  = '<RSAKeyValue><Modulus>tjUSopN6XtXRGRi4sl28MUdMCxD8nIPqQrcpfdaNGEYR5I5Ji5+aJq92xc2wCG6bTtc/WKPfld8LwzoN6mix2Lx7gDqrtkh2ee2LrDwggBO/vT5Qo++tcrle/uHBaaffQZqkn8hkJY6rPcZ3uTMYA8/21EcEgF20kjtrmcPxJW1//gz1nLPQQnf9yx02/ZTCDRBh96Urhh9Nj/KaJ9tYnp99BTllWITJ0R8/8C+CNQVVYsNs4gjEFn3RHHIM+om6hMGJWcyFF81wIOrNYw+0Vctvzf0b4G/1IaNcl24pBvdpxF3X59DMDiPwtl9oib842lTY8btVmRWW89UAAtUmXR0UzAUh3y6ir2cnOwlHt1bvlX/Wzch6vXBKYfN4HiI3ita4HMtoM0Je/yUrqnnCQcs0sNVIfMB8NeAnTgNG+kAYJxwE7qlKIi8bgReEo8bVOfrAtYPn3Nadi0N0YPOKyeRFjp7jUeBgKz02APL+6mtfCf35Zxkety+7cChZrILF</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'
$files      = @(
    "WindowsOptimizer.ps1", "config.json", "version.json", "assets/logo.png",
    "assets/banner.png", "modules/Tweaks.ps1", "modules/RamCleaner.ps1", "modules/Updater.ps1",
    "modules/Startup.ps1", "modules/DiskCleaner.ps1", "modules/Services.ps1", "modules/Network.ps1",
    "pages/Game.ps1", "pages/Analyzer.ps1", "pages/Apps.ps1", "pages/Network.ps1",
    "pages/Health.ps1", "pages/Privacy.ps1", "pages/Extras.ps1", "pages/Monitor.ps1", "pages/SmartMem.ps1"
)

Write-Host ""
Write-Host "  WINDOWS OPTIMIZER - Kurulum" -ForegroundColor Magenta
Write-Host "  ---------------------------" -ForegroundColor DarkGray

# Surum bilgisi + imza dogrulamasi: imzasiz veya degistirilmis surum KURULMAZ
$info = $null
try { $info = Invoke-RestMethod -Uri "$baseUrl/version.json?t=$([DateTime]::UtcNow.Ticks)" -UseBasicParsing -TimeoutSec 15 } catch {}
if (-not $info -or -not $info.sha256 -or -not $info.signature) {
    Write-Host "  Surum bilgisi alinamadi veya imzasiz. Guvenlik nedeniyle kurulum yapilmadi." -ForegroundColor Red
    return
}
$names = [string[]]@($info.sha256.PSObject.Properties | ForEach-Object Name)
[Array]::Sort($names, [StringComparer]::Ordinal)
$canon = "version=$($info.version)`n" + (($names | ForEach-Object { "$_=$($info.sha256.$_)" }) -join "`n")
$rsa = New-Object Security.Cryptography.RSACryptoServiceProvider
$rsa.FromXmlString($publicKey)
if (-not $rsa.VerifyData([Text.Encoding]::UTF8.GetBytes($canon), "SHA256", [Convert]::FromBase64String("$($info.signature)"))) {
    Write-Host "  Dijital imza GECERSIZ. Guvenlik nedeniyle kurulum yapilmadi." -ForegroundColor Red
    return
}
$files = @(@("version.json") + $names)
Write-Host "  Surum: v$($info.version)  (imza dogrulandi)" -ForegroundColor Gray

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
        if ($f -ne "version.json") {
            $got = ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($dest))) -replace '-', '').ToLower()
            if ($got -ne "$($info.sha256.$f)".ToLower()) { throw "SHA-256 uyusmuyor (dosya degistirilmis)" }
        }
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
