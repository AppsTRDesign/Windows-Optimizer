# pages/Game.ps1 - Oyun Modu profili
# Baslat: RAM temizligi + gecici Nihai Performans plani + bildirimleri sustur + secili arka plan uygulamalarini kapat
# Bitir : her sey eski haline doner, kapanan uygulamalar (yonetici olmadan) yeniden acilir. Durum settings.json'da saklanir.

Add-WoStrings @{
    NavGame = "Oyun Modu"; Title_Game = "Oyun Modu"; Sub_Game = "Tek tuşla oyun için en yüksek performans — bitince her şey eski haline döner"
    GmOffTitle = "Oyun Modu kapalı"; GmOnTitle = "Oyun Modu açık"; GmOffSub = "Oyuna başlamadan önce açın; sistem kaynakları oyuna ayrılır."
    GmOnSub = "{0} tarihinden beri açık · {1} uygulama kapatıldı · {2} bellek kazanıldı"
    BtnGmStart = "Oyun Modunu Başlat"; BtnGmStop = "Oyun Modunu Bitir"; GmStarting = "Oyun Modu başlatılıyor…"; GmStopping = "Eski ayarlar geri yükleniyor…"
    GmOptsTitle = "Ne yapılsın?"; GmOptRam = "Belleği temizle"; GmOptRamD = "Standby ve working set belleği boşaltılır"
    GmOptPower = "Nihai Performans güç planına geç"; GmOptPowerD = "Oyun bitince önceki planınıza döner"
    GmOptNotif = "Bildirimleri sustur"; GmOptNotifD = "Uygulama bildirimleri oyun sırasında gösterilmez"
    GmOptClose = "Seçili arka plan uygulamalarını kapat"; GmOptCloseD = "Aşağıdaki listeden seçtikleriniz kapatılır"
    GmOptRelaunch = "Bitince kapanan uygulamaları yeniden aç"; GmOptRelaunchD = "Uygulamalar normal kullanıcı olarak açılır"
    GmAppsTitle = "Kapatılacak arka plan uygulamaları"; GmAppsSub = "Yalnızca şu an çalışanlar listelenir"; GmAppsNone = "Listedeki uygulamaların hiçbiri şu an çalışmıyor."
    GmRunning = "Çalışıyor · {0}"; GmStarted = "Oyun Modu açık: {0} uygulama kapatıldı, {1} bellek boşaltıldı"; GmStopped = "Oyun Modu kapatıldı, ayarlar geri yüklendi"
    GmTip = "İpucu: Optimizasyonlar → Oyun Performansı bölümündeki kalıcı ayarlar (Oyun Modu, GPU önceliği, Game DVR) ile birlikte kullanın."
} @{
    NavGame = "Game Mode"; Title_Game = "Game Mode"; Sub_Game = "One-click maximum performance for gaming — everything is restored afterwards"
    GmOffTitle = "Game Mode is off"; GmOnTitle = "Game Mode is on"; GmOffSub = "Turn it on before you start playing; system resources are dedicated to the game."
    GmOnSub = "On since {0} · {1} apps closed · {2} memory gained"
    BtnGmStart = "Start Game Mode"; BtnGmStop = "Stop Game Mode"; GmStarting = "Starting Game Mode…"; GmStopping = "Restoring previous settings…"
    GmOptsTitle = "What should happen?"; GmOptRam = "Clean memory"; GmOptRamD = "Standby and working set memory are freed"
    GmOptPower = "Switch to Ultimate Performance plan"; GmOptPowerD = "Your previous plan is restored afterwards"
    GmOptNotif = "Silence notifications"; GmOptNotifD = "App notifications are not shown while gaming"
    GmOptClose = "Close selected background apps"; GmOptCloseD = "The apps you select below are closed"
    GmOptRelaunch = "Reopen closed apps afterwards"; GmOptRelaunchD = "Apps are reopened as a normal user"
    GmAppsTitle = "Background apps to close"; GmAppsSub = "Only currently running apps are listed"; GmAppsNone = "None of the listed apps are running right now."
    GmRunning = "Running · {0}"; GmStarted = "Game Mode on: {0} apps closed, {1} memory freed"; GmStopped = "Game Mode off, settings restored"
    GmTip = "Tip: Use together with the permanent settings in Optimizations → Gaming Performance (Game Mode, GPU priority, Game DVR)."
}

Register-WoPage @{
    Name = "Game"; Icon = 0xE7FC
    Loc = @("GmOptsTitle", "GmOptRam", "GmOptRamD", "GmOptPower", "GmOptPowerD", "GmOptNotif", "GmOptNotifD", "GmOptClose", "GmOptCloseD",
            "GmOptRelaunch", "GmOptRelaunchD", "GmAppsTitle", "GmAppsSub", "GmTip")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageGame">
  <StackPanel Margin="0,0,14,20">
    <Border x:Name="GmHero" CornerRadius="14" Padding="26,22" BorderThickness="1">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <Border x:Name="GmIconBox" Width="60" Height="60" CornerRadius="16" VerticalAlignment="Center">
          <TextBlock Text="&#xE7FC;" FontFamily="{DynamicResource Icons}" FontSize="28" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
        <StackPanel Grid.Column="1" Margin="20,0,20,0" VerticalAlignment="Center">
          <TextBlock x:Name="GmTitle" FontSize="24" FontWeight="Bold" Foreground="White"/>
          <TextBlock x:Name="GmSub" FontSize="12.5" Foreground="#B4B4CC" Margin="0,6,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <Button x:Name="BtnGmToggle" Grid.Column="2" Style="{DynamicResource PrimaryBtn}" Height="48" MinWidth="220" FontSize="14" VerticalAlignment="Center"/>
      </Grid>
    </Border>
    <Grid Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="GmOptsTitle" Style="{DynamicResource CardTitle}" Margin="0,0,0,16"/>
          <CheckBox x:Name="GmChkRam" Style="{DynamicResource Check}"><StackPanel><TextBlock x:Name="GmOptRam" FontSize="12.5" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="GmOptRamD" Style="{DynamicResource Desc}" FontSize="11"/></StackPanel></CheckBox>
          <CheckBox x:Name="GmChkPower" Style="{DynamicResource Check}"><StackPanel><TextBlock x:Name="GmOptPower" FontSize="12.5" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="GmOptPowerD" Style="{DynamicResource Desc}" FontSize="11"/></StackPanel></CheckBox>
          <CheckBox x:Name="GmChkNotif" Style="{DynamicResource Check}"><StackPanel><TextBlock x:Name="GmOptNotif" FontSize="12.5" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="GmOptNotifD" Style="{DynamicResource Desc}" FontSize="11"/></StackPanel></CheckBox>
          <CheckBox x:Name="GmChkClose" Style="{DynamicResource Check}"><StackPanel><TextBlock x:Name="GmOptClose" FontSize="12.5" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="GmOptCloseD" Style="{DynamicResource Desc}" FontSize="11"/></StackPanel></CheckBox>
          <CheckBox x:Name="GmChkRelaunch" Style="{DynamicResource Check}"><StackPanel><TextBlock x:Name="GmOptRelaunch" FontSize="12.5" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="GmOptRelaunchD" Style="{DynamicResource Desc}" FontSize="11"/></StackPanel></CheckBox>
          <Border Background="#171726" CornerRadius="8" Padding="12,10" Margin="0,6,0,0">
            <TextBlock x:Name="GmTip" Style="{DynamicResource Desc}" FontSize="11"/>
          </Border>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="GmAppsTitle" Style="{DynamicResource CardTitle}"/>
          <TextBlock x:Name="GmAppsSub" Style="{DynamicResource Desc}" Margin="0,3,0,14"/>
          <StackPanel x:Name="GmAppList"/>
        </StackPanel>
      </Border>
    </Grid>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { Update-GameUi; Refresh-GameApps }
    OnLang = { Update-GameUi; Refresh-GameApps }
}

# Kapatilabilecek bilinen arka plan uygulamalari: surec adi -> gorunen ad
$WoGameApps = [ordered]@{
    "OneDrive" = "OneDrive"; "msedge" = "Microsoft Edge"; "Widgets" = "Widgets"; "WidgetService" = "Widget Service"
    "PhoneExperienceHost" = "Phone Link"; "mscopilot" = "Copilot"; "ms-teams" = "Microsoft Teams"; "Teams" = "Teams (classic)"
    "Spotify" = "Spotify"; "Discord" = "Discord"; "Dropbox" = "Dropbox"; "GoogleDriveFS" = "Google Drive"
    "Creative Cloud" = "Adobe Creative Cloud"; "AdobeIPCBroker" = "Adobe IPC Broker"; "Skype" = "Skype"; "Zoom" = "Zoom"
    "EpicGamesLauncher" = "Epic Games Launcher"; "EADesktop" = "EA app"; "Battle.net" = "Battle.net"; "UbisoftConnect" = "Ubisoft Connect"
    "steamwebhelper" = "Steam (web helper)"; "WhatsApp" = "WhatsApp"; "Telegram" = "Telegram"; "Copilot" = "Copilot"
}
$WoGameDefaultApps = @("OneDrive", "msedge", "Widgets", "WidgetService", "PhoneExperienceHost", "mscopilot", "Copilot", "Creative Cloud", "AdobeIPCBroker", "Dropbox", "GoogleDriveFS")

# Ayarlar (settings.json -> game)
$g = $Settings["game"]
$script:GameOpts = @{ Ram = $true; Power = $true; Notif = $true; Close = $true; Relaunch = $true; Apps = $WoGameDefaultApps }
if ($g) { foreach ($k in @("Ram", "Power", "Notif", "Close", "Relaunch", "Apps")) { if ($null -ne $g.$k) { $script:GameOpts[$k] = $g.$k } } }
$script:GameOpts.Apps = @($script:GameOpts.Apps)
$script:GameState = $Settings["gameActive"]
$script:GameBusy = $false

function Save-GameSettings {
    $Settings["game"] = $script:GameOpts
    $Settings["gameActive"] = $script:GameState
    Save-WoSettings
}

$GmChecks = @{ GmChkRam = "Ram"; GmChkPower = "Power"; GmChkNotif = "Notif"; GmChkClose = "Close"; GmChkRelaunch = "Relaunch" }
foreach ($k in $GmChecks.Keys) {
    (N $k).IsChecked = [bool]$script:GameOpts[$GmChecks[$k]]
    (N $k).Add_Click({ param($s) $script:GameOpts[$GmChecks[$s.Name]] = [bool]$s.IsChecked; Save-GameSettings })
}

function Update-GameUi {
    $on = [bool]$script:GameState
    $hero = N "GmHero"
    if ($on) {
        $hero.Background = New-Object Windows.Media.LinearGradientBrush(([Windows.Media.ColorConverter]::ConvertFromString("#14532D")), ([Windows.Media.ColorConverter]::ConvertFromString("#14141F")), 0)
        $hero.BorderBrush = Brush "#1F7A4D"
        (N "GmIconBox").Background = Brush "#22C55E"
        (N "GmTitle").Text = T "GmOnTitle"
        (N "GmSub").Text = (T "GmOnSub") -f $script:GameState.Since, @($script:GameState.Closed).Count, (Fmt-GB ([double]$script:GameState.Gain))
        (N "BtnGmToggle").Style = $window.FindResource("DangerBtn"); (N "BtnGmToggle").Content = T "BtnGmStop"
    } else {
        $hero.Background = New-Object Windows.Media.LinearGradientBrush(([Windows.Media.ColorConverter]::ConvertFromString("#2A1F5C")), ([Windows.Media.ColorConverter]::ConvertFromString("#14141F")), 0)
        $hero.BorderBrush = Brush "#3B2F7A"
        (N "GmIconBox").Background = $window.FindResource("AccentGrad")
        (N "GmTitle").Text = T "GmOffTitle"; (N "GmSub").Text = T "GmOffSub"
        (N "BtnGmToggle").Style = $window.FindResource("PrimaryBtn"); (N "BtnGmToggle").Content = T "BtnGmStart"
    }
    (N "BtnGmToggle").IsEnabled = -not $script:GameBusy
    foreach ($k in $GmChecks.Keys) { (N $k).IsEnabled = -not $on }
}

function Refresh-GameApps {
    $list = N "GmAppList"; $list.Children.Clear()
    $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $WoGameApps.Contains($_.ProcessName) } | Group-Object ProcessName)
    if ($procs.Count -eq 0) { [void]$list.Children.Add((New-Tb (T "GmAppsNone") 12 "#7A7A94")); return }
    $check = $window.FindResource("Check")
    foreach ($grp in ($procs | Sort-Object { $WoGameApps[$_.Name] })) {
        $mem = ($grp.Group | Measure-Object WorkingSet64 -Sum).Sum
        $cb = New-Object Windows.Controls.CheckBox; $cb.Style = $check; $cb.Tag = $grp.Name; $cb.Focusable = $false
        $cb.IsChecked = $script:GameOpts.Apps -contains $grp.Name
        $cb.IsEnabled = -not $script:GameState
        $sp = New-Object Windows.Controls.StackPanel
        [void]$sp.Children.Add((New-Tb $WoGameApps[$grp.Name] 12.5 "#EDEDF5"))
        [void]$sp.Children.Add((New-Tb ((T "GmRunning") -f (Fmt-GB $mem)) 11 "#7A7A94"))
        $cb.Content = $sp
        $cb.Add_Click({
            param($s)
            $apps = [System.Collections.ArrayList]@($script:GameOpts.Apps)
            if ($s.IsChecked) { if ($apps -notcontains $s.Tag) { [void]$apps.Add($s.Tag) } } else { $apps.Remove($s.Tag) }
            $script:GameOpts.Apps = @($apps); Save-GameSettings
        })
        [void]$list.Children.Add($cb)
    }
}

function Start-GameMode {
    if ($script:GameBusy -or $script:GameState) { return }
    $script:GameBusy = $true; Update-GameUi
    Set-Status (T "GmStarting") "busy"
    Start-Bg -Work {
        param($Opts, $PlanGuid)
        $st = [ordered]@{ Since = (Get-Date -Format "HH:mm"); PrevScheme = $null; PrevToast = $null; ToastSet = $false; Closed = @(); Gain = 0 }
        $before = [WoNative]::GetMemInfo()
        if ($Opts.Close) {
            foreach ($name in $Opts.Apps) {
                $ps = @(Get-Process -Name $name -ErrorAction SilentlyContinue)
                if ($ps.Count -eq 0) { continue }
                $path = ($ps | Where-Object Path | Select-Object -First 1).Path
                $ps | Stop-Process -Force -ErrorAction SilentlyContinue
                if ($path -and $name -ne "msedge") { $st.Closed += [pscustomobject]@{ Name = $name; Path = $path } }
                elseif ($path) { $st.Closed += [pscustomobject]@{ Name = $name; Path = $null } }
            }
            Start-Sleep -Milliseconds 800
        }
        if ($Opts.Power) {
            $st.PrevScheme = ([regex]::Match((& powercfg.exe /getactivescheme), '[0-9a-fA-F-]{36}')).Value
            if (-not ((& powercfg.exe /list) -match $PlanGuid)) {
                & powercfg.exe /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 $PlanGuid | Out-Null
                if ($LASTEXITCODE) { & powercfg.exe /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c $PlanGuid | Out-Null }
                & powercfg.exe /changename $PlanGuid "Windows Optimizer - Ultimate" | Out-Null
            }
            & powercfg.exe /setactive $PlanGuid
        }
        if ($Opts.Notif) {
            $k = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
            try { $st.PrevToast = (Get-ItemProperty -LiteralPath $k -Name ToastEnabled -ErrorAction Stop).ToastEnabled } catch {}
            if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }
            New-ItemProperty -LiteralPath $k -Name ToastEnabled -Value 0 -PropertyType DWord -Force | Out-Null
            $st.ToastSet = $true
        }
        if ($Opts.Ram) {
            [void][WoNative]::EnablePrivilege("SeProfileSingleProcessPrivilege"); [void][WoNative]::EnablePrivilege("SeIncreaseQuotaPrivilege")
            [void][WoNative]::MemCommand(2); [void][WoNative]::MemCommand(3); [void][WoNative]::MemCommand(4)
            Start-Sleep -Milliseconds 300
        }
        $st.Gain = [Math]::Max([double]0, [double]([WoNative]::GetMemInfo().Avail) - [double]$before.Avail)
        [pscustomobject]$st
    } -ArgList @($script:GameOpts, $WoPlanGuid) -Done {
        param($out, $err)
        $script:GameBusy = $false
        $st = @($out) | Select-Object -Last 1
        if ($err) { Write-WoLog "Oyun modu: $err" }
        if ($st) {
            $script:GameState = $st; Save-GameSettings
            Set-Status ((T "GmStarted") -f @($st.Closed).Count, (Fmt-GB ([double]$st.Gain))) "ok"
        }
        Update-GameUi; Refresh-GameApps
    }
}

function Stop-GameMode {
    if ($script:GameBusy -or -not $script:GameState) { return }
    $script:GameBusy = $true; Update-GameUi
    Set-Status (T "GmStopping") "busy"
    Start-Bg -Work {
        param($St, $Relaunch, $PlanGuid)
        if ($St.PrevScheme -and $St.PrevScheme -ne $PlanGuid) { & powercfg.exe /setactive $St.PrevScheme }
        if ($St.ToastSet) {
            $k = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
            if ($null -eq $St.PrevToast) { Remove-ItemProperty -LiteralPath $k -Name ToastEnabled -ErrorAction SilentlyContinue }
            else { New-ItemProperty -LiteralPath $k -Name ToastEnabled -Value ([int]$St.PrevToast) -PropertyType DWord -Force | Out-Null }
        }
        if ($Relaunch) {
            # explorer.exe uzerinden acilinca uygulama yonetici olarak degil, normal kullanici olarak calisir
            foreach ($c in @($St.Closed)) { if ($c.Path -and (Test-Path -LiteralPath $c.Path)) { Start-Process explorer.exe -ArgumentList "`"$($c.Path)`"" } }
        }
    } -ArgList @($script:GameState, [bool]$script:GameOpts.Relaunch, $WoPlanGuid) -Done {
        param($out, $err)
        $script:GameBusy = $false
        if ($err) { Write-WoLog "Oyun modu bitirme: $err" }
        $script:GameState = $null; Save-GameSettings
        Set-Status (T "GmStopped") "ok"
        Update-GameUi; Refresh-GameApps
    }
}

function Toggle-GameMode { if ($script:GameState) { Stop-GameMode } else { Start-GameMode } }
(N "BtnGmToggle").Add_Click({ Toggle-GameMode })
