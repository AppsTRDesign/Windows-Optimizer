# tools/release.ps1 - Surum yayinlama: dosya ozetleri (SHA-256) + dijital imza
#
# Kullanim:
#   .\tools\release.ps1 -Version 3.2.0 -Notes "Degisiklik notlari"
#   .\tools\release.ps1 -NewKey          (yalnizca ilk kez / anahtar yenilemek icin)
#
# Ozel anahtar %APPDATA%\WindowsOptimizer-signing\private-key.xml konumunda tutulur ve ASLA GitHub'a yuklenmez.
# Yedekleyin: kaybolursa mevcut kullanicilar yeni guncellemeleri kabul etmez (yeniden kurulum gerekir).
param([string]$Version, [string]$Notes = "", [switch]$NewKey)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$keyDir = Join-Path $env:APPDATA "WindowsOptimizer-signing"
$privPath = Join-Path $keyDir "private-key.xml"
$pubPath = Join-Path $PSScriptRoot "public-key.xml"

function Get-Canonical([string]$Ver, $Map) {
    $names = [string[]]@($Map.Keys)
    [Array]::Sort($names, [StringComparer]::Ordinal)
    return "version=$Ver`n" + (($names | ForEach-Object { "$_=$($Map[$_])" }) -join "`n")
}

# ---------- anahtar ----------
if ($NewKey) {
    if (Test-Path $privPath) {
        $bak = "$privPath.$(Get-Date -Format yyyyMMddHHmmss).bak"
        Copy-Item $privPath $bak
        Write-Host "Eski anahtar yedeklendi: $bak" -ForegroundColor Yellow
    }
    New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
    $rsa = New-Object Security.Cryptography.RSACryptoServiceProvider(3072)
    [IO.File]::WriteAllText($privPath, $rsa.ToXmlString($true))
    [IO.File]::WriteAllText($pubPath, $rsa.ToXmlString($false))
    # Ozel anahtar dosyasini yalnizca bu kullaniciya ac
    $acl = Get-Acl $privPath; $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule("$env:USERDOMAIN\$env:USERNAME", "FullControl", "Allow")))
    Set-Acl $privPath $acl
    Write-Host "Yeni imza anahtari olusturuldu." -ForegroundColor Green
    Write-Host "  Ozel anahtar : $privPath  (YEDEKLEYIN, PAYLASMAYIN)"
    Write-Host "  Acik anahtar : $pubPath"
    Write-Host "Acik anahtari modules\Updater.ps1 ve install.ps1 icindeki `$WoUpdatePublicKey degerine yazin." -ForegroundColor Cyan
    if (-not $Version) { return }
}
if (-not $Version) { throw "Surum belirtin: -Version 3.2.0" }
if (-not (Test-Path $privPath)) { throw "Ozel anahtar yok: once .\tools\release.ps1 -NewKey calistirin" }

# ---------- dosyalar ve ozetler ----------
$files = New-Object System.Collections.Generic.List[string]
foreach ($f in @("WindowsOptimizer.ps1", "config.json", "LICENSE")) { if (Test-Path (Join-Path $root $f)) { $files.Add($f) } }
foreach ($dir in @("assets", "modules", "pages")) {
    Get-ChildItem (Join-Path $root $dir) -File | Where-Object { $_.Extension -in @(".ps1", ".png", ".json") } |
        ForEach-Object { $files.Add("$dir/$($_.Name)") }
}
$sha = [Security.Cryptography.SHA256]::Create()
$map = [ordered]@{}
foreach ($f in $files) {
    $bytes = [IO.File]::ReadAllBytes((Join-Path $root ($f -replace '/', '\')))
    $map[$f] = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLower()
}

# PowerShell betikleri yayinlanmadan once sozdizimi denetimi
foreach ($f in $files | Where-Object { $_ -like "*.ps1" }) {
    $e = $null; [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $root ($f -replace '/', '\')), [ref]$null, [ref]$e)
    if ($e.Count) { throw "Sozdizimi hatasi: $f -> $($e[0].Message)" }
}

# ---------- imza ----------
$rsa = New-Object Security.Cryptography.RSACryptoServiceProvider
$rsa.FromXmlString([IO.File]::ReadAllText($privPath))
$canon = Get-Canonical $Version $map
$sig = [Convert]::ToBase64String($rsa.SignData([Text.Encoding]::UTF8.GetBytes($canon), "SHA256"))

# Uygulamaya gomulu acik anahtarla dogrula (anahtar uyusmazligini yayinlamadan yakala)
$updSrc = [IO.File]::ReadAllText((Join-Path $root "modules\Updater.ps1"))
$embedded = [regex]::Match($updSrc, "\`$WoUpdatePublicKey = '([^']+)'").Groups[1].Value
if (-not $embedded) { throw "modules\Updater.ps1 icinde `$WoUpdatePublicKey bulunamadi" }
$v = New-Object Security.Cryptography.RSACryptoServiceProvider; $v.FromXmlString($embedded)
if (-not $v.VerifyData([Text.Encoding]::UTF8.GetBytes($canon), "SHA256", [Convert]::FromBase64String($sig))) {
    throw "Imza, uygulamaya gomulu acik anahtarla dogrulanamadi. Updater.ps1 ve install.ps1 icindeki anahtari guncelleyin."
}

# ---------- version.json ----------
$old = $null; try { $old = Get-Content (Join-Path $root "version.json") -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
$out = [ordered]@{
    version   = $Version
    url       = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1"
    notes     = $(if ($Notes) { $Notes } elseif ($old) { $old.notes } else { "" })
    files     = @(@("version.json") + @($map.Keys))
    sha256    = $map
    signature = $sig
}
$json = $out | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText((Join-Path $root "version.json"), $json, (New-Object Text.UTF8Encoding $false))
Write-Host "version.json imzalandi: v$Version, $($map.Count) dosya." -ForegroundColor Green
Write-Host "Simdi tum dosyalari (version.json dahil) GitHub'a yukleyin. version.json'dan sonra hicbir dosyayi degistirmeyin;" -ForegroundColor Cyan
Write-Host "degistirirseniz bu betigi yeniden calistirin, yoksa istemciler guncellemeyi reddeder." -ForegroundColor Cyan
