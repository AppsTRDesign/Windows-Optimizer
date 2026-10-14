# WindowsOptimizer.ps1 - v2.0
# Moduler Windows 10/11 optimizasyon araci (WPF)
param([string]$Snapshot, [switch]$Updated)

[Console]::OutputEncoding = [Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $Snapshot) {
    try {
        Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList @(
            "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`""
        )
    } catch {}
    exit
}

$AppDir       = $PSScriptRoot
$LogPath      = Join-Path $env:TEMP "WindowsOptimizer.log"
$SettingsPath = Join-Path $AppDir "settings.json"

function Write-WoLog([string]$Msg) {
    try { "[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date), $Msg | Out-File $LogPath -Append -Encoding UTF8 } catch {}
}

. (Join-Path $AppDir "modules\RamCleaner.ps1")
. (Join-Path $AppDir "modules\Tweaks.ps1")
. (Join-Path $AppDir "modules\Updater.ps1")
. (Join-Path $AppDir "modules\Startup.ps1")
. (Join-Path $AppDir "modules\DiskCleaner.ps1")

# Konsol penceresini gizle (kisayol zaten gizli baslatir; dogrudan calistirma icin)
if (-not $Snapshot) { try { [void][WoNative]::ShowWindow([WoNative]::GetConsoleWindow(), 0) } catch {} }
[void](Enable-WoMemPrivileges)

$LocalVersion = "0.0.0"
try { $LocalVersion = (Get-Content (Join-Path $AppDir "version.json") -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch {}

$Config = [pscustomobject]@{ author = "AppsTRDesign"; github = ""; instagram = ""; website = ""; logo = "assets/logo.png" }
try { $Config = Get-Content (Join-Path $AppDir "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}

# ---------------- AYARLAR ----------------
$Settings = @{
    language  = "TR"
    autoClean = 0
    ram       = @{ WorkingSets = $true; Modified = $true; Standby = $true; LowStandby = $false; FileCache = $false }
}
if (Test-Path $SettingsPath) {
    try {
        $s = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($s.language -in @("TR", "EN")) { $Settings.language = $s.language }
        if ($s.autoClean -ne $null) { $Settings.autoClean = [int]$s.autoClean }
        if ($s.ram) { foreach ($k in @($Settings.ram.Keys)) { if ($s.ram.$k -ne $null) { $Settings.ram[$k] = [bool]$s.ram.$k } } }
    } catch {}
}
function Save-WoSettings {
    try { $Settings | ConvertTo-Json -Depth 4 | Set-Content $SettingsPath -Encoding UTF8 } catch { Write-WoLog "Ayar kaydedilemedi: $_" }
}

# ---------------- DİL ----------------
$Str = @{
TR = @{
    NavCaption = "MENÜ"; NavHome = "Genel Bakış"; NavTweaks = "Optimizasyonlar"; NavMemory = "Bellek (RAM)"; NavSettings = "Ayarlar"
    Title_Home = "Genel Bakış"; Sub_Home = "Sisteminizin anlık durumu ve hızlı işlemler"
    Title_Tweaks = "Optimizasyonlar"; Sub_Tweaks = "Her ayarın gerçek durumu okunur — kapatırsanız Windows varsayılanına döner"
    Title_Memory = "Bellek (RAM)"; Sub_Memory = "Canlı bellek izleme ve optimizasyon"
    Title_Settings = "Ayarlar"; Sub_Settings = "Dil, güncellemeler ve bakım"
    UpdTitle = "Güncelleme mevcut"; BtnUpdate = "Şimdi güncelle"; UpdRetry = "Tekrar dene"; UpdVer = "v{0}  →  v{1}"
    Upd_start = "Hazırlanıyor…"; Upd_download = "İndiriliyor {0}/{1}"; Upd_verify = "Dosyalar doğrulanıyor…"
    Upd_ready = "Kuruluyor, yeniden başlatılıyor…"; Upd_error = "Hata: {0}"
    UpdChecking = "Güncellemeler denetleniyor…"; UpdLatest = "En güncel sürümü kullanıyorsunuz (v{0})"
    UpdAvailable = "Yeni sürüm mevcut: v{0} — sol menüden güncelleyebilirsiniz"; UpdFail = "Güncelleme sunucusuna ulaşılamadı"
    Updated = "Güncelleme tamamlandı — v{0} kullanıyorsunuz"
    HeroCaption = "OPTİMİZASYON DURUMU"; HeroLabel = "  optimizasyon etkin"; HeroHint = "Önerilen {0} ayardan {1} tanesi etkin"
    BtnQuickOptimize = "Önerilenleri Uygula"; BtnGoTweaks = "Tüm ayarları gör"
    CpuTitle = "İşlemci"; RamTitle = "Bellek"; DiskTitle = "Sistem Diski"
    CpuSub = "{0} mantıksal çekirdek · {1} işlem"; RamSub = "{0} / {1} kullanımda"; DiskSub = "{0} boş · toplam {1}"
    SysTitle = "Sistem Bilgisi"; LblOs = "İşletim sistemi"; LblBuild = "Derleme"; LblCpu = "İşlemci"; LblRam = "Fiziksel bellek"; LblUptime = "Çalışma süresi"; LblProc = "Çalışan işlem"
    Uptime = "{0} gün {1} sa {2} dk"
    QaTitle = "Hızlı İşlemler"
    QaCleanT = "Belleği temizle"; QaCleanD = "Standby ve working set belleğini serbest bırakır"
    QaExplorerT = "Explorer'ı yeniden başlat"; QaExplorerD = "Görev çubuğu/Başlat değişikliklerini anında uygular"
    QaRestoreT = "Geri yükleme noktası oluştur"; QaRestoreD = "Değişiklik yapmadan önce güvenli bir yedek alın"
    BtnSelRec = "Önerilenleri seç"; BtnSelReset = "Seçimi sıfırla"
    TwSummary = "{0} / {1} optimizasyon etkin"; TwPending = "  ·  {0} bekleyen değişiklik"
    BtnApplyN = "Uygula ({0})"; BtnApply0 = "Değişiklik yok"
    RestartText = "Bazı değişikliklerin görünmesi için Explorer'ın yeniden başlatılması gerekiyor."; BtnRestartExplorer = "Şimdi yeniden başlat"
    Chip_On = "Etkin"; Chip_Off = "Kapalı"; Chip_Apply = "Uygulanacak"; Chip_Revert = "Geri alınacak"; RecBadge = "ÖNERİLEN"
    NeedExplorer = "Explorer yeniden başlatma gerekir"; NeedLogoff = "Oturumu kapatıp açmak gerekir"
    Applying = "Optimizasyonlar uygulanıyor…"; ApplyOK = "{0} değişiklik başarıyla uygulandı"; ApplyWarn = "{0} başarılı, {1} hata — ayrıntılar günlük dosyasında"
    LogoffHint = " · Bazı ayarlar oturum yeniden açıldığında etkinleşir"
    MemInUseT = "Kullanımda"; MemStandbyT = "Önbellek (Standby)"; MemModifiedT = "Değiştirilmiş"; MemFreeT = "Boş"
    PctOfTotal = "toplamın %{0}"
    ChartTitle = "Canlı Bellek İzleme"; LiveText = "CANLI"; LegInUse = "Kullanımda"; LegModified = "Değiştirilmiş"; LegStandby = "Standby"
    AxisLeft = "2 dakika önce"; AxisRight = "şimdi"
    CleanTitle = "Bellek Optimizasyonu"
    OptWorkingSets = "Working set'leri boşalt"; OptWorkingSetsD = "Süreçlerin kullanmadığı sayfaları RAM'den çıkarır"
    OptModified = "Değiştirilmiş listeyi yaz"; OptModifiedD = "Bekleyen sayfaları diske yazıp serbest bırakır"
    OptStandby = "Standby listesini temizle"; OptStandbyD = "Tüm önbelleği boşaltır (en büyük etki)"
    OptLowStandby = "Sadece düşük öncelikli standby"; OptLowStandbyD = "Daha yumuşak; sık kullanılan önbellek korunur"
    OptFileCache = "Sistem dosya önbelleğini boşalt"; OptFileCacheD = "Dosya sistemi önbelleğini sıfırlar"
    BtnClean = "Belleği Optimize Et"; Cleaning = "Optimize ediliyor"
    AutoTitle = "Otomatik temizlik (kullanım eşiği)"; AutoOff = "Kapalı"
    CleanOK = "Bellek optimize edildi: +{0} kullanılabilir ({1} ms)"; CleanWarn = "Bazı işlemler başarısız oldu: {0}"; CleanAuto = "Otomatik: "
    ResTitle = "Son Optimizasyon"; ResNone = "Henüz optimizasyon yapılmadı. Sonuçlar burada önce/sonra olarak görünecek."
    ResGainSub = "kullanılabilir belleğe eklendi"; ResColBefore = "Önce"; ResColAfter = "Sonra"
    ResRowInUse = "Kullanımda"; ResRowStandby = "Standby"; ResRowModified = "Değiştirilmiş"; ResRowAvail = "Kullanılabilir"
    ResTime = "{0:HH:mm:ss} · {1} ms"
    ProcTitle = "En Çok Bellek Kullananlar"
    MemNote = "Not: Windows boş RAM'i önbellek (standby) olarak kullanır ve bu normaldir. Temizlik; oyun veya ağır bir uygulama açmadan önce, ya da bellek sıkıştığında anlık rahatlama sağlar."
    SetLangT = "Dil"; SetLangD = "Arayüz dili"
    SetUpdT = "Güncellemeler"; BtnCheckUpdate = "Güncellemeleri denetle"; VersionLbl = "Yüklü sürüm: v{0}"
    SetShortcutT = "Kısayollar"; SetShortcutD = "Masaüstü ve Başlat menüsü kısayolunu (yönetici olarak, konsolsuz) yeniden oluşturur."; BtnFixShortcut = "Kısayolu onar"
    ShortcutOK = "Kısayollar oluşturuldu ({0})"; ShortcutFail = "Kısayol oluşturulamadı"
    SetRestoreT = "Sistem Geri Yükleme"; SetRestoreD = "Optimizasyonlardan önce bir geri yükleme noktası oluşturmanız önerilir."; BtnRestore2 = "Nokta oluştur"
    RestoreBusy = "Geri yükleme noktası oluşturuluyor (1 dakika sürebilir)…"; RestoreOK = "Geri yükleme noktası oluşturuldu"; RestoreFail = "Geri yükleme noktası oluşturulamadı: {0}"
    SetLogT = "Günlük Dosyası"; SetLogD = "Hata ve işlem kayıtlarını görüntüleyin."; BtnOpenLog = "Günlüğü aç"
    SetAboutT = "Hakkında"
    ExplorerBusy = "Explorer yeniden başlatılıyor…"; ExplorerOK = "Explorer yeniden başlatıldı"
    StatusReady = "Hazır"; AdminBadge = "Yönetici modu"
    NeedReboot = "Yeniden başlatma gerekir"; RebootHint = " · Bazı ayarlar bilgisayar yeniden başlatıldığında etkinleşir"
    NavStartup = "Başlangıç"; NavDisk = "Disk Temizleme"
    Title_Startup = "Başlangıç Uygulamaları"; Sub_Startup = "Windows açılırken çalışan programları yönetin — açılışı hızlandırın"
    Title_Disk = "Disk Temizleme"; Sub_Disk = "Disk kapasiteleri ve gereksiz dosyalar"
    SuSummary = "{0} başlangıç öğesi · {1} etkin"; SuLoading = "Başlangıç öğeleri taranıyor…"
    SuHint = "Kapattığınız öğeler silinmez, sadece Windows açılırken başlamaz. Görev Yöneticisi ile uyumludur."
    BtnSuTaskMgr = "Görev Yöneticisi"; BtnSuRefresh = "Yenile"
    SuGroupOn = "ETKİN"; SuGroupOff = "DEVRE DIŞI"
    Src_RegUser = "Kayıt defteri (kullanıcı)"; Src_RegMachine = "Kayıt defteri (tüm kullanıcılar)"
    Src_FolderUser = "Başlangıç klasörü"; Src_FolderCommon = "Başlangıç klasörü (ortak)"; Src_Task = "Zamanlanmış görev"
    SuCritical = "SİSTEM"; SuMissing = "DOSYA YOK"; SuOpen = "Konumu aç"
    SuToggledOn = "{0} başlangıçta açılacak"; SuToggledOff = "{0} artık başlangıçta açılmayacak"; SuFail = "{0} değiştirilemedi: {1}"
    DcTitle = "Gereksiz Dosyalar"; DcSub = "Taranan kategorileri seçin ve temizleyin"
    BtnDiskScan = "Yeniden tara"; DcScanning = "Taranıyor…"; DcSelTitle = "SEÇİLİ ALAN"; DcSelFiles = "{0:N0} dosya · {1} kategori"
    BtnDiskClean = "Seçilenleri Temizle"; DcCleaning = "Temizleniyor…"
    DcResult = "{0} boşaltıldı"; DcResultSub = "{0:N0} dosya silindi · {1:N0} dosya kullanımda olduğu için atlandı"
    DcNote = "Kullanımdaki dosyalar ve son 24 saatte değişen geçici dosyalar atlanır. Tarayıcı geçmişi, şifreler ve çerezler silinmez."
    BtnCleanMgr = "Windows Disk Temizleme"; DcConfirm = "{0} kalıcı olarak silinecek.`n`nDevam edilsin mi?"
    DcRecycleConfirm = "`n`nGeri Dönüşüm Kutusu da kalıcı olarak boşaltılacak."
    DcDone = "Disk temizliği tamamlandı: {0} boşaltıldı"
    DriveFree = "{0} boş / {1}"; DriveSystem = "SİSTEM"; DriveLocal = "Yerel Disk"
}
EN = @{
    NavCaption = "MENU"; NavHome = "Overview"; NavTweaks = "Optimizations"; NavMemory = "Memory (RAM)"; NavSettings = "Settings"
    Title_Home = "Overview"; Sub_Home = "Live system status and quick actions"
    Title_Tweaks = "Optimizations"; Sub_Tweaks = "Each setting's real state is read — turning it off restores the Windows default"
    Title_Memory = "Memory (RAM)"; Sub_Memory = "Live memory monitoring and optimization"
    Title_Settings = "Settings"; Sub_Settings = "Language, updates and maintenance"
    UpdTitle = "Update available"; BtnUpdate = "Update now"; UpdRetry = "Try again"; UpdVer = "v{0}  →  v{1}"
    Upd_start = "Preparing…"; Upd_download = "Downloading {0}/{1}"; Upd_verify = "Verifying files…"
    Upd_ready = "Installing, restarting…"; Upd_error = "Error: {0}"
    UpdChecking = "Checking for updates…"; UpdLatest = "You are on the latest version (v{0})"
    UpdAvailable = "New version available: v{0} — update from the sidebar"; UpdFail = "Could not reach the update server"
    Updated = "Update complete — you are on v{0}"
    HeroCaption = "OPTIMIZATION STATUS"; HeroLabel = "  optimizations active"; HeroHint = "{1} of {0} recommended settings active"
    BtnQuickOptimize = "Apply Recommended"; BtnGoTweaks = "See all settings"
    CpuTitle = "Processor"; RamTitle = "Memory"; DiskTitle = "System Disk"
    CpuSub = "{0} logical cores · {1} processes"; RamSub = "{0} / {1} in use"; DiskSub = "{0} free · {1} total"
    SysTitle = "System Info"; LblOs = "Operating system"; LblBuild = "Build"; LblCpu = "Processor"; LblRam = "Physical memory"; LblUptime = "Uptime"; LblProc = "Processes"
    Uptime = "{0}d {1}h {2}m"
    QaTitle = "Quick Actions"
    QaCleanT = "Clean memory"; QaCleanD = "Frees standby and working set memory"
    QaExplorerT = "Restart Explorer"; QaExplorerD = "Applies taskbar/Start changes instantly"
    QaRestoreT = "Create restore point"; QaRestoreD = "Take a safe backup before making changes"
    BtnSelRec = "Select recommended"; BtnSelReset = "Reset selection"
    TwSummary = "{0} / {1} optimizations active"; TwPending = "  ·  {0} pending changes"
    BtnApplyN = "Apply ({0})"; BtnApply0 = "No changes"
    RestartText = "Explorer needs to restart for some changes to become visible."; BtnRestartExplorer = "Restart now"
    Chip_On = "Active"; Chip_Off = "Off"; Chip_Apply = "Will apply"; Chip_Revert = "Will revert"; RecBadge = "RECOMMENDED"
    NeedExplorer = "Requires Explorer restart"; NeedLogoff = "Requires sign out"
    Applying = "Applying optimizations…"; ApplyOK = "{0} changes applied successfully"; ApplyWarn = "{0} succeeded, {1} failed — see log file"
    LogoffHint = " · Some settings take effect after signing in again"
    MemInUseT = "In use"; MemStandbyT = "Cached (Standby)"; MemModifiedT = "Modified"; MemFreeT = "Free"
    PctOfTotal = "{0}% of total"
    ChartTitle = "Live Memory Monitor"; LiveText = "LIVE"; LegInUse = "In use"; LegModified = "Modified"; LegStandby = "Standby"
    AxisLeft = "2 minutes ago"; AxisRight = "now"
    CleanTitle = "Memory Optimization"
    OptWorkingSets = "Empty working sets"; OptWorkingSetsD = "Removes pages processes are not using"
    OptModified = "Flush modified list"; OptModifiedD = "Writes pending pages to disk and frees them"
    OptStandby = "Purge standby list"; OptStandbyD = "Clears the whole cache (biggest effect)"
    OptLowStandby = "Low-priority standby only"; OptLowStandbyD = "Gentler; keeps frequently used cache"
    OptFileCache = "Flush system file cache"; OptFileCacheD = "Resets the file system cache"
    BtnClean = "Optimize Memory"; Cleaning = "Optimizing"
    AutoTitle = "Auto clean (usage threshold)"; AutoOff = "Off"
    CleanOK = "Memory optimized: +{0} available ({1} ms)"; CleanWarn = "Some operations failed: {0}"; CleanAuto = "Auto: "
    ResTitle = "Last Optimization"; ResNone = "No optimization yet. Before/after results will appear here."
    ResGainSub = "added to available memory"; ResColBefore = "Before"; ResColAfter = "After"
    ResRowInUse = "In use"; ResRowStandby = "Standby"; ResRowModified = "Modified"; ResRowAvail = "Available"
    ResTime = "{0:HH:mm:ss} · {1} ms"
    ProcTitle = "Top Memory Consumers"
    MemNote = "Note: Windows uses free RAM as cache (standby), which is normal. Cleaning gives instant relief before launching a game or heavy app, or when memory is tight."
    SetLangT = "Language"; SetLangD = "Interface language"
    SetUpdT = "Updates"; BtnCheckUpdate = "Check for updates"; VersionLbl = "Installed version: v{0}"
    SetShortcutT = "Shortcuts"; SetShortcutD = "Recreates the Desktop and Start menu shortcut (as admin, without console)."; BtnFixShortcut = "Repair shortcut"
    ShortcutOK = "Shortcuts created ({0})"; ShortcutFail = "Could not create shortcut"
    SetRestoreT = "System Restore"; SetRestoreD = "Creating a restore point before optimizing is recommended."; BtnRestore2 = "Create point"
    RestoreBusy = "Creating restore point (may take a minute)…"; RestoreOK = "Restore point created"; RestoreFail = "Could not create restore point: {0}"
    SetLogT = "Log File"; SetLogD = "View error and activity logs."; BtnOpenLog = "Open log"
    SetAboutT = "About"
    ExplorerBusy = "Restarting Explorer…"; ExplorerOK = "Explorer restarted"
    StatusReady = "Ready"; AdminBadge = "Administrator mode"
    NeedReboot = "Requires restart"; RebootHint = " · Some settings take effect after restarting the PC"
    NavStartup = "Startup"; NavDisk = "Disk Cleanup"
    Title_Startup = "Startup Apps"; Sub_Startup = "Manage programs that run when Windows starts — boot faster"
    Title_Disk = "Disk Cleanup"; Sub_Disk = "Drive capacity and junk files"
    SuSummary = "{0} startup items · {1} enabled"; SuLoading = "Scanning startup items…"
    SuHint = "Disabled items are not deleted, they just don't start with Windows. Compatible with Task Manager."
    BtnSuTaskMgr = "Task Manager"; BtnSuRefresh = "Refresh"
    SuGroupOn = "ENABLED"; SuGroupOff = "DISABLED"
    Src_RegUser = "Registry (user)"; Src_RegMachine = "Registry (all users)"
    Src_FolderUser = "Startup folder"; Src_FolderCommon = "Startup folder (common)"; Src_Task = "Scheduled task"
    SuCritical = "SYSTEM"; SuMissing = "FILE MISSING"; SuOpen = "Open location"
    SuToggledOn = "{0} will start with Windows"; SuToggledOff = "{0} will no longer start with Windows"; SuFail = "Could not change {0}: {1}"
    DcTitle = "Junk Files"; DcSub = "Select scanned categories and clean"
    BtnDiskScan = "Rescan"; DcScanning = "Scanning…"; DcSelTitle = "SELECTED"; DcSelFiles = "{0:N0} files · {1} categories"
    BtnDiskClean = "Clean Selected"; DcCleaning = "Cleaning…"
    DcResult = "{0} freed"; DcResultSub = "{0:N0} files deleted · {1:N0} files skipped (in use)"
    DcNote = "Files in use and temp files changed in the last 24 hours are skipped. Browser history, passwords and cookies are not deleted."
    BtnCleanMgr = "Windows Disk Cleanup"; DcConfirm = "{0} will be permanently deleted.`n`nContinue?"
    DcRecycleConfirm = "`n`nThe Recycle Bin will also be permanently emptied."
    DcDone = "Disk cleanup complete: {0} freed"
    DriveFree = "{0} free / {1}"; DriveSystem = "SYSTEM"; DriveLocal = "Local Disk"
}
}
$script:Lang = $Settings.language
function T([string]$Key) { $v = $Str[$script:Lang][$Key]; if ($null -eq $v) { return $Key } return $v }

# ---------------- XAML ----------------
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Optimizer" Width="1160" Height="760" MinWidth="1020" MinHeight="660"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="CanResizeWithGrip" UseLayoutRounding="True"
        FontFamily="Segoe UI Variable Text, Segoe UI" TextOptions.TextFormattingMode="Display">
  <Window.Resources>
    <FontFamily x:Key="Icons">Segoe Fluent Icons, Segoe MDL2 Assets</FontFamily>
    <SolidColorBrush x:Key="CardBg" Color="#14141F"/>
    <SolidColorBrush x:Key="CardLine" Color="#22223A"/>
    <SolidColorBrush x:Key="Txt" Color="#EDEDF5"/>
    <SolidColorBrush x:Key="Txt2" Color="#B4B4CC"/>
    <SolidColorBrush x:Key="Muted" Color="#7A7A94"/>
    <SolidColorBrush x:Key="Accent" Color="#8B5CF6"/>
    <LinearGradientBrush x:Key="AccentGrad" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#7C5CFF" Offset="0"/><GradientStop Color="#A855F7" Offset="1"/>
    </LinearGradientBrush>

    <Style TargetType="ScrollViewer">
      <Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
      <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="8"/>
      <Setter Property="MinWidth" Value="8"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border x:Name="T" CornerRadius="4" Background="#2C2C46"/>
                      <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="T" Property="Background" Value="#43436A"/></Trigger>
                      </ControlTemplate.Triggers>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource CardBg}"/>
      <Setter Property="BorderBrush" Value="{StaticResource CardLine}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="12"/>
      <Setter Property="Padding" Value="20"/>
    </Style>
    <Style x:Key="CardTitle" TargetType="TextBlock">
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{StaticResource Txt}"/>
    </Style>
    <Style x:Key="Caption" TargetType="TextBlock">
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{StaticResource Muted}"/>
    </Style>
    <Style x:Key="Desc" TargetType="TextBlock">
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Foreground" Value="{StaticResource Muted}"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="Ico" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="{StaticResource Icons}"/>
      <Setter Property="FontSize" Value="16"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>

    <Style x:Key="NavBtn" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#9C9CB8"/>
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="Height" Value="42"/>
      <Setter Property="Margin" Value="12,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="GroupName" Value="nav"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="9" Background="Transparent">
              <Grid>
                <Border x:Name="Ind" Width="3" Height="18" CornerRadius="2" HorizontalAlignment="Left"
                        Background="{StaticResource AccentGrad}" Visibility="Collapsed"/>
                <StackPanel Orientation="Horizontal" Margin="16,0,0,0" VerticalAlignment="Center">
                  <TextBlock x:Name="Ic" Text="{TemplateBinding Tag}" FontFamily="{StaticResource Icons}"
                             FontSize="16" VerticalAlignment="Center" Margin="0,0,14,0"/>
                  <ContentPresenter VerticalAlignment="Center"/>
                </StackPanel>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#191928"/>
                <Setter Property="Foreground" Value="#E6E6F2"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#211D3B"/>
                <Setter Property="Foreground" Value="White"/>
                <Setter TargetName="Ind" Property="Visibility" Value="Visible"/>
                <Setter TargetName="Ic" Property="Foreground" Value="#A78BFA"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SegBtn" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#B4B4CC"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,0,6,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="7" Background="#1B1B2B" BorderBrush="#2A2A42" BorderThickness="1" Padding="12,6">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#4A4A70"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{StaticResource AccentGrad}"/>
                <Setter TargetName="Bd" Property="BorderBrush" Value="#8B5CF6"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="Track" Width="44" Height="24" CornerRadius="12" Background="#24243A"
                    BorderBrush="#3A3A58" BorderThickness="1">
              <Ellipse x:Name="Thumb" Width="16" Height="16" Fill="#9C9CB8" HorizontalAlignment="Left" Margin="4,0,0,0"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Track" Property="BorderBrush" Value="#6A5ACD"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="{StaticResource AccentGrad}"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="#8B5CF6"/>
                <Setter TargetName="Thumb" Property="Fill" Value="White"/>
                <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Thumb" Property="Margin" Value="0,0,4,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Check" TargetType="CheckBox">
      <Setter Property="Foreground" Value="{StaticResource Txt}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,0,0,12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Background="Transparent">
              <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Border x:Name="Box" Width="18" Height="18" CornerRadius="5" Background="#1B1B2B"
                      BorderBrush="#3A3A58" BorderThickness="1.5" VerticalAlignment="Top" Margin="0,1,12,0">
                <TextBlock x:Name="Mark" Text="&#xE73E;" FontFamily="{StaticResource Icons}" FontSize="11"
                           Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
              </Border>
              <ContentPresenter Grid.Column="1"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Box" Property="BorderBrush" Value="#8B5CF6"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="{StaticResource AccentGrad}"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="#8B5CF6"/>
                <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Height" Value="40"/>
      <Setter Property="Padding" Value="18,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid>
              <Border x:Name="Bd" CornerRadius="9" Background="{StaticResource AccentGrad}"/>
              <Border x:Name="Hl" CornerRadius="9" Background="White" Opacity="0"/>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Hl" Property="Opacity" Value="0.08"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="Hl" Property="Opacity" Value="0.16"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SecondaryBtn" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource Txt}"/>
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Height" Value="36"/>
      <Setter Property="Padding" Value="14,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="9" Background="#1C1C2E" BorderBrush="#2C2C46" BorderThickness="1">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#25253C"/>
                <Setter TargetName="Bd" Property="BorderBrush" Value="#4A4A70"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ActionBtn" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="10" Background="#181826" BorderBrush="#24243A" BorderThickness="1" Padding="14,12">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1F1F33"/>
                <Setter TargetName="Bd" Property="BorderBrush" Value="#3E3E64"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleBtn" TargetType="Button">
      <Setter Property="Width" Value="40"/>
      <Setter Property="Height" Value="32"/>
      <Setter Property="Foreground" Value="#B4B4CC"/>
      <Setter Property="FontFamily" Value="{StaticResource Icons}"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="7" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#22223A"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="CloseBtn" TargetType="Button" BasedOn="{StaticResource TitleBtn}">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="7" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#E5484D"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="LinkBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#8E8EAE"/>
      <Setter Property="FontSize" Value="11.5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,0,12,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <TextBlock x:Name="Tx" Text="{TemplateBinding Content}" Foreground="{TemplateBinding Foreground}"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Tx" Property="Foreground" Value="#C4B5FD"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Slim" TargetType="ProgressBar">
      <Setter Property="Height" Value="6"/>
      <Setter Property="Background" Value="#23233A"/>
      <Setter Property="Foreground" Value="{StaticResource AccentGrad}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border x:Name="PART_Track" CornerRadius="3" Background="{TemplateBinding Background}"/>
              <Border x:Name="PART_Indicator" CornerRadius="3" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}"/>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border CornerRadius="12" Background="#0C0C14" BorderBrush="#26263C" BorderThickness="1">
    <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="240"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

      <!-- ===================== SIDEBAR ===================== -->
      <Border Grid.Column="0" Background="#10101A" CornerRadius="12,0,0,12" BorderBrush="#1C1C2C" BorderThickness="0,0,1,0">
        <DockPanel LastChildFill="True">
          <Grid x:Name="SideHead" DockPanel.Dock="Top" Margin="20,22,16,22" Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border Width="42" Height="42" CornerRadius="11" Background="{StaticResource AccentGrad}">
              <Image x:Name="LogoImg" Margin="5" Stretch="Uniform"/>
            </Border>
            <StackPanel Grid.Column="1" Margin="12,0,0,0" VerticalAlignment="Center">
              <TextBlock Text="Windows Optimizer" FontSize="15" FontWeight="SemiBold" Foreground="White"/>
              <TextBlock x:Name="SideVersion" FontSize="11" Foreground="{StaticResource Muted}" Margin="0,2,0,0"/>
            </StackPanel>
          </Grid>

          <TextBlock x:Name="NavCaption" DockPanel.Dock="Top" Style="{StaticResource Caption}" Margin="26,4,0,8"/>
          <RadioButton x:Name="NavHome"     DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xE80F;" IsChecked="True"/>
          <RadioButton x:Name="NavTweaks"   DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xE945;"/>
          <RadioButton x:Name="NavMemory"   DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xE9D9;"/>
          <RadioButton x:Name="NavStartup"  DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xE7E8;"/>
          <RadioButton x:Name="NavDisk"     DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xEDA2;"/>
          <RadioButton x:Name="NavSettings" DockPanel.Dock="Top" Style="{StaticResource NavBtn}" Tag="&#xE713;"/>

          <StackPanel DockPanel.Dock="Bottom" Margin="0,0,0,16">
            <Border x:Name="UpdateCard" Visibility="Collapsed" Margin="14,0,14,14" Padding="14" CornerRadius="11"
                    BorderBrush="#3B2F7A" BorderThickness="1">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#221C45" Offset="0"/><GradientStop Color="#15142A" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <StackPanel>
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Border Width="30" Height="30" CornerRadius="8" Background="#2D2560">
                    <TextBlock Text="&#xE896;" Style="{StaticResource Ico}" FontSize="14" Foreground="#C4B5FD" HorizontalAlignment="Center"/>
                  </Border>
                  <StackPanel Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center">
                    <TextBlock x:Name="UpdTitle" FontSize="12.5" FontWeight="SemiBold" Foreground="White" TextTrimming="CharacterEllipsis"/>
                    <TextBlock x:Name="UpdVersion" FontSize="11" Foreground="#B4B4CC" TextTrimming="CharacterEllipsis"/>
                  </StackPanel>
                </Grid>
                <TextBlock x:Name="UpdNotes" FontSize="11" Foreground="{StaticResource Muted}" TextWrapping="Wrap"
                           MaxHeight="44" TextTrimming="CharacterEllipsis" Margin="0,10,0,0"/>
                <StackPanel x:Name="UpdProgressPanel" Visibility="Collapsed" Margin="0,12,0,0">
                  <ProgressBar x:Name="UpdProgress" Style="{StaticResource Slim}" Maximum="100"/>
                  <Grid Margin="0,6,0,0">
                    <TextBlock x:Name="UpdStage" FontSize="11" Foreground="#B4B4CC" TextTrimming="CharacterEllipsis" Margin="0,0,36,0"/>
                    <TextBlock x:Name="UpdPct" FontSize="11" Foreground="#C4B5FD" HorizontalAlignment="Right"/>
                  </Grid>
                </StackPanel>
                <Button x:Name="BtnUpdate" Style="{StaticResource PrimaryBtn}" Height="34" FontSize="12.5" Margin="0,12,0,0"/>
              </StackPanel>
            </Border>
            <TextBlock x:Name="AuthorLabel" FontSize="11" Foreground="#5E5E7A" Margin="26,0,0,6"/>
            <WrapPanel Margin="26,0,10,0">
              <Button x:Name="BtnGithub" Content="GitHub" Style="{StaticResource LinkBtn}"/>
              <Button x:Name="BtnInstagram" Content="Instagram" Style="{StaticResource LinkBtn}"/>
              <Button x:Name="BtnWebsite" Content="Website" Style="{StaticResource LinkBtn}"/>
            </WrapPanel>
          </StackPanel>
          <Grid/>
        </DockPanel>
      </Border>

      <!-- ===================== CONTENT ===================== -->
      <Grid Grid.Column="1">
        <Grid.RowDefinitions><RowDefinition Height="76"/><RowDefinition Height="*"/><RowDefinition Height="38"/></Grid.RowDefinitions>

        <Grid x:Name="TopBar" Grid.Row="0" Background="Transparent">
          <StackPanel Margin="30,0,0,0" VerticalAlignment="Center">
            <TextBlock x:Name="PageTitle" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
            <TextBlock x:Name="PageSub" FontSize="12" Foreground="{StaticResource Muted}" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,10,0">
            <Button x:Name="BtnLang" Style="{StaticResource TitleBtn}" FontFamily="Segoe UI" FontSize="11" FontWeight="SemiBold" Margin="0,0,4,0"/>
            <Button x:Name="BtnMin" Content="&#xE921;" Style="{StaticResource TitleBtn}" Margin="0,0,4,0"/>
            <Button x:Name="BtnClose" Content="&#xE8BB;" Style="{StaticResource CloseBtn}"/>
          </StackPanel>
        </Grid>

        <Grid Grid.Row="1" Margin="30,0,16,0">

          <!-- ============ HOME ============ -->
          <ScrollViewer x:Name="PageHome">
            <StackPanel Margin="0,0,14,20">
              <Border CornerRadius="14" Padding="26,22" BorderBrush="#3B2F7A" BorderThickness="1">
                <Border.Background>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#2A1F5C" Offset="0"/><GradientStop Color="#171530" Offset="0.65"/><GradientStop Color="#14141F" Offset="1"/>
                  </LinearGradientBrush>
                </Border.Background>
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <StackPanel VerticalAlignment="Center" Margin="0,0,24,0">
                    <TextBlock x:Name="HeroCaption" Style="{StaticResource Caption}" Foreground="#A78BFA"/>
                    <StackPanel Orientation="Horizontal" Margin="0,6,0,0">
                      <TextBlock x:Name="HeroValue" FontSize="36" FontWeight="Bold" Foreground="White"/>
                      <TextBlock x:Name="HeroLabel" FontSize="15" Foreground="#B4B4CC" VerticalAlignment="Bottom" Margin="0,0,0,8"/>
                    </StackPanel>
                    <ProgressBar x:Name="HeroProgress" Style="{StaticResource Slim}" Height="8" Maximum="100" Margin="0,10,0,0" Width="460" HorizontalAlignment="Left"/>
                    <TextBlock x:Name="HeroHint" FontSize="12" Foreground="#9C9CB8" Margin="0,10,0,0"/>
                  </StackPanel>
                  <StackPanel Grid.Column="1" VerticalAlignment="Center" Width="220">
                    <Button x:Name="BtnQuickOptimize" Style="{StaticResource PrimaryBtn}" Height="44"/>
                    <Button x:Name="BtnGoTweaks" Style="{StaticResource SecondaryBtn}" Margin="0,10,0,0"/>
                  </StackPanel>
                </Grid>
              </Border>

              <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="20,18,20,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#xE9D9;" Style="{StaticResource Ico}" Foreground="#A78BFA" Margin="0,0,10,0"/>
                      <TextBlock x:Name="CpuTitle" FontSize="13" Foreground="#B4B4CC" VerticalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                      <TextBlock x:Name="CpuValue" Text="0" FontSize="32" FontWeight="Bold" Foreground="White"/>
                      <TextBlock Text="%" FontSize="16" Foreground="{StaticResource Muted}" VerticalAlignment="Bottom" Margin="3,0,0,7"/>
                    </StackPanel>
                    <TextBlock x:Name="CpuSub" FontSize="11.5" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                    <Canvas x:Name="CpuSpark" Height="48" Margin="0,12,0,0" ClipToBounds="True"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="2" Style="{StaticResource Card}" Padding="20,18,20,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#xE964;" Style="{StaticResource Ico}" Foreground="#38BDF8" Margin="0,0,10,0"/>
                      <TextBlock x:Name="RamTitle" FontSize="13" Foreground="#B4B4CC" VerticalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                      <TextBlock x:Name="RamValue" Text="0" FontSize="32" FontWeight="Bold" Foreground="White"/>
                      <TextBlock Text="%" FontSize="16" Foreground="{StaticResource Muted}" VerticalAlignment="Bottom" Margin="3,0,0,7"/>
                    </StackPanel>
                    <TextBlock x:Name="RamSub" FontSize="11.5" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                    <Canvas x:Name="RamSpark" Height="48" Margin="0,12,0,0" ClipToBounds="True"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="4" Style="{StaticResource Card}" Padding="20,18,20,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#xEDA2;" Style="{StaticResource Ico}" Foreground="#34D399" Margin="0,0,10,0"/>
                      <TextBlock x:Name="DiskTitle" FontSize="13" Foreground="#B4B4CC" VerticalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                      <TextBlock x:Name="DiskValue" Text="0" FontSize="32" FontWeight="Bold" Foreground="White"/>
                      <TextBlock Text="%" FontSize="16" Foreground="{StaticResource Muted}" VerticalAlignment="Bottom" Margin="3,0,0,7"/>
                    </StackPanel>
                    <TextBlock x:Name="DiskSub" FontSize="11.5" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                    <ProgressBar x:Name="DiskBar" Style="{StaticResource Slim}" Maximum="100" Margin="0,32,0,16" Foreground="#34D399"/>
                  </StackPanel>
                </Border>
              </Grid>

              <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}">
                  <StackPanel>
                    <TextBlock x:Name="SysTitle" Style="{StaticResource CardTitle}" Margin="0,0,0,14"/>
                    <Grid x:Name="SysGrid">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                      <Grid.RowDefinitions>
                        <RowDefinition Height="30"/><RowDefinition Height="30"/><RowDefinition Height="30"/>
                        <RowDefinition Height="30"/><RowDefinition Height="30"/><RowDefinition Height="30"/>
                      </Grid.RowDefinitions>
                      <TextBlock x:Name="LblOs"     Grid.Row="0" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="LblBuild"  Grid.Row="1" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="LblCpu"    Grid.Row="2" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="LblRam"    Grid.Row="3" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="LblUptime" Grid.Row="4" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="LblProc"   Grid.Row="5" Style="{StaticResource Desc}"/>
                      <TextBlock x:Name="SiOs"     Grid.Row="0" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}" TextTrimming="CharacterEllipsis"/>
                      <TextBlock x:Name="SiBuild"  Grid.Row="1" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}" TextTrimming="CharacterEllipsis"/>
                      <TextBlock x:Name="SiCpu"    Grid.Row="2" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}" TextTrimming="CharacterEllipsis"/>
                      <TextBlock x:Name="SiRam"    Grid.Row="3" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}"/>
                      <TextBlock x:Name="SiUptime" Grid.Row="4" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}"/>
                      <TextBlock x:Name="SiProc"   Grid.Row="5" Grid.Column="1" FontSize="12.5" Foreground="{StaticResource Txt}"/>
                    </Grid>
                  </StackPanel>
                </Border>
                <Border Grid.Column="2" Style="{StaticResource Card}" Padding="20,20,20,12">
                  <StackPanel>
                    <TextBlock x:Name="QaTitle" Style="{StaticResource CardTitle}" Margin="0,0,0,14"/>
                    <Button x:Name="QaClean" Style="{StaticResource ActionBtn}">
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="38"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <Border Width="30" Height="30" CornerRadius="8" Background="#1E2A44" HorizontalAlignment="Left">
                          <TextBlock Text="&#xE964;" Style="{StaticResource Ico}" FontSize="14" Foreground="#38BDF8" HorizontalAlignment="Center"/>
                        </Border>
                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                          <TextBlock x:Name="QaCleanT" FontSize="13" Foreground="{StaticResource Txt}"/>
                          <TextBlock x:Name="QaCleanD" FontSize="11" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                        </StackPanel>
                        <TextBlock Grid.Column="2" Text="&#xE76C;" Style="{StaticResource Ico}" FontSize="11" Foreground="{StaticResource Muted}"/>
                      </Grid>
                    </Button>
                    <Button x:Name="QaExplorer" Style="{StaticResource ActionBtn}">
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="38"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <Border Width="30" Height="30" CornerRadius="8" Background="#2A2350" HorizontalAlignment="Left">
                          <TextBlock Text="&#xE72C;" Style="{StaticResource Ico}" FontSize="14" Foreground="#A78BFA" HorizontalAlignment="Center"/>
                        </Border>
                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                          <TextBlock x:Name="QaExplorerT" FontSize="13" Foreground="{StaticResource Txt}"/>
                          <TextBlock x:Name="QaExplorerD" FontSize="11" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                        </StackPanel>
                        <TextBlock Grid.Column="2" Text="&#xE76C;" Style="{StaticResource Ico}" FontSize="11" Foreground="{StaticResource Muted}"/>
                      </Grid>
                    </Button>
                    <Button x:Name="QaRestore" Style="{StaticResource ActionBtn}">
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="38"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <Border Width="30" Height="30" CornerRadius="8" Background="#173328" HorizontalAlignment="Left">
                          <TextBlock Text="&#xE81C;" Style="{StaticResource Ico}" FontSize="14" Foreground="#34D399" HorizontalAlignment="Center"/>
                        </Border>
                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                          <TextBlock x:Name="QaRestoreT" FontSize="13" Foreground="{StaticResource Txt}"/>
                          <TextBlock x:Name="QaRestoreD" FontSize="11" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
                        </StackPanel>
                        <TextBlock Grid.Column="2" Text="&#xE76C;" Style="{StaticResource Ico}" FontSize="11" Foreground="{StaticResource Muted}"/>
                      </Grid>
                    </Button>
                  </StackPanel>
                </Border>
              </Grid>
            </StackPanel>
          </ScrollViewer>

          <!-- ============ TWEAKS ============ -->
          <Grid x:Name="PageTweaks" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <StackPanel Margin="0,0,14,0">
              <Border Style="{StaticResource Card}" Padding="18,12">
                <Grid>
                  <StackPanel VerticalAlignment="Center">
                    <TextBlock x:Name="TwSummary" FontSize="13.5" FontWeight="SemiBold" Foreground="{StaticResource Txt}"/>
                    <ProgressBar x:Name="TwProgress" Style="{StaticResource Slim}" Maximum="100" Width="220" HorizontalAlignment="Left" Margin="0,8,0,0"/>
                  </StackPanel>
                  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button x:Name="BtnSelRec" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,0"/>
                    <Button x:Name="BtnSelReset" Style="{StaticResource SecondaryBtn}" Margin="0,0,12,0"/>
                    <Button x:Name="BtnApplyTweaks" Style="{StaticResource PrimaryBtn}" MinWidth="150"/>
                  </StackPanel>
                </Grid>
              </Border>
              <Border x:Name="RestartBar" Visibility="Collapsed" Margin="0,10,0,0" CornerRadius="10" Padding="16,10"
                      Background="#2A2410" BorderBrush="#5C4A1A" BorderThickness="1">
                <Grid>
                  <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,180,0">
                    <TextBlock Text="&#xE7BA;" Style="{StaticResource Ico}" Foreground="#FBBF24" Margin="0,0,10,0"/>
                    <TextBlock x:Name="RestartText" FontSize="12.5" Foreground="#FDE68A" TextWrapping="Wrap" VerticalAlignment="Center"/>
                  </StackPanel>
                  <Button x:Name="BtnRestartExplorer" Style="{StaticResource SecondaryBtn}" Height="32" HorizontalAlignment="Right"/>
                </Grid>
              </Border>
            </StackPanel>
            <ScrollViewer Grid.Row="1" Margin="0,14,0,0">
              <StackPanel x:Name="TweakList" Margin="0,0,14,20"/>
            </ScrollViewer>
          </Grid>

          <!-- ============ MEMORY ============ -->
          <ScrollViewer x:Name="PageMemory" Visibility="Collapsed">
            <StackPanel Margin="0,0,14,20">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/><ColumnDefinition Width="12"/><ColumnDefinition Width="*"/><ColumnDefinition Width="12"/>
                  <ColumnDefinition Width="*"/><ColumnDefinition Width="12"/><ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Grid.Column="0" Style="{StaticResource Card}" Padding="16,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal"><Border Width="8" Height="8" CornerRadius="4" Background="#8B5CF6" Margin="0,0,8,0"/><TextBlock x:Name="MemInUseT" FontSize="12" Foreground="#B4B4CC"/></StackPanel>
                    <TextBlock x:Name="MemInUse" FontSize="24" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                    <TextBlock x:Name="MemInUseP" FontSize="11" Foreground="{StaticResource Muted}"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="2" Style="{StaticResource Card}" Padding="16,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal"><Border Width="8" Height="8" CornerRadius="4" Background="#38BDF8" Margin="0,0,8,0"/><TextBlock x:Name="MemStandbyT" FontSize="12" Foreground="#B4B4CC"/></StackPanel>
                    <TextBlock x:Name="MemStandby" FontSize="24" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                    <TextBlock x:Name="MemStandbyP" FontSize="11" Foreground="{StaticResource Muted}"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="4" Style="{StaticResource Card}" Padding="16,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal"><Border Width="8" Height="8" CornerRadius="4" Background="#F59E0B" Margin="0,0,8,0"/><TextBlock x:Name="MemModifiedT" FontSize="12" Foreground="#B4B4CC"/></StackPanel>
                    <TextBlock x:Name="MemModified" FontSize="24" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                    <TextBlock x:Name="MemModifiedP" FontSize="11" Foreground="{StaticResource Muted}"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="6" Style="{StaticResource Card}" Padding="16,14">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal"><Border Width="8" Height="8" CornerRadius="4" Background="#34D399" Margin="0,0,8,0"/><TextBlock x:Name="MemFreeT" FontSize="12" Foreground="#B4B4CC"/></StackPanel>
                    <TextBlock x:Name="MemFree" FontSize="24" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                    <TextBlock x:Name="MemFreeP" FontSize="11" Foreground="{StaticResource Muted}"/>
                  </StackPanel>
                </Border>
              </Grid>

              <Grid Margin="0,14,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="300"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="20,18,20,14">
                  <Grid>
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <Grid>
                      <StackPanel Orientation="Horizontal">
                        <TextBlock x:Name="ChartTitle" Style="{StaticResource CardTitle}" VerticalAlignment="Center"/>
                        <Border CornerRadius="8" Background="#3A1520" Padding="7,2" Margin="10,0,0,0" VerticalAlignment="Center">
                          <StackPanel Orientation="Horizontal">
                            <Ellipse x:Name="LiveDot" Width="6" Height="6" Fill="#F87171" Margin="0,0,5,0" VerticalAlignment="Center"/>
                            <TextBlock x:Name="LiveText" FontSize="10" FontWeight="Bold" Foreground="#FCA5A5"/>
                          </StackPanel>
                        </Border>
                      </StackPanel>
                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <Border Width="10" Height="10" CornerRadius="2" Background="#8B5CF6" Margin="0,0,6,0"/>
                        <TextBlock x:Name="LegInUse" FontSize="11" Foreground="#B4B4CC" Margin="0,0,14,0"/>
                        <Border Width="10" Height="10" CornerRadius="2" Background="#F59E0B" Margin="0,0,6,0"/>
                        <TextBlock x:Name="LegModified" FontSize="11" Foreground="#B4B4CC" Margin="0,0,14,0"/>
                        <Border Width="10" Height="10" CornerRadius="2" Background="#38BDF8" Margin="0,0,6,0"/>
                        <TextBlock x:Name="LegStandby" FontSize="11" Foreground="#B4B4CC"/>
                      </StackPanel>
                    </Grid>
                    <Canvas x:Name="MemChart" Grid.Row="1" Height="270" Margin="0,16,0,0" ClipToBounds="True" Background="Transparent"/>
                    <Grid Grid.Row="2" Margin="52,6,0,0">
                      <TextBlock x:Name="AxisLeft" FontSize="10.5" Foreground="{StaticResource Muted}"/>
                      <TextBlock x:Name="AxisRight" FontSize="10.5" Foreground="{StaticResource Muted}" HorizontalAlignment="Right"/>
                    </Grid>
                  </Grid>
                </Border>

                <Border Grid.Column="2" Style="{StaticResource Card}">
                  <StackPanel>
                    <TextBlock x:Name="CleanTitle" Style="{StaticResource CardTitle}" Margin="0,0,0,16"/>
                    <CheckBox x:Name="ChkWorkingSets" Style="{StaticResource Check}">
                      <StackPanel><TextBlock x:Name="OptWorkingSets" FontSize="12.5" Foreground="{StaticResource Txt}"/><TextBlock x:Name="OptWorkingSetsD" Style="{StaticResource Desc}" FontSize="11"/></StackPanel>
                    </CheckBox>
                    <CheckBox x:Name="ChkModified" Style="{StaticResource Check}">
                      <StackPanel><TextBlock x:Name="OptModified" FontSize="12.5" Foreground="{StaticResource Txt}"/><TextBlock x:Name="OptModifiedD" Style="{StaticResource Desc}" FontSize="11"/></StackPanel>
                    </CheckBox>
                    <CheckBox x:Name="ChkStandby" Style="{StaticResource Check}">
                      <StackPanel><TextBlock x:Name="OptStandby" FontSize="12.5" Foreground="{StaticResource Txt}"/><TextBlock x:Name="OptStandbyD" Style="{StaticResource Desc}" FontSize="11"/></StackPanel>
                    </CheckBox>
                    <CheckBox x:Name="ChkLowStandby" Style="{StaticResource Check}">
                      <StackPanel><TextBlock x:Name="OptLowStandby" FontSize="12.5" Foreground="{StaticResource Txt}"/><TextBlock x:Name="OptLowStandbyD" Style="{StaticResource Desc}" FontSize="11"/></StackPanel>
                    </CheckBox>
                    <CheckBox x:Name="ChkFileCache" Style="{StaticResource Check}">
                      <StackPanel><TextBlock x:Name="OptFileCache" FontSize="12.5" Foreground="{StaticResource Txt}"/><TextBlock x:Name="OptFileCacheD" Style="{StaticResource Desc}" FontSize="11"/></StackPanel>
                    </CheckBox>
                    <Button x:Name="BtnClean" Style="{StaticResource PrimaryBtn}" Height="44" Margin="0,6,0,0"/>
                    <TextBlock x:Name="AutoTitle" Style="{StaticResource Caption}" Margin="0,18,0,8"/>
                    <WrapPanel>
                      <RadioButton x:Name="Auto0"  GroupName="auto" Style="{StaticResource SegBtn}" Tag="0"/>
                      <RadioButton x:Name="Auto75" GroupName="auto" Style="{StaticResource SegBtn}" Tag="75" Content="%75"/>
                      <RadioButton x:Name="Auto85" GroupName="auto" Style="{StaticResource SegBtn}" Tag="85" Content="%85"/>
                      <RadioButton x:Name="Auto90" GroupName="auto" Style="{StaticResource SegBtn}" Tag="90" Content="%90"/>
                    </WrapPanel>
                  </StackPanel>
                </Border>
              </Grid>

              <Grid Margin="0,14,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}">
                  <StackPanel>
                    <Grid>
                      <TextBlock x:Name="ResTitle" Style="{StaticResource CardTitle}"/>
                      <TextBlock x:Name="ResTime" FontSize="11" Foreground="{StaticResource Muted}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                    <TextBlock x:Name="ResNone" Style="{StaticResource Desc}" Margin="0,14,0,0"/>
                    <StackPanel x:Name="ResPanel" Visibility="Collapsed" Margin="0,12,0,0">
                      <StackPanel Orientation="Horizontal">
                        <TextBlock x:Name="ResGain" FontSize="30" FontWeight="Bold" Foreground="#34D399"/>
                        <TextBlock x:Name="ResGainSub" FontSize="12" Foreground="#9C9CB8" VerticalAlignment="Bottom" Margin="10,0,0,7"/>
                      </StackPanel>
                      <Grid Margin="0,12,0,0">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                          <RowDefinition Height="24"/><RowDefinition Height="26"/><RowDefinition Height="26"/><RowDefinition Height="26"/><RowDefinition Height="26"/>
                        </Grid.RowDefinitions>
                        <TextBlock x:Name="ResColBefore" Grid.Column="1" Style="{StaticResource Caption}" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="ResColAfter"  Grid.Column="2" Style="{StaticResource Caption}" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="ResRowInUse"    Grid.Row="1" Style="{StaticResource Desc}"/>
                        <TextBlock x:Name="ResRowStandby"  Grid.Row="2" Style="{StaticResource Desc}"/>
                        <TextBlock x:Name="ResRowModified" Grid.Row="3" Style="{StaticResource Desc}"/>
                        <TextBlock x:Name="ResRowAvail"    Grid.Row="4" Style="{StaticResource Desc}"/>
                        <TextBlock x:Name="RbInUse"  Grid.Row="1" Grid.Column="1" FontSize="12.5" Foreground="#B4B4CC" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RbStandby" Grid.Row="2" Grid.Column="1" FontSize="12.5" Foreground="#B4B4CC" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RbModified" Grid.Row="3" Grid.Column="1" FontSize="12.5" Foreground="#B4B4CC" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RbAvail"  Grid.Row="4" Grid.Column="1" FontSize="12.5" Foreground="#B4B4CC" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RaInUse"  Grid.Row="1" Grid.Column="2" FontSize="12.5" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RaStandby" Grid.Row="2" Grid.Column="2" FontSize="12.5" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RaModified" Grid.Row="3" Grid.Column="2" FontSize="12.5" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Right"/>
                        <TextBlock x:Name="RaAvail"  Grid.Row="4" Grid.Column="2" FontSize="12.5" FontWeight="SemiBold" Foreground="#34D399" HorizontalAlignment="Right"/>
                      </Grid>
                    </StackPanel>
                    <Border Background="#171726" CornerRadius="8" Padding="12,10" Margin="0,16,0,0">
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <TextBlock Text="&#xE946;" Style="{StaticResource Ico}" FontSize="13" Foreground="#7A7A94" VerticalAlignment="Top" Margin="0,1,10,0"/>
                        <TextBlock x:Name="MemNote" Grid.Column="1" Style="{StaticResource Desc}" FontSize="11"/>
                      </Grid>
                    </Border>
                  </StackPanel>
                </Border>
                <Border Grid.Column="2" Style="{StaticResource Card}">
                  <StackPanel>
                    <TextBlock x:Name="ProcTitle" Style="{StaticResource CardTitle}" Margin="0,0,0,12"/>
                    <StackPanel x:Name="ProcList"/>
                  </StackPanel>
                </Border>
              </Grid>
            </StackPanel>
          </ScrollViewer>

          <!-- ============ STARTUP ============ -->
          <Grid x:Name="PageStartup" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="18,12" Margin="0,0,14,0">
              <Grid>
                <StackPanel VerticalAlignment="Center" Margin="0,0,330,0">
                  <TextBlock x:Name="SuSummary" FontSize="13.5" FontWeight="SemiBold" Foreground="{StaticResource Txt}"/>
                  <TextBlock x:Name="SuHint" Style="{StaticResource Desc}" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                  <Button x:Name="BtnSuTaskMgr" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,0"/>
                  <Button x:Name="BtnSuRefresh" Style="{StaticResource SecondaryBtn}"/>
                </StackPanel>
              </Grid>
            </Border>
            <ScrollViewer Grid.Row="1" Margin="0,14,0,0">
              <StackPanel x:Name="StartupList" Margin="0,0,14,20"/>
            </ScrollViewer>
          </Grid>

          <!-- ============ DISK ============ -->
          <ScrollViewer x:Name="PageDisk" Visibility="Collapsed">
            <StackPanel Margin="0,0,14,20">
              <UniformGrid x:Name="DriveList" Columns="4"/>
              <Grid Margin="0,14,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="300"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="0">
                  <StackPanel>
                    <Grid Margin="20,16,20,12">
                      <StackPanel>
                        <TextBlock x:Name="DcTitle" Style="{StaticResource CardTitle}"/>
                        <TextBlock x:Name="DcSub" Style="{StaticResource Desc}" Margin="0,3,0,0"/>
                      </StackPanel>
                      <Button x:Name="BtnDiskScan" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                    <StackPanel x:Name="CleanList"/>
                  </StackPanel>
                </Border>
                <Border Grid.Column="2" Style="{StaticResource Card}" VerticalAlignment="Top">
                  <StackPanel>
                    <TextBlock x:Name="DcSelTitle" Style="{StaticResource Caption}"/>
                    <TextBlock x:Name="DcSelBytes" Text="—" FontSize="32" FontWeight="Bold" Foreground="White" Margin="0,6,0,0"/>
                    <TextBlock x:Name="DcSelFiles" Style="{StaticResource Desc}"/>
                    <Button x:Name="BtnDiskClean" Style="{StaticResource PrimaryBtn}" Height="44" Margin="0,16,0,0" IsEnabled="False"/>
                    <Border x:Name="DcResultBox" Visibility="Collapsed" Background="#0F2E25" BorderBrush="#1F5C47" BorderThickness="1" CornerRadius="9" Padding="12,10" Margin="0,14,0,0">
                      <StackPanel>
                        <TextBlock x:Name="DcResult" FontSize="18" FontWeight="Bold" Foreground="#34D399"/>
                        <TextBlock x:Name="DcResultSub" FontSize="11" Foreground="#9FD8C2" TextWrapping="Wrap" Margin="0,2,0,0"/>
                      </StackPanel>
                    </Border>
                    <Border Background="#171726" CornerRadius="8" Padding="12,10" Margin="0,14,0,0">
                      <TextBlock x:Name="DcNote" Style="{StaticResource Desc}" FontSize="11"/>
                    </Border>
                    <Button x:Name="BtnCleanMgr" Style="{StaticResource SecondaryBtn}" Margin="0,12,0,0"/>
                  </StackPanel>
                </Border>
              </Grid>
            </StackPanel>
          </ScrollViewer>

          <!-- ============ SETTINGS ============ -->
          <ScrollViewer x:Name="PageSettings" Visibility="Collapsed">
            <StackPanel Margin="0,0,14,20" MaxWidth="860" HorizontalAlignment="Left">
              <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                <Grid>
                  <StackPanel Margin="0,0,200,0"><TextBlock x:Name="SetLangT" Style="{StaticResource CardTitle}"/><TextBlock x:Name="SetLangD" Style="{StaticResource Desc}" Margin="0,4,0,0"/></StackPanel>
                  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <RadioButton x:Name="LangTR" GroupName="lang" Style="{StaticResource SegBtn}" Content="Türkçe"/>
                    <RadioButton x:Name="LangEN" GroupName="lang" Style="{StaticResource SegBtn}" Content="English" Margin="0"/>
                  </StackPanel>
                </Grid>
              </Border>
              <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                <Grid>
                  <StackPanel Margin="0,0,220,0"><TextBlock x:Name="SetUpdT" Style="{StaticResource CardTitle}"/><TextBlock x:Name="SetVerText" Style="{StaticResource Desc}" Margin="0,4,0,0"/><TextBlock x:Name="SetUpdStatus" Style="{StaticResource Desc}" Foreground="#A78BFA" Margin="0,4,0,0"/></StackPanel>
                  <Button x:Name="BtnCheckUpdate" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </Border>
              <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                <Grid>
                  <StackPanel Margin="0,0,220,0"><TextBlock x:Name="SetShortcutT" Style="{StaticResource CardTitle}"/><TextBlock x:Name="SetShortcutD" Style="{StaticResource Desc}" Margin="0,4,0,0"/></StackPanel>
                  <Button x:Name="BtnFixShortcut" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </Border>
              <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                <Grid>
                  <StackPanel Margin="0,0,220,0"><TextBlock x:Name="SetRestoreT" Style="{StaticResource CardTitle}"/><TextBlock x:Name="SetRestoreD" Style="{StaticResource Desc}" Margin="0,4,0,0"/></StackPanel>
                  <Button x:Name="BtnRestore2" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </Border>
              <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                <Grid>
                  <StackPanel Margin="0,0,220,0"><TextBlock x:Name="SetLogT" Style="{StaticResource CardTitle}"/><TextBlock x:Name="SetLogD" Style="{StaticResource Desc}" Margin="0,4,0,0"/></StackPanel>
                  <Button x:Name="BtnOpenLog" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </Border>
              <Border Style="{StaticResource Card}">
                <StackPanel>
                  <TextBlock x:Name="SetAboutT" Style="{StaticResource CardTitle}" Margin="0,0,0,12"/>
                  <Border CornerRadius="10" ClipToBounds="True" HorizontalAlignment="Left" MaxWidth="540">
                    <Image x:Name="BannerImg" Stretch="Uniform"/>
                  </Border>
                  <TextBlock x:Name="AboutText" Style="{StaticResource Desc}" Margin="0,12,0,0"/>
                </StackPanel>
              </Border>
            </StackPanel>
          </ScrollViewer>
        </Grid>

        <!-- STATUS BAR -->
        <Border Grid.Row="2" BorderBrush="#1C1C2C" BorderThickness="0,1,0,0" CornerRadius="0,0,12,0">
          <Grid Margin="30,0,30,0">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,200,0">
              <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#34D399" Margin="0,0,10,0" VerticalAlignment="Center"/>
              <TextBlock x:Name="StatusText" FontSize="12" Foreground="#B4B4CC" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
              <TextBlock Text="&#xE7EF;" Style="{StaticResource Ico}" FontSize="12" Foreground="#7A7A94" Margin="0,0,6,0"/>
              <TextBlock x:Name="AdminBadge" FontSize="11.5" Foreground="#7A7A94"/>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

try {
    $window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
    function N([string]$Name) { $window.FindName($Name) }

    $BrushConv = New-Object Windows.Media.BrushConverter
    function Brush([string]$Hex) { $BrushConv.ConvertFromString($Hex) }
    function Fmt-GB([double]$Bytes) { if ($Bytes -ge 1GB) { "{0:N1} GB" -f ($Bytes / 1GB) } else { "{0:N0} MB" -f ($Bytes / 1MB) } }

    function Load-Image([string]$Path) {
        if (-not (Test-Path $Path)) { return $null }
        $b = New-Object Windows.Media.Imaging.BitmapImage
        $b.BeginInit(); $b.UriSource = New-Object Uri($Path); $b.CacheOption = "OnLoad"; $b.EndInit()
        return $b
    }
    (N "LogoImg").Source   = Load-Image (Join-Path $AppDir ($Config.logo -replace '/', '\'))
    (N "BannerImg").Source = Load-Image (Join-Path $AppDir "assets\banner.png")
    try { $window.Icon = (N "LogoImg").Source } catch {}

    # ---------------- PENCERE ----------------
    (N "TopBar").Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
    (N "SideHead").Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
    (N "BtnMin").Add_Click({ $window.WindowState = "Minimized" })
    (N "BtnClose").Add_Click({ $window.Close() })

    foreach ($pair in @(@("BtnGithub", "github"), @("BtnInstagram", "instagram"), @("BtnWebsite", "website"))) {
        $btn = N $pair[0]; $url = $Config.($pair[1])
        if ($url -and $url -ne "#") { $btn.Tag = $url; $btn.Add_Click({ param($s) Start-Process $s.Tag }) }
        else { $btn.Visibility = "Collapsed" }
    }

    # ---------------- DURUM ÇUBUĞU ----------------
    function Set-Status([string]$Text, [string]$Kind = "info") {
        $colors = @{ info = "#8B5CF6"; ok = "#34D399"; warn = "#FBBF24"; err = "#F87171"; busy = "#38BDF8" }
        (N "StatusText").Text = $Text
        (N "StatusDot").Fill = Brush $colors[$Kind]
        if ($Kind -ne "busy") { Write-WoLog "[$Kind] $Text" }
    }

    # ---------------- ARKA PLAN İŞLERİ ----------------
    $script:Pool = [runspacefactory]::CreateRunspacePool(1, 4)
    $script:Pool.Open()
    $script:Jobs = New-Object System.Collections.ArrayList

    function Start-Bg([scriptblock]$Work, [object[]]$ArgList, [scriptblock]$Done) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $script:Pool
        [void]$ps.AddScript($Work.ToString())
        foreach ($a in $ArgList) { [void]$ps.AddArgument($a) }
        [void]$script:Jobs.Add(@{ PS = $ps; H = $ps.BeginInvoke(); Done = $Done })
    }

    function Poll-Bg {
        foreach ($j in @($script:Jobs)) {
            if (-not $j.H.IsCompleted) { continue }
            $script:Jobs.Remove($j)
            $out = $null; $err = $null
            try { $out = $j.PS.EndInvoke($j.H) } catch { $err = $_.Exception.InnerException.Message; if (-not $err) { $err = $_.Exception.Message } }
            if (-not $err -and $j.PS.Streams.Error.Count -gt 0) { $err = $j.PS.Streams.Error[0].ToString() }
            $j.PS.Dispose()
            if ($j.Done) { try { & $j.Done $out $err } catch { Write-WoLog "Callback hatasi: $_" } }
        }
    }

    # ---------------- SAYFALAR ----------------
    $Pages = @{ Home = "PageHome"; Tweaks = "PageTweaks"; Memory = "PageMemory"; Startup = "PageStartup"; Disk = "PageDisk"; Settings = "PageSettings" }
    $PageOrder = @("Home", "Tweaks", "Memory", "Startup", "Disk", "Settings")
    $script:Page = "Home"
    function Show-Page([string]$Name) {
        $script:Page = $Name
        foreach ($k in $Pages.Keys) { (N $Pages[$k]).Visibility = if ($k -eq $Name) { "Visible" } else { "Collapsed" } }
        (N "PageTitle").Text = T "Title_$Name"
        (N "PageSub").Text   = T "Sub_$Name"
        (N "Nav$Name").IsChecked = $true
        if ($Name -eq "Memory") { $window.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, [Action]{ Draw-MemChart; Refresh-ProcList }) | Out-Null }
        if ($Name -eq "Startup" -and -not $script:StartupLoaded) { Load-Startup }
        if ($Name -eq "Disk") { (N "PageDisk").ScrollToTop(); Show-Drives; if (-not $script:DiskScanned) { Start-DiskScan } }
        if ($Name -eq "Home") { $window.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, [Action]{ Draw-Sparks }) | Out-Null }
    }
    foreach ($p in $PageOrder) {
        (N "Nav$p").Add_Checked({ param($s) $n = $s.Name.Substring(3); if ($script:Page -ne $n) { Show-Page $n } })
    }

    # ================= TWEAKS =================
    $script:TweakState = @{}
    $script:TweakRows  = @{}
    $script:CatHeaders = @{}

    function Refresh-TweakStates {
        foreach ($t in $TweakCatalog) { $script:TweakState[$t.Id] = [bool](Test-WoTweak $t) }
    }

    function New-Tb([string]$Text, [double]$Size, [string]$Color) {
        $tb = New-Object Windows.Controls.TextBlock
        $tb.Text = $Text; $tb.FontSize = $Size; $tb.Foreground = Brush $Color; $tb.TextWrapping = "Wrap"
        return $tb
    }

    function Build-TweakList {
        $list = N "TweakList"
        $list.Children.Clear()
        $script:TweakRows = @{}; $script:CatHeaders = @{}
        $cardStyle = $window.FindResource("Card")
        $switchStyle = $window.FindResource("Switch")
        $iconFont = $window.FindResource("Icons")

        foreach ($catKey in $TweakCategories.Keys) {
            $cat = $TweakCategories[$catKey]
            $card = New-Object Windows.Controls.Border
            $card.Style = $cardStyle; $card.Padding = New-Object Windows.Thickness(0); $card.Margin = New-Object Windows.Thickness(0, 0, 0, 14)
            $stack = New-Object Windows.Controls.StackPanel
            $card.Child = $stack

            # Kategori basligi
            $head = New-Object Windows.Controls.Grid
            $head.Margin = New-Object Windows.Thickness(20, 16, 20, 12)
            $hs = New-Object Windows.Controls.StackPanel; $hs.Orientation = "Horizontal"
            $ib = New-Object Windows.Controls.Border
            $ib.Width = 30; $ib.Height = 30; $ib.CornerRadius = New-Object Windows.CornerRadius(8); $ib.Background = Brush "#231F3F"
            $ic = New-Tb ([string]$cat.Icon) 14 "#A78BFA"; $ic.FontFamily = $iconFont
            $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"; $ib.Child = $ic
            $ht = New-Tb $cat[$script:Lang] 14.5 "#EDEDF5"; $ht.FontWeight = [Windows.FontWeights]::SemiBold
            $ht.VerticalAlignment = "Center"; $ht.Margin = New-Object Windows.Thickness(12, 0, 0, 0)
            [void]$hs.Children.Add($ib); [void]$hs.Children.Add($ht)
            $cnt = New-Tb "" 12 "#7A7A94"; $cnt.HorizontalAlignment = "Right"; $cnt.VerticalAlignment = "Center"
            [void]$head.Children.Add($hs); [void]$head.Children.Add($cnt)
            [void]$stack.Children.Add($head)
            $script:CatHeaders[$catKey] = $cnt

            foreach ($t in ($TweakCatalog | Where-Object { $_.Cat -eq $catKey })) {
                $row = New-Object Windows.Controls.Border
                $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0)
                $row.Padding = New-Object Windows.Thickness(20, 12, 20, 12)
                $g = New-Object Windows.Controls.Grid
                foreach ($w in @("*", "Auto", "Auto")) {
                    $cd = New-Object Windows.Controls.ColumnDefinition
                    $cd.Width = if ($w -eq "*") { New-Object Windows.GridLength(1, "Star") } else { [Windows.GridLength]::Auto }
                    $g.ColumnDefinitions.Add($cd)
                }
                $txt = New-Object Windows.Controls.StackPanel; $txt.Margin = New-Object Windows.Thickness(0, 0, 16, 0)
                $titleRow = New-Object Windows.Controls.WrapPanel
                $name = New-Tb $t[$script:Lang][0] 13.5 "#EDEDF5"
                [void]$titleRow.Children.Add($name)
                if ($t.Rec) {
                    $rb = New-Object Windows.Controls.Border
                    $rb.CornerRadius = New-Object Windows.CornerRadius(5); $rb.Background = Brush "#1E2A44"
                    $rb.Padding = New-Object Windows.Thickness(6, 1, 6, 1); $rb.Margin = New-Object Windows.Thickness(8, 1, 0, 0)
                    $rb.VerticalAlignment = "Center"
                    $rbt = New-Tb (T "RecBadge") 9.5 "#7DD3FC"; $rbt.FontWeight = [Windows.FontWeights]::Bold
                    $rb.Child = $rbt
                    [void]$titleRow.Children.Add($rb)
                }
                $desc = New-Tb $t[$script:Lang][1] 11.5 "#7A7A94"; $desc.Margin = New-Object Windows.Thickness(0, 3, 0, 0)
                [void]$txt.Children.Add($titleRow); [void]$txt.Children.Add($desc)
                if ($t.Restart) {
                    $rsKey = @{ explorer = "NeedExplorer"; logoff = "NeedLogoff"; reboot = "NeedReboot" }[$t.Restart]
                    $rs = New-Tb ("↻ " + (T $rsKey)) 10.5 "#A1885A"
                    $rs.Margin = New-Object Windows.Thickness(0, 3, 0, 0)
                    [void]$txt.Children.Add($rs)
                }

                $chip = New-Object Windows.Controls.Border
                $chip.CornerRadius = New-Object Windows.CornerRadius(10); $chip.Padding = New-Object Windows.Thickness(10, 3, 10, 3)
                $chip.Margin = New-Object Windows.Thickness(0, 0, 16, 0); $chip.VerticalAlignment = "Center"; $chip.MinWidth = 86
                $chipT = New-Tb "" 11 "#B4B4CC"; $chipT.HorizontalAlignment = "Center"; $chipT.TextWrapping = "NoWrap"
                $chip.Child = $chipT
                [Windows.Controls.Grid]::SetColumn($chip, 1)

                $sw = New-Object Windows.Controls.CheckBox
                $sw.Style = $switchStyle; $sw.Tag = $t.Id
                $sw.IsChecked = $script:TweakState[$t.Id]
                $sw.Add_Click({ Update-TweakSummary })
                [Windows.Controls.Grid]::SetColumn($sw, 2)

                [void]$g.Children.Add($txt); [void]$g.Children.Add($chip); [void]$g.Children.Add($sw)
                $row.Child = $g
                [void]$stack.Children.Add($row)
                $script:TweakRows[$t.Id] = @{ Switch = $sw; Chip = $chip; ChipText = $chipT }
            }
            [void]$list.Children.Add($card)
        }
        Update-TweakSummary
    }

    function Update-TweakSummary {
        $total = $TweakCatalog.Count; $active = 0; $pending = 0
        $recTotal = 0; $recActive = 0
        $catCount = @{}
        foreach ($t in $TweakCatalog) {
            $cur = $script:TweakState[$t.Id]
            if ($cur) { $active++ }
            if ($t.Rec) { $recTotal++; if ($cur) { $recActive++ } }
            if (-not $catCount[$t.Cat]) { $catCount[$t.Cat] = @(0, 0) }
            $catCount[$t.Cat][1]++; if ($cur) { $catCount[$t.Cat][0]++ }
            $r = $script:TweakRows[$t.Id]
            if (-not $r) { continue }
            $want = [bool]$r.Switch.IsChecked
            if ($want -ne $cur) { $pending++ }
            $style = if ($want -and -not $cur) { @("Chip_Apply", "#2A2350", "#C4B5FD") }
                     elseif (-not $want -and $cur) { @("Chip_Revert", "#3A2E10", "#FCD34D") }
                     elseif ($cur) { @("Chip_On", "#12302A", "#6EE7B7") }
                     else { @("Chip_Off", "#1C1C2C", "#8A8AA6") }
            $r.ChipText.Text = T $style[0]
            $r.Chip.Background = Brush $style[1]
            $r.ChipText.Foreground = Brush $style[2]
        }
        foreach ($k in $script:CatHeaders.Keys) { $script:CatHeaders[$k].Text = "{0} / {1}" -f $catCount[$k][0], $catCount[$k][1] }

        $summary = (T "TwSummary") -f $active, $total
        if ($pending -gt 0) { $summary += (T "TwPending") -f $pending }
        (N "TwSummary").Text = $summary
        (N "TwProgress").Value = [int](100 * $active / [Math]::Max([double]1, $total))
        $btn = N "BtnApplyTweaks"
        $btn.Content = if ($pending -gt 0) { (T "BtnApplyN") -f $pending } else { T "BtnApply0" }
        $btn.IsEnabled = ($pending -gt 0) -and -not $script:Applying

        (N "HeroValue").Text = "$active / $total"
        (N "HeroProgress").Value = [int](100 * $active / [Math]::Max([double]1, $total))
        (N "HeroHint").Text = (T "HeroHint") -f $recTotal, $recActive
    }

    $script:Applying = $false
    function Invoke-TweakChanges {
        if ($script:Applying) { return }
        $apply = @(); $revert = @()
        foreach ($t in $TweakCatalog) {
            $want = [bool]$script:TweakRows[$t.Id].Switch.IsChecked
            $cur = $script:TweakState[$t.Id]
            if ($want -and -not $cur) { $apply += $t.Id } elseif (-not $want -and $cur) { $revert += $t.Id }
        }
        if (($apply.Count + $revert.Count) -eq 0) { return }
        $script:Applying = $true
        (N "BtnApplyTweaks").IsEnabled = $false; (N "BtnQuickOptimize").IsEnabled = $false
        Set-Status (T "Applying") "busy"

        Start-Bg -Work {
            param($ModPath, $Apply, $Revert)
            . $ModPath
            foreach ($id in $Apply) {
                try { Invoke-WoTweak (Get-WoTweak $id); [pscustomobject]@{ Id = $id; Ok = $true; Rev = $false } }
                catch { [pscustomobject]@{ Id = $id; Ok = $false; Rev = $false; Err = $_.Exception.Message } }
            }
            foreach ($id in $Revert) {
                try { Invoke-WoTweak (Get-WoTweak $id) -Revert; [pscustomobject]@{ Id = $id; Ok = $true; Rev = $true } }
                catch { [pscustomobject]@{ Id = $id; Ok = $false; Rev = $true; Err = $_.Exception.Message } }
            }
        } -ArgList @((Join-Path $AppDir "modules\Tweaks.ps1"), $apply, $revert) -Done {
            param($out, $err)
            $script:Applying = $false
            (N "BtnQuickOptimize").IsEnabled = $true
            $ok = @($out | Where-Object { $_.Ok }).Count
            $fail = @($out | Where-Object { -not $_.Ok })
            foreach ($f in $fail) { Write-WoLog "Tweak hatasi ($($f.Id)): $($f.Err)" }
            if ($err) { Write-WoLog "Tweak isi hatasi: $err" }

            Refresh-TweakStates
            foreach ($id in $script:TweakRows.Keys) { $script:TweakRows[$id].Switch.IsChecked = $script:TweakState[$id] }
            Update-TweakSummary

            $restarts = @($out | Where-Object { $_.Ok } | ForEach-Object { (Get-WoTweak $_.Id).Restart } | Where-Object { $_ })
            if ($restarts -contains "explorer") { (N "RestartBar").Visibility = "Visible" }
            $msg = if ($fail.Count -eq 0 -and -not $err) { (T "ApplyOK") -f $ok } else { (T "ApplyWarn") -f $ok, [Math]::Max(1, $fail.Count) }
            if ($fail.Count -gt 0) {
                $names = $fail | ForEach-Object { (Get-WoTweak $_.Id)[$script:Lang][0] }
                $msg += " (" + ($names -join ", ") + ")"
            }
            if ($restarts -contains "reboot") { $msg += T "RebootHint" }
            elseif ($restarts -contains "logoff") { $msg += T "LogoffHint" }
            Set-Status $msg $(if ($fail.Count -eq 0 -and -not $err) { "ok" } else { "warn" })
        }
    }

    function Select-Recommended {
        foreach ($t in $TweakCatalog) {
            if ($t.Rec) { $script:TweakRows[$t.Id].Switch.IsChecked = $true }
        }
        Update-TweakSummary
    }

    (N "BtnApplyTweaks").Add_Click({ Invoke-TweakChanges })
    (N "BtnSelRec").Add_Click({ Select-Recommended })
    (N "BtnSelReset").Add_Click({
        foreach ($id in $script:TweakRows.Keys) { $script:TweakRows[$id].Switch.IsChecked = $script:TweakState[$id] }
        Update-TweakSummary
    })
    (N "BtnQuickOptimize").Add_Click({ Select-Recommended; Invoke-TweakChanges })
    (N "BtnGoTweaks").Add_Click({ Show-Page "Tweaks" })

    # ================= EXPLORER / GERİ YÜKLEME / KISAYOL =================
    function Restart-Explorer {
        Set-Status (T "ExplorerBusy") "busy"
        Start-Bg -Work {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        } -Done {
            param($out, $err)
            (N "RestartBar").Visibility = "Collapsed"
            Set-Status (T "ExplorerOK") "ok"
        }
    }
    (N "BtnRestartExplorer").Add_Click({ Restart-Explorer })
    (N "QaExplorer").Add_Click({ Restart-Explorer })

    $script:RestoreBusy = $false
    function New-RestorePoint {
        if ($script:RestoreBusy) { return }
        $script:RestoreBusy = $true
        (N "QaRestore").IsEnabled = $false; (N "BtnRestore2").IsEnabled = $false
        Set-Status (T "RestoreBusy") "busy"
        Start-Bg -Work {
            $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
            New-ItemProperty -Path $k -Name SystemRestorePointCreationFrequency -Value 0 -PropertyType DWord -Force | Out-Null
            try { Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop } catch {}
            Checkpoint-Computer -Description "Windows Optimizer" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            "ok"
        } -Done {
            param($out, $err)
            $script:RestoreBusy = $false
            (N "QaRestore").IsEnabled = $true; (N "BtnRestore2").IsEnabled = $true
            if ($err) { Set-Status ((T "RestoreFail") -f $err) "err" } else { Set-Status (T "RestoreOK") "ok" }
        }
    }
    (N "QaRestore").Add_Click({ New-RestorePoint })
    (N "BtnRestore2").Add_Click({ New-RestorePoint })

    (N "BtnFixShortcut").Add_Click({
        try {
            $made = @(New-WoShortcut $AppDir)
            if ($made.Count -gt 0) { Set-Status ((T "ShortcutOK") -f $made.Count) "ok" } else { Set-Status (T "ShortcutFail") "err" }
        } catch { Set-Status "$(T 'ShortcutFail'): $($_.Exception.Message)" "err" }
    })
    (N "BtnOpenLog").Add_Click({
        if (-not (Test-Path $LogPath)) { Write-WoLog "Gunluk olusturuldu" }
        Start-Process notepad.exe $LogPath
    })

    # ================= BELLEK =================
    $HistCap = 120
    $script:MemHist = New-Object System.Collections.ArrayList
    $script:CpuHist = New-Object System.Collections.ArrayList
    $script:RamHist = New-Object System.Collections.ArrayList
    $script:MemEvents = New-Object System.Collections.ArrayList
    $script:SampleNo = 0
    $script:LastMem = $null
    $script:CpuPrev = $null
    $script:Cleaning = $false
    $script:LastClean = [DateTime]::MinValue

    function Push-Hist($List, $Item, [int]$Cap) { [void]$List.Add($Item); while ($List.Count -gt $Cap) { $List.RemoveAt(0) } }

    function Get-CpuUsage {
        $idle = 0L; $kern = 0L; $user = 0L
        [void][WoNative]::GetSystemTimes([ref]$idle, [ref]$kern, [ref]$user)
        $cur = @($idle, ($kern + $user))
        $pct = 0
        if ($script:CpuPrev) {
            $dTotal = $cur[1] - $script:CpuPrev[1]; $dIdle = $cur[0] - $script:CpuPrev[0]
            if ($dTotal -gt 0) { $pct = [Math]::Max([double]0, [Math]::Min([double]100, 100 * (1 - $dIdle / $dTotal))) }
        }
        $script:CpuPrev = $cur
        return $pct
    }

    function New-Brush([string]$Hex, [byte]$Alpha) {
        $c = [Windows.Media.ColorConverter]::ConvertFromString($Hex); $c.A = $Alpha
        return New-Object Windows.Media.SolidColorBrush($c)
    }
    function New-VGrad([string]$Hex, [byte]$Top, [byte]$Bottom) {
        $c1 = [Windows.Media.ColorConverter]::ConvertFromString($Hex); $c1.A = $Top
        $c2 = [Windows.Media.ColorConverter]::ConvertFromString($Hex); $c2.A = $Bottom
        return New-Object Windows.Media.LinearGradientBrush($c1, $c2, 90)
    }

    function Draw-Spark($Canvas, $Values, [double]$Max, [string]$Hex) {
        $Canvas.Children.Clear()
        $w = $Canvas.ActualWidth; $h = $Canvas.ActualHeight
        if ($w -lt 10 -or $Values.Count -lt 2) { return }
        $cap = 60; $step = $w / ($cap - 1)
        $vals = @($Values | Select-Object -Last $cap)
        $line = New-Object Windows.Media.PointCollection
        $n = $vals.Count
        for ($i = 0; $i -lt $n; $i++) {
            $x = $w - ($n - 1 - $i) * $step
            $y = $h - 2 - ([Math]::Min($Max, $vals[$i]) / $Max) * ($h - 6)
            $line.Add((New-Object Windows.Point($x, $y)))
        }
        $fill = [Windows.Media.PointCollection]::new($line)
        $fill.Add((New-Object Windows.Point($w, $h))); $fill.Add((New-Object Windows.Point(($w - ($n - 1) * $step), $h)))
        $pg = New-Object Windows.Shapes.Polygon; $pg.Points = $fill; $pg.Fill = New-VGrad $Hex 90 0
        $pl = New-Object Windows.Shapes.Polyline; $pl.Points = $line; $pl.Stroke = Brush $Hex; $pl.StrokeThickness = 2
        $pl.StrokeLineJoin = "Round"
        [void]$Canvas.Children.Add($pg); [void]$Canvas.Children.Add($pl)
    }
    function Draw-Sparks {
        Draw-Spark (N "CpuSpark") $script:CpuHist 100 "#A78BFA"
        Draw-Spark (N "RamSpark") $script:RamHist 100 "#38BDF8"
    }

    $ChartColors = @{ InUse = "#8B5CF6"; Modified = "#F59E0B"; Standby = "#38BDF8" }
    function Draw-MemChart {
        $c = N "MemChart"
        $c.Children.Clear()
        $W = $c.ActualWidth; $H = $c.ActualHeight
        if ($W -lt 50 -or $script:MemHist.Count -lt 1) { return }
        $left = 52; $top = 6; $bottom = $H - 2
        $pw = $W - $left - 4; $ph = $bottom - $top
        $total = [double]$script:MemHist[$script:MemHist.Count - 1].Total
        $step = $pw / ($HistCap - 1)
        $lastNo = $script:MemHist[$script:MemHist.Count - 1].No

        # Izgara + eksen etiketleri (GB)
        for ($i = 0; $i -le 4; $i++) {
            $y = $top + $ph * $i / 4
            $ln = New-Object Windows.Shapes.Line
            $ln.X1 = $left; $ln.X2 = $W - 4; $ln.Y1 = $y; $ln.Y2 = $y
            $ln.Stroke = Brush "#22223A"; $ln.StrokeThickness = 1
            if ($i -lt 4) { $ln.StrokeDashArray = [Windows.Media.DoubleCollection]::new([double[]]@(3, 4)) }
            [void]$c.Children.Add($ln)
            $lbl = New-Tb ("{0:N0} GB" -f ($total * (4 - $i) / 4 / 1GB)) 10.5 "#6A6A86"
            $lbl.TextWrapping = "NoWrap"
            [Windows.Controls.Canvas]::SetLeft($lbl, 0); [Windows.Controls.Canvas]::SetTop($lbl, [Math]::Max([double]0, $y - 8))
            [void]$c.Children.Add($lbl)
        }

        # Yigilmis alanlar: InUse -> +Modified -> +Standby
        $layers = @("InUse", "Modified", "Standby")
        $prevTop = $null
        $cum = @{}
        foreach ($s in $script:MemHist) { $cum[$s.No] = 0.0 }
        foreach ($layer in $layers) {
            $topPts = New-Object Windows.Media.PointCollection
            $basePts = New-Object System.Collections.Generic.List[Windows.Point]
            foreach ($s in $script:MemHist) {
                $x = $left + $pw - ($lastNo - $s.No) * $step
                if ($x -lt $left) { continue }
                $b = $cum[$s.No]; $v = $b + [double]$s.$layer; $cum[$s.No] = $v
                $topPts.Add((New-Object Windows.Point($x, ($bottom - $v / $total * $ph))))
                $basePts.Add((New-Object Windows.Point($x, ($bottom - $b / $total * $ph))))
            }
            if ($topPts.Count -lt 1) { continue }
            if ($topPts.Count -eq 1) {
                $p = $topPts[0]; $topPts.Insert(0, (New-Object Windows.Point(($p.X - 1), $p.Y)))
                $bp = $basePts[0]; $basePts.Insert(0, (New-Object Windows.Point(($bp.X - 1), $bp.Y)))
            }
            $poly = [Windows.Media.PointCollection]::new($topPts)
            for ($i = $basePts.Count - 1; $i -ge 0; $i--) { $poly.Add($basePts[$i]) }
            $pg = New-Object Windows.Shapes.Polygon; $pg.Points = $poly; $pg.Fill = New-VGrad $ChartColors[$layer] 150 60
            $pl = New-Object Windows.Shapes.Polyline; $pl.Points = $topPts; $pl.Stroke = Brush $ChartColors[$layer]; $pl.StrokeThickness = 1.6
            [void]$c.Children.Add($pg); [void]$c.Children.Add($pl)
        }

        # Optimizasyon isaretleri
        foreach ($e in $script:MemEvents) {
            $x = $left + $pw - ($lastNo - $e.No) * $step
            if ($x -lt $left) { continue }
            $ln = New-Object Windows.Shapes.Line
            $ln.X1 = $x; $ln.X2 = $x; $ln.Y1 = $top; $ln.Y2 = $bottom
            $ln.Stroke = Brush "#34D399"; $ln.StrokeThickness = 1.5
            $ln.StrokeDashArray = [Windows.Media.DoubleCollection]::new([double[]]@(4, 3))
            [void]$c.Children.Add($ln)
            $tag = New-Object Windows.Controls.Border
            $tag.Background = Brush "#0F2E25"; $tag.BorderBrush = Brush "#34D399"; $tag.BorderThickness = New-Object Windows.Thickness(1)
            $tag.CornerRadius = New-Object Windows.CornerRadius(6); $tag.Padding = New-Object Windows.Thickness(6, 2, 6, 2)
            $tt = New-Tb $e.Text 10.5 "#6EE7B7"; $tt.FontWeight = [Windows.FontWeights]::SemiBold; $tt.TextWrapping = "NoWrap"
            $tag.Child = $tt
            $tag.Measure((New-Object Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
            $tx = [Math]::Min($x + 4, $W - $tag.DesiredSize.Width - 2)
            if ($tx -lt $x) { $tx = $x - $tag.DesiredSize.Width - 4 }
            [Windows.Controls.Canvas]::SetLeft($tag, $tx); [Windows.Controls.Canvas]::SetTop($tag, $top + 4)
            [void]$c.Children.Add($tag)
        }
    }
    (N "MemChart").Add_SizeChanged({ Draw-MemChart })

    function Update-MemCards($m) {
        $tot = [double]$m.Total
        $set = {
            param($name, $bytes)
            (N $name).Text = Fmt-GB $bytes
            (N "${name}P").Text = (T "PctOfTotal") -f [int](100 * $bytes / $tot)
        }
        & $set "MemInUse" $m.InUse
        if ($m.ListOk) { & $set "MemStandby" $m.Standby; & $set "MemModified" $m.Modified; & $set "MemFree" $m.Free }
        else { foreach ($n in @("MemStandby", "MemModified", "MemFree")) { (N $n).Text = "—"; (N "${n}P").Text = "" } }
    }

    $script:ProcBusy = $false
    function Refresh-ProcList {
        if ($script:ProcBusy) { return }
        $script:ProcBusy = $true
        Start-Bg -Work {
            Get-Process | Group-Object ProcessName | ForEach-Object {
                [pscustomobject]@{ Name = $_.Name; Count = $_.Count; WS = [double]($_.Group | Measure-Object WorkingSet64 -Sum).Sum }
            } | Sort-Object WS -Descending | Select-Object -First 8
        } -Done {
            param($out, $err)
            $script:ProcBusy = $false
            $list = N "ProcList"; $list.Children.Clear()
            $items = @($out)
            if ($items.Count -eq 0) { return }
            $max = [double]$items[0].WS
            $slim = $window.FindResource("Slim")
            foreach ($p in $items) {
                $g = New-Object Windows.Controls.Grid; $g.Margin = New-Object Windows.Thickness(0, 0, 0, 10)
                foreach ($w in @(150, 0, 76)) {
                    $cd = New-Object Windows.Controls.ColumnDefinition
                    $cd.Width = if ($w -eq 0) { New-Object Windows.GridLength(1, "Star") } else { New-Object Windows.GridLength($w) }
                    $g.ColumnDefinitions.Add($cd)
                }
                $label = if ($p.Count -gt 1) { "$($p.Name)  ×$($p.Count)" } else { $p.Name }
                $nt = New-Tb $label 12 "#D4D4E4"; $nt.TextWrapping = "NoWrap"; $nt.TextTrimming = "CharacterEllipsis"
                $nt.VerticalAlignment = "Center"
                $pb = New-Object Windows.Controls.ProgressBar
                $pb.Style = $slim; $pb.Maximum = 100; $pb.Value = 100 * $p.WS / $max; $pb.VerticalAlignment = "Center"
                $pb.Margin = New-Object Windows.Thickness(8, 0, 12, 0)
                $vt = New-Tb (Fmt-GB $p.WS) 12 "#EDEDF5"; $vt.HorizontalAlignment = "Right"; $vt.VerticalAlignment = "Center"
                [Windows.Controls.Grid]::SetColumn($pb, 1); [Windows.Controls.Grid]::SetColumn($vt, 2)
                [void]$g.Children.Add($nt); [void]$g.Children.Add($pb); [void]$g.Children.Add($vt)
                [void]$list.Children.Add($g)
            }
        }
    }

    function Get-RamOps {
        @{
            WorkingSets = [bool](N "ChkWorkingSets").IsChecked; Modified = [bool](N "ChkModified").IsChecked
            Standby = [bool](N "ChkStandby").IsChecked; LowStandby = [bool](N "ChkLowStandby").IsChecked
            FileCache = [bool](N "ChkFileCache").IsChecked
        }
    }

    function Start-RamClean([switch]$Auto) {
        if ($script:Cleaning) { return }
        $script:Cleaning = $true
        $script:CleanAuto = [bool]$Auto
        $script:LastClean = Get-Date
        (N "BtnClean").IsEnabled = $false; (N "QaClean").IsEnabled = $false
        Set-Status ((T "Cleaning") + "…") "busy"
        Start-Bg -Work $RamCleanJob -ArgList @(, (Get-RamOps)) -Done {
            param($out, $err)
            $script:Cleaning = $false
            (N "BtnClean").IsEnabled = $true; (N "QaClean").IsEnabled = $true
            (N "BtnClean").Content = T "BtnClean"
            $r = @($out) | Select-Object -Last 1
            if ($err -or -not $r) { Set-Status ((T "CleanWarn") -f $err) "err"; return }
            $b = $r.Before; $a = $r.After
            $gain = [double]$a.Avail - [double]$b.Avail
            $gainTxt = if ($gain -ge 0) { "+" + (Fmt-GB $gain) } else { "-" + (Fmt-GB (-$gain)) }

            (N "ResNone").Visibility = "Collapsed"; (N "ResPanel").Visibility = "Visible"
            (N "ResGain").Text = $gainTxt
            (N "ResTime").Text = (T "ResTime") -f (Get-Date), $r.Ms
            (N "RbInUse").Text = Fmt-GB $b.InUse;       (N "RaInUse").Text = Fmt-GB $a.InUse
            (N "RbStandby").Text = Fmt-GB $b.Standby;   (N "RaStandby").Text = Fmt-GB $a.Standby
            (N "RbModified").Text = Fmt-GB $b.Modified; (N "RaModified").Text = Fmt-GB $a.Modified
            (N "RbAvail").Text = Fmt-GB $b.Avail;       (N "RaAvail").Text = Fmt-GB $a.Avail
            [void]$script:MemEvents.Add(@{ No = $script:SampleNo; Text = $gainTxt })
            while ($script:MemEvents.Count -gt 6) { $script:MemEvents.RemoveAt(0) }

            $failed = @($r.Codes.Keys | Where-Object { $r.Codes[$_] -ne 0 } | ForEach-Object { "{0} (0x{1:X8})" -f $_, $r.Codes[$_] })
            $prefix = if ($script:CleanAuto) { T "CleanAuto" } else { "" }
            if ($failed.Count -gt 0) { Set-Status ($prefix + ((T "CleanWarn") -f ($failed -join ", "))) "warn" }
            else { Set-Status ($prefix + ((T "CleanOK") -f (Fmt-GB ([Math]::Max([double]0, $gain))), $r.Ms)) "ok" }
            Draw-MemChart
            if ($script:Page -eq "Memory") { Refresh-ProcList }
        }
    }
    (N "BtnClean").Add_Click({ Start-RamClean })
    (N "QaClean").Add_Click({ Show-Page "Memory"; Start-RamClean })

    # Bellek secenekleri + otomatik temizlik
    $OptMap = @{ ChkWorkingSets = "WorkingSets"; ChkModified = "Modified"; ChkStandby = "Standby"; ChkLowStandby = "LowStandby"; ChkFileCache = "FileCache" }
    foreach ($k in $OptMap.Keys) {
        (N $k).IsChecked = $Settings.ram[$OptMap[$k]]
        (N $k).Add_Click({
            param($s)
            if ($s.Name -eq "ChkStandby" -and $s.IsChecked) { (N "ChkLowStandby").IsChecked = $false }
            if ($s.Name -eq "ChkLowStandby" -and $s.IsChecked) { (N "ChkStandby").IsChecked = $false }
            $ops = Get-RamOps
            foreach ($o in $ops.Keys) { $Settings.ram[$o] = $ops[$o] }
            Save-WoSettings
        })
    }
    $autoBtn = N ("Auto{0}" -f $Settings.autoClean)
    if ($autoBtn) { $autoBtn.IsChecked = $true } else { (N "Auto0").IsChecked = $true }
    foreach ($a in @("Auto0", "Auto75", "Auto85", "Auto90")) {
        (N $a).Add_Checked({ param($s) $Settings.autoClean = [int]$s.Tag; Save-WoSettings })
    }

    # ================= SİSTEM BİLGİSİ =================
    try {
        $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $build = [int]$cv.CurrentBuild
        $prod = "$($cv.ProductName)"
        if ($build -ge 22000) { $prod = $prod -replace "Windows 10", "Windows 11" }
        (N "SiOs").Text = "$prod  $($cv.DisplayVersion)"
        (N "SiBuild").Text = "$build.$($cv.UBR)"
        (N "SiCpu").Text = ((Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0").ProcessorNameString).Trim()
        (N "SiCpu").ToolTip = (N "SiCpu").Text
    } catch {}

    function Update-Home($m, [double]$cpu) {
        (N "CpuValue").Text = "{0:N0}" -f $cpu
        (N "RamValue").Text = "$($m.Load)"
        (N "RamSub").Text = (T "RamSub") -f (Fmt-GB ($m.Total - $m.Avail)), (Fmt-GB $m.Total)
        (N "SiRam").Text = Fmt-GB $m.Total
        $up = [TimeSpan]::FromMilliseconds([WoNative]::GetTickCount64())
        (N "SiUptime").Text = (T "Uptime") -f $up.Days, $up.Hours, $up.Minutes
        if ($script:SampleNo % 5 -eq 1) {
            $pc = [Diagnostics.Process]::GetProcesses().Length
            (N "SiProc").Text = "$pc"
            (N "CpuSub").Text = (T "CpuSub") -f [Environment]::ProcessorCount, $pc
            try {
                $d = New-Object IO.DriveInfo($env:SystemDrive.Substring(0, 1))
                $used = 100 * (1 - $d.AvailableFreeSpace / $d.TotalSize)
                (N "DiskValue").Text = "{0:N0}" -f $used
                (N "DiskBar").Value = $used
                (N "DiskBar").Foreground = Brush $(if ($used -ge 90) { "#F87171" } elseif ($used -ge 75) { "#FBBF24" } else { "#34D399" })
                (N "DiskSub").Text = (T "DiskSub") -f (Fmt-GB $d.AvailableFreeSpace), (Fmt-GB $d.TotalSize)
            } catch {}
        }
        Draw-Sparks
    }

    # ================= ANA ZAMANLAYICI (1 sn) =================
    $script:Tick = 0
    function On-Tick {
        $script:SampleNo++
        $m = [WoNative]::GetMemInfo()
        $script:LastMem = $m
        $cpu = Get-CpuUsage
        Push-Hist $script:CpuHist $cpu 60
        Push-Hist $script:RamHist ([double]$m.Load) 60
        Push-Hist $script:MemHist ([pscustomobject]@{
            No = $script:SampleNo; Total = $m.Total; InUse = $m.InUse
            Modified = $(if ($m.ListOk) { $m.Modified } else { 0 })
            Standby  = $(if ($m.ListOk) { $m.Standby } else { 0 })
        }) $HistCap

        switch ($script:Page) {
            "Home"   { Update-Home $m $cpu }
            "Memory" {
                Update-MemCards $m
                Draw-MemChart
                if ($script:SampleNo % 3 -eq 0) { Refresh-ProcList }
                (N "LiveDot").Opacity = if ($script:SampleNo % 2) { 1 } else { 0.35 }
            }
        }
        if ($script:Page -ne "Home" -and $script:SampleNo % 5 -eq 1) { Update-Home $m $cpu }

        # Otomatik temizlik (5 dk bekleme)
        if ($Settings.autoClean -gt 0 -and -not $script:Cleaning -and $m.Load -ge $Settings.autoClean -and
            ((Get-Date) - $script:LastClean).TotalMinutes -ge 5) { Start-RamClean -Auto }
    }

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({ try { On-Tick } catch { Write-WoLog "Tick hatasi: $_" } })

    # Hizli zamanlayici: arka plan isleri + ilerleme
    $script:CloseAt = $null
    $fast = New-Object Windows.Threading.DispatcherTimer
    $fast.Interval = [TimeSpan]::FromMilliseconds(120)
    $fast.Add_Tick({
        try {
            Poll-Bg
            if ($script:Cleaning) {
                $dots = "." * (1 + ([int]((Get-Date).Millisecond / 334)))
                (N "BtnClean").Content = (T "Cleaning") + $dots
            }
            if ($script:UpdSync) { Update-UpdProgress }
            if ($script:CloseAt -and (Get-Date) -ge $script:CloseAt) { $script:CloseAt = $null; $window.Close() }
        } catch { Write-WoLog "Fast tick hatasi: $_" }
    })

    # ================= GÜNCELLEME =================
    $script:Remote = $null
    $script:UpdSync = $null
    $script:UpdChecking = $false

    function Show-UpdateCard {
        $r = $script:Remote
        (N "UpdateCard").Visibility = "Visible"
        (N "UpdVersion").Text = (T "UpdVer") -f $LocalVersion, $r.version
        (N "UpdNotes").Text = "$($r.notes)"
        (N "UpdNotes").Visibility = if ($r.notes) { "Visible" } else { "Collapsed" }
        (N "UpdNotes").ToolTip = "$($r.notes)"
    }

    function Check-Update([switch]$Manual) {
        if ($script:UpdChecking) { return }
        $script:UpdChecking = $true
        $script:UpdManual = [bool]$Manual
        if ($Manual) { (N "SetUpdStatus").Text = T "UpdChecking" }
        Start-Bg -Work {
            param($Mod)
            . $Mod
            Get-WoRemoteInfo
        } -ArgList @((Join-Path $AppDir "modules\Updater.ps1")) -Done {
            param($out, $err)
            $script:UpdChecking = $false
            $r = @($out) | Select-Object -Last 1
            if ($err -or -not $r -or -not $r.version) {
                Write-WoLog "Guncelleme denetimi basarisiz: $err"
                if ($script:UpdManual) { (N "SetUpdStatus").Text = T "UpdFail" }
                return
            }
            if (Test-WoNewer $r.version $LocalVersion) {
                $script:Remote = $r
                Show-UpdateCard
                (N "SetUpdStatus").Text = (T "UpdAvailable") -f $r.version
            } else {
                (N "SetUpdStatus").Text = (T "UpdLatest") -f $LocalVersion
            }
        }
    }
    (N "BtnCheckUpdate").Add_Click({ Check-Update -Manual })

    function Start-Update {
        if (-not $script:Remote -or $script:UpdSync) { return }
        $files = @($script:Remote.files | Where-Object { $_ })
        if ($files.Count -eq 0) { $files = $WoDefaultFiles }
        $stage = Join-Path $env:TEMP ("WO-update-" + $script:Remote.version)
        $script:UpdSync = [hashtable]::Synchronized(@{ Stage = "start"; Pct = 0; Index = 0; Count = $files.Count; File = ""; Error = $null })
        $script:UpdStagePath = $stage
        (N "UpdProgressPanel").Visibility = "Visible"
        (N "BtnUpdate").IsEnabled = $false
        (N "UpdNotes").Visibility = "Collapsed"
        Write-WoLog "Guncelleme basladi: v$LocalVersion -> v$($script:Remote.version)"
        Start-Bg -Work $WoDownloadJob -ArgList @($WoRepoRaw, $files, $stage, $script:UpdSync) -Done {
            param($out, $err)
            $sync = $script:UpdSync
            if ($err -and $sync.Stage -ne "error") { $sync.Error = $err; $sync.Stage = "error" }
            Update-UpdProgress
            if ($sync.Stage -eq "ready") {
                try {
                    Start-WoApplyUpdate -Stage $script:UpdStagePath -InstallDir $AppDir -ParentPid $PID
                    $script:CloseAt = (Get-Date).AddMilliseconds(900)
                } catch { $sync.Error = $_.Exception.Message; $sync.Stage = "error"; Update-UpdProgress }
            }
            if ($sync.Stage -eq "error") {
                Write-WoLog "Guncelleme hatasi: $($sync.Error)"
                $script:UpdSync = $null
                (N "BtnUpdate").IsEnabled = $true
                (N "BtnUpdate").Content = T "UpdRetry"
            }
        }
    }
    (N "BtnUpdate").Add_Click({ Start-Update })

    function Update-UpdProgress {
        $s = $script:UpdSync
        if (-not $s) { return }
        (N "UpdProgress").Value = [int]$s.Pct
        (N "UpdPct").Text = "$([int]$s.Pct)%"
        $txt = switch ($s.Stage) {
            "download" { (T "Upd_download") -f $s.Index, $s.Count }
            "verify"   { T "Upd_verify" }
            "ready"    { T "Upd_ready" }
            "error"    { (T "Upd_error") -f $s.Error }
            default    { T "Upd_start" }
        }
        (N "UpdStage").Text = $txt
        (N "UpdStage").ToolTip = if ($s.Stage -eq "download") { $s.File } else { $txt }
        (N "UpdStage").Foreground = Brush $(if ($s.Stage -eq "error") { "#F87171" } else { "#B4B4CC" })
    }

    function Fmt-Size([double]$Bytes) {
        if ($Bytes -ge 1GB) { "{0:N2} GB" -f ($Bytes / 1GB) } elseif ($Bytes -ge 1MB) { "{0:N1} MB" -f ($Bytes / 1MB) }
        elseif ($Bytes -gt 0) { "{0:N0} KB" -f [Math]::Ceiling($Bytes / 1KB) } else { "0 MB" }
    }
    function New-Badge([string]$Text, [string]$Bg, [string]$Fg) {
        $b = New-Object Windows.Controls.Border
        $b.CornerRadius = New-Object Windows.CornerRadius(5); $b.Background = Brush $Bg
        $b.Padding = New-Object Windows.Thickness(6, 1, 6, 1); $b.Margin = New-Object Windows.Thickness(8, 0, 0, 0)
        $b.VerticalAlignment = "Center"
        $t = New-Tb $Text 9.5 $Fg; $t.FontWeight = [Windows.FontWeights]::Bold; $t.TextWrapping = "NoWrap"
        $b.Child = $t
        return $b
    }
    function New-Cols($Grid, [object[]]$Widths) {
        foreach ($w in $Widths) {
            $cd = New-Object Windows.Controls.ColumnDefinition
            $cd.Width = if ($w -eq "*") { New-Object Windows.GridLength(1, "Star") } elseif ($w -eq "Auto") { [Windows.GridLength]::Auto } else { New-Object Windows.GridLength([double]$w) }
            $Grid.ColumnDefinitions.Add($cd)
        }
    }

    # ================= BAŞLANGIÇ =================
    Add-Type -AssemblyName System.Drawing
    $script:StartupItems = @()
    $script:StartupLoaded = $false
    $script:StartupBusy = $false
    $script:IconCache = @{}

    function Get-WoIcon([string]$Path) {
        if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        if ($script:IconCache.ContainsKey($Path)) { return $script:IconCache[$Path] }
        $src = $null
        try {
            $ico = [Drawing.Icon]::ExtractAssociatedIcon($Path)
            $src = [Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon($ico.Handle, [Windows.Int32Rect]::Empty,
                [Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions())
            $src.Freeze(); $ico.Dispose()
        } catch {}
        $script:IconCache[$Path] = $src
        return $src
    }

    function Load-Startup {
        if ($script:StartupBusy) { return }
        $script:StartupBusy = $true
        (N "SuSummary").Text = T "SuLoading"
        (N "BtnSuRefresh").IsEnabled = $false
        Start-Bg -Work {
            param($Mod)
            . $Mod
            Get-WoStartupItems
        } -ArgList @((Join-Path $AppDir "modules\Startup.ps1")) -Done {
            param($out, $err)
            $script:StartupBusy = $false; $script:StartupLoaded = $true
            (N "BtnSuRefresh").IsEnabled = $true
            if ($err) { Write-WoLog "Baslangic taramasi: $err" }
            $script:StartupItems = @($out | Where-Object { $_ -and $_.Id })
            Build-StartupList
        }
    }

    function Update-StartupSummary {
        $on = @($script:StartupItems | Where-Object Enabled).Count
        (N "SuSummary").Text = (T "SuSummary") -f $script:StartupItems.Count, $on
    }

    function Build-StartupList {
        $list = N "StartupList"; $list.Children.Clear()
        $cardStyle = $window.FindResource("Card"); $switchStyle = $window.FindResource("Switch")
        $titleBtn = $window.FindResource("TitleBtn")
        foreach ($grp in @(@{ On = $true; Key = "SuGroupOn" }, @{ On = $false; Key = "SuGroupOff" })) {
            $items = @($script:StartupItems | Where-Object { [bool]$_.Enabled -eq $grp.On } | Sort-Object Name)
            if ($items.Count -eq 0) { continue }
            $cap = New-Tb ("{0}  ·  {1}" -f (T $grp.Key), $items.Count) 11 "#7A7A94"
            $cap.FontWeight = [Windows.FontWeights]::SemiBold; $cap.Margin = New-Object Windows.Thickness(4, 0, 0, 8)
            [void]$list.Children.Add($cap)
            $card = New-Object Windows.Controls.Border
            $card.Style = $cardStyle; $card.Padding = New-Object Windows.Thickness(0); $card.Margin = New-Object Windows.Thickness(0, 0, 0, 16)
            $stack = New-Object Windows.Controls.StackPanel; $card.Child = $stack
            $first = $true
            foreach ($it in $items) {
                $row = New-Object Windows.Controls.Border
                $row.Padding = New-Object Windows.Thickness(18, 12, 18, 12)
                if (-not $first) { $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0) }
                $first = $false
                $g = New-Object Windows.Controls.Grid; New-Cols $g @(46, "*", "Auto", "Auto")

                # Simge (yoksa bas harf)
                $iconBox = New-Object Windows.Controls.Border
                $iconBox.Width = 34; $iconBox.Height = 34; $iconBox.CornerRadius = New-Object Windows.CornerRadius(9)
                $iconBox.Background = Brush "#1C1C2E"; $iconBox.HorizontalAlignment = "Left"
                $img = Get-WoIcon $it.Path
                if ($img) {
                    $im = New-Object Windows.Controls.Image; $im.Source = $img; $im.Width = 22; $im.Height = 22
                    $iconBox.Child = $im
                } else {
                    $lt = New-Tb ("$($it.Name)".Substring(0, 1).ToUpper()) 14 "#A78BFA"; $lt.FontWeight = [Windows.FontWeights]::Bold
                    $lt.HorizontalAlignment = "Center"; $lt.VerticalAlignment = "Center"; $iconBox.Child = $lt
                }

                $txt = New-Object Windows.Controls.StackPanel; $txt.Margin = New-Object Windows.Thickness(0, 0, 12, 0)
                $tr = New-Object Windows.Controls.WrapPanel
                $display = if ($it.Description -and $it.Description.Length -lt 60 -and $it.Name -match '_[0-9A-F]{16,}|^\{') { $it.Description } else { $it.Name }
                $nm = New-Tb $display 13.5 "#EDEDF5"; $nm.TextWrapping = "NoWrap"; $nm.TextTrimming = "CharacterEllipsis"
                [void]$tr.Children.Add($nm)
                if ($it.Critical) { [void]$tr.Children.Add((New-Badge (T "SuCritical") "#3A2E10" "#FCD34D")) }
                if (-not $it.Exists) { [void]$tr.Children.Add((New-Badge (T "SuMissing") "#3A1520" "#FCA5A5")) }
                $pub = if ($it.Publisher) { "$($it.Publisher)  ·  " } else { "" }
                $meta = New-Tb ($pub + (T "Src_$($it.Source)")) 11.5 "#9C9CB8"; $meta.Margin = New-Object Windows.Thickness(0, 2, 0, 0)
                $cmd = New-Tb $it.Command 10.5 "#6A6A86"; $cmd.TextWrapping = "NoWrap"; $cmd.TextTrimming = "CharacterEllipsis"
                $cmd.ToolTip = $it.Command; $cmd.Margin = New-Object Windows.Thickness(0, 2, 0, 0)
                [void]$txt.Children.Add($tr); [void]$txt.Children.Add($meta); [void]$txt.Children.Add($cmd)

                $open = New-Object Windows.Controls.Button
                $open.Style = $titleBtn; $open.Content = [string][char]0xE838; $open.ToolTip = T "SuOpen"
                $open.Margin = New-Object Windows.Thickness(0, 0, 10, 0); $open.Tag = $it.Path; $open.IsEnabled = [bool]$it.Exists
                $open.Add_Click({ param($s) Start-Process explorer.exe "/select,`"$($s.Tag)`"" })

                $sw = New-Object Windows.Controls.CheckBox
                $sw.Style = $switchStyle; $sw.IsChecked = [bool]$it.Enabled; $sw.Tag = $it
                $sw.Add_Click({
                    param($s)
                    $item = $s.Tag; $want = [bool]$s.IsChecked
                    try {
                        Set-WoStartupItem $item $want
                        $item.Enabled = $want
                        Set-Status ((T $(if ($want) { "SuToggledOn" } else { "SuToggledOff" })) -f $item.Name) "ok"
                    } catch {
                        $s.IsChecked = -not $want
                        Set-Status ((T "SuFail") -f $item.Name, $_.Exception.Message) "err"
                    }
                    Update-StartupSummary
                })

                [Windows.Controls.Grid]::SetColumn($txt, 1); [Windows.Controls.Grid]::SetColumn($open, 2); [Windows.Controls.Grid]::SetColumn($sw, 3)
                [void]$g.Children.Add($iconBox); [void]$g.Children.Add($txt); [void]$g.Children.Add($open); [void]$g.Children.Add($sw)
                $row.Child = $g
                [void]$stack.Children.Add($row)
            }
            [void]$list.Children.Add($card)
        }
        Update-StartupSummary
    }
    (N "BtnSuRefresh").Add_Click({ Load-Startup })
    (N "BtnSuTaskMgr").Add_Click({ Start-Process taskmgr.exe -ArgumentList "/7 /startup" })

    # ================= DİSK =================
    $script:DiskScan = @{}
    $script:DiskScanned = $false
    $script:DiskBusy = $false
    $script:CleanSel = @{}
    foreach ($c in $DiskCategories) { $script:CleanSel[$c.Id] = [bool]$c.Rec }

    function Show-Drives {
        $grid = N "DriveList"; $grid.Children.Clear()
        $drives = @(Get-WoDrives)
        $grid.Columns = [Math]::Max(1, [Math]::Min(4, $drives.Count))
        $grid.Margin = New-Object Windows.Thickness(0, 0, -12, 0)
        $cardStyle = $window.FindResource("Card"); $slim = $window.FindResource("Slim"); $iconFont = $window.FindResource("Icons")
        foreach ($d in $drives) {
            $used = 100 * (1 - $d.Free / [Math]::Max([double]1, $d.Total))
            $card = New-Object Windows.Controls.Border
            $card.Style = $cardStyle; $card.Padding = New-Object Windows.Thickness(18, 16, 18, 16); $card.Margin = New-Object Windows.Thickness(0, 0, 12, 0)
            $sp = New-Object Windows.Controls.StackPanel
            $head = New-Object Windows.Controls.Grid; New-Cols $head @(40, "*")
            $ib = New-Object Windows.Controls.Border
            $ib.Width = 32; $ib.Height = 32; $ib.CornerRadius = New-Object Windows.CornerRadius(8); $ib.Background = Brush "#173328"; $ib.HorizontalAlignment = "Left"
            $ic = New-Tb ([string][char]0xEDA2) 15 "#34D399"; $ic.FontFamily = $iconFont; $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"
            $ib.Child = $ic
            $hs = New-Object Windows.Controls.StackPanel; $hs.VerticalAlignment = "Center"
            $tr = New-Object Windows.Controls.StackPanel; $tr.Orientation = "Horizontal"
            $label = if ($d.Label) { $d.Label } else { T "DriveLocal" }
            $nt = New-Tb "$label ($($d.Letter):)" 13 "#EDEDF5"; $nt.TextWrapping = "NoWrap"; $nt.TextTrimming = "CharacterEllipsis"; $nt.FontWeight = [Windows.FontWeights]::SemiBold
            [void]$tr.Children.Add($nt)
            $fl = New-Object Windows.Controls.StackPanel; $fl.Orientation = "Horizontal"; $fl.Margin = New-Object Windows.Thickness(0, 2, 0, 0)
            $ft = New-Tb "$($d.Format)" 10.5 "#6A6A86"; $ft.VerticalAlignment = "Center"
            [void]$fl.Children.Add($ft)
            if ($d.System) { [void]$fl.Children.Add((New-Badge (T "DriveSystem") "#231F3F" "#C4B5FD")) }
            [void]$hs.Children.Add($tr); [void]$hs.Children.Add($fl)
            [Windows.Controls.Grid]::SetColumn($hs, 1)
            [void]$head.Children.Add($ib); [void]$head.Children.Add($hs)
            $pctRow = New-Object Windows.Controls.StackPanel; $pctRow.Orientation = "Horizontal"; $pctRow.Margin = New-Object Windows.Thickness(0, 12, 0, 0)
            $pv = New-Tb ("{0:N0}" -f $used) 26 "#FFFFFF"; $pv.FontWeight = [Windows.FontWeights]::Bold
            $pp = New-Tb "%" 14 "#7A7A94"; $pp.VerticalAlignment = "Bottom"; $pp.Margin = New-Object Windows.Thickness(2, 0, 0, 5)
            [void]$pctRow.Children.Add($pv); [void]$pctRow.Children.Add($pp)
            $bar = New-Object Windows.Controls.ProgressBar
            $bar.Style = $slim; $bar.Maximum = 100; $bar.Value = $used; $bar.Height = 8; $bar.Margin = New-Object Windows.Thickness(0, 6, 0, 8)
            if ($used -ge 90) { $bar.Foreground = Brush "#F87171" } elseif ($used -ge 75) { $bar.Foreground = Brush "#FBBF24" }
            $fr = New-Tb ((T "DriveFree") -f (Fmt-GB $d.Free), (Fmt-GB $d.Total)) 11.5 "#9C9CB8"
            [void]$sp.Children.Add($head); [void]$sp.Children.Add($pctRow); [void]$sp.Children.Add($bar); [void]$sp.Children.Add($fr)
            $card.Child = $sp
            [void]$grid.Children.Add($card)
        }
    }

    function Build-CleanList {
        $list = N "CleanList"; $list.Children.Clear()
        $check = $window.FindResource("Check")
        foreach ($c in $DiskCategories) {
            $row = New-Object Windows.Controls.Border
            $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0)
            $row.Padding = New-Object Windows.Thickness(20, 12, 20, 12)
            $g = New-Object Windows.Controls.Grid; New-Cols $g @("*", 110)
            $cb = New-Object Windows.Controls.CheckBox
            $cb.Style = $check; $cb.Margin = New-Object Windows.Thickness(0); $cb.Tag = $c.Id
            $cb.Focusable = $false
            $cb.IsChecked = $script:CleanSel[$c.Id]
            $txt = New-Object Windows.Controls.StackPanel
            $nm = New-Tb $c[$script:Lang][0] 13 "#EDEDF5"
            $ds = New-Tb $c[$script:Lang][1] 11.5 "#7A7A94"; $ds.Margin = New-Object Windows.Thickness(0, 2, 12, 0)
            [void]$txt.Children.Add($nm); [void]$txt.Children.Add($ds)
            $cb.Content = $txt
            $cb.Add_Click({ param($s) $script:CleanSel[$s.Tag] = [bool]$s.IsChecked; Update-CleanSummary })
            $r = $script:DiskScan[$c.Id]
            $sizeTxt = if ($script:DiskBusy -and -not $r) { "…" } elseif ($r) { Fmt-Size $r.Bytes } else { "—" }
            $color = if ($r -and $r.Bytes -ge 1GB) { "#FBBF24" } elseif ($r -and $r.Bytes -eq 0) { "#34D399" } else { "#EDEDF5" }
            $sz = New-Tb $sizeTxt 13.5 $color; $sz.FontWeight = [Windows.FontWeights]::SemiBold
            $sz.HorizontalAlignment = "Right"; $sz.VerticalAlignment = "Center"; $sz.TextWrapping = "NoWrap"
            [Windows.Controls.Grid]::SetColumn($sz, 1)
            [void]$g.Children.Add($cb); [void]$g.Children.Add($sz)
            $row.Child = $g
            [void]$list.Children.Add($row)
        }
        Update-CleanSummary
    }

    function Update-CleanSummary {
        $bytes = 0.0; $files = 0; $cats = 0
        foreach ($c in $DiskCategories) {
            $r = $script:DiskScan[$c.Id]
            if ($script:CleanSel[$c.Id] -and $r -and $r.Bytes -gt 0) { $bytes += $r.Bytes; $files += $r.Files; $cats++ }
        }
        (N "DcSelBytes").Text = if ($script:DiskScanned) { Fmt-Size $bytes } else { "—" }
        (N "DcSelFiles").Text = (T "DcSelFiles") -f $files, $cats
        (N "BtnDiskClean").IsEnabled = ($bytes -gt 0) -and -not $script:DiskBusy
        return $bytes
    }

    function Start-DiskScan {
        if ($script:DiskBusy) { return }
        $script:DiskBusy = $true
        $script:DiskScan = @{}
        (N "BtnDiskScan").IsEnabled = $false
        (N "DcSub").Text = T "DcScanning"
        Build-CleanList
        Start-Bg -Work {
            param($Mod)
            . $Mod
            Get-WoDiskScan
        } -ArgList @((Join-Path $AppDir "modules\DiskCleaner.ps1")) -Done {
            param($out, $err)
            $script:DiskBusy = $false; $script:DiskScanned = $true
            (N "BtnDiskScan").IsEnabled = $true
            (N "DcSub").Text = T "DcSub"
            if ($err) { Write-WoLog "Disk taramasi: $err" }
            foreach ($r in @($out)) { if ($r.Id) { $script:DiskScan[$r.Id] = $r } }
            Build-CleanList
            if ($script:Page -eq "Disk") { [void]$window.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::ContextIdle, [Action]{ (N "PageDisk").ScrollToTop() }) }
        }
    }

    function Start-DiskClean {
        if ($script:DiskBusy) { return }
        $ids = @($DiskCategories | Where-Object { $script:CleanSel[$_.Id] -and $script:DiskScan[$_.Id] -and $script:DiskScan[$_.Id].Bytes -gt 0 } | ForEach-Object Id)
        if ($ids.Count -eq 0) { return }
        $bytes = Update-CleanSummary
        $msg = (T "DcConfirm") -f (Fmt-Size $bytes)
        if ($ids -contains "Recycle") { $msg += T "DcRecycleConfirm" }
        $res = [Windows.MessageBox]::Show($window, $msg, "Windows Optimizer", "YesNo", "Warning")
        if ("$res" -ne "Yes") { return }

        $script:DiskBusy = $true
        (N "BtnDiskClean").IsEnabled = $false; (N "BtnDiskScan").IsEnabled = $false
        (N "BtnDiskClean").Content = T "DcCleaning"
        Set-Status (T "DcCleaning") "busy"
        Start-Bg -Work {
            param($Mod, $Ids)
            . $Mod
            Invoke-WoDiskClean $Ids
        } -ArgList @((Join-Path $AppDir "modules\DiskCleaner.ps1"), [string[]]$ids) -Done {
            param($out, $err)
            $script:DiskBusy = $false
            (N "BtnDiskClean").Content = T "BtnDiskClean"
            $freed = 0.0; $del = 0; $fail = 0
            foreach ($r in @($out)) { if ($r.Id) { $freed += $r.Freed; $del += $r.Deleted; $fail += $r.Failed } }
            if ($err) { Write-WoLog "Disk temizligi: $err" }
            (N "DcResultBox").Visibility = "Visible"
            (N "DcResult").Text = (T "DcResult") -f (Fmt-Size $freed)
            (N "DcResultSub").Text = (T "DcResultSub") -f $del, $fail
            Set-Status ((T "DcDone") -f (Fmt-Size $freed)) "ok"
            Show-Drives
            Start-DiskScan
        }
    }
    (N "BtnDiskScan").Add_Click({ Start-DiskScan })
    (N "BtnDiskClean").Add_Click({ Start-DiskClean })
    (N "BtnCleanMgr").Add_Click({ Start-Process cleanmgr.exe })

    # ================= DİL =================
    $LocNames = @(
        "NavCaption", "UpdTitle", "HeroCaption", "HeroLabel", "BtnQuickOptimize", "BtnGoTweaks",
        "CpuTitle", "RamTitle", "DiskTitle", "SysTitle", "LblOs", "LblBuild", "LblCpu", "LblRam", "LblUptime", "LblProc",
        "QaTitle", "QaCleanT", "QaCleanD", "QaExplorerT", "QaExplorerD", "QaRestoreT", "QaRestoreD",
        "BtnSelRec", "BtnSelReset", "RestartText", "BtnRestartExplorer",
        "MemInUseT", "MemStandbyT", "MemModifiedT", "MemFreeT", "ChartTitle", "LiveText", "LegInUse", "LegModified", "LegStandby",
        "AxisLeft", "AxisRight", "CleanTitle", "OptWorkingSets", "OptWorkingSetsD", "OptModified", "OptModifiedD",
        "OptStandby", "OptStandbyD", "OptLowStandby", "OptLowStandbyD", "OptFileCache", "OptFileCacheD", "BtnClean", "AutoTitle",
        "ResTitle", "ResNone", "ResGainSub", "ResColBefore", "ResColAfter", "ResRowInUse", "ResRowStandby", "ResRowModified", "ResRowAvail",
        "ProcTitle", "MemNote", "SetLangT", "SetLangD", "SetUpdT", "BtnCheckUpdate", "SetShortcutT", "SetShortcutD", "BtnFixShortcut",
        "SetRestoreT", "SetRestoreD", "BtnRestore2", "SetLogT", "SetLogD", "BtnOpenLog", "SetAboutT", "AdminBadge",
        "SuHint", "BtnSuTaskMgr", "BtnSuRefresh", "DcTitle", "DcSub", "BtnDiskScan", "DcSelTitle", "BtnDiskClean", "DcNote", "BtnCleanMgr"
    )
    function Apply-Language {
        foreach ($n in $LocNames) {
            $ctrl = N $n
            if (-not $ctrl) { continue }
            if ($ctrl -is [Windows.Controls.TextBlock]) { $ctrl.Text = T $n } else { $ctrl.Content = T $n }
        }
        foreach ($p in $PageOrder) { (N "Nav$p").Content = T "Nav$p" }
        (N "Auto0").Content = T "AutoOff"
        (N "BtnLang").Content = if ($script:Lang -eq "TR") { "EN" } else { "TR" }
        (N "SideVersion").Text = "v$LocalVersion"
        (N "SetVerText").Text = (T "VersionLbl") -f $LocalVersion
        (N "AuthorLabel").Text = "by $($Config.author)"
        (N "AboutText").Text = "Windows Optimizer v$LocalVersion  ·  © $($Config.author)"
        (N "PageTitle").Text = T "Title_$($script:Page)"
        (N "PageSub").Text = T "Sub_$($script:Page)"
        if ($script:UpdSync) { Update-UpdProgress } elseif (-not (N "BtnUpdate").IsEnabled) { } else { (N "BtnUpdate").Content = T "BtnUpdate" }
        if ($script:Remote) { Show-UpdateCard }
        (N "CpuSub").Text = (T "CpuSub") -f [Environment]::ProcessorCount, [Diagnostics.Process]::GetProcesses().Length
        if ($script:TweakRows.Count -gt 0) { Build-TweakList }
        if ($script:StartupLoaded) { Build-StartupList } else { (N "SuSummary").Text = T "SuLoading" }
        if ($script:Page -eq "Disk") { Show-Drives }
        Build-CleanList
        (N "Lang$($script:Lang)").IsChecked = $true
    }
    function Set-Language([string]$L) {
        if ($script:Lang -eq $L) { return }
        $script:Lang = $L; $Settings.language = $L; Save-WoSettings
        Apply-Language
        Set-Status (T "StatusReady") "info"
    }
    (N "BtnLang").Add_Click({ Set-Language $(if ($script:Lang -eq "TR") { "EN" } else { "TR" }) })
    (N "LangTR").Add_Checked({ Set-Language "TR" })
    (N "LangEN").Add_Checked({ Set-Language "EN" })

    # ================= BAŞLAT =================
    Refresh-TweakStates
    Apply-Language
    Build-TweakList
    Show-Page "Home"
    Set-Status (T "StatusReady") "info"
    if ($Updated) { Set-Status ((T "Updated") -f $LocalVersion) "ok" }

    $window.Add_Closing({
        $timer.Stop(); $fast.Stop()
        if (-not $Snapshot) { Save-WoSettings }
    })

    $window.Add_ContentRendered({
        On-Tick
        $timer.Start(); $fast.Start()
        if (-not $Snapshot) { Check-Update }
    })

    # Gelistirici: -Snapshot <klasor> her sayfanin PNG goruntusunu alir ve cikar
    if ($Snapshot) {
        New-Item -ItemType Directory -Path $Snapshot -Force | Out-Null
        $script:Remote = [pscustomobject]@{ version = "2.1.0"; notes = "Örnek sürüm notu: yeni modüller ve hata düzeltmeleri, uzun metin taşmadan sarılır." }
        Show-UpdateCard
        $script:SnapStep = 0
        $snapTimer = New-Object Windows.Threading.DispatcherTimer
        $snapTimer.Interval = [TimeSpan]::FromSeconds(1)
        $snapTimer.Add_Tick({
            $script:SnapStep++
            $snap = {
                param($name)
                $root = $window.Content
                $rtb = New-Object Windows.Media.Imaging.RenderTargetBitmap([int]$root.ActualWidth, [int]$root.ActualHeight, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
                $rtb.Render($root)
                $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
                $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($rtb))
                $fs = [IO.File]::Create((Join-Path $Snapshot "$name.png")); $enc.Save($fs); $fs.Close()
            }
            switch ($script:SnapStep) {
                4  { & $snap "1-Home"; Show-Page "Tweaks" }
                5  { & $snap "2-Tweaks"; Show-Page "Memory" }
                8  { & $snap "3-Memory"; Start-RamClean }
                12 { & $snap "4-Memory-after"; Show-Page "Startup" }
                16 { & $snap "5-Startup"; Show-Page "Disk" }
                24 { & $snap "6-Disk"; Show-Page "Settings" }
                25 { & $snap "7-Settings"; $window.Close() }
            }
        })
        $snapTimer.Start()
    }

    [void]$window.ShowDialog()
    $script:Pool.Close()
}
catch {
    $err = "HATA: $($_.Exception.Message)`r`nSATIR: $($_.InvocationInfo.ScriptLineNumber)`r`n$($_.ScriptStackTrace)"
    Write-WoLog $err
    try { [Windows.MessageBox]::Show($err, "Windows Optimizer - Hata", "OK", "Error") | Out-Null } catch { Write-Host $err -ForegroundColor Red }
}
