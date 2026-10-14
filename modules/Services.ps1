# modules/Services.ps1 - Arka plan servisleri analizi
# Her servis siniflandirilir: rec (gereksiz olabilir) | third (ucuncu parti) | ms (Windows bileseni)
# Degistirilen servislerin ilk baslangic tipi services-backup.json'a yazilir; "Geri al" ile dondurulur.

$WoSvcBackupPath = Join-Path (Split-Path $PSScriptRoot -Parent) "services-backup.json"

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
        $mode = switch ("$($s.StartMode)") { "Auto" { "Automatic" } "Manual" { "Manual" } "Disabled" { "Disabled" } default { "$($s.StartMode)" } }
        $rank = @{ Automatic = 2; Manual = 1; Disabled = 0 }
        $needs = $rec -and $rank.ContainsKey($mode) -and $rank[$mode] -gt $rank[$rec]
        $cat = if ($needs) { "rec" } elseif (-not $isMs) { "third" } else { "ms" }
        $mem = 0
        # Paylasimli svchost sureclerinde bellek servise ait degildir; yalnizca tek servisli surecler
        if ($s.ProcessId -and $svcPerPid[[int]$s.ProcessId] -eq 1) { $mem = $procMem[[int]$s.ProcessId] }
        [pscustomobject]@{
            Name = $s.Name; Display = "$($s.DisplayName)"; Description = "$($s.Description)"
            State = "$($s.State)"; StartMode = $mode; Path = $exe; Company = $company; IsMicrosoft = $isMs
            Category = $cat; RecStart = $rec; NeedsChange = $needs; Risk = $risk
            ReasonTR = $reasonTR; ReasonEN = $reasonEN; Mem = $mem
            Original = $backup.($s.Name)
        }
    }
}

function Set-WoServiceStart([string]$Name, [string]$Mode, [string]$CurrentMode) {
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
    Set-Service -Name $Name -StartupType $orig -ErrorAction Stop
    if ($orig -eq "Automatic") { Start-Service -Name $Name -ErrorAction SilentlyContinue }
    $backup.PSObject.Properties.Remove($Name)
    $backup | ConvertTo-Json | Set-Content $WoSvcBackupPath -Encoding UTF8
}
