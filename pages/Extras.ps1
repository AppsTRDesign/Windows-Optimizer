# pages/Extras.ps1 - Ayarlar sayfasina eklenen kartlar:
#   Profil disa/ice aktarma · Sistem tepsisi ve Windows ile baslatma · Zamanlanmis haftalik bakim

Add-WoStrings @{
    PrfT = "Profil (dışa / içe aktar)"; PrfD = "Tüm ayarlarınızı bir dosyaya kaydedin ve başka bir bilgisayara tek tıkla uygulayın."
    BtnPrfExport = "Dışa aktar"; BtnPrfImport = "İçe aktar"; PrfExporting = "Profil hazırlanıyor…"; PrfSaved = "Profil kaydedildi: {0}"
    PrfBad = "Bu dosya geçerli bir Windows Optimizer profili değil"; PrfTitle = "Profil uygulansın mı?"
    PrfMsg = "'{0}' profili ({1}, {2}) uygulanacak:`n`n•  {3} optimizasyon ayarı`n•  {4} başlangıç öğesi`n•  {5} servis`n•  DNS: {6}`n`nYalnızca farklı olan ayarlar değiştirilir; hepsi 'Sıfırla' ile geri alınabilir."
    PrfOk = "Uygula"; PrfDone = "Profil uygulandı: {0} değişiklik"; PrfWarn = "Profil uygulandı: {0} değişiklik, {1} başarısız (günlüğe bakın)"
    TrayT = "Sistem tepsisi"; TrayD = "Pencereyi kapatınca uygulama tepside çalışmaya devam eder; RAM izleme ve otomatik temizlik sürer."
    TrayChkClose = "Kapatınca tepsiye küçült"; TrayChkStart = "Windows açılınca tepside başlat (UAC sormadan)"; TrayChkNotify = "Tepsi bildirimlerini göster"
    TrayHintTitle = "Windows Optimizer arka planda çalışıyor"; TrayHintMsg = "Açmak için tepsi simgesine çift tıklayın. Çıkmak için sağ tıklayıp 'Çıkış'ı seçin."
    TrayOpen = "Aç"; TrayClean = "Belleği temizle"; TrayGameOn = "Oyun Modunu başlat"; TrayGameOff = "Oyun Modunu bitir"; TrayExit = "Çıkış"
    TrayTip = "Windows Optimizer · RAM %{0} · CPU %{1}"; TrayStartOn = "Windows ile başlatma açıldı"; TrayStartOff = "Windows ile başlatma kapatıldı"
    MntT = "Zamanlanmış bakım"; MntD = "Haftada bir, bilgisayar açıkken arka planda: gereksiz dosyalar (önerilen kategoriler), RAM ve DNS önbelleği temizlenir."
    MntChk = "Haftalık otomatik bakımı aç"; MntDay = "Gün"; MntHour = "Saat"; MntLast = "Son bakım: {0} · {1} disk alanı ve {2} bellek boşaltıldı"; MntNever = "Henüz bakım yapılmadı"
    MntOn = "Haftalık bakım planlandı: {0} {1}"; MntOff = "Zamanlanmış bakım kapatıldı"; BtnMntRun = "Şimdi çalıştır"; MntRunning = "Bakım arka planda çalışıyor…"
    Day_Mon = "Pzt"; Day_Tue = "Sal"; Day_Wed = "Çar"; Day_Thu = "Per"; Day_Fri = "Cum"; Day_Sat = "Cmt"; Day_Sun = "Paz"
} @{
    PrfT = "Profile (export / import)"; PrfD = "Save all your settings to a file and apply them to another PC in one click."
    BtnPrfExport = "Export"; BtnPrfImport = "Import"; PrfExporting = "Preparing profile…"; PrfSaved = "Profile saved: {0}"
    PrfBad = "This file is not a valid Windows Optimizer profile"; PrfTitle = "Apply profile?"
    PrfMsg = "Profile '{0}' ({1}, {2}) will be applied:`n`n•  {3} optimization settings`n•  {4} startup items`n•  {5} services`n•  DNS: {6}`n`nOnly settings that differ are changed; everything can be undone with 'Reset'."
    PrfOk = "Apply"; PrfDone = "Profile applied: {0} changes"; PrfWarn = "Profile applied: {0} changes, {1} failed (see log)"
    TrayT = "System tray"; TrayD = "When you close the window the app keeps running in the tray; RAM monitoring and auto-clean continue."
    TrayChkClose = "Minimize to tray on close"; TrayChkStart = "Start in tray with Windows (no UAC prompt)"; TrayChkNotify = "Show tray notifications"
    TrayHintTitle = "Windows Optimizer is running in the background"; TrayHintMsg = "Double-click the tray icon to open it. Right-click and choose 'Exit' to quit."
    TrayOpen = "Open"; TrayClean = "Clean memory"; TrayGameOn = "Start Game Mode"; TrayGameOff = "Stop Game Mode"; TrayExit = "Exit"
    TrayTip = "Windows Optimizer · RAM {0}% · CPU {1}%"; TrayStartOn = "Start with Windows enabled"; TrayStartOff = "Start with Windows disabled"
    MntT = "Scheduled maintenance"; MntD = "Once a week, in the background while the PC is on: junk files (recommended categories), RAM and DNS cache are cleaned."
    MntChk = "Enable weekly automatic maintenance"; MntDay = "Day"; MntHour = "Time"; MntLast = "Last run: {0} · {1} disk space and {2} memory freed"; MntNever = "Never run yet"
    MntOn = "Weekly maintenance scheduled: {0} {1}"; MntOff = "Scheduled maintenance disabled"; BtnMntRun = "Run now"; MntRunning = "Maintenance is running in the background…"
    Day_Mon = "Mon"; Day_Tue = "Tue"; Day_Wed = "Wed"; Day_Thu = "Thu"; Day_Fri = "Fri"; Day_Sat = "Sat"; Day_Sun = "Sun"
}

$ExtrasXaml = @'
<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="ExtrasPanel">
  <Border Style="{DynamicResource Card}" Margin="0,0,0,12">
    <Grid>
      <StackPanel Margin="0,0,250,0"><TextBlock x:Name="PrfT" Style="{DynamicResource CardTitle}"/><TextBlock x:Name="PrfD" Style="{DynamicResource Desc}" Margin="0,4,0,0"/></StackPanel>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
        <Button x:Name="BtnPrfImport" Style="{DynamicResource SecondaryBtn}" Margin="0,0,8,0"/>
        <Button x:Name="BtnPrfExport" Style="{DynamicResource SecondaryBtn}"/>
      </StackPanel>
    </Grid>
  </Border>
  <Border Style="{DynamicResource Card}" Margin="0,0,0,12">
    <StackPanel>
      <TextBlock x:Name="TrayT" Style="{DynamicResource CardTitle}"/><TextBlock x:Name="TrayD" Style="{DynamicResource Desc}" Margin="0,4,0,14"/>
      <CheckBox x:Name="TrayChkClose" Style="{DynamicResource Check}" Foreground="{DynamicResource Txt}"/>
      <CheckBox x:Name="TrayChkStart" Style="{DynamicResource Check}" Foreground="{DynamicResource Txt}"/>
      <CheckBox x:Name="TrayChkNotify" Style="{DynamicResource Check}" Foreground="{DynamicResource Txt}" Margin="0"/>
    </StackPanel>
  </Border>
  <Border Style="{DynamicResource Card}" Margin="0,0,0,12">
    <StackPanel>
      <Grid>
        <StackPanel Margin="0,0,160,0"><TextBlock x:Name="MntT" Style="{DynamicResource CardTitle}"/><TextBlock x:Name="MntD" Style="{DynamicResource Desc}" Margin="0,4,0,0"/></StackPanel>
        <Button x:Name="BtnMntRun" Style="{DynamicResource SecondaryBtn}" HorizontalAlignment="Right" VerticalAlignment="Top"/>
      </Grid>
      <CheckBox x:Name="MntChk" Style="{DynamicResource Check}" Foreground="{DynamicResource Txt}" Margin="0,14,0,10"/>
      <StackPanel x:Name="MntSched" Orientation="Horizontal">
        <TextBlock x:Name="MntDay" Style="{DynamicResource Caption}" VerticalAlignment="Center" Margin="0,0,10,0" MinWidth="34"/>
        <WrapPanel x:Name="MntDays"/>
        <TextBlock x:Name="MntHour" Style="{DynamicResource Caption}" VerticalAlignment="Center" Margin="16,0,10,0"/>
        <WrapPanel x:Name="MntHours"/>
      </StackPanel>
      <TextBlock x:Name="MntLastText" Style="{DynamicResource Desc}" FontSize="11.5" Margin="0,12,0,0"/>
    </StackPanel>
  </Border>
</StackPanel>
'@
$extras = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$ExtrasXaml)))
[void]$script:Frags.Add($extras)
$setStack = (N "PageSettings").Content
$setStack.Children.Insert(1, $extras)   # Dil kartindan hemen sonra

$script:PageDefs["Extras"] = @{
    Name = "Extras"
    Loc = @("PrfT", "PrfD", "BtnPrfExport", "BtnPrfImport", "TrayT", "TrayD", "TrayChkClose", "TrayChkStart", "TrayChkNotify", "MntT", "MntD", "MntChk", "MntDay", "MntHour", "BtnMntRun")
    OnLang = { if ($script:ExtrasLazyDone) { Build-MntChoices }; Update-MntText; Update-TrayMenu }
}

# =============== 4) PROFIL ===============
function Export-WoProfile {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "Windows Optimizer (*.woprofile)|*.woprofile|JSON (*.json)|*.json"
    $dlg.FileName = "$env:COMPUTERNAME-$(Get-Date -Format yyyyMMdd).woprofile"
    if (-not $dlg.ShowDialog($window)) { return }
    $file = $dlg.FileName
    Set-Status (T "PrfExporting") "busy"
    $tw = [ordered]@{}; foreach ($t in $TweakCatalog) { $tw[$t.Id] = [bool]$script:TweakState[$t.Id] }
    Start-Bg -Work {
        param($Mods, $Tw, $File, $Ver, $Ram, $Auto)
        foreach ($m in $Mods) { . $m }
        $startup = @(Get-WoStartupItems | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Name = $_.Name; Enabled = [bool]$_.Enabled } })
        $svc = @()
        $bk = Get-WoServiceBackup
        foreach ($p in $bk.PSObject.Properties) {
            $s = Get-CimInstance Win32_Service -Filter "Name='$($p.Name)'" -ErrorAction SilentlyContinue
            if ($s) { $svc += [pscustomobject]@{ Name = $s.Name; Mode = @{ Auto = "Automatic"; Manual = "Manual"; Disabled = "Disabled" }["$($s.StartMode)"] } }
        }
        $dns = @(Get-WoNetAdapters | ForEach-Object Provider | Select-Object -Unique)
        $prof = [ordered]@{
            app = "Windows Optimizer"; format = 1; version = $Ver; computer = $env:COMPUTERNAME; created = (Get-Date -Format "yyyy-MM-dd HH:mm")
            tweaks = $Tw; startup = $startup; services = $svc; dns = $(if ($dns.Count -eq 1) { $dns[0] } else { "custom" }); ram = $Ram; autoClean = $Auto
        }
        $prof | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $File -Encoding UTF8
        $File
    } -ArgList @($ModPaths, $tw, $file, $LocalVersion, $Settings.ram, $Settings.autoClean) -Done {
        param($out, $err)
        if ($err) { Set-Status "$err" "err" } else { Set-Status ((T "PrfSaved") -f (Split-Path (@($out)[-1]) -Leaf)) "ok" }
    }
}

function Import-WoProfile {
    if ($script:GlobalBusy) { return }
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "Windows Optimizer (*.woprofile;*.json)|*.woprofile;*.json"
    if (-not $dlg.ShowDialog($window)) { return }
    $prof = $null
    try { $prof = Get-Content -LiteralPath $dlg.FileName -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    if (-not $prof -or $prof.app -ne "Windows Optimizer" -or -not $prof.tweaks) {
        [void](Show-WoDialog -Title "Windows Optimizer" -Message (T "PrfBad") -Kind "error"); return
    }
    $twCount = @($prof.tweaks.PSObject.Properties | Where-Object { $null -ne (Get-WoTweak $_.Name) -and [bool]$_.Value -ne [bool]$script:TweakState[$_.Name] }).Count
    $dnsName = if ($prof.dns -and $WoDnsProviders.Contains("$($prof.dns)")) { if ($prof.dns -eq "auto") { T "Dns_auto" } else { $WoDnsProviders["$($prof.dns)"].Name } } else { "—" }
    $msg = (T "PrfMsg") -f (Split-Path $dlg.FileName -Leaf), $prof.computer, $prof.created, $twCount, @($prof.startup).Count, @($prof.services).Count, $dnsName
    if (-not (Show-WoDialog -Title (T "PrfTitle") -Message $msg -Kind "info" -Ok (T "PrfOk") -Cancel (T "DlgCancel"))) { return }

    if ($prof.ram) { foreach ($k in @($Settings.ram.Keys)) { if ($null -ne $prof.ram.$k) { $Settings.ram[$k] = [bool]$prof.ram.$k } } }
    if ($null -ne $prof.autoClean) { $Settings.autoClean = [int]$prof.autoClean }
    Save-WoSettings
    Set-GlobalBusy $true
    Set-Status (T "Applying") "busy"
    Start-Bg -Work {
        param($Mods, $Prof)
        foreach ($m in $Mods) { . $m }
        foreach ($p in $Prof.tweaks.PSObject.Properties) {
            $t = Get-WoTweak $p.Name
            if (-not $t) { continue }
            $want = [bool]$p.Value
            if ($want -eq [bool](Test-WoTweak $t)) { continue }
            try { Invoke-WoTweak $t -Revert:(-not $want); [pscustomobject]@{ What = $t.Id; Ok = $true; Restart = $t.Restart } }
            catch { [pscustomobject]@{ What = $t.Id; Ok = $false; Err = $_.Exception.Message } }
        }
        $items = @(Get-WoStartupItems)
        foreach ($e in @($Prof.startup)) {
            $it = $items | Where-Object Id -eq $e.Id | Select-Object -First 1
            if (-not $it -or [bool]$it.Enabled -eq [bool]$e.Enabled) { continue }
            try { Set-WoStartupItem $it ([bool]$e.Enabled); [pscustomobject]@{ What = $it.Name; Ok = $true } }
            catch { [pscustomobject]@{ What = $it.Name; Ok = $false; Err = $_.Exception.Message } }
        }
        foreach ($e in @($Prof.services)) {
            $s = Get-CimInstance Win32_Service -Filter "Name='$($e.Name)'" -ErrorAction SilentlyContinue
            if (-not $s -or -not $e.Mode) { continue }
            $cur = @{ Auto = "Automatic"; Manual = "Manual"; Disabled = "Disabled" }["$($s.StartMode)"]
            if ($cur -eq $e.Mode) { continue }
            try { Set-WoServiceStart $e.Name $e.Mode $(if ($s.DelayedAutoStart -and $cur -eq "Automatic") { "AutomaticDelayed" } else { $cur }); [pscustomobject]@{ What = $e.Name; Ok = $true } }
            catch { [pscustomobject]@{ What = $e.Name; Ok = $false; Err = $_.Exception.Message } }
        }
        if ($Prof.dns -and $Prof.dns -ne "custom" -and $WoDnsProviders.Contains("$($Prof.dns)")) {
            $now = @(Get-WoNetAdapters | ForEach-Object Provider | Select-Object -Unique)
            if (-not ($now.Count -eq 1 -and $now[0] -eq $Prof.dns)) {
                try { [void](Set-WoDns "$($Prof.dns)"); [pscustomobject]@{ What = "DNS"; Ok = $true } }
                catch { [pscustomobject]@{ What = "DNS"; Ok = $false; Err = $_.Exception.Message } }
            }
        }
    } -ArgList @($ModPaths, $prof) -Done {
        param($out, $err)
        Set-GlobalBusy $false
        $res = @($out | Where-Object { $_.What })
        $ok = @($res | Where-Object Ok).Count; $fail = @($res | Where-Object { -not $_.Ok })
        foreach ($f in $fail) { Write-WoLog "Profil ($($f.What)): $($f.Err)" }
        if ($err) { Write-WoLog "Profil isi: $err" }
        foreach ($k in $OptMap.Keys) { (N $k).IsChecked = $Settings.ram[$OptMap[$k]] }
        $ab = N ("Auto{0}" -f $Settings.autoClean); if ($ab) { $ab.IsChecked = $true }
        Sync-AllAfterChange @($res | Where-Object Ok | ForEach-Object Restart)
        if ($script:NetLoaded) { Load-Network $false }
        if ($fail.Count -eq 0) { Set-Status ((T "PrfDone") -f $ok) "ok" } else { Set-Status ((T "PrfWarn") -f $ok, $fail.Count) "warn" }
    }
}
(N "BtnPrfExport").Add_Click({ Export-WoProfile })
(N "BtnPrfImport").Add_Click({ Import-WoProfile })

# =============== 5) SISTEM TEPSISI ===============
Add-Type -AssemblyName System.Windows.Forms
Add-WoType "WoMenuColors" @"
using System.Drawing;
using System.Windows.Forms;
public class WoMenuColors : ProfessionalColorTable {
    static Color Bg = Color.FromArgb(21, 21, 31), Hi = Color.FromArgb(42, 35, 80), Line = Color.FromArgb(44, 44, 70);
    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Line; } }
    public override Color MenuItemBorder { get { return Hi; } }
    public override Color MenuItemSelected { get { return Hi; } }
    public override Color SeparatorDark { get { return Line; } }
    public override Color SeparatorLight { get { return Bg; } }
}
"@ @("System.Windows.Forms", "System.Drawing")


function Show-WoTrayTip([string]$Title, [string]$Text) {
    if ($script:TrayIcon -and $Settings["trayNotify"] -ne $false) { $script:TrayIcon.ShowBalloonTip(4000, $Title, $Text, [System.Windows.Forms.ToolTipIcon]::Info) }
}

function Show-WoWindow {
    $window.Show(); $window.WindowState = "Normal"; [void]$window.Activate()
    if (-not $script:TimersStarted) { $script:TimersStarted = $true; On-Tick; $timer.Start(); $fast.Start() }
}

function Update-TrayMenu {
    if (-not $script:TrayIcon) { return }
    $m = $script:TrayMenu
    $m.Items[0].Text = T "TrayOpen"; $m.Items[2].Text = T "TrayClean"
    $m.Items[3].Text = if ($script:GameState) { T "TrayGameOff" } else { T "TrayGameOn" }
    $m.Items[5].Text = T "TrayExit"
}

function New-WoTrayIcon {
    if ($script:TrayIcon) { return }
    $ni = New-Object System.Windows.Forms.NotifyIcon
    try {
        $png = Join-Path $AppDir "assets\logo.png"
        $bmp = New-Object System.Drawing.Bitmap((New-Object System.Drawing.Bitmap($png)), 32, 32)
        $ni.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    } catch { $ni.Icon = [System.Drawing.SystemIcons]::Application }
    $ni.Text = "Windows Optimizer"
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object WoMenuColors))
    $menu.BackColor = [System.Drawing.Color]::FromArgb(21, 21, 31); $menu.ForeColor = [System.Drawing.Color]::FromArgb(237, 237, 245)
    $menu.ShowImageMargin = $false; $menu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $miOpen = $menu.Items.Add("Open"); $miOpen.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    $miClean = $menu.Items.Add("Clean"); $miGame = $menu.Items.Add("Game")
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    $miExit = $menu.Items.Add("Exit")
    foreach ($it in @($miOpen, $miClean, $miGame, $miExit)) { $it.ForeColor = [System.Drawing.Color]::FromArgb(237, 237, 245); $it.Padding = New-Object System.Windows.Forms.Padding(6, 4, 6, 4) }
    $miOpen.Add_Click({ Show-WoWindow })
    $miClean.Add_Click({ Start-RamClean -Auto })
    $miGame.Add_Click({ Toggle-GameMode })
    $miExit.Add_Click({ $script:ReallyExit = $true; $window.Close() })
    $menu.Add_Opening({ Update-TrayMenu })
    $ni.ContextMenuStrip = $menu
    $ni.Add_MouseDoubleClick({ Show-WoWindow })
    $ni.Visible = $true
    $script:TrayIcon = $ni; $script:TrayMenu = $menu
    Update-TrayMenu
}

function Remove-WoTrayIcon {
    if ($script:TrayIcon) { $script:TrayIcon.Visible = $false; $script:TrayIcon.Dispose(); $script:TrayIcon = $null }
}

# Tepsi ipucu metni: RAM ve CPU (5 sn'de bir)
$trayTimer = New-Object Windows.Threading.DispatcherTimer
$trayTimer.Interval = [TimeSpan]::FromSeconds(5)
$trayTimer.Add_Tick({
    if ($script:TrayIcon -and $script:LastMem) {
        $cpu = if ($script:CpuHist.Count) { [int]$script:CpuHist[$script:CpuHist.Count - 1] } else { 0 }
        $t = (T "TrayTip") -f $script:LastMem.Load, $cpu
        $script:TrayIcon.Text = $t.Substring(0, [Math]::Min(63, $t.Length))
    }
})
$trayTimer.Start()

$WoTrayTask = "WindowsOptimizer-Tray"
function Test-WoTrayTask { [bool](Get-ScheduledTask -TaskName $WoTrayTask -ErrorAction SilentlyContinue) }
function Set-WoTrayTask([bool]$On) {
    if ($On) {
        $act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $AppDir 'WindowsOptimizer.ps1')`" -Tray" -WorkingDirectory $AppDir
        $trg = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
        $prn = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
        $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
        Register-ScheduledTask -TaskName $WoTrayTask -Action $act -Trigger $trg -Principal $prn -Settings $set -Force | Out-Null
    } else {
        Unregister-ScheduledTask -TaskName $WoTrayTask -Confirm:$false -ErrorAction SilentlyContinue
    }
}

if ($null -eq $Settings["trayClose"]) { $Settings["trayClose"] = $true }
if ($null -eq $Settings["trayNotify"]) { $Settings["trayNotify"] = $true }
(N "TrayChkClose").IsChecked = [bool]$Settings["trayClose"]
(N "TrayChkNotify").IsChecked = [bool]$Settings["trayNotify"]
# Zamanlanmis gorev sorgusu yavas (~0,5 sn): Ayarlar sayfasi ilk acildiginda yapilir
$script:ExtrasLazyDone = $false
function Initialize-ExtrasLazy {
    if ($script:ExtrasLazyDone) { return }
    $script:ExtrasLazyDone = $true
    (N "TrayChkStart").IsChecked = Test-WoTrayTask
    Build-MntChoices
}
$script:PageDefs["Settings"] = @{ Name = "Settings"; OnShow = { Initialize-ExtrasLazy } }
# Tepsi simgesi pencere cizildikten sonra kurulur (acilisi geciktirmez)
if (($Settings["trayClose"] -or $Tray) -and -not $Snapshot) {
    if ($Tray) { New-WoTrayIcon } else { $window.Add_ContentRendered({ if (-not $script:TrayIcon) { New-WoTrayIcon } }) }
}

(N "TrayChkClose").Add_Click({
    $Settings["trayClose"] = [bool](N "TrayChkClose").IsChecked; Save-WoSettings
    if ($Settings["trayClose"]) { New-WoTrayIcon } elseif (-not $Tray) { Remove-WoTrayIcon }
})
(N "TrayChkNotify").Add_Click({ $Settings["trayNotify"] = [bool](N "TrayChkNotify").IsChecked; Save-WoSettings })
(N "TrayChkStart").Add_Click({
    $on = [bool](N "TrayChkStart").IsChecked
    try {
        Set-WoTrayTask $on
        if ($on -and -not $Settings["trayClose"]) { $Settings["trayClose"] = $true; (N "TrayChkClose").IsChecked = $true; Save-WoSettings; New-WoTrayIcon }
        Set-Status (T $(if ($on) { "TrayStartOn" } else { "TrayStartOff" })) "ok"
    } catch { (N "TrayChkStart").IsChecked = -not $on; Set-Status "$($_.Exception.Message)" "err" }
})

# =============== 9) ZAMANLANMIS BAKIM ===============
$WoMntTask = "WindowsOptimizer-Maintenance"
$MntDayKeys = @("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
$MntDayEnum = @{ Mon = "Monday"; Tue = "Tuesday"; Wed = "Wednesday"; Thu = "Thursday"; Fri = "Friday"; Sat = "Saturday"; Sun = "Sunday" }
$MntHoursList = @("10:00", "13:00", "18:00", "21:00")
$mc = $Settings["maint"]
$script:Mnt = @{ Day = $(if ($mc.Day) { "$($mc.Day)" } else { "Sun" }); Hour = $(if ($mc.Hour) { "$($mc.Hour)" } else { "13:00" }) }

function Test-WoMntTask { [bool](Get-ScheduledTask -TaskName $WoMntTask -ErrorAction SilentlyContinue) }
function Set-WoMntTask([bool]$On) {
    if ($On) {
        $act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $AppDir 'WindowsOptimizer.ps1')`" -Maintenance" -WorkingDirectory $AppDir
        $trg = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $MntDayEnum[$script:Mnt.Day] -At $script:Mnt.Hour
        $prn = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
        # Kacirilan bakim bilgisayar acilinca calisir; pilde de calisir
        $set = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1)
        Register-ScheduledTask -TaskName $WoMntTask -Action $act -Trigger $trg -Principal $prn -Settings $set -Force | Out-Null
    } else {
        Unregister-ScheduledTask -TaskName $WoMntTask -Confirm:$false -ErrorAction SilentlyContinue
    }
    $Settings["maint"] = @{ Day = $script:Mnt.Day; Hour = $script:Mnt.Hour }
    Save-WoSettings
}

function Build-MntChoices {
    $seg = $window.FindResource("SegBtn")
    $on = Test-WoMntTask
    foreach ($pair in @(@("MntDays", $MntDayKeys, "Day"), @("MntHours", $MntHoursList, "Hour"))) {
        $wp = N $pair[0]; $wp.Children.Clear()
        foreach ($v in $pair[1]) {
            $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $seg; $rb.GroupName = "mnt_" + $pair[2]
            $rb.Content = if ($pair[2] -eq "Day") { T "Day_$v" } else { $v }
            $rb.Tag = @{ K = $pair[2]; V = $v }; $rb.IsChecked = ($script:Mnt[$pair[2]] -eq $v); $rb.FontSize = 11.5; $rb.Margin = New-Object Windows.Thickness(0, 0, 4, 0)
            $rb.IsEnabled = $on
            $rb.Add_Click({
                param($s)
                $script:Mnt[$s.Tag.K] = $s.Tag.V
                try { Set-WoMntTask $true; Set-Status ((T "MntOn") -f (T "Day_$($script:Mnt.Day)"), $script:Mnt.Hour) "ok" } catch { Set-Status "$($_.Exception.Message)" "err" }
            })
            [void]$wp.Children.Add($rb)
        }
    }
    (N "MntChk").IsChecked = $on
    (N "MntSched").Opacity = if ($on) { 1 } else { 0.45 }
}

$WoMntLastPath = Join-Path $AppDir "maint-last.json"
function Get-WoMntLast { if (Test-Path $WoMntLastPath) { try { return (Get-Content $WoMntLastPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {} }; return $null }
function Update-MntText {
    $l = Get-WoMntLast
    (N "MntLastText").Text = if ($l -and $l.Date) { (T "MntLast") -f $l.Date, (Fmt-Size ([double]$l.Freed)), (Fmt-GB ([double]$l.Ram)) } else { T "MntNever" }
}

(N "MntChk").Add_Click({
    $on = [bool](N "MntChk").IsChecked
    try {
        Set-WoMntTask $on
        Set-Status $(if ($on) { (T "MntOn") -f (T "Day_$($script:Mnt.Day)"), $script:Mnt.Hour } else { T "MntOff" }) "ok"
    } catch { Set-Status "$($_.Exception.Message)" "err" }
    Build-MntChoices
})
(N "BtnMntRun").Add_Click({
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @("-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", "`"$(Join-Path $AppDir 'WindowsOptimizer.ps1')`"", "-Maintenance")
    Set-Status (T "MntRunning") "busy"
    $script:MntWatchUntil = (Get-Date).AddMinutes(10)
    $script:MntLastSeen = "$((Get-WoMntLast).Date)"
})
# "Simdi calistir" bitince sonucu maint-last.json'dan oku
$mntTimer = New-Object Windows.Threading.DispatcherTimer
$mntTimer.Interval = [TimeSpan]::FromSeconds(3)
$mntTimer.Add_Tick({
    if (-not $script:MntWatchUntil) { return }
    if ((Get-Date) -gt $script:MntWatchUntil) { $script:MntWatchUntil = $null; return }
    try {
        $last = Get-WoMntLast
        if ($last -and "$($last.Date)" -ne $script:MntLastSeen) {
            $script:MntWatchUntil = $null
            Update-MntText
            Set-Status ((T "MntLast") -f $last.Date, (Fmt-Size ([double]$last.Freed)), (Fmt-GB ([double]$last.Ram))) "ok"
            Show-WoTrayTip "Windows Optimizer" ((T "MntLast") -f $last.Date, (Fmt-Size ([double]$last.Freed)), (Fmt-GB ([double]$last.Ram)))
        }
    } catch {}
})
$mntTimer.Start()

Update-MntText
