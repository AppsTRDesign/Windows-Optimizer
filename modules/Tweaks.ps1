# modules/Tweaks.ps1 - Optimizasyon katalogu ve uygulama motoru
# Her tweak: Reg (P=yol, N=ad, V=uygulanan deger, D=varsayilan; D=$null -> deger silinir)
#            Svc (N=servis, D=varsayilan baslangic tipi)
#            Test/Apply/Revert: registry disi ayarlar icin ozel scriptblock'lar
#            Restart: 'explorer' | 'logoff' | 'reboot' | $null

$CDM   = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$ADV   = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$POL   = "HKLM:\SOFTWARE\Policies\Microsoft"
$CAM   = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$MMCSS = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$WoPlanGuid = "57a1c0de-0000-4000-8000-0000000000aa"   # Uygulamanin olusturdugu Nihai Performans kopyasi

$TweakCategories = [ordered]@{
    ads    = @{ Icon = [char]0xE72E; TR = "Reklamlar & Öneriler";  EN = "Ads & Suggestions" }
    perm   = @{ Icon = [char]0xE8D7; TR = "Gizlilik İzinleri";     EN = "Privacy Permissions" }
    search = @{ Icon = [char]0xE774; TR = "Arama, Edge & Copilot"; EN = "Search, Edge & Copilot" }
    system = @{ Icon = [char]0xE770; TR = "Sistem & Telemetri";    EN = "System & Telemetry" }
    perf   = @{ Icon = [char]0xE945; TR = "Performans";            EN = "Performance" }
    game   = @{ Icon = [char]0xE7FC; TR = "Oyun Performansı";      EN = "Gaming Performance" }
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

    @{ Id="BgApps"; Cat="perf"; Rec=$false
       TR=@("Mağaza uygulamalarının arka planda çalışmasını engelle","RAM/CPU tasarrufu sağlar. Uyarı: WhatsApp, Telefon Bağlantısı gibi uygulamaların bildirimleri gecikebilir.")
       EN=@("Block Store apps from running in background","Saves RAM/CPU. Warning: notifications from apps like WhatsApp or Phone Link may be delayed.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; N="GlobalUserDisabled"; V=1; D=$null}
              @{P="$POL\Windows\AppPrivacy"; N="LetAppsRunInBackground"; V=2; D=$null} ) }

    @{ Id="VisualFx"; Cat="perf"; Rec=$false; Restart="logoff"
       TR=@("Görsel efektleri performans için azalt","Pencere/görev çubuğu animasyonlarını, seçim gölgelerini ve Aero Peek'i kapatır. Yazı tipi yumuşatma korunur.")
       EN=@("Reduce visual effects for performance","Turns off window/taskbar animations, selection shadows and Aero Peek. Font smoothing is kept.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; N="VisualFXSetting"; V=3; D=$null}
              @{P="HKCU:\Control Panel\Desktop\WindowMetrics"; N="MinAnimate"; V="0"; D="1"}
              @{P=$ADV; N="TaskbarAnimations"; V=0; D=1}
              @{P=$ADV; N="ListviewAlphaSelect"; V=0; D=1}
              @{P=$ADV; N="ListviewShadow"; V=0; D=1}
              @{P="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; N="EnableAeroPeek"; V=0; D=1} ) }

    @{ Id="Transparency"; Cat="perf"; Rec=$false
       TR=@("Şeffaflık efektlerini kapat","Başlat, görev çubuğu ve pencerelerdeki saydamlığı kapatır; zayıf GPU'larda akıcılığı artırır.")
       EN=@("Disable transparency effects","Turns off transparency in Start, taskbar and windows; smoother on weak GPUs.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; N="EnableTransparency"; V=0; D=1} ) }

    @{ Id="Hibernate"; Cat="perf"; Rec=$false
       TR=@("Hazırda bekletmeyi kapat","hiberfil.sys dosyasını silerek RAM boyutu kadar disk alanı kazandırır. Hızlı Başlangıç da kapanır.")
       EN=@("Disable hibernation","Deletes hiberfil.sys, freeing disk space equal to your RAM. Also disables Fast Startup.")
       Test={ (Get-WoRegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabled") -eq 0 }
       Apply={ & powercfg.exe /hibernate off; if ($LASTEXITCODE) { throw "powercfg /hibernate off: $LASTEXITCODE" } }
       Revert={ & powercfg.exe /hibernate on; if ($LASTEXITCODE) { throw "powercfg /hibernate on: $LASTEXITCODE" } } }

    @{ Id="DeliveryOpt"; Cat="perf"; Rec=$true
       TR=@("Güncellemelerin P2P paylaşımını kapat","Windows Update dosyalarının internetteki diğer bilgisayarlara yüklenmesini durdurur; bant genişliği ve disk tasarrufu.")
       EN=@("Disable P2P update sharing","Stops uploading Windows Update files to other PCs on the internet; saves bandwidth and disk.")
       Reg=@( @{P="$POL\Windows\DeliveryOptimization"; N="DODownloadMode"; V=0; D=$null} ) }

    # ---------------- GİZLİLİK İZİNLERİ ----------------
    @{ Id="PermLocation"; Cat="perm"; Rec=$false
       TR=@("Konum erişimi","Uygulamaların ve Windows'un konumunuza erişimi. Kapatılırsa hava durumu, saat dilimi ve Cihazımı Bul etkilenir.")
       EN=@("Location access","Apps and Windows can access your location. If turned off, weather, time zone and Find My Device are affected.")
       Reg=@( @{P="$CAM\location"; N="Value"; V="Deny"; D="Allow"}
              @{P="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; N="Value"; V="Deny"; D="Allow"} ) }

    @{ Id="PermMic"; Cat="perm"; Rec=$false
       TR=@("Mikrofon erişimi","Uygulamaların mikrofona erişimi. Kapatılırsa Discord, Teams ve oyun içi sesli sohbet çalışmaz.")
       EN=@("Microphone access","Apps can use the microphone. If turned off, Discord, Teams and in-game voice chat stop working.")
       Reg=@( @{P="$CAM\microphone"; N="Value"; V="Deny"; D="Allow"}
              @{P="$CAM\microphone\NonPackaged"; N="Value"; V="Deny"; D="Allow"} ) }

    @{ Id="PermCamera"; Cat="perm"; Rec=$false
       TR=@("Kamera erişimi","Uygulamaların kameraya erişimi. Kapatılırsa görüntülü görüşme uygulamaları çalışmaz.")
       EN=@("Camera access","Apps can use the camera. If turned off, video call apps stop working.")
       Reg=@( @{P="$CAM\webcam"; N="Value"; V="Deny"; D="Allow"}
              @{P="$CAM\webcam\NonPackaged"; N="Value"; V="Deny"; D="Allow"} ) }

    @{ Id="PermData"; Cat="perm"; Rec=$true
       TR=@("Kişisel verilere uygulama erişimi","Uygulamaların kişiler, takvim, arama geçmişi, e-posta, mesajlar, görevler, hesap bilgisi ve radyolara (Bluetooth) erişimi.")
       EN=@("App access to personal data","App access to contacts, calendar, call history, email, messages, tasks, account info and radios.")
       Reg=@( "contacts","appointments","phoneCall","phoneCallHistory","email","chat","userDataTasks","userAccountInformation","radios" |
              ForEach-Object { @{P="$CAM\$_"; N="Value"; V="Deny"; D="Allow"} } ) }

    @{ Id="PermDiag"; Cat="perm"; Rec=$true
       TR=@("Uygulama tanılama erişimi","Uygulamaların diğer uygulamalar hakkında tanılama bilgisi okuması.")
       EN=@("App diagnostics access","Apps can read diagnostic info about other apps.")
       Reg=@( @{P="$CAM\appDiagnostics"; N="Value"; V="Deny"; D="Allow"} ) }

    @{ Id="PermSpeech"; Cat="perm"; Rec=$true
       TR=@("Çevrimiçi konuşma tanıma","Ses verileriniz tanıma için Microsoft bulutuna gönderilir.")
       EN=@("Online speech recognition","Your voice data is sent to Microsoft's cloud for recognition.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; N="HasAccepted"; V=0; D=$null} ) }

    @{ Id="PermInking"; Cat="perm"; Rec=$true
       TR=@("Yazma ve mürekkep kişiselleştirmesi","Klavye/kalem girişinizden kişisel sözlük oluşturulur ve Microsoft'a gönderilir.")
       EN=@("Inking & typing personalization","A personal dictionary is built from your typing/pen input and sent to Microsoft.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\InputPersonalization"; N="RestrictImplicitInkCollection"; V=1; D=0}
              @{P="HKCU:\SOFTWARE\Microsoft\InputPersonalization"; N="RestrictImplicitTextCollection"; V=1; D=0}
              @{P="HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"; N="HarvestContacts"; V=0; D=1}
              @{P="HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; N="AcceptedPrivacyPolicy"; V=0; D=1} ) }

    # ---------------- OYUN ----------------
    @{ Id="GameMode"; Cat="game"; Rec=$true
       TR=@("Oyun Modunu etkinleştir","Oyun açıkken Windows Update ve arka plan işlerini erteler, CPU/GPU'yu oyuna ayırır.")
       EN=@("Enable Game Mode","Defers Windows Update and background work while gaming, prioritizing CPU/GPU for the game.")
       Reg=@( @{P="HKCU:\SOFTWARE\Microsoft\GameBar"; N="AutoGameModeEnabled"; V=1; D=$null}
              @{P="HKCU:\SOFTWARE\Microsoft\GameBar"; N="AllowAutoGameMode"; V=1; D=$null} ) }

    @{ Id="GamePriority"; Cat="game"; Rec=$true
       TR=@("Oyunlara yüksek CPU/GPU önceliği ver","MMCSS ile oyun iş parçacıklarına öncelik verir, arka plan ağ kısıtlamasını kaldırır.")
       EN=@("Give games high CPU/GPU priority","Prioritizes game threads via MMCSS and removes background network throttling.")
       Reg=@( @{P="$MMCSS"; N="SystemResponsiveness"; V=10; D=20}
              @{P="$MMCSS"; N="NetworkThrottlingIndex"; V=[uint32]4294967295; D=10}
              @{P="$MMCSS\Tasks\Games"; N="GPU Priority"; V=8; D=8}
              @{P="$MMCSS\Tasks\Games"; N="Priority"; V=6; D=2}
              @{P="$MMCSS\Tasks\Games"; N="Scheduling Category"; V="High"; D="Medium"}
              @{P="$MMCSS\Tasks\Games"; N="SFIO Priority"; V="High"; D="Normal"} ) }

    @{ Id="PowerPlan"; Cat="game"; Rec=$false
       TR=@("Nihai Performans güç planını etkinleştir","CPU'nun güç tasarrufu durumlarına girmesini önler, gecikmeyi azaltır. Dizüstünde pil daha hızlı biter.")
       EN=@("Enable Ultimate Performance power plan","Keeps the CPU out of power-saving states for lower latency. Drains laptop battery faster.")
       Test={ (& powercfg.exe /getactivescheme) -match $WoPlanGuid }
       Apply={
           $prev = ([regex]::Match((& powercfg.exe /getactivescheme), '[0-9a-fA-F-]{36}')).Value
           if ($prev -and $prev -ne $WoPlanGuid) { Set-WoRegValue "HKCU:\SOFTWARE\WindowsOptimizer" "PrevPowerScheme" $prev }
           if (-not ((& powercfg.exe /list) -match $WoPlanGuid)) {
               & powercfg.exe /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $WoPlanGuid | Out-Null   # Nihai Performans
               if ($LASTEXITCODE) { & powercfg.exe /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c $WoPlanGuid | Out-Null }  # Yuksek Performans
               if ($LASTEXITCODE) { throw "Guc plani olusturulamadi ($LASTEXITCODE)" }
               & powercfg.exe /changename $WoPlanGuid "Windows Optimizer - Ultimate" | Out-Null
           }
           & powercfg.exe /setactive $WoPlanGuid
           if ($LASTEXITCODE) { throw "Guc plani etkinlestirilemedi ($LASTEXITCODE)" }
       }
       Revert={
           $prev = Get-WoRegValue "HKCU:\SOFTWARE\WindowsOptimizer" "PrevPowerScheme"
           if (-not $prev) { $prev = "381b4222-f694-41f0-9685-ff5bb260df2e" }   # Dengeli
           & powercfg.exe /setactive $prev
           if ($LASTEXITCODE) { & powercfg.exe /setactive 381b4222-f694-41f0-9685-ff5bb260df2e }
           & powercfg.exe /delete $WoPlanGuid | Out-Null
       } }

    @{ Id="HAGS"; Cat="game"; Rec=$false; Restart="reboot"
       TR=@("Donanım hızlandırmalı GPU zamanlamasını aç","GPU belleğini ekran kartı kendisi yönetir; gecikmeyi azaltabilir. Destekleyen GPU (GTX 1000 / RX 5000 ve üstü) gerekir.")
       EN=@("Enable hardware-accelerated GPU scheduling","The GPU manages its own memory; may reduce latency. Requires a supporting GPU (GTX 1000 / RX 5000 or newer).")
       Reg=@( @{P="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; N="HwSchMode"; V=2; D=1} ) }

    @{ Id="FSO"; Cat="game"; Rec=$false
       TR=@("Tam ekran optimizasyonlarını kapat","Oyunları gerçek özel tam ekranda çalıştırır; bazı eski DirectX 9/11 oyunlarda giriş gecikmesini azaltır.")
       EN=@("Disable fullscreen optimizations","Runs games in true exclusive fullscreen; can reduce input lag in some older DirectX 9/11 games.")
       Reg=@( @{P="HKCU:\System\GameConfigStore"; N="GameDVR_FSEBehaviorMode"; V=2; D=$null}
              @{P="HKCU:\System\GameConfigStore"; N="GameDVR_FSEBehavior"; V=2; D=$null}
              @{P="HKCU:\System\GameConfigStore"; N="GameDVR_HonorUserFSEBehaviorMode"; V=1; D=$null}
              @{P="HKCU:\System\GameConfigStore"; N="GameDVR_DXGIHonorFSEWindowsCompatible"; V=1; D=$null} ) }

    @{ Id="MouseAccel"; Cat="game"; Rec=$false; Restart="logoff"
       TR=@("Fare ivmesini kapat (işaretçi hassasiyeti)","Fare hareketi hıza göre değişmez; nişan alma tutarlı olur. FPS oyuncuları için önerilir.")
       EN=@("Disable mouse acceleration (pointer precision)","Mouse movement no longer scales with speed for consistent aim. Recommended for FPS players.")
       Reg=@( @{P="HKCU:\Control Panel\Mouse"; N="MouseSpeed"; V="0"; D="1"}
              @{P="HKCU:\Control Panel\Mouse"; N="MouseThreshold1"; V="0"; D="6"}
              @{P="HKCU:\Control Panel\Mouse"; N="MouseThreshold2"; V="0"; D="10"} ) }

    @{ Id="GameDVR"; Cat="game"; Rec=$true
       TR=@("Xbox Game DVR arka plan kaydını kapat","Oyunlarda arka plan video yakalamayı kapatır, FPS'i artırabilir.")
       EN=@("Disable Xbox Game DVR background recording","Turns off background capture in games; may increase FPS.")
       Reg=@( @{P="HKCU:\System\GameConfigStore"; N="GameDVR_Enabled"; V=0; D=1}
              @{P="$POL\Windows\GameDVR"; N="AllowGameDVR"; V=0; D=$null} ) }
)

# ---------------- MOTOR ----------------
function Get-WoRegValue([string]$Path, [string]$Name) {
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

# Yedek yol 1: WMI StdRegProv (yazmayi WmiPrvSE yapar).
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

# Yedek yol 2: Yerel Grup Ilkesi (Registry.pol + gpupdate). gpedit / LGPO.exe ile ayni yontem:
# deger ilke dosyasina yazilir, registry'ye Grup Ilkesi servisi uygular. UCPD'nin kilitledigi
# politika anahtarlari (or. Widgets / Dsh) icin resmi yoldur.
$WoGpoRoot = Join-Path $env:SystemRoot "System32\GroupPolicy"

function Read-WoPol([string]$File) {
    $list = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $File)) { return , $list }
    $b = [IO.File]::ReadAllBytes($File)
    if ($b.Length -lt 8 -or [Text.Encoding]::ASCII.GetString($b, 0, 4) -ne "PReg") { throw "Gecersiz Registry.pol" }
    $u = [Text.Encoding]::Unicode
    $i = 8
    $readStr = {
        $start = $script:polPos
        while ([BitConverter]::ToUInt16($b, $script:polPos) -ne 0) { $script:polPos += 2 }
        $s = $u.GetString($b, $start, $script:polPos - $start); $script:polPos += 2; $s
    }
    while ($i -lt $b.Length) {
        $script:polPos = $i + 2                       # '['
        $key = & $readStr; $script:polPos += 2        # ';'
        $val = & $readStr; $script:polPos += 2
        $type = [BitConverter]::ToUInt32($b, $script:polPos); $script:polPos += 6
        $size = [BitConverter]::ToUInt32($b, $script:polPos); $script:polPos += 6
        $data = New-Object byte[] $size
        [Array]::Copy($b, $script:polPos, $data, 0, $size); $script:polPos += $size + 2   # ']'
        [void]$list.Add([pscustomobject]@{ Key = $key; Value = $val; Type = $type; Data = $data })
        $i = $script:polPos
    }
    return , $list
}

function Write-WoPol([string]$File, $Entries) {
    $u = [Text.Encoding]::Unicode
    $ms = New-Object IO.MemoryStream
    $w = New-Object IO.BinaryWriter($ms)
    $w.Write([Text.Encoding]::ASCII.GetBytes("PReg")); $w.Write([uint32]1)
    $sep = $u.GetBytes(";")
    foreach ($e in $Entries) {
        $w.Write($u.GetBytes("[")); $w.Write($u.GetBytes($e.Key + [char]0)); $w.Write($sep)
        $w.Write($u.GetBytes($e.Value + [char]0)); $w.Write($sep)
        $w.Write([uint32]$e.Type); $w.Write($sep)
        $w.Write([uint32]$e.Data.Length); $w.Write($sep)
        $w.Write([byte[]]$e.Data); $w.Write($u.GetBytes("]"))
    }
    $w.Flush()
    New-Item -ItemType Directory -Path (Split-Path $File -Parent) -Force | Out-Null
    [IO.File]::WriteAllBytes($File, $ms.ToArray())
}

# gpt.ini: surumu artir ve registry CSE'yi kaydet (yoksa Grup Ilkesi dosyayi islemez)
function Update-WoGptIni([bool]$Machine) {
    $ini = Join-Path $WoGpoRoot "gpt.ini"
    $lines = if (Test-Path $ini) { @(Get-Content $ini) } else { @("[General]") }
    $cse = "[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}]"
    $extKey = if ($Machine) { "gPCMachineExtensionNames" } else { "gPCUserExtensionNames" }
    $ver = 0; $hasExt = $false
    $out = foreach ($l in $lines) {
        if ($l -match '^Version=(\d+)') { $ver = [int64]$Matches[1]; continue }
        if ($l -match "^$extKey=(.*)") {
            $hasExt = $true
            if ($Matches[1] -notlike "*35378EAC-683F-11D2-A89A-00C04FBBCFA2*") { "$extKey=$cse$($Matches[1])" } else { $l }
            continue
        }
        $l
    }
    if (-not $hasExt) { $out = @($out) + "$extKey=$cse" }
    # Dusuk 16 bit = bilgisayar, yuksek 16 bit = kullanici surumu
    $ver = if ($Machine) { $ver + 1 } else { $ver + 65536 }
    $out = @($out) + "Version=$ver"
    [IO.File]::WriteAllLines($ini, [string[]]$out, [Text.Encoding]::ASCII)
}

function Set-WoRegValueGpo([string]$Path, [string]$Name, $Value) {
    $machine = $Path -like "HKLM:*"
    $key = $Path -replace '^HK(LM|CU):\\', ''
    $file = Join-Path $WoGpoRoot ($(if ($machine) { "Machine" } else { "User" }) + "\Registry.pol")
    $entries = Read-WoPol $file
    foreach ($e in @($entries)) {
        if ($e.Key -eq $key -and ($e.Value -eq $Name -or $e.Value -eq "**del.$Name")) { $entries.Remove($e) }
    }
    $u = [Text.Encoding]::Unicode
    if ($null -eq $Value) {
        # "**del." yonergesi: Grup Ilkesi degeri registry'den siler
        [void]$entries.Add([pscustomobject]@{ Key = $key; Value = "**del.$Name"; Type = 1; Data = $u.GetBytes(" " + [char]0) })
    } elseif ($Value -is [string]) {
        [void]$entries.Add([pscustomobject]@{ Key = $key; Value = $Name; Type = 1; Data = $u.GetBytes($Value + [char]0) })
    } else {
        [void]$entries.Add([pscustomobject]@{ Key = $key; Value = $Name; Type = 4; Data = [BitConverter]::GetBytes([uint32]$Value) })
    }
    Write-WoPol $file $entries
    Update-WoGptIni $machine
    $target = if ($machine) { "computer" } else { "user" }
    Start-Process gpupdate.exe -ArgumentList "/target:$target", "/force" -WindowStyle Hidden -Wait
    for ($i = 0; $i -lt 20; $i++) {
        $now = Get-WoRegValue $Path $Name
        if (($null -eq $Value -and $null -eq $now) -or ($null -ne $Value -and (Test-WoRegEqual $now $Value))) { return }
        Start-Sleep -Milliseconds 500
    }
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
        $msgs = @($_.Exception.Message)
        $done = $false
        try { Set-WoRegValueWmi $Path $Name $Value; $done = $true } catch { $msgs += "WMI: $($_.Exception.Message)" }
        if (-not $done -and $Path -match '^HK(LM|CU):\\SOFTWARE\\Policies\\') {
            try { Set-WoRegValueGpo $Path $Name $Value; $done = $true } catch { $msgs += "GPO: $($_.Exception.Message)" }
        }
        if (-not $done) { throw "$Path\$Name : $($msgs -join ' | ')" }
    }
    # Dogrula: yazilan deger gercekten yerinde mi?
    $now = Get-WoRegValue $Path $Name
    if (($null -eq $Value -and $null -ne $now) -or ($null -ne $Value -and -not (Test-WoRegEqual $now $Value))) {
        throw "$Path\$Name : deger yazildi ama dogrulanamadi (okunan: $now, beklenen: $Value)"
    }
}

# DWORD'ler okunurken Int32 ya da UInt32 donebilir (-1 = 4294967295); bit degeriyle karsilastir
function Test-WoRegEqual($A, $B) {
    if ($null -eq $A -or $null -eq $B) { return $false }
    $num = { param($x) $x -is [int] -or $x -is [uint32] -or $x -is [long] -or $x -is [int16] -or $x -is [byte] }
    if ((& $num $A) -and (& $num $B)) { return ([int64]$A -band 4294967295L) -eq ([int64]$B -band 4294967295L) }
    return "$A" -eq "$B"
}

function Test-WoTweak($Tweak) {
    if ($Tweak.Test) { try { if (-not (& $Tweak.Test)) { return $false } } catch { return $false } }
    foreach ($r in $Tweak.Reg) {
        if (-not (Test-WoRegEqual (Get-WoRegValue $r.P $r.N) $r.V)) { return $false }
    }
    foreach ($s in $Tweak.Svc) {
        $svc = Get-Service -Name $s.N -ErrorAction SilentlyContinue
        if ($svc -and "$($svc.StartType)" -ne "Disabled") { return $false }
    }
    return $true
}

function Invoke-WoTweak($Tweak, [switch]$Revert) {
    if ($Revert -and $Tweak.Revert) { & $Tweak.Revert }
    if (-not $Revert -and $Tweak.Apply) { & $Tweak.Apply }
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
