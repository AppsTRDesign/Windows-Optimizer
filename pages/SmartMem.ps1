# pages/SmartMem.ps1 - Akilli bellek yonetimi
#   1) Akilli standby temizleyici (yalnizca bos bellek esigin altina dusunce; oyunlarda takilmayi azaltir)
#   2) Arka plan kisitlayici: bellek onceligi DUSUK + verimlilik modu (EcoQoS); one gelen uygulamada otomatik kaldirilir
#   3) Bellek sizintisi dedektoru (surec bazli buyume izleme)
#   4) Sanal bellek (sayfa dosyasi) danismani
#   5) Tarayici bellek tasarrufu (Optimizasyonlar katalogundaki ayar)

Add-WoType "WoProc" @"
using System;
using System.Runtime.InteropServices;
public static class WoProc {
    [DllImport("kernel32.dll")] static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] static extern bool SetProcessInformation(IntPtr h, int cls, ref uint info, int size);
    [DllImport("kernel32.dll")] static extern bool SetProcessInformation(IntPtr h, int cls, ref PPTS info, int size);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out int pid);
    [StructLayout(LayoutKind.Sequential)] struct PPTS { public uint Version, ControlMask, StateMask; }
    const uint PROCESS_SET_INFORMATION = 0x0200;
    public static int ForegroundPid() { int pid; GetWindowThreadProcessId(GetForegroundWindow(), out pid); return pid; }
    // Bellek onceligi: 1=cok dusuk, 2=dusuk, 5=normal
    public static bool SetMemoryPriority(int pid, uint prio) {
        IntPtr h = OpenProcess(PROCESS_SET_INFORMATION, false, pid); if (h == IntPtr.Zero) return false;
        try { return SetProcessInformation(h, 0, ref prio, 4); } finally { CloseHandle(h); }
    }
    // Verimlilik modu (EcoQoS): on=true kisitla, false=Windows'a birak
    public static bool SetEcoQoS(int pid, bool on) {
        IntPtr h = OpenProcess(PROCESS_SET_INFORMATION, false, pid); if (h == IntPtr.Zero) return false;
        try { PPTS s = new PPTS(); s.Version = 1; s.ControlMask = on ? 1u : 0u; s.StateMask = on ? 1u : 0u; return SetProcessInformation(h, 4, ref s, 12); }
        finally { CloseHandle(h); }
    }
}
"@

Add-WoStrings @{
    NavSmartMem = "Akıllı Bellek"; Title_SmartMem = "Akıllı Bellek"; Sub_SmartMem = "Belleği silmek yerine akıllıca yönetin — kalıcı etkisi olan yöntemler"
    SmIntro = "Windows boş belleği önbellek olarak kullanır; bu iyidir. Gerçek kazanç, belleği kimin tükettiğini bulmak ve arka plan uygulamalarını öne gelen uygulamanın lehine kısıtlamaktır."
    SmStbT = "Akıllı standby temizleyici"; SmStbD = "Yalnızca boş bellek eşiğin altına düştüğünde önbelleği boşaltır (ISLC yöntemi). Oyunlarda ani takılmaları azaltabilir; sürekli temizlik yapmaz."
    SmStbOn = "Etkinleştir"; SmStbThr = "Boş bellek şunun altına düşünce:"; SmStbGame = "Yalnızca Oyun Modu açıkken"
    SmStbStat = "Bu oturumda {0} kez temizlendi · son: {1} · şu an boş: {2}"; SmStbNever = "henüz yok"
    SmLimT = "Arka plan uygulamalarını kısıtla"; SmLimD = "Seçili uygulamalar arka plandayken bellek önceliği düşürülür ve verimlilik moduna alınır; bellek sıkışınca Windows önce onları boşaltır. Uygulama öne geldiğinde kısıtlama anında kalkar."
    SmLimOn = "Etkinleştir"; SmLimNone = "Listedeki uygulamaların hiçbiri şu an çalışmıyor."; SmLimActive = "{0} süreç kısıtlanıyor"; SmLimFg = "ön planda"
    SmLeakT = "Bellek sızıntısı dedektörü"; SmLeakD = "Uygulamaların bellek kullanımı dakikada bir kaydedilir. Sürekli büyüyen uygulama işaretlenir; yeniden başlatmak belleği geri kazandırır."
    SmLeakWait = "Veri toplanıyor… (en az 20 dakika gerekir · {0} dk)"; SmLeakNone = "Şüpheli büyüme yok. {0} dakikalık veri incelendi."
    SmLeakRow = "{0} → {1}  (+{2} / {3} dk)"; SmLeakFlag = "SIZINTI ŞÜPHESİ"; SmLeakGrow = "BÜYÜYOR"
    BtnSmRestart = "Yeniden başlat"; SmRestarted = "{0} yeniden başlatıldı"; SmLeakTip = "{0} belleği sürekli büyütüyor: {1} → {2}"
    SmPfT = "Sanal bellek (sayfa dosyası) danışmanı"; SmPfAuto = "Windows otomatik yönetiyor (önerilen)"; SmPfManual = "Elle ayarlanmış"
    SmPfFile = "{0} · ayrılan {1} · şu an {2} · en yüksek {3}"; SmPfCommit = "Taahhüt edilen bellek: {0} / {1}"
    SmPfOk = "Ayarlar sağlıklı görünüyor."; SmPfNone = "Sayfa dosyası yok: bellek dolunca uygulamalar ve oyunlar çökebilir. Otomatik yönetime alın."
    SmPfHdd = "Sayfa dosyası HDD üzerinde ({0}). SSD'ye taşımak takılmaları azaltır: Sistem → Gelişmiş sistem ayarları → Performans → Sanal bellek."
    SmPfSmall = "Sayfa dosyası küçük: en yüksek kullanım ayrılan alanın %{0}'ine ulaşmış. Otomatik yönetime almanız önerilir."
    BtnSmPfAuto = "Otomatik yönetime al"; SmPfAutoTitle = "Sayfa dosyası Windows'a bırakılsın mı?"
    SmPfAutoMsg = "Sayfa dosyası boyutu Windows tarafından otomatik yönetilecek (önerilen ayar). Değişiklik yeniden başlatmadan sonra etkin olur."; SmPfDone = "Sayfa dosyası otomatik yönetime alındı — yeniden başlatın"
    SmBrT = "Tarayıcı bellek tasarrufu"; SmBrD = "Chrome, Edge ve Brave'de kullanılmayan sekmeler uyutulur. Tarayıcılar genelde en çok belleği kullanan uygulamalardır."
    SmBrOn = "Açık — etkin"; BtnSmBr = "Aç"
} @{
    NavSmartMem = "Smart Memory"; Title_SmartMem = "Smart Memory"; Sub_SmartMem = "Manage memory smartly instead of wiping it — methods with lasting effect"
    SmIntro = "Windows uses free memory as cache; that's good. The real gain is finding what consumes memory and restricting background apps in favour of the foreground app."
    SmStbT = "Smart standby cleaner"; SmStbD = "Purges the cache only when free memory drops below a threshold (ISLC method). Can reduce sudden stutters in games; doesn't clean constantly."
    SmStbOn = "Enable"; SmStbThr = "When free memory drops below:"; SmStbGame = "Only while Game Mode is on"
    SmStbStat = "Cleaned {0} times this session · last: {1} · free now: {2}"; SmStbNever = "not yet"
    SmLimT = "Restrict background apps"; SmLimD = "Selected apps get low memory priority and efficiency mode while in the background; Windows reclaims their memory first under pressure. Restrictions lift instantly when the app comes to the foreground."
    SmLimOn = "Enable"; SmLimNone = "None of the listed apps are running right now."; SmLimActive = "{0} processes restricted"; SmLimFg = "foreground"
    SmLeakT = "Memory leak detector"; SmLeakD = "Each app's memory usage is recorded every minute. Apps that keep growing are flagged; restarting them reclaims memory."
    SmLeakWait = "Collecting data… (needs at least 20 minutes · {0} min)"; SmLeakNone = "No suspicious growth. {0} minutes of data analysed."
    SmLeakRow = "{0} → {1}  (+{2} / {3} min)"; SmLeakFlag = "POSSIBLE LEAK"; SmLeakGrow = "GROWING"
    BtnSmRestart = "Restart"; SmRestarted = "{0} restarted"; SmLeakTip = "{0} keeps growing its memory: {1} → {2}"
    SmPfT = "Virtual memory (page file) advisor"; SmPfAuto = "Managed automatically by Windows (recommended)"; SmPfManual = "Set manually"
    SmPfFile = "{0} · allocated {1} · current {2} · peak {3}"; SmPfCommit = "Committed memory: {0} / {1}"
    SmPfOk = "Settings look healthy."; SmPfNone = "No page file: apps and games may crash when memory fills up. Switch to automatic management."
    SmPfHdd = "Page file is on an HDD ({0}). Moving it to an SSD reduces stutter: System → Advanced system settings → Performance → Virtual memory."
    SmPfSmall = "Page file is small: peak usage reached {0}% of the allocated size. Automatic management is recommended."
    BtnSmPfAuto = "Make automatic"; SmPfAutoTitle = "Let Windows manage the page file?"
    SmPfAutoMsg = "The page file size will be managed automatically by Windows (recommended). Takes effect after a restart."; SmPfDone = "Page file set to automatic — restart"
    SmBrT = "Browser memory saver"; SmBrD = "Inactive tabs are put to sleep in Chrome, Edge and Brave. Browsers are usually the biggest memory users."
    SmBrOn = "On — active"; BtnSmBr = "Enable"
}

Register-WoPage @{
    Name = "SmartMem"; Icon = 0xE964
    Loc = @("SmIntro", "SmStbT", "SmStbD", "SmStbOn", "SmStbThr", "SmStbGame", "SmLimT", "SmLimD", "SmLimOn", "SmLeakT", "SmLeakD", "SmPfT", "SmBrT", "SmBrD")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageSmartMem">
  <StackPanel Margin="0,0,14,20">
    <Border Background="#171726" CornerRadius="10" Padding="14,10" Margin="0,0,0,14">
      <TextBlock x:Name="SmIntro" Style="{DynamicResource Desc}" FontSize="12"/>
    </Border>
    <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="SmStbT" Style="{DynamicResource CardTitle}"/>
          <TextBlock x:Name="SmStbD" Style="{DynamicResource Desc}" Margin="0,4,0,14"/>
          <CheckBox x:Name="SmStbOn" Style="{DynamicResource Switch}" HorizontalAlignment="Left"/>
          <TextBlock x:Name="SmStbThr" Style="{DynamicResource Caption}" Margin="0,14,0,8"/>
          <WrapPanel x:Name="SmStbThrs"/>
          <CheckBox x:Name="SmStbGame" Style="{DynamicResource Check}" Foreground="{DynamicResource Txt}" Margin="0,12,0,0"/>
          <TextBlock x:Name="SmStbStat" Style="{DynamicResource Desc}" FontSize="11.5" Margin="0,4,0,0"/>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="SmBrT" Style="{DynamicResource CardTitle}"/>
          <TextBlock x:Name="SmBrD" Style="{DynamicResource Desc}" Margin="0,4,0,14"/>
          <Button x:Name="BtnSmBr" Style="{DynamicResource PrimaryBtn}" Height="36" HorizontalAlignment="Left" MinWidth="140"/>
          <TextBlock x:Name="SmPfT" Style="{DynamicResource CardTitle}" Margin="0,22,0,0"/>
          <StackPanel x:Name="SmPf" Margin="0,8,0,0"/>
        </StackPanel>
      </Border>
    </Grid>
    <Border Style="{DynamicResource Card}" Margin="0,16,0,0">
      <StackPanel>
        <Grid>
          <StackPanel Margin="0,0,80,0"><TextBlock x:Name="SmLimT" Style="{DynamicResource CardTitle}"/><TextBlock x:Name="SmLimD" Style="{DynamicResource Desc}" Margin="0,4,0,0"/></StackPanel>
          <CheckBox x:Name="SmLimOn" Style="{DynamicResource Switch}" HorizontalAlignment="Right" VerticalAlignment="Top"/>
        </Grid>
        <TextBlock x:Name="SmLimStat" FontSize="11.5" Foreground="#34D399" Margin="0,10,0,6"/>
        <WrapPanel x:Name="SmLimList"/>
      </StackPanel>
    </Border>
    <Border Style="{DynamicResource Card}" Margin="0,16,0,0">
      <StackPanel>
        <TextBlock x:Name="SmLeakT" Style="{DynamicResource CardTitle}"/>
        <TextBlock x:Name="SmLeakD" Style="{DynamicResource Desc}" Margin="0,4,0,12"/>
        <StackPanel x:Name="SmLeakList"/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { Update-SmAll; Load-SmPagefile }
    OnLang = { Update-SmAll; if ($script:SmPf) { Build-SmPagefile } }
}

# ---------------- ayarlar ----------------
$sm = $Settings["smartmem"]
$script:Sm = @{
    StbOn = [bool]$sm.StbOn; StbMb = $(if ($sm.StbMb) { [int]$sm.StbMb } else { 1024 }); StbGame = [bool]$sm.StbGame
    LimOn = [bool]$sm.LimOn; LimApps = $(if ($sm.LimApps) { @($sm.LimApps) } else { @("OneDrive", "Teams", "ms-teams", "Spotify", "Steam", "steamwebhelper", "EpicGamesLauncher", "EADesktop", "Dropbox", "GoogleDriveFS", "Creative Cloud", "PhoneExperienceHost", "Widgets", "mscopilot", "WhatsApp", "Telegram", "Discord") })
}
function Save-SmSettings { $Settings["smartmem"] = $script:Sm; Save-WoSettings }

# =============== 1) Akilli standby temizleyici ===============
$script:StbCount = 0; $script:StbLast = $null; $script:StbBusy = $false
function Build-SmThresholds {
    $wp = N "SmStbThrs"; $wp.Children.Clear()
    foreach ($mb in @(512, 1024, 2048, 4096)) {
        $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $window.FindResource("SegBtn"); $rb.GroupName = "smthr"; $rb.Tag = $mb
        $rb.Content = $(if ($mb -ge 1024) { "$($mb / 1024) GB" } else { "$mb MB" }); $rb.IsChecked = ($script:Sm.StbMb -eq $mb)
        $rb.Add_Checked({ param($s) $script:Sm.StbMb = [int]$s.Tag; Save-SmSettings })
        [void]$wp.Children.Add($rb)
    }
}
(N "SmStbOn").IsChecked = $script:Sm.StbOn
(N "SmStbGame").IsChecked = $script:Sm.StbGame
(N "SmStbOn").Add_Click({ $script:Sm.StbOn = [bool](N "SmStbOn").IsChecked; Save-SmSettings })
(N "SmStbGame").Add_Click({ $script:Sm.StbGame = [bool](N "SmStbGame").IsChecked; Save-SmSettings })

# =============== 2) Arka plan kisitlayici ===============
$script:LimApplied = @{}   # pid -> ad
function Build-SmLimList {
    $wp = N "SmLimList"; $wp.Children.Clear()
    $known = @("OneDrive", "Teams", "ms-teams", "Spotify", "Steam", "steamwebhelper", "EpicGamesLauncher", "EADesktop", "Dropbox", "GoogleDriveFS", "Creative Cloud",
               "PhoneExperienceHost", "Widgets", "mscopilot", "WhatsApp", "Telegram", "Discord", "chrome", "msedge", "brave", "firefox", "opera", "Code", "slack", "Zoom")
    $running = @{}; foreach ($p in [Diagnostics.Process]::GetProcesses()) { $running[$p.ProcessName] = $true }
    $names = @(($known + $script:Sm.LimApps) | Select-Object -Unique | Where-Object { $running[$_] } | Sort-Object)
    if ($names.Count -eq 0) { [void]$wp.Children.Add((New-Tb (T "SmLimNone") 12 "#7A7A94")); return }
    foreach ($n in $names) {
        $cb = New-Object Windows.Controls.CheckBox; $cb.Style = $window.FindResource("Check"); $cb.Margin = New-Object Windows.Thickness(0, 0, 18, 8)
        $cb.Content = $n; $cb.Foreground = Brush "#EDEDF5"; $cb.Tag = $n; $cb.IsChecked = ($script:Sm.LimApps -contains $n); $cb.Focusable = $false
        $cb.Add_Click({
            param($s)
            $l = [Collections.ArrayList]@($script:Sm.LimApps)
            if ($s.IsChecked) { if ($l -notcontains $s.Tag) { [void]$l.Add($s.Tag) } } else { $l.Remove($s.Tag); Release-SmLimits $s.Tag }
            $script:Sm.LimApps = @($l); Save-SmSettings
        })
        [void]$wp.Children.Add($cb)
    }
}
function Release-SmLimits([string]$Only) {
    foreach ($pid0 in @($script:LimApplied.Keys)) {
        if ($Only -and $script:LimApplied[$pid0] -ne $Only) { continue }
        [void][WoProc]::SetMemoryPriority([int]$pid0, 5); [void][WoProc]::SetEcoQoS([int]$pid0, $false)
        $script:LimApplied.Remove($pid0)
    }
}
(N "SmLimOn").IsChecked = $script:Sm.LimOn
(N "SmLimOn").Add_Click({ $script:Sm.LimOn = [bool](N "SmLimOn").IsChecked; Save-SmSettings; if (-not $script:Sm.LimOn) { Release-SmLimits } })
$window.Add_Closed({ try { Release-SmLimits } catch {} })

function Invoke-SmLimiter {
    if (-not $script:Sm.LimOn) { return }
    $fg = [WoProc]::ForegroundPid()
    $fgName = try { [Diagnostics.Process]::GetProcessById($fg).ProcessName } catch { "" }
    $seen = @{}
    foreach ($n in $script:Sm.LimApps) {
        foreach ($p in @(Get-Process -Name $n -ErrorAction SilentlyContinue)) {
            $id = [int]$p.Id; $seen[$id] = $true
            # Ayni uygulamanin herhangi bir penceresi ondeyse (or. tarayici) tum surecleri serbest
            if ($p.ProcessName -eq $fgName) {
                if ($script:LimApplied.ContainsKey($id)) { [void][WoProc]::SetMemoryPriority($id, 5); [void][WoProc]::SetEcoQoS($id, $false); $script:LimApplied.Remove($id) }
            } elseif (-not $script:LimApplied.ContainsKey($id)) {
                $ok = [WoProc]::SetMemoryPriority($id, 2)
                [void][WoProc]::SetEcoQoS($id, $true)
                if ($ok) { $script:LimApplied[$id] = $p.ProcessName }
            }
        }
    }
    foreach ($id in @($script:LimApplied.Keys)) { if (-not $seen[[int]$id]) { $script:LimApplied.Remove($id) } }
}

# =============== 3) Sizinti dedektoru ===============
$script:LeakHist = @{}        # ad -> ArrayList of @(dakika, bayt)
$script:LeakStart = Get-Date; $script:LeakNotified = @{}; $script:LeakBusy = $false
function Sample-SmLeaks {
    if ($script:LeakBusy) { return }
    $script:LeakBusy = $true
    Start-Bg -Work {
        $h = @{}
        foreach ($p in [Diagnostics.Process]::GetProcesses()) {
            try { if ($p.SessionId -eq 0) { continue }; $h[$p.ProcessName] = [double]$h[$p.ProcessName] + [double]$p.PrivateMemorySize64 } catch {}
        }
        $h
    } -Done {
        param($out, $err)
        $script:LeakBusy = $false
        $h = @($out) | Select-Object -Last 1
        if (-not ($h -is [hashtable])) { return }
        $minute = [int]((Get-Date) - $script:LeakStart).TotalMinutes
        $top = @($h.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | ForEach-Object Key)
        foreach ($n in (@($top) + @($script:LeakHist.Keys) | Select-Object -Unique)) {
            if (-not $script:LeakHist[$n]) { $script:LeakHist[$n] = New-Object System.Collections.ArrayList }
            [void]$script:LeakHist[$n].Add(@($minute, [double]$h[$n]))
            while ($script:LeakHist[$n].Count -gt 360) { $script:LeakHist[$n].RemoveAt(0) }
        }
        foreach ($l in (Get-SmLeaks | Where-Object Flag)) {
            if (-not $script:LeakNotified[$l.Name]) {
                $script:LeakNotified[$l.Name] = $true
                Show-WoTrayTip "Windows Optimizer" ((T "SmLeakTip") -f $l.Name, (Fmt-GB $l.First), (Fmt-GB $l.Last))
            }
        }
        if ($script:Page -eq "SmartMem") { Build-SmLeaks }
    }
}
# Dogrusal egim + tutarlilik (R^2): kisa sicramalari degil, surekli buyumeyi yakalar
function Get-SmLeaks {
    foreach ($n in $script:LeakHist.Keys) {
        $pts = @($script:LeakHist[$n] | Where-Object { $_[1] -gt 0 })
        if ($pts.Count -lt 20) { continue }
        $xs = $pts | ForEach-Object { [double]$_[0] }; $ys = $pts | ForEach-Object { [double]$_[1] }
        $mx = ($xs | Measure-Object -Average).Average; $my = ($ys | Measure-Object -Average).Average
        $sxy = 0.0; $sxx = 0.0; $syy = 0.0
        for ($i = 0; $i -lt $pts.Count; $i++) { $dx = $xs[$i] - $mx; $dy = $ys[$i] - $my; $sxy += $dx * $dy; $sxx += $dx * $dx; $syy += $dy * $dy }
        if ($sxx -eq 0 -or $syy -eq 0) { continue }
        $slope = $sxy / $sxx; $r2 = ($sxy * $sxy) / ($sxx * $syy)
        $first = $ys[0]; $last = $ys[-1]; $growth = $last - $first; $mins = $xs[-1] - $xs[0]
        if ($growth -lt 150MB -or $slope -le 0) { continue }
        [pscustomobject]@{ Name = $n; First = $first; Last = $last; Growth = $growth; Minutes = $mins; R2 = $r2
                           Flag = ($r2 -ge 0.7 -and $growth -ge 400MB -and $last -ge 1.5 * $first); Series = $ys }
    }
}
function Build-SmLeaks {
    $list = N "SmLeakList"; $list.Children.Clear()
    $mins = [int]((Get-Date) - $script:LeakStart).TotalMinutes
    if ($mins -lt 20) { [void]$list.Children.Add((New-Tb ((T "SmLeakWait") -f $mins) 12 "#7A7A94")); return }
    $leaks = @(Get-SmLeaks | Sort-Object Growth -Descending | Select-Object -First 8)
    if ($leaks.Count -eq 0) { [void]$list.Children.Add((New-Tb ((T "SmLeakNone") -f $mins) 12 "#34D399")); return }
    foreach ($l in $leaks) {
        $g = New-Object Windows.Controls.Grid; $g.Margin = New-Object Windows.Thickness(0, 0, 0, 12); New-Cols $g @("*", 160, "Auto")
        $sp = New-Object Windows.Controls.StackPanel
        $tr = New-Object Windows.Controls.WrapPanel
        $nm = New-Tb $l.Name 13 "#EDEDF5"; $nm.FontWeight = [Windows.FontWeights]::SemiBold; [void]$tr.Children.Add($nm)
        [void]$tr.Children.Add($(if ($l.Flag) { New-Badge (T "SmLeakFlag") "#3A1520" "#FCA5A5" } else { New-Badge (T "SmLeakGrow") "#3A2E10" "#FCD34D" }))
        [void]$sp.Children.Add($tr)
        [void]$sp.Children.Add((New-Tb ((T "SmLeakRow") -f (Fmt-GB $l.First), (Fmt-GB $l.Last), (Fmt-GB $l.Growth), [int]$l.Minutes) 11.5 "#9C9CB8"))
        $cv = New-Object Windows.Controls.Canvas; $cv.Height = 34; $cv.Width = 150; $cv.ClipToBounds = $true; $cv.Margin = New-Object Windows.Thickness(8, 0, 8, 0)
        $b = New-Object Windows.Controls.Button; $b.Style = $window.FindResource("SecondaryBtn"); $b.Height = 32; $b.Content = T "BtnSmRestart"; $b.Tag = $l.Name; $b.VerticalAlignment = "Center"
        $b.Add_Click({
            param($s)
            $ps = @(Get-Process -Name $s.Tag -ErrorAction SilentlyContinue); $path = ($ps | Where-Object Path | Select-Object -First 1).Path
            $ps | Stop-Process -Force -ErrorAction SilentlyContinue
            if ($path) { Start-Sleep -Milliseconds 800; Start-Process explorer.exe "`"$path`"" }
            $script:LeakHist.Remove($s.Tag); $script:LeakNotified.Remove($s.Tag)
            Set-Status ((T "SmRestarted") -f $s.Tag) "ok"; Build-SmLeaks
        })
        [Windows.Controls.Grid]::SetColumn($cv, 1); [Windows.Controls.Grid]::SetColumn($b, 2)
        [void]$g.Children.Add($sp); [void]$g.Children.Add($cv); [void]$g.Children.Add($b); [void]$list.Children.Add($g)
        $series = New-Object System.Collections.ArrayList; foreach ($v in ($l.Series | Select-Object -Last 60)) { [void]$series.Add($v) }
        $cv.Width = 150; $cv.Measure((New-Object Windows.Size(150, 34))); $cv.Arrange((New-Object Windows.Rect(0, 0, 150, 34)))
        Draw-Spark $cv $series (($series | Measure-Object -Maximum).Maximum * 1.05) $(if ($l.Flag) { "#F87171" } else { "#FBBF24" })
    }
}

# =============== 4) Sayfa dosyasi danismani ===============
$script:SmPf = $null
function Load-SmPagefile {
    Start-Bg -Work {
        $cs = Get-CimInstance Win32_ComputerSystem
        $use = @(Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue)
        $files = foreach ($u in $use) {
            $letter = "$($u.Name)".Substring(0, 1); $media = ""
            try { $dn = (Get-Partition -DriveLetter $letter -ErrorAction Stop | Get-Disk).Number; $media = "$((Get-PhysicalDisk | Where-Object { "$($_.DeviceId)" -eq "$dn" }).MediaType)" } catch {}
            [pscustomobject]@{ Name = $u.Name; Alloc = [double]$u.AllocatedBaseSize * 1MB; Cur = [double]$u.CurrentUsage * 1MB; Peak = [double]$u.PeakUsage * 1MB; Media = $media; Letter = $letter }
        }
        $ssd = [bool](Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object MediaType -eq "SSD")
        [pscustomobject]@{ Auto = [bool]$cs.AutomaticManagedPagefile; Files = @($files); HasSsd = $ssd }
    } -Done {
        param($out, $err)
        $script:SmPf = @($out) | Select-Object -Last 1
        Build-SmPagefile
    }
}
function Build-SmPagefile {
    $p = N "SmPf"; $p.Children.Clear(); $pf = $script:SmPf; if (-not $pf) { return }
    [void]$p.Children.Add((New-Tb $(if ($pf.Auto) { T "SmPfAuto" } else { T "SmPfManual" }) 12.5 $(if ($pf.Auto) { "#34D399" } else { "#FBBF24" })))
    foreach ($f in $pf.Files) { $t = New-Tb ((T "SmPfFile") -f $f.Name, (Fmt-GB $f.Alloc), (Fmt-GB $f.Cur), (Fmt-GB $f.Peak)) 11.5 "#9C9CB8"; $t.Margin = New-Object Windows.Thickness(0, 4, 0, 0); [void]$p.Children.Add($t) }
    if ($script:LastMem) { $c = New-Tb ((T "SmPfCommit") -f (Fmt-GB $script:LastMem.CommitUsed), (Fmt-GB $script:LastMem.CommitLimit)) 11.5 "#9C9CB8"; $c.Margin = New-Object Windows.Thickness(0, 4, 0, 0); [void]$p.Children.Add($c) }
    $adv = @()
    if ($pf.Files.Count -eq 0) { $adv += T "SmPfNone" }
    foreach ($f in $pf.Files) {
        if ($f.Media -eq "HDD" -and $pf.HasSsd) { $adv += (T "SmPfHdd") -f $f.Name }
        if (-not $pf.Auto -and $f.Alloc -gt 0 -and $f.Peak / $f.Alloc -ge 0.8) { $adv += (T "SmPfSmall") -f [int](100 * $f.Peak / $f.Alloc) }
    }
    $a = New-Tb $(if ($adv.Count) { $adv -join "`n" } else { T "SmPfOk" }) 11.5 $(if ($adv.Count) { "#FCD34D" } else { "#6EE7B7" }); $a.Margin = New-Object Windows.Thickness(0, 8, 0, 0)
    [void]$p.Children.Add($a)
    if (-not $pf.Auto) {
        $b = New-Object Windows.Controls.Button; $b.Style = $window.FindResource("SecondaryBtn"); $b.Height = 32; $b.Content = T "BtnSmPfAuto"; $b.HorizontalAlignment = "Left"; $b.Margin = New-Object Windows.Thickness(0, 10, 0, 0)
        $b.Add_Click({
            if (-not (Show-WoDialog -Title (T "SmPfAutoTitle") -Message (T "SmPfAutoMsg") -Kind "info" -Ok (T "BtnSmPfAuto") -Cancel (T "DlgCancel"))) { return }
            try {
                Get-CimInstance Win32_ComputerSystem | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true } -ErrorAction Stop
                Set-Status (T "SmPfDone") "ok"; Set-RestartNeed "reboot"; Load-SmPagefile
            } catch { Set-Status "$($_.Exception.Message)" "err" }
        })
        [void]$p.Children.Add($b)
    }
}

# =============== 5) Tarayici bellek tasarrufu ===============
function Update-SmBrowser {
    $on = [bool]$script:TweakState["BrowserMemSaver"]
    $b = N "BtnSmBr"; $b.Content = if ($on) { "✓ " + (T "SmBrOn") } else { T "BtnSmBr" }; $b.IsEnabled = -not $on -and -not $script:Applying
}
(N "BtnSmBr").Add_Click({
    $t = Get-WoTweak "BrowserMemSaver"
    if ($t -and $script:TweakRows[$t.Id]) { Set-WantApplied $t $true; Invoke-TweakChanges }
})

function Update-SmAll {
    Build-SmThresholds; Build-SmLimList; Build-SmLeaks; Update-SmBrowser; Update-SmStat
}
function Update-SmStat {
    $m = $script:LastMem
    $free = if ($m -and $m.ListOk) { Fmt-GB $m.Free } else { "—" }
    (N "SmStbStat").Text = (T "SmStbStat") -f $script:StbCount, $(if ($script:StbLast) { $script:StbLast.ToString("HH:mm:ss") } else { T "SmStbNever" }), $free
    (N "SmLimStat").Text = if ($script:Sm.LimOn) { (T "SmLimActive") -f $script:LimApplied.Count } else { "" }
}

# =============== motor: 3 sn'de bir (standby + kisitlayici), dakikada bir (sizinti) ===============
$script:SmTick = 0
$smTimer = New-Object Windows.Threading.DispatcherTimer
$smTimer.Interval = [TimeSpan]::FromSeconds(3)
$smTimer.Add_Tick({
    try {
        $script:SmTick++
        $m = $script:LastMem
        # Akilli standby: bos bellek esigin altinda + standby kayda deger + (istenirse) Oyun Modu acik; 30 sn bekleme
        if ($script:Sm.StbOn -and $m -and $m.ListOk -and -not $script:StbBusy -and $m.Free -lt ($script:Sm.StbMb * 1MB) -and $m.Standby -gt 512MB -and
            (-not $script:Sm.StbGame -or $script:GameState) -and (-not $script:StbLast -or ((Get-Date) - $script:StbLast).TotalSeconds -ge 30)) {
            $script:StbBusy = $true
            Start-Bg -Work { [void][WoNative]::EnablePrivilege("SeProfileSingleProcessPrivilege"); [WoNative]::MemCommand(4) } -Done {
                param($out, $err)
                $script:StbBusy = $false; $script:StbCount++; $script:StbLast = Get-Date
                Write-WoLog "Akilli standby temizligi (#$($script:StbCount))"
            }
        }
        Invoke-SmLimiter
        if ($script:SmTick % 20 -eq 1) { Sample-SmLeaks }
        if ($script:Page -eq "SmartMem") { Update-SmStat; Update-SmBrowser }
    } catch { Write-WoLog "Akilli bellek: $_" }
})
$smTimer.Start()
