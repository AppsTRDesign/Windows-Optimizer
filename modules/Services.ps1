# modules/Services.ps1 - Arka plan servisleri analizi
# Her servis siniflandirilir: rec (gereksiz olabilir) | third (ucuncu parti) | ms (Windows bileseni)
# Degistirilen servislerin ilk baslangic tipi services-backup.json'a yazilir; "Geri al" ile dondurulur.

# Derlenmis C# tiplerini onbellege alir: ilk acilista derlenip DLL olarak saklanir, sonraki acilislarda dogrudan yuklenir.
if (-not (Get-Command Add-WoType -ErrorAction SilentlyContinue)) {
    function Add-WoType([string]$Name, [string]$Code, [string[]]$Refs = @()) {
        if ($Name -as [type]) { return }
        try {
            $dir = Join-Path $env:LOCALAPPDATA "WindowsOptimizer\typecache"
            $sha = [Security.Cryptography.SHA256]::Create()
            $key = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Code + ($Refs -join ",") + $PSVersionTable.CLRVersion))).Replace("-", "").Substring(0, 16)
            $dll = Join-Path $dir "$Name-$key.dll"
            if (-not (Test-Path $dll)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Get-ChildItem $dir -Filter "$Name-*.dll" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                $tmp = "$dll.$PID.tmp"
                if ($Refs.Count) { Add-Type -TypeDefinition $Code -ReferencedAssemblies $Refs -OutputAssembly $tmp -OutputType Library }
                else { Add-Type -TypeDefinition $Code -OutputAssembly $tmp -OutputType Library }
                Move-Item $tmp $dll -Force
            }
            Add-Type -Path $dll
        } catch {}
        if (-not ($Name -as [type])) {
            if ($Refs.Count) { Add-Type -TypeDefinition $Code -ReferencedAssemblies $Refs } else { Add-Type -TypeDefinition $Code }
        }
    }
}

$WoSvcBackupPath = Join-Path (Split-Path $PSScriptRoot -Parent) "services-backup.json"

# Servisin yapilandirma izni var mi? (yalnizca acmayi dener, hicbir sey degistirmez)
Add-WoType "WoSvc" @"
using System;
using System.Runtime.InteropServices;
public static class WoSvc {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr OpenSCManager(string m, string d, uint a);
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr OpenService(IntPtr scm, string n, uint a);
    [DllImport("advapi32.dll")] static extern bool CloseServiceHandle(IntPtr h);
    public static bool CanConfigure(string name) {
        IntPtr scm = OpenSCManager(null, null, 0x0001);          // SC_MANAGER_CONNECT
        if (scm == IntPtr.Zero) return false;
        try {
            IntPtr h = OpenService(scm, name, 0x0002);            // SERVICE_CHANGE_CONFIG
            if (h == IntPtr.Zero) return false;
            CloseServiceHandle(h);
            return true;
        } finally { CloseServiceHandle(scm); }
    }
}
"@


# Kendini koruyan guvenlik yazilimlari: servis izni olsa bile surucu degisikligi engeller
$WoProtectedVendors = 'Norton|Gen Digital|NortonLifeLock|Symantec|Avast|AVG|Kaspersky|ESET|Bitdefender|McAfee|Malwarebytes|Sophos|Trend Micro|Avira|Panda|F-Secure|Webroot|Comodo|Emsisoft|G DATA'

# Ad -> @(onerilen tip, risk, TR aciklama, EN aciklama)   risk: safe | caution
$WoServiceKnowledge = @{
    "DiagTrack"        = @("Disabled", "safe", "Telemetri verilerini toplar ve Microsoft'a gönderir.", "Collects and sends telemetry data to Microsoft.")
    "dmwappushservice" = @("Disabled", "safe", "WAP push mesaj yönlendirme; telemetri altyapısının parçası.", "WAP push message routing; part of the telemetry pipeline.")
    "WerSvc"           = @("Manual", "safe", "Hata raporlama; yalnızca bir uygulama çöktüğünde gerekir.", "Error reporting; only needed when an app crashes.")
    "wercplsupport"    = @("Manual", "safe", "Sorun raporları denetim masası desteği.", "Problem reports control panel support.")
    "RetailDemo"       = @("Disabled", "safe", "Mağazalardaki demo modu için; evde gereksiz.", "Store demo mode; useless at home.")
    "MapsBroker"       = @("Disabled", "safe", "Çevrimdışı harita indirme yöneticisi.", "Offline maps download manager.")
    "Fax"              = @("Disabled", "safe", "Faks gönderme/alma.", "Fax send/receive.")
    "WMPNetworkSvc"    = @("Disabled", "safe", "Windows Media Player ağ paylaşımı.", "Windows Media Player network sharing.")
    "RemoteRegistry"   = @("Disabled", "safe", "Kayıt defterine ağ üzerinden erişim — güvenlik riski.", "Remote registry access over the network — security risk.")
    "PhoneSvc"         = @("Manual", "safe", "Telefon durumu yönetimi; ihtiyaç olunca başlar.", "Telephony state; starts when needed.")
    "SEMgrSvc"         = @("Manual", "safe", "Ödemeler ve NFC yöneticisi.", "Payments and NFC manager.")
    "WalletService"    = @("Manual", "safe", "Cüzdan istemcileri için.", "Used by wallet clients.")
    "wisvc"            = @("Disabled", "safe", "Windows Insider programı servisi.", "Windows Insider program service.")
    "TrkWks"           = @("Manual", "safe", "Ağdaki NTFS dosyalarına bağlantı takibi; ev kullanımında gereksiz.", "Tracks links to NTFS files across a network; not needed at home.")
    "icssvc"           = @("Manual", "safe", "Mobil etkin nokta (hotspot).", "Mobile hotspot.")
    "SharedAccess"     = @("Manual", "safe", "İnternet Bağlantısı Paylaşımı.", "Internet Connection Sharing.")
    "lfsvc"            = @("Manual", "caution", "Konum servisi. Konum özelliği kullanmıyorsanız gereksiz.", "Geolocation. Not needed if you don't use location.")
    "XblAuthManager"   = @("Manual", "caution", "Xbox Live kimlik doğrulama. Game Pass/Xbox uygulaması kullanıyorsanız dokunmayın.", "Xbox Live auth. Leave it if you use Game Pass/Xbox app.")
    "XblGameSave"      = @("Manual", "caution", "Xbox bulut kayıtları. Game Pass kullanıyorsanız dokunmayın.", "Xbox cloud saves. Leave it if you use Game Pass.")
    "XboxNetApiSvc"    = @("Manual", "caution", "Xbox Live ağ servisi.", "Xbox Live networking.")
    "XboxGipSvc"       = @("Manual", "caution", "Xbox aksesuar yönetimi (kablosuz kumanda vb.).", "Xbox accessory management (wireless controllers etc.).")
    "WpcMonSvc"        = @("Disabled", "caution", "Ebeveyn denetimleri. Çocuk hesabı yoksa gereksiz.", "Parental controls. Not needed without child accounts.")
    "Spooler"          = @("Manual", "caution", "Yazdırma biriktiricisi. Yazıcı kullanmıyorsanız el ile yapılabilir.", "Print spooler. Can be manual if you don't print.")
    "WSearch"          = @("Manual", "caution", "Dosya dizinleme. El ile yapılırsa Başlat/Outlook araması yavaşlar.", "File indexing. If manual, Start/Outlook search gets slower.")
    "edgeupdate"       = @("Manual", "safe", "Edge güncelleyici; Edge açılınca kendisi denetler.", "Edge updater; checks itself when Edge opens.")
    "edgeupdatem"      = @("Manual", "safe", "Edge güncelleyici; Edge açılınca kendisi denetler.", "Edge updater; checks itself when Edge opens.")
    "MicrosoftEdgeElevationService" = @("Manual", "safe", "Edge yükseltme servisi; gerektiğinde başlar.", "Edge elevation service; starts when needed.")
}
# ASLA kapatilmamasi gerekenler: kapatilirsa veri erisilemez hale gelir veya uygulama calismaz.
# Tarayici "Elevation" servisleri: Chrome/Brave/Edge sifre ve cerezleri bu servis uzerinden sifreler (App-Bound Encryption);
# kapaliyken profiller bos / cikis yapilmis gorunur. Hile korumalari: kapaliyken ilgili oyunlar acilmaz.
$WoNoDisablePattern = 'ElevationService|Elevation Service|AntiCheat|^vgc$|^BEService$|EasyAntiCheat'
$WoNoDisableReason = @{
    browser = @("Tarayıcının kayıtlı şifreleri ve oturumları bu servise bağlı. Kapatılırsa tarayıcı profilleri boş veya çıkış yapılmış görünür.",
                "The browser's saved passwords and sessions depend on this service. If disabled, browser profiles look empty or signed out.")
    browserFix = @("Bu servis KAPALI olduğu için tarayıcı kayıtlı şifreleri ve oturumları açamıyor. 'El ile' yapın, sonra tarayıcıyı yeniden başlatın.",
                   "This service is DISABLED, so the browser can't open saved passwords and sessions. Set it to 'Manual', then restart the browser.")
    game = @("Oyunun hile koruması. Kapatılırsa ilgili oyunlar açılmaz; oyun gerektiğinde kendisi başlatır.",
             "The game's anti-cheat. If disabled, related games won't start; the game starts it when needed.")
    gameFix = @("Bu hile koruması KAPALI olduğu için ilgili oyunlar açılmayabilir. 'El ile' yapın.",
                "This anti-cheat is DISABLED, so related games may not start. Set it to 'Manual'.")
}

# Ucuncu parti guncelleyiciler: El ile yeterli (uygulama acilinca guncellemeyi kendisi yapar)
$WoUpdaterPattern = 'update|updater|gupdate|AdobeARM|MozillaMaintenance|^brave|BraveElevation|Opera.*(Update|Assistant)|Dropbox(Update)?|Zoom.*Update|Wondershare.*Helper|CCleaner'

function Get-WoServiceBackup {
    if (Test-Path $WoSvcBackupPath) { try { return (Get-Content $WoSvcBackupPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {} }
    return [pscustomobject]@{}
}

function Get-WoServices {
    $backup = Get-WoServiceBackup
    $winDir = $env:SystemRoot.ToLower()
    $companyCache = @{}
    $procMem = @{}
    try { foreach ($p in Get-CimInstance Win32_Process -Property ProcessId, WorkingSetSize) { $procMem[[int]$p.ProcessId] = [double]$p.WorkingSetSize } } catch {}
    $svcPerPid = @{}
    $all = @(Get-CimInstance Win32_Service)
    $names = @{}; foreach ($s in $all) { $names[$s.Name] = $true }
    foreach ($s in $all) { if ($s.ProcessId) { $svcPerPid[[int]$s.ProcessId]++ } }

    foreach ($s in $all) {
        $exe = Split-WoCommand "$($s.PathName)"
        $company = ""
        if ($exe) {
            if (-not $companyCache.ContainsKey($exe)) {
                $c = ""
                try { if (Test-Path -LiteralPath $exe) { $c = "$((Get-Item -LiteralPath $exe -Force).VersionInfo.CompanyName)".Trim() } } catch {}
                $companyCache[$exe] = $c
            }
            $company = $companyCache[$exe]
        }
        $inWin = $exe -and $exe.ToLower().StartsWith($winDir)
        $isMs = $inWin -or $company -like "*Microsoft*"
        $know = $WoServiceKnowledge[$s.Name]
        $rec = $null; $risk = "safe"; $reasonTR = ""; $reasonEN = ""
        if ($know) {
            $rec = $know[0]; $risk = $know[1]; $reasonTR = $know[2]; $reasonEN = $know[3]
        } elseif (-not $isMs -and ($s.Name -match $WoUpdaterPattern -or $s.DisplayName -match $WoUpdaterPattern)) {
            $rec = "Manual"
            $reasonTR = "Güncelleme servisi; uygulama açıldığında güncellemeyi kendisi denetler."
            $reasonEN = "Updater service; the app checks for updates itself when opened."
        }
        # Kullanici basina servis kopyasi (or. WpnUserService_69cdb): sablonu uzerinden yonetilir
        $svcType = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($s.Name)", "Type", 0)
        $userInst = (([int]$svcType) -band 0x80) -ne 0
        $protected = "none"
        if ($userInst) { $protected = "user" }
        elseif ($company -match $WoProtectedVendors -or $s.DisplayName -match $WoProtectedVendors) { $protected = "vendor" }
        elseif (-not [WoSvc]::CanConfigure($s.Name)) { $protected = "acl" }
        if ($protected -ne "none") { $rec = $null }
        $mode = switch ("$($s.StartMode)") { "Auto" { "Automatic" } "Manual" { "Manual" } "Disabled" { "Disabled" } default { "$($s.StartMode)" } }
        $rank = @{ Automatic = 2; Manual = 1; Disabled = 0 }
        $needs = $rec -and $rank.ContainsKey($mode) -and $rank[$mode] -gt $rank[$rec]
        $noDisable = ($s.Name -match $WoNoDisablePattern) -or ($s.DisplayName -match $WoNoDisablePattern)
        if ($noDisable) {
            $kind = if ($s.Name -match 'Elevation' -or $s.DisplayName -match 'Elevation') { "browser" } else { "game" }
            if ($mode -eq "Disabled" -and $protected -ne "user") {
                # Kapali olmasi bir sorun: duzeltmeyi oner (guvenli)
                $rec = "Manual"; $needs = $true; $risk = "safe"
                $reasonTR = $WoNoDisableReason["$($kind)Fix"][0]; $reasonEN = $WoNoDisableReason["$($kind)Fix"][1]
            } elseif (-not $reasonTR) {
                $reasonTR = $WoNoDisableReason[$kind][0]; $reasonEN = $WoNoDisableReason[$kind][1]
            }
        }
        $cat = if ($needs) { "rec" } elseif (-not $isMs) { "third" } else { "ms" }
        $mem = 0
        # Paylasimli svchost sureclerinde bellek servise ait degildir; yalnizca tek servisli surecler
        if ($s.ProcessId -and $svcPerPid[[int]$s.ProcessId] -eq 1) { $mem = $procMem[[int]$s.ProcessId] }
        $orig = $backup.($s.Name)
        [pscustomobject]@{
            Name = $s.Name; Display = "$($s.DisplayName)"; Description = "$($s.Description)"; Delayed = [bool]$s.DelayedAutoStart
            State = "$($s.State)"; StartMode = $mode; Path = $exe; Company = $company; IsMicrosoft = $isMs
            Category = $cat; RecStart = $rec; NeedsChange = $needs; Risk = $risk
            ReasonTR = $reasonTR; ReasonEN = $reasonEN; Mem = $mem; Protected = $protected; NoDisable = $noDisable
            Original = $(if ($orig -eq "AutomaticDelayed") { "Automatic" } else { $orig })
        }
    }
}

function Set-WoServiceStart([string]$Name, [string]$Mode, [string]$CurrentMode) {
    if ($Mode -eq "Disabled" -and $Name -match $WoNoDisablePattern) { throw "Bu servis kapatilamaz (tarayici sifreleri / oyun hile korumasi icin gerekli)" }
    # Ilk degisiklikte orijinal tipi sakla
    $backup = Get-WoServiceBackup
    if (-not $backup.($Name) -and $CurrentMode) {
        $backup | Add-Member -NotePropertyName $Name -NotePropertyValue $CurrentMode -Force
        $backup | ConvertTo-Json | Set-Content $WoSvcBackupPath -Encoding UTF8
    }
    if ($Mode -eq "Disabled") { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
    try { Set-Service -Name $Name -StartupType $Mode -ErrorAction Stop }
    catch {
        $sc = @{ Automatic = "auto"; Manual = "demand"; Disabled = "disabled" }[$Mode]
        $out = & sc.exe config "$Name" start= $sc 2>&1
        if ($LASTEXITCODE) { throw "$($_.Exception.Message) / sc: $out" }
    }
}

function Restore-WoService([string]$Name) {
    $backup = Get-WoServiceBackup
    $orig = $backup.($Name)
    if (-not $orig) { return }
    if ($orig -eq "AutomaticDelayed") {
        $out = & sc.exe config "$Name" start= delayed-auto 2>&1
        if ($LASTEXITCODE) { throw "sc: $out" }
    } else {
        try { Set-Service -Name $Name -StartupType $orig -ErrorAction Stop }
        catch {
            $out = & sc.exe config "$Name" start= $(@{ Automatic = "auto"; Manual = "demand"; Disabled = "disabled" }[$orig]) 2>&1
            if ($LASTEXITCODE) { throw "$($_.Exception.Message) / sc: $out" }
        }
    }
    if ($orig -like "Automatic*") { Start-Service -Name $Name -ErrorAction SilentlyContinue }
    $backup.PSObject.Properties.Remove($Name)
    $backup | ConvertTo-Json | Set-Content $WoSvcBackupPath -Encoding UTF8
}

function Get-WoChangedServices {
    $backup = Get-WoServiceBackup
    @($backup.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Original = $_.Value } })
}

function Restore-AllWoServices {
    foreach ($c in (Get-WoChangedServices)) {
        try { Restore-WoService $c.Name; [pscustomobject]@{ Name = $c.Name; Ok = $true } }
        catch { [pscustomobject]@{ Name = $c.Name; Ok = $false; Err = $_.Exception.Message } }
    }
}
