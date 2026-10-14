# modules/Updater.ps1 - Surum karsilastirma, ilerlemeli indirme, guvenli kurulum ve kisayol

$WoRepoRaw = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main"

# Uzak version.json 'files' listesi vermezse kullanilir
$WoDefaultFiles = @(
    "WindowsOptimizer.ps1", "config.json", "version.json", "assets/logo.png",
    "assets/banner.png", "modules/Tweaks.ps1", "modules/RamCleaner.ps1", "modules/Updater.ps1",
    "modules/Startup.ps1", "modules/DiskCleaner.ps1", "modules/Services.ps1", "modules/Network.ps1",
    "pages/Game.ps1", "pages/Analyzer.ps1", "pages/Apps.ps1", "pages/Network.ps1",
    "pages/Health.ps1", "pages/Privacy.ps1", "pages/Extras.ps1", "pages/Monitor.ps1", "pages/SmartMem.ps1"
)
# ---------------- IMZALI GUNCELLEME ----------------
# version.json icindeki dosya ozetleri (sha256) proje sahibinin ozel anahtariyla imzalanir (tools\release.ps1).
# Istemci yalnizca bu gomulu acik anahtarla dogrulanan surumleri kurar; tek bayt degisen dosya reddedilir.
$WoUpdatePublicKey = '<RSAKeyValue><Modulus>tjUSopN6XtXRGRi4sl28MUdMCxD8nIPqQrcpfdaNGEYR5I5Ji5+aJq92xc2wCG6bTtc/WKPfld8LwzoN6mix2Lx7gDqrtkh2ee2LrDwggBO/vT5Qo++tcrle/uHBaaffQZqkn8hkJY6rPcZ3uTMYA8/21EcEgF20kjtrmcPxJW1//gz1nLPQQnf9yx02/ZTCDRBh96Urhh9Nj/KaJ9tYnp99BTllWITJ0R8/8C+CNQVVYsNs4gjEFn3RHHIM+om6hMGJWcyFF81wIOrNYw+0Vctvzf0b4G/1IaNcl24pBvdpxF3X59DMDiPwtl9oib842lTY8btVmRWW89UAAtUmXR0UzAUh3y6ir2cnOwlHt1bvlX/Wzch6vXBKYfN4HiI3ita4HMtoM0Je/yUrqnnCQcs0sNVIfMB8NeAnTgNG+kAYJxwE7qlKIi8bgReEo8bVOfrAtYPn3Nadi0N0YPOKyeRFjp7jUeBgKz02APL+6mtfCf35Zxkety+7cChZrILF</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'

function Get-WoManifestCanonical([string]$Version, $ShaMap) {
    $names = [string[]]@($ShaMap.PSObject.Properties | ForEach-Object Name)
    [Array]::Sort($names, [StringComparer]::Ordinal)
    return "version=$Version`n" + (($names | ForEach-Object { "$_=$($ShaMap.$_)" }) -join "`n")
}

# Gecerliyse $null, degilse hata metni dondurur
function Test-WoManifest($Info) {
    if (-not $Info.sha256 -or -not $Info.signature) { return "unsigned" }
    try {
        $rsa = New-Object Security.Cryptography.RSACryptoServiceProvider
        $rsa.FromXmlString($WoUpdatePublicKey)
        $data = [Text.Encoding]::UTF8.GetBytes((Get-WoManifestCanonical "$($Info.version)" $Info.sha256))
        if ($rsa.VerifyData($data, "SHA256", [Convert]::FromBase64String("$($Info.signature)"))) { return $null }
        return "badsig"
    } catch { return "badsig" }
}

function Get-WoSignedFiles($Info) {
    @(@("version.json") + @($Info.sha256.PSObject.Properties | ForEach-Object Name))
}

# Eski surumlerden kalan, artik kullanilmayan dosyalar
$WoObsoleteFiles = @("modules/AdsBlocker.ps1", "modules/FeatureManager.ps1", "modules/BackgroundManager.ps1")

# "1.3" ile "1.3.0" esit sayilir ([version] bunlari farkli gorur)
function ConvertTo-WoVersion([string]$Text) {
    $parts = @(("$Text" -replace '[^\d\.]', '').Split('.') | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    while ($parts.Count -lt 4) { $parts += 0 }
    return New-Object Version($parts[0], $parts[1], $parts[2], $parts[3])
}

function Test-WoNewer([string]$Remote, [string]$Local) {
    try { return (ConvertTo-WoVersion $Remote) -gt (ConvertTo-WoVersion $Local) } catch { return $false }
}

function Set-WoLnkRunAsAdmin([string]$LnkPath) {
    $bytes = [IO.File]::ReadAllBytes($LnkPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20   # SLDF_RUNAS_USER
    [IO.File]::WriteAllBytes($LnkPath, $bytes)
}

function New-WoIcon([string]$InstallDir) {
    $png = Join-Path $InstallDir "assets\logo.png"
    $ico = Join-Path $InstallDir "assets\logo.ico"
    if (-not (Test-Path $png)) { return $null }
    try {
        Add-Type -AssemblyName System.Drawing
        $src = [Drawing.Image]::FromFile($png)
        $bmp = New-Object Drawing.Bitmap($src, 256, 256)
        $icon = [Drawing.Icon]::FromHandle($bmp.GetHicon())
        $fs = [IO.File]::Create($ico); $icon.Save($fs); $fs.Close()
        $src.Dispose(); $bmp.Dispose()
    } catch {}
    if (Test-Path $ico) { return $ico } else { return $null }
}

# Masaustu + Baslat menusu kisayolu; konsol penceresi acmaz, dogrudan yonetici olarak calisir
function New-WoShortcut([string]$InstallDir) {
    $ico = New-WoIcon $InstallDir
    $script = Join-Path $InstallDir "WindowsOptimizer.ps1"
    $targets = @(
        (Join-Path ([Environment]::GetFolderPath("Desktop")) "Windows Optimizer.lnk"),
        (Join-Path ([Environment]::GetFolderPath("Programs")) "Windows Optimizer.lnk")
    )
    $ws = New-Object -ComObject WScript.Shell
    $made = @()
    foreach ($lnk in $targets) {
        try {
            $sc = $ws.CreateShortcut($lnk)
            $sc.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
            $sc.Arguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
            $sc.WorkingDirectory = $InstallDir
            $sc.WindowStyle      = 7
            $sc.Description      = "Windows Optimizer"
            if ($ico) { $sc.IconLocation = "$ico,0" }
            $sc.Save()
            Set-WoLnkRunAsAdmin $lnk
            $made += $lnk
        } catch {}
    }
    return $made
}

function Get-WoRemoteInfo {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Headers.Add("Cache-Control", "no-cache")
    $wc.Encoding = [Text.Encoding]::UTF8
    $json = $wc.DownloadString("$WoRepoRaw/version.json?t=$([DateTime]::UtcNow.Ticks)")
    return ($json.TrimStart([char]0xFEFF) | ConvertFrom-Json)
}

# Arka plan runspace'inde calisir. $Sync: Stage, Pct, File, Index, Count, Error
$WoDownloadJob = {
    param($BaseUrl, $Files, $Stage, $Sync, $Expected)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
        New-Item -ItemType Directory -Path $Stage -Force | Out-Null
        $n = $Files.Count; $i = 0
        $Sync.Count = $n; $Sync.Stage = "download"
        foreach ($f in $Files) {
            $Sync.File = $f; $Sync.Index = $i + 1
            $dest = Join-Path $Stage ($f -replace '/', '\')
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            $req = [Net.HttpWebRequest]::Create("$BaseUrl/$f`?t=$([DateTime]::UtcNow.Ticks)")
            $req.Headers.Add("Cache-Control", "no-cache")
            $req.Timeout = 20000
            $resp = $req.GetResponse()
            $len = $resp.ContentLength
            $in = $resp.GetResponseStream()
            $out = [IO.File]::Create($dest)
            $buf = New-Object byte[] 32768; $read = 0; $total = 0
            while (($read = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $out.Write($buf, 0, $read); $total += $read
                if ($len -gt 0) { $Sync.Pct = [int](100 * ($i + ($total / $len)) / $n) }
            }
            $out.Close(); $in.Close(); $resp.Close()
            if ($total -eq 0) { throw "Bos dosya: $f" }
            $i++; $Sync.Pct = [int](100 * $i / $n)
        }

        # Imzali ozetlerle karsilastir (indirilen ham baytlar; tek bayt farki bile reddedilir)
        $Sync.Stage = "verify"
        $sha = [Security.Cryptography.SHA256]::Create()
        foreach ($f in $Files) {
            if ($f -eq "version.json") { continue }
            $want = "$($Expected[$f])"
            if (-not $want) { throw "Imzasiz dosya: $f" }
            $got = ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes((Join-Path $Stage ($f -replace '/', '\'))))) -replace '-', '').ToLower()
            if ($got -ne $want.ToLower()) { throw "SHA-256 uyusmuyor: $f" }
        }
        # PS 5.1 icin UTF-8 BOM
        $utf8Bom = New-Object Text.UTF8Encoding $true
        foreach ($f in $Files | Where-Object { $_ -match '\.(ps1|json)$' }) {
            $p = Join-Path $Stage ($f -replace '/', '\')
            $txt = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
            if ($f -like '*.ps1') {
                $errs = $null
                [void][Management.Automation.Language.Parser]::ParseInput($txt, [ref]$null, [ref]$errs)
                if ($errs.Count -gt 0) { throw "Bozuk dosya: $f ($($errs[0].Message))" }
            } else { [void]($txt | ConvertFrom-Json) }
            [IO.File]::WriteAllText($p, $txt, $utf8Bom)
        }
        $Sync.Stage = "ready"; $Sync.Pct = 100
    } catch {
        $Sync.Error = $_.Exception.Message; $Sync.Stage = "error"
    }
}

# Uygulama kapandiktan sonra dosyalari yerine koyan, kisayolu yenileyen ve yeniden baslatan betik
function Start-WoApplyUpdate([string]$Stage, [string]$InstallDir, [int]$ParentPid) {
    $applier = Join-Path $env:TEMP "WO-apply-update.ps1"
    $Stage = $Stage -replace "'", "''"; $InstallDir = $InstallDir -replace "'", "''"
    $obsolete = ($WoObsoleteFiles | ForEach-Object { "'$_'" }) -join ','
    $code = @"
`$ErrorActionPreference = 'Continue'
`$log = Join-Path `$env:TEMP 'WindowsOptimizer-update.log'
"[`$(Get-Date)] Guncelleme basladi" | Out-File `$log -Encoding UTF8
try { Wait-Process -Id $ParentPid -Timeout 30 -ErrorAction SilentlyContinue } catch {}
Start-Sleep -Milliseconds 500
`$stage = (Get-Item -LiteralPath '$Stage').FullName; `$target = '$InstallDir'
Get-ChildItem -LiteralPath `$stage -Recurse -File | ForEach-Object {
    `$rel  = `$_.FullName.Substring(`$stage.Length).TrimStart('\')
    `$dest = Join-Path `$target `$rel
    New-Item -ItemType Directory -Path (Split-Path `$dest -Parent) -Force | Out-Null
    for (`$k = 0; `$k -lt 10; `$k++) {
        try { Copy-Item -LiteralPath `$_.FullName -Destination `$dest -Force -ErrorAction Stop; "OK `$rel" | Out-File `$log -Append -Encoding UTF8; break }
        catch { Start-Sleep -Milliseconds 500; if (`$k -eq 9) { "HATA `$rel : `$(`$_.Exception.Message)" | Out-File `$log -Append -Encoding UTF8 } }
    }
}
foreach (`$o in @($obsolete)) { Remove-Item (Join-Path `$target (`$o -replace '/','\')) -Force -ErrorAction SilentlyContinue }
try { . (Join-Path `$target 'modules\Updater.ps1'); New-WoShortcut `$target | Out-File `$log -Append -Encoding UTF8 } catch { "Kisayol hatasi: `$(`$_.Exception.Message)" | Out-File `$log -Append -Encoding UTF8 }
Start-Process powershell.exe -WindowStyle Hidden -WorkingDirectory `$target -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',"``"`$target\WindowsOptimizer.ps1``"",'-Updated')
Remove-Item -LiteralPath `$stage -Recurse -Force -ErrorAction SilentlyContinue
"[`$(Get-Date)] Tamamlandi" | Out-File `$log -Append -Encoding UTF8
"@
    [IO.File]::WriteAllText($applier, $code, (New-Object Text.UTF8Encoding $true))
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", "`"$applier`""
    )
}
