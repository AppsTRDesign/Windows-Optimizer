# modules/Tweaks.ps1 - Optimizasyon katalogu ve uygulama motoru
# Her tweak: Reg (P=yol, N=ad, V=uygulanan deger, D=varsayilan; D=$null -> deger silinir)
#            Svc (N=servis, D=varsayilan baslangic tipi)
#            Restart: 'explorer' | 'logoff' | $null

$CDM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$ADV = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$POL = "HKLM:\SOFTWARE\Policies\Microsoft"

$TweakCategories = [ordered]@{
    ads    = @{ Icon = [char]0xE72E; TR = "Reklamlar & Gizlilik"; EN = "Ads & Privacy" }
    search = @{ Icon = [char]0xE774; TR = "Arama, Edge & Copilot"; EN = "Search, Edge & Copilot" }
    system = @{ Icon = [char]0xE770; TR = "Sistem & Telemetri";    EN = "System & Telemetry" }
    perf   = @{ Icon = [char]0xE945; TR = "Performans";            EN = "Performance" }
}

$TweakCatalog = @(
    # ---------------- REKLAMLAR & GİZLİLİK ----------------
    @{ Id="ExplorerAds"; Cat="ads"; Rec=$true; Restart="explorer"
       TR=@("Dosya Gezgini reklamlarını kapat","OneDrive/Microsoft 365 senkronizasyon bildirimlerini gizler.")
       EN=@("Disable File Explorer ads","Hides OneDrive/Microsoft 365 sync provider notifications.")
       Reg=@( @{P=$ADV; N="ShowSyncProviderNotifications"; V=0; D=1} ) }

    @{ Id="LockScreen"; Cat="ads"; Rec=$true
       TR=@("Kilit ekranı ipuçlarını ve reklamlarını kapat","Spotlight 'eğlenceli bilgiler' ve tanıtım katmanlarını kaldırır.")
       EN=@("Disable lock screen tips & ads","Removes Spotlight fun facts and promo overlays.")
       Reg=@( @{P=$CDM; N="RotatingLockScreenOverlayEnabled"; V=0; D=1}
              @{P=$CDM; N="SubscribedContent-338387Enabled"; V=0; D=1} ) }

    @{ Id="SettingsAds"; Cat="ads"; Rec=$true
       TR=@("Ayarlar uygulamasındaki önerileri kapat","Ayarlar içindeki 'önerilen içerik' kartlarını kapatır.")
       EN=@("Disable Settings app suggestions","Turns off 'suggested content' cards inside Settings.")
       Reg=@( @{P=$CDM; N="SubscribedContent-338393Enabled"; V=0; D=1}
              @{P=$CDM; N="SubscribedContent-353694Enabled"; V=0; D=1}
              @{P=$CDM; N="SubscribedContent-353696Enabled"; V=0; D=1} ) }

    @{ Id="Tips"; Cat="ads"; Rec=$true
       TR=@("Windows ipuçlarını ve önerilerini kapat","'Windows'u kullanırken ipuçları al' bildirimlerini durdurur.")
       EN=@("Disable Windows tips & suggestions","Stops 'tips and suggestions as you use Windows'.")
       Reg=@( @{P=$CDM; N="SoftLandingEnabled"; V=0; D=1}
              @{P=$CDM; N="SubscribedContent-338389Enabled"; V=0; D=1} ) }

    @{ Id="Welcome"; Cat="ads"; Rec=$true
       TR=@("'Hoş geldiniz' deneyimini kapat","Güncellemelerden sonra açılan tanıtım ekranını kapatır.")
       EN=@("Disable 'Welcome Experience'","Stops the promo screen shown after updates.")
       Reg=@( @{P=$CDM; N="SubscribedContent-310093Enabled"; V=0; D=1} ) }

    @{ Id="FinishSetup"; Cat="ads"; Rec=$true
       TR=@("'Cihazınızı kurmayı bitirin' ekranını kapat","Microsoft 365 / OneDrive / Game Pass hatırlatıcılarını kaldırır.")
       EN=@("Disable 'Finish setting up' nag","Removes Microsoft 365 / OneDrive / Game Pass reminders.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; N="ScoobeSystemSettingEnabled"; V=0; D=1} ) }

    @{ Id="StartAds"; Cat="ads"; Rec=$true; Restart="explorer"
       TR=@("Başlat menüsü reklamlarını ve otomatik uygulama kurulumunu kapat","Önerilen uygulamaları, sessiz kurulan uygulamaları ve Başlat önerilerini engeller.")
       EN=@("Disable Start menu ads & silent app installs","Blocks promoted apps, silently installed apps and Start recommendations.")
       Reg=@( @{P=$CDM; N="SubscribedContent-338388Enabled"; V=0; D=1}
              @{P=$CDM; N="SystemPaneSuggestionsEnabled"; V=0; D=1}
              @{P=$CDM; N="SilentInstalledAppsEnabled"; V=0; D=1}
              @{P=$CDM; N="PreInstalledAppsEnabled"; V=0; D=1}
              @{P=$CDM; N="OemPreInstalledAppsEnabled"; V=0; D=1}
              @{P=$ADV; N="Start_IrisRecommendations"; V=0; D=$null} ) }

    @{ Id="NotifSugg"; Cat="ads"; Rec=$true
       TR=@("Bildirim merkezindeki önerileri kapat","Windows'un 'önerilen' bildirimlerini susturur.")
       EN=@("Disable suggested notifications","Silences Windows 'suggested' toast notifications.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested"; N="Enabled"; V=0; D=$null} ) }

    @{ Id="PersonalAds"; Cat="ads"; Rec=$true
       TR=@("Kişiselleştirilmiş reklam kimliğini kapat","Uygulamaların reklam kimliğinizi kullanmasını engeller.")
       EN=@("Disable advertising ID","Prevents apps from using your advertising ID.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; N="Enabled"; V=0; D=1}
              @{P="$POL\Windows\AdvertisingInfo"; N="DisabledByGroupPolicy"; V=1; D=$null} ) }

    @{ Id="Tailored"; Cat="ads"; Rec=$true
       TR=@("'Uyarlanmış deneyimleri' kapat","Tanılama verilerine göre kişiselleştirilmiş ipuçlarını kapatır.")
       EN=@("Disable 'Tailored experiences'","Turns off tips personalized from diagnostic data.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"; N="TailoredExperiencesWithDiagnosticDataEnabled"; V=0; D=1} ) }

    @{ Id="Activity"; Cat="ads"; Rec=$true
       TR=@("Etkinlik geçmişini kapat","Uygulama/dosya etkinliğinizin toplanmasını ve buluta gönderilmesini durdurur.")
       EN=@("Disable activity history","Stops collecting and uploading your app/file activity.")
       Reg=@( @{P="$POL\Windows\System"; N="EnableActivityFeed"; V=0; D=$null}
              @{P="$POL\Windows\System"; N="PublishUserActivities"; V=0; D=$null}
              @{P="$POL\Windows\System"; N="UploadUserActivities"; V=0; D=$null} ) }

    # ---------------- ARAMA, EDGE & COPILOT ----------------
    @{ Id="Bing"; Cat="search"; Rec=$true; Restart="explorer"
       TR=@("Başlat aramasında Bing/web sonuçlarını kapat","Arama yalnızca yerel dosya ve uygulamaları gösterir, daha hızlı açılır.")
       EN=@("Disable Bing/web results in Start search","Search shows local files and apps only and opens faster.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; N="BingSearchEnabled"; V=0; D=$null}
              @{P="HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; N="DisableSearchBoxSuggestions"; V=1; D=$null} ) }

    @{ Id="EdgeBar"; Cat="search"; Rec=$true
       TR=@("Edge arama çubuğu widget'ını kapat","Masaüstündeki Edge arama çubuğunu engeller.")
       EN=@("Disable Edge search bar widget","Blocks the Edge search bar on the desktop.")
       Reg=@( @{P="$POL\Edge"; N="WebWidgetAllowed"; V=0; D=$null}
              @{P="$POL\Edge"; N="SearchbarAllowed"; V=0; D=$null} ) }

    @{ Id="EdgeJunk"; Cat="search"; Rec=$true
       TR=@("Edge önerilerini, alışveriş asistanını ve kenar çubuğunu kapat","Kişiselleştirme raporlamasını, öneri açılır pencerelerini ve Copilot kenar çubuğunu kapatır.")
       EN=@("Disable Edge suggestions, shopping & sidebar","Turns off personalization reporting, recommendation pop-ups and the Copilot sidebar.")
       Reg=@( @{P="$POL\Edge"; N="PersonalizationReportingEnabled"; V=0; D=$null}
              @{P="$POL\Edge"; N="ShowRecommendationsEnabled"; V=0; D=$null}
              @{P="$POL\Edge"; N="EdgeShoppingAssistantEnabled"; V=0; D=$null}
              @{P="$POL\Edge"; N="HubsSidebarEnabled"; V=0; D=$null} ) }

    @{ Id="Copilot"; Cat="search"; Rec=$true; Restart="explorer"
       TR=@("Windows Copilot'u kapat","Görev çubuğundaki Copilot düğmesini ve kısayolunu kaldırır.")
       EN=@("Disable Windows Copilot","Removes the Copilot taskbar button and shortcut.")
       Reg=@( @{P="HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; N="TurnOffWindowsCopilot"; V=1; D=$null}
              @{P=$ADV; N="ShowCopilotButton"; V=0; D=$null} ) }

    @{ Id="Widgets"; Cat="search"; Rec=$true; Restart="explorer"
       TR=@("Pencere öğelerini / Haber ve ilgi alanlarını kapat","Arka planda çalışan haber akışını ve widget panelini kapatır.")
       EN=@("Disable Widgets / News and interests","Turns off the background news feed and widgets board.")
       Reg=@( @{P="$POL\Dsh"; N="AllowNewsAndInterests"; V=0; D=$null}
              @{P="$POL\Windows\Windows Feeds"; N="EnableFeeds"; V=0; D=$null} ) }

    # ---------------- SİSTEM & TELEMETRİ ----------------
    @{ Id="Telemetry"; Cat="system"; Rec=$true
       TR=@("Telemetri ve veri toplamayı kapat","Tanılama verisini en aza indirir, DiagTrack ve WAP Push servislerini durdurur.")
       EN=@("Disable telemetry & data collection","Minimizes diagnostic data and stops DiagTrack and WAP Push services.")
       Reg=@( @{P="$POL\Windows\DataCollection"; N="AllowTelemetry"; V=0; D=$null}
              @{P="$POL\Windows\DataCollection"; N="DoNotShowFeedbackNotifications"; V=1; D=$null} )
       Svc=@( @{N="DiagTrack"; D="Automatic"}, @{N="dmwappushservice"; D="Manual"} ) }

    @{ Id="Cortana"; Cat="system"; Rec=$true
       TR=@("Cortana'yı devre dışı bırak","Cortana'yı ve kilit ekranındaki erişimini kapatır.")
       EN=@("Disable Cortana","Turns off Cortana including above the lock screen.")
       Reg=@( @{P="$POL\Windows\Windows Search"; N="AllowCortana"; V=0; D=$null}
              @{P="$POL\Windows\Windows Search"; N="AllowCortanaAboveLock"; V=0; D=$null} ) }

    @{ Id="Consumer"; Cat="system"; Rec=$true
       TR=@("Tüketici özelliklerini kapat","Otomatik yüklenen sponsorlu uygulamaları (Candy Crush vb.) engeller.")
       EN=@("Disable consumer features","Blocks auto-installed sponsored apps (Candy Crush etc.).")
       Reg=@( @{P="$POL\Windows\CloudContent"; N="DisableWindowsConsumerFeatures"; V=1; D=$null}
              @{P="$POL\Windows\CloudContent"; N="DisableConsumerAccountStateContent"; V=1; D=$null} ) }

    @{ Id="Feedback"; Cat="system"; Rec=$true
       TR=@("Geri bildirim isteklerini kapat","Windows'un 'bize geri bildirim verin' sorularını durdurur.")
       EN=@("Disable feedback requests","Stops Windows 'give us feedback' prompts.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Siuf\Rules"; N="NumberOfSIUFInPeriod"; V=0; D=$null} ) }

    @{ Id="ErrorReport"; Cat="system"; Rec=$false
       TR=@("Windows Hata Raporlamayı kapat","Çökme raporlarının Microsoft'a gönderilmesini ve WerSvc servisini kapatır.")
       EN=@("Disable Windows Error Reporting","Stops sending crash reports and disables WerSvc.")
       Reg=@( @{P="$POL\Windows\Windows Error Reporting"; N="Disabled"; V=1; D=$null} )
       Svc=@( @{N="WerSvc"; D="Manual"} ) }

    # ---------------- PERFORMANS ----------------
    @{ Id="EdgeBoost"; Cat="perf"; Rec=$true
       TR=@("Edge'in arka planda çalışmasını kapat","Startup Boost ve arka plan modunu kapatır; Edge kapalıyken RAM tüketmez.")
       EN=@("Stop Edge running in background","Disables Startup Boost and background mode; Edge uses no RAM when closed.")
       Reg=@( @{P="$POL\Edge"; N="StartupBoostEnabled"; V=0; D=$null}
              @{P="$POL\Edge"; N="BackgroundModeEnabled"; V=0; D=$null} ) }

    @{ Id="StartupDelay"; Cat="perf"; Rec=$true
       TR=@("Başlangıç uygulaması gecikmesini kaldır","Oturum açıldıktan sonra başlangıç uygulamaları beklemeden açılır.")
       EN=@("Remove startup app delay","Startup apps launch immediately after sign-in.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; N="StartupDelayInMSec"; V=0; D=$null}
              @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; N="WaitForIdleState"; V=0; D=$null} ) }

    @{ Id="MenuDelay"; Cat="perf"; Rec=$true; Restart="logoff"
       TR=@("Menü açılma gecikmesini azalt","Alt menüler 400 ms yerine 100 ms'de açılır, arayüz daha çevik hissettirir.")
       EN=@("Reduce menu show delay","Sub-menus open in 100 ms instead of 400 ms.")
       Reg=@( @{P="HKCU:\Control Panel\Desktop"; N="MenuShowDelay"; V="100"; D="400"} ) }

    @{ Id="GameDVR"; Cat="perf"; Rec=$false
       TR=@("Xbox Game DVR arka plan kaydını kapat","Oyunlarda arka plan video yakalamayı kapatır, FPS'i artırabilir.")
       EN=@("Disable Xbox Game DVR background recording","Turns off background capture in games; may increase FPS.")
       Reg=@( @{P="HKCU:\System\GameConfigStore"; N="GameDVR_Enabled"; V=0; D=1}
              @{P="$POL\Windows\GameDVR"; N="AllowGameDVR"; V=0; D=$null} ) }

    @{ Id="BgApps"; Cat="perf"; Rec=$false
       TR=@("Mağaza uygulamalarının arka planda çalışmasını engelle","RAM/CPU tasarrufu sağlar. Uyarı: WhatsApp, Telefon Bağlantısı gibi uygulamaların bildirimleri gecikebilir.")
       EN=@("Block Store apps from running in background","Saves RAM/CPU. Warning: notifications from apps like WhatsApp or Phone Link may be delayed.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; N="GlobalUserDisabled"; V=1; D=$null}
              @{P="$POL\Windows\AppPrivacy"; N="LetAppsRunInBackground"; V=2; D=$null} ) }
)

# ---------------- MOTOR ----------------
function Get-WoRegValue([string]$Path, [string]$Name) {
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

# Yedek yol: WMI StdRegProv. Bazi anahtarlar (or. Widgets/Dsh) UCPD surucusu tarafindan
# powershell.exe/reg.exe icin kilitlenir; yazmayi WmiPrvSE yaptigi icin engele takilmaz.
function Set-WoRegValueWmi([string]$Path, [string]$Name, $Value) {
    $hive = if ($Path -like "HKLM:*") { [uint32]2147483650 } else { [uint32]2147483649 }
    $sub  = $Path -replace '^HK(LM|CU):\\', ''
    $base = @{ hDefKey = $hive; sSubKeyName = $sub }
    $cim  = @{ Namespace = "root/default"; ClassName = "StdRegProv"; ErrorAction = "Stop" }
    if ($null -eq $Value) {
        $r = Invoke-CimMethod @cim -MethodName DeleteValue -Arguments ($base + @{ sValueName = $Name })
        if ($r.ReturnValue -notin 0, 2) { throw "WMI DeleteValue: $($r.ReturnValue)" }   # 2 = zaten yok
        return
    }
    [void](Invoke-CimMethod @cim -MethodName CreateKey -Arguments $base)
    $r = if ($Value -is [string]) {
        Invoke-CimMethod @cim -MethodName SetStringValue -Arguments ($base + @{ sValueName = $Name; sValue = $Value })
    } else {
        Invoke-CimMethod @cim -MethodName SetDWORDValue -Arguments ($base + @{ sValueName = $Name; uValue = [uint32]$Value })
    }
    if ($r.ReturnValue -ne 0) { throw "WMI SetValue: $($r.ReturnValue)" }
}

function Set-WoRegValue([string]$Path, [string]$Name, $Value) {
    try {
        if ($null -eq $Value) {
            if ($null -ne (Get-WoRegValue $Path $Name)) { Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop }
        } else {
            if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
            $type = if ($Value -is [string]) { "String" } else { "DWord" }
            New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $type -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        $first = $_.Exception.Message
        try { Set-WoRegValueWmi $Path $Name $Value }
        catch { throw "$Path\$Name : $first (WMI: $($_.Exception.Message))" }
    }
    # Dogrula: yazilan deger gercekten yerinde mi?
    $now = Get-WoRegValue $Path $Name
    if (($null -eq $Value -and $null -ne $now) -or ($null -ne $Value -and "$now" -ne "$Value")) {
        throw "$Path\$Name : deger yazilamadi"
    }
}

function Test-WoTweak($Tweak) {
    foreach ($r in $Tweak.Reg) {
        $cur = Get-WoRegValue $r.P $r.N
        if ($null -eq $cur -or "$cur" -ne "$($r.V)") { return $false }
    }
    foreach ($s in $Tweak.Svc) {
        $svc = Get-Service -Name $s.N -ErrorAction SilentlyContinue
        if ($svc -and "$($svc.StartType)" -ne "Disabled") { return $false }
    }
    return $true
}

function Invoke-WoTweak($Tweak, [switch]$Revert) {
    foreach ($r in $Tweak.Reg) {
        $val = if ($Revert) { $r.D } else { $r.V }
        Set-WoRegValue $r.P $r.N $val
    }
    foreach ($s in $Tweak.Svc) {
        if (-not (Get-Service -Name $s.N -ErrorAction SilentlyContinue)) { continue }
        if ($Revert) {
            Set-Service -Name $s.N -StartupType $s.D -ErrorAction Stop
        } else {
            Stop-Service -Name $s.N -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s.N -StartupType Disabled -ErrorAction Stop
        }
    }
}

function Get-WoTweak([string]$Id) { $TweakCatalog | Where-Object { $_.Id -eq $Id } | Select-Object -First 1 }
