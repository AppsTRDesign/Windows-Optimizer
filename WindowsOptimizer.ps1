# WindowsOptimizer.ps1 - v1.3
# Özellikler: Revert + TR/EN + RAM/BG self-contained + Auto-update
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile","-ExecutionPolicy","Bypass","-NoExit","-File","`"$PSCommandPath`""
    )
    exit
}

$logPath    = "$env:TEMP\WindowsOptimizer-error.log"
$backupPath = Join-Path $PSScriptRoot "backup.json"
$settingsPath = Join-Path $PSScriptRoot "settings.json"

# ---------- DİL SÖZLÜĞÜ ----------
$Lang = @{
    TR = @{
        Subtitle        = "v1.3  -  Modüler Windows 10/11 Tweaker"
        SecAds          = "REKLAMLAR & GİZLİLİK"
        SecSearch       = "ARAMA & WEB"
        SecSystem       = "SİSTEM"
        SecPerf         = "PERFORMANS"
        SecBg           = "ARKA PLAN"
        ChkExplorerAds  = "Dosya Gezgini reklamlarını kapat"
        ChkLockScreen   = "Kilit ekranı ipuçları ve reklamlarını kapat"
        ChkSettingsAds  = "Ayarlar uygulaması reklamlarını kapat"
        ChkGeneralTips  = "Genel ipuçları ve önerileri kapat"
        ChkFinishSetup  = "'Kurulumu tamamla' reklamlarını kapat"
        ChkWelcome      = "'Hoş geldiniz' deneyimi reklamlarını kapat"
        ChkPersonalAds  = "Kişiselleştirilmiş reklamları kapat"
        ChkTailored     = "'Uyarlanmış deneyimleri' kapat"
        ChkStartMenuAds = "Başlat menüsü reklamlarını kapat"
        ChkNotifSugg    = "Bildirim önerilerini kapat"
        ChkBing         = "Aramada Bing sonuçlarını kapat"
        ChkEdgeBar      = "Edge arama çubuğu widget'ını kapat"
        ChkTelemetry    = "Telemetri ve veri toplamayı kapat"
        ChkCortana      = "Cortana'yı devre dışı bırak"
        ChkConsumer     = "Tüketici özelliklerini kapat"
        ChkBgApps       = "Arka plan uygulamalarını kapat"
        ChkBgServices   = "Gereksiz arka plan servislerini kapat"
        ChkBgCortana    = "Cortana arka plan görevini kapat"
        ChkRam          = "RAM bekleme belleğini temizle"
        ChkRamTrim      = "Çalışan süreçlerin bellek izini kırp"
        BtnApply        = "UYGULA"
        BtnRevert       = "GERİ AL"
        BtnUpdate       = "GÜNCELLE"
        StatusReady     = "Hazır - Değişiklikleri uygulamak için seçin"
        StatusApplying  = "Uygulanıyor..."
        StatusReverting = "Geri alınıyor..."
        StatusOK        = "✓ {0} değişiklik uygulandı"
        StatusWarn      = "⚠ {0} başarılı, {1} hata (konsola bakın)"
        StatusReverted  = "✓ {0} değişiklik geri alındı"
        StatusNoBackup  = "Geri alınacak kayıt yok"
        UpdateFound     = "🎉 Yeni sürüm: v{0} - Güncellemek için tıklayın"
        UpdateNone      = "✓ Güncel sürüm: v{0}"
        LangBtn         = "EN"
    }
    EN = @{
        Subtitle        = "v1.3  -  Modular Windows 10/11 Tweaker"
        SecAds          = "ADS & PRIVACY"
        SecSearch       = "SEARCH & WEB"
        SecSystem       = "SYSTEM"
        SecPerf         = "PERFORMANCE"
        SecBg           = "BACKGROUND"
        ChkExplorerAds  = "Disable File Explorer ads"
        ChkLockScreen   = "Disable lock screen tips & ads"
        ChkSettingsAds  = "Disable Settings app ads"
        ChkGeneralTips  = "Disable general tips & suggestions"
        ChkFinishSetup  = "Disable 'Finish Setup' ads"
        ChkWelcome      = "Disable 'Welcome Experience' ads"
        ChkPersonalAds  = "Disable personalized ads"
        ChkTailored     = "Disable 'Tailored Experiences'"
        ChkStartMenuAds = "Disable Start Menu ads"
        ChkNotifSugg    = "Disable notification suggestions"
        ChkBing         = "Disable Bing results in search"
        ChkEdgeBar      = "Disable Edge search bar widget"
        ChkTelemetry    = "Disable telemetry & data collection"
        ChkCortana      = "Disable Cortana"
        ChkConsumer     = "Disable consumer features"
        ChkBgApps       = "Disable background apps"
        ChkBgServices   = "Disable unnecessary background services"
        ChkBgCortana    = "Disable Cortana background task"
        ChkRam          = "Clean RAM standby memory"
        ChkRamTrim      = "Trim running process working sets"
        BtnApply        = "APPLY"
        BtnRevert       = "REVERT"
        BtnUpdate       = "UPDATE"
        StatusReady     = "Ready - Select tweaks and click apply"
        StatusApplying  = "Applying..."
        StatusReverting = "Reverting..."
        StatusOK        = "✓ {0} changes applied"
        StatusWarn      = "⚠ {0} ok, {1} failed (see console)"
        StatusReverted  = "✓ {0} changes reverted"
        StatusNoBackup  = "Nothing to revert"
        UpdateFound     = "🎉 New version: v{0} - Click to update"
        UpdateNone      = "✓ Up to date: v{0}"
        LangBtn         = "TR"
    }
}

# ---------- AYARLARI OKU ----------
function Load-Settings {
    if (Test-Path $settingsPath) {
        try { return Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch {}
    }
    return [PSCustomObject]@{ language = "TR" }
}
function Save-Settings($s) {
    $s | ConvertTo-Json | Set-Content $settingsPath -Encoding UTF8
}

$settings = Load-Settings
if (-not $settings.language) { $settings.language = "TR" }

# ---------- BACKUP ----------
function Load-Backup {
    $hash = @{}
    if (Test-Path $backupPath) {
        try {
            $json = Get-Content $backupPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($p in $json.PSObject.Properties) { $hash[$p.Name] = $p.Value }
        } catch {}
    }
    return $hash
}
function Save-Backup($hash) {
    $hash | ConvertTo-Json -Depth 6 | Set-Content $backupPath -Encoding UTF8
}

# ---------- AKSİYON TANIMLARI ----------
# Her aksiyon: { "ChkXxx" = @( @{Path="..."; Name="..."; Value=0}, ... ) }
$ActionDefs = [ordered]@{
    ChkExplorerAds = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ShowSyncProviderNotifications"; Value=0 }
    )
    ChkLockScreen = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="RotatingLockScreenOverlayEnabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338387Enabled"; Value=0 }
    )
    ChkSettingsAds = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338393Enabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-353694Enabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-353696Enabled"; Value=0 }
    )
    ChkGeneralTips = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SoftLandingEnabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-310093Enabled"; Value=0 }
    )
    ChkFinishSetup = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name="ScoobeSystemSettingEnabled"; Value=0 }
    )
    ChkWelcome = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338388Enabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338389Enabled"; Value=0 }
    )
    ChkPersonalAds = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0 }
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0 }
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name="DisabledByGroupPolicy"; Value=1 }
    )
    ChkTailored = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"; Name="TailoredExperiencesWithDiagnosticDataEnabled"; Value=0 }
    )
    ChkStartMenuAds = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SystemPaneSuggestionsEnabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SilentInstalledAppsEnabled"; Value=0 }
    )
    ChkNotifSugg = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-314563Enabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-88000326Enabled"; Value=0 }
    )
    ChkBing = @(
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name="BingSearchEnabled"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name="CortanaConsent"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name="DisableSearchBoxSuggestions"; Value=1 }
    )
    ChkEdgeBar = @(
        @{ Path="HKCU:\SOFTWARE\Policies\Microsoft\Edge"; Name="WebWidgetAllowed"; Value=0 }
        @{ Path="HKCU:\SOFTWARE\Policies\Microsoft\Edge"; Name="SearchbarAllowed"; Value=0 }
    )
    ChkTelemetry = @(
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Value=0 }
    )
    ChkCortana = @(
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name="AllowCortana"; Value=0 }
    )
    ChkConsumer = @(
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name="DisableWindowsConsumerFeatures"; Value=1 }
    )
    ChkBgApps = @(
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name="LetAppsRunInBackground"; Value=2 }
    )
    ChkBgServices = @(
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack"; Name="Start"; Value=4 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice"; Name="Start"; Value=4 }
    )
    ChkBgCortana = @(
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name="AllowCortanaAboveLock"; Value=0 }
    )
}

# ---------- APPLY / REVERT FONKSİYONLARI ----------
function Apply-RegistryList {
    param($List, [hashtable]$Backup)
    foreach ($r in $List) {
        $key = "$($r.Path)|$($r.Name)"
        if (-not $Backup.ContainsKey($key)) {
            $orig = $null; $existed = $false
            if (Test-Path $r.Path) {
                try {
                    $prop = Get-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction Stop
                    $orig = $prop.($r.Name); $existed = $true
                } catch { $existed = $false }
            }
            $Backup[$key] = @{ Path=$r.Path; Name=$r.Name; Value=$orig; Existed=$existed }
        }
        if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }
        Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force
    }
}

function Restore-RegistryList {
    param($List, [hashtable]$Backup)
    $count = 0
    foreach ($r in $List) {
        $key = "$($r.Path)|$($r.Name)"
        if ($Backup.ContainsKey($key)) {
            $b = $Backup[$key]
            try {
                if ($b.Existed) {
                    Set-ItemProperty -Path $b.Path -Name $b.Name -Value $b.Value -Type DWord -Force -ErrorAction Stop
                } else {
                    Remove-ItemProperty -Path $b.Path -Name $b.Name -ErrorAction SilentlyContinue
                }
                $count++
            } catch {}
        }
    }
    return $count
}

# ---------- MODÜLLERİ YÜKLE ----------
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    Set-Location $PSScriptRoot

    $configPath = Join-Path $PSScriptRoot "config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $config = [PSCustomObject]@{ author="Anonim"; github="#"; instagram="#"; website="#"; logo="assets/logo.png"; version="1.3.0" }
    }
    if (-not $config.version) { $config.version = "1.3.0" }

    . "$PSScriptRoot\modules\RamCleaner.ps1"
    . "$PSScriptRoot\modules\BackgroundManager.ps1"

    $logoPath   = Join-Path $PSScriptRoot ($config.logo -replace '/','\')
    $bannerPath = Join-Path $PSScriptRoot "assets\banner.png"

    # ---------- XAML ----------
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Optimizer" Height="880" Width="640"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="CanResizeWithGrip">

  <Window.Resources>
    <Style x:Key="ModernCheck" TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E6E6F0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Margin" Value="0,5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal" Background="Transparent">
              <Border x:Name="Box" Width="20" Height="20" CornerRadius="5"
                      Background="#1E1E30" BorderBrush="#3A3A55" BorderThickness="1.5"
                      VerticalAlignment="Center" Margin="0,0,12,0">
                <TextBlock x:Name="Check" Text="&#x2713;" Foreground="White" FontWeight="Bold"
                           FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"
                           Visibility="Collapsed"/>
              </Border>
              <ContentPresenter VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="#7C5CFF"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="#7C5CFF"/>
                <Setter TargetName="Check" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Box" Property="BorderBrush" Value="#7C5CFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleBtn" TargetType="Button">
      <Setter Property="Width" Value="34"/>
      <Setter Property="Height" Value="34"/>
      <Setter Property="Foreground" Value="#C0C0D0"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#2E2E48"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="8">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#7C5CFF" Offset="0"/>
                  <GradientStop Color="#A855F7" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.7"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="DangerBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="8" Background="#3A1E1E" BorderBrush="#7C3A3A" BorderThickness="1">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#4A2525"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="LinkBtn" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#9C8CFF"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="Padding" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <TextBlock x:Name="Txt" Text="{TemplateBinding Content}"
                       Foreground="{TemplateBinding Foreground}"
                       TextDecorations="Underline"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Txt" Property="Foreground" Value="#C4B5FD"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border CornerRadius="14" BorderBrush="#2A2A45" BorderThickness="1">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
        <GradientStop Color="#0F0F1A" Offset="0"/>
        <GradientStop Color="#141428" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>

    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="78"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <Border Grid.Row="0" x:Name="BannerBox" CornerRadius="14,14,0,0" ClipToBounds="True">
        <Image x:Name="BannerImg" Stretch="UniformToFill"/>
      </Border>

      <Border Grid.Row="1" x:Name="HeaderBar">
        <Border.Background>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#1E1E38" Offset="0"/>
            <GradientStop Color="#252545" Offset="1"/>
          </LinearGradientBrush>
        </Border.Background>
        <Grid>
          <StackPanel Orientation="Horizontal" Margin="22,0,0,0" VerticalAlignment="Center">
            <Border Width="46" Height="46" CornerRadius="10" Background="#7C5CFF" Margin="0,0,16,0">
              <Image x:Name="LogoImg" Stretch="Uniform" Margin="6"/>
            </Border>
            <StackPanel VerticalAlignment="Center">
              <TextBlock Text="WINDOWS OPTIMIZER" FontSize="17" FontWeight="Bold" Foreground="White"/>
              <TextBlock x:Name="SubTitle" FontSize="11" Foreground="#9090B0" Margin="0,2,0,0"/>
            </StackPanel>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,14,0" VerticalAlignment="Center">
            <Button x:Name="BtnLang" Content="EN" Style="{StaticResource TitleBtn}" FontSize="11" Margin="0,0,4,0"/>
            <Button x:Name="BtnMin" Content="&#x2014;" Style="{StaticResource TitleBtn}"/>
            <Button x:Name="BtnClose" Content="&#x2715;" Style="{StaticResource TitleBtn}" Margin="4,0,0,0"/>
          </StackPanel>
        </Grid>
      </Border>

      <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="0,6,0,6">
        <StackPanel Margin="26,8,26,8">

          <TextBlock x:Name="LblSecAds" Foreground="#7C5CFF" FontSize="11" FontWeight="Bold" Margin="0,10,0,8"/>
          <CheckBox x:Name="ChkExplorerAds" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkLockScreen"  Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkSettingsAds" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkGeneralTips" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkFinishSetup" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkWelcome"     Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkPersonalAds" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkTailored"    Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkStartMenuAds" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkNotifSugg"   Style="{StaticResource ModernCheck}" IsChecked="True"/>

          <TextBlock x:Name="LblSecSearch" Foreground="#7C5CFF" FontSize="11" FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkBing"    Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkEdgeBar" Style="{StaticResource ModernCheck}" IsChecked="True"/>

          <TextBlock x:Name="LblSecSystem" Foreground="#7C5CFF" FontSize="11" FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkTelemetry" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkCortana"   Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkConsumer"  Style="{StaticResource ModernCheck}" IsChecked="True"/>

          <TextBlock x:Name="LblSecBg" Foreground="#7C5CFF" FontSize="11" FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkBgApps"     Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkBgServices" Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkBgCortana"  Style="{StaticResource ModernCheck}" IsChecked="True"/>

          <TextBlock x:Name="LblSecPerf" Foreground="#7C5CFF" FontSize="11" FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkRam"     Style="{StaticResource ModernCheck}" IsChecked="True"/>
          <CheckBox x:Name="ChkRamTrim" Style="{StaticResource ModernCheck}" IsChecked="True"/>
        </StackPanel>
      </ScrollViewer>

      <Border Grid.Row="3" Background="#101020" CornerRadius="0,0,14,14">
        <StackPanel Margin="22,12,22,12">
          <Grid>
            <TextBlock x:Name="StatusText" VerticalAlignment="Center" Foreground="#8888A8" FontSize="12"/>
          </Grid>
          <Grid Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left">
              <Button x:Name="BtnUpdate" Content="GÜNCELLE" Style="{StaticResource DangerBtn}"
                      Width="140" Height="38" Visibility="Collapsed" Margin="0,0,8,0"/>
              <Button x:Name="BtnRevert" Content="GERİ AL" Style="{StaticResource DangerBtn}"
                      Width="110" Height="38"/>
            </StackPanel>
            <Button x:Name="BtnApply" Content="UYGULA" Style="{StaticResource PrimaryBtn}"
                    Width="160" Height="42" HorizontalAlignment="Right"/>
          </Grid>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,12,0,0">
            <TextBlock x:Name="AuthorLabel" Foreground="#606080" FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Button x:Name="BtnGithub"    Content="GitHub"    Style="{StaticResource LinkBtn}" Margin="0,0,10,0"/>
            <Button x:Name="BtnInstagram" Content="Instagram" Style="{StaticResource LinkBtn}" Margin="0,0,10,0"/>
            <Button x:Name="BtnWebsite"   Content="Website"   Style="{StaticResource LinkBtn}"/>
          </StackPanel>
        </StackPanel>
      </Border>
    </Grid>
  </Border>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    function N($n) { $window.FindName($n) }

    # ---- Logo / banner ----
    if (Test-Path $logoPath) {
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit(); $bmp.UriSource = New-Object System.Uri($logoPath, [System.UriKind]::Absolute)
            $bmp.CacheOption = "OnLoad"; $bmp.EndInit()
            (N "LogoImg").Source = $bmp
        } catch {}
    }
    if (Test-Path $bannerPath) {
        try {
            $bb = New-Object System.Windows.Media.Imaging.BitmapImage
            $bb.BeginInit(); $bb.UriSource = New-Object System.Uri($bannerPath, [System.UriKind]::Absolute)
            $bb.CacheOption = "OnLoad"; $bb.EndInit()
            (N "BannerImg").Source = $bb
        } catch { (N "BannerBox").Visibility = "Collapsed" }
    } else { (N "BannerBox").Visibility = "Collapsed" }

    # ---- Pencere kontrolleri ----
    (N "HeaderBar").Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
    (N "BtnMin").Add_Click({ $window.WindowState = "Minimized" })
    (N "BtnClose").Add_Click({ $window.Close() })

    # ---- Dil uygulama ----
    $script:CurrentLang = $settings.language
    function Apply-Language {
        $L = $Lang[$script:CurrentLang]
        $map = @{
            "LblSecAds"    = "SecAds";    "LblSecSearch" = "SecSearch"
            "LblSecSystem" = "SecSystem"; "LblSecBg"     = "SecBg"
            "LblSecPerf"   = "SecPerf"
            "ChkExplorerAds"="ChkExplorerAds"; "ChkLockScreen"="ChkLockScreen"
            "ChkSettingsAds"="ChkSettingsAds"; "ChkGeneralTips"="ChkGeneralTips"
            "ChkFinishSetup"="ChkFinishSetup"; "ChkWelcome"="ChkWelcome"
            "ChkPersonalAds"="ChkPersonalAds"; "ChkTailored"="ChkTailored"
            "ChkStartMenuAds"="ChkStartMenuAds"; "ChkNotifSugg"="ChkNotifSugg"
            "ChkBing"="ChkBing"; "ChkEdgeBar"="ChkEdgeBar"
            "ChkTelemetry"="ChkTelemetry"; "ChkCortana"="ChkCortana"
            "ChkConsumer"="ChkConsumer"
            "ChkBgApps"="ChkBgApps"; "ChkBgServices"="ChkBgServices"
            "ChkBgCortana"="ChkBgCortana"
            "ChkRam"="ChkRam"; "ChkRamTrim"="ChkRamTrim"
        }
        foreach ($k in $map.Keys) {
            $ctrl = N $k
            if ($ctrl) { $ctrl.Content = $L[$map[$k]] }
        }
        (N "SubTitle").Text   = $L.Subtitle
        (N "BtnApply").Content  = $L.BtnApply
        (N "BtnRevert").Content = $L.BtnRevert
        (N "BtnLang").Content   = $L.LangBtn
        (N "AuthorLabel").Text  = "by $($config.author)"
        if ((N "BtnUpdate").Visibility -eq "Visible") {
            $u = (N "BtnUpdate").Tag
            (N "BtnUpdate").Content = $L.BtnUpdate
        }
    }
    Apply-Language

    (N "BtnLang").Add_Click({
        $script:CurrentLang = if ($script:CurrentLang -eq "TR") { "EN" } else { "TR" }
        $settings.language = $script:CurrentLang
        Save-Settings $settings
        Apply-Language
    })

    # ---- Link butonları ----
    foreach ($pair in @(@("BtnGithub","github"), @("BtnInstagram","instagram"), @("BtnWebsite","website"))) {
        $btn = N $pair[0]; $url = $config.($pair[1])
        if ($url -and $url -ne "#") {
            $u = $url
            $btn.Add_Click({ Start-Process $u }.GetNewClosure())
        } else { $btn.Visibility = "Collapsed" }
    }

    # ---- Durum mesajları ----
    $status = N "StatusText"
    $L = $Lang[$script:CurrentLang]
    $status.Text = $L.StatusReady

    # ---- APPLY ----
    (N "BtnApply").Add_Click({
        $ok = 0; $fail = 0
        $L = $Lang[$script:CurrentLang]
        $status.Text = $L.StatusApplying
        $status.Foreground = "#C4B5FD"
        $window.Dispatcher.Invoke([Action]{}, "Render")

        $backup = Load-Backup

        # Registry aksiyonları
        foreach ($id in $ActionDefs.Keys) {
            $cb = N $id
            if ($cb -and $cb.IsChecked) {
                try { Apply-RegistryList -List $ActionDefs[$id] -Backup $backup; $ok++ }
                catch {
                    $fail++
                    Write-Host "HATA ($id): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        # RAM temizleme
        if ((N "ChkRam").IsChecked) {
            try { Clear-StandbyMemory | Out-Null; $ok++ } catch { $fail++; Write-Host "RAM: $($_.Exception.Message)" -ForegroundColor Red }
        }
        if ((N "ChkRamTrim").IsChecked) {
            try { Trim-WorkingSets | Out-Null; $ok++ } catch { $fail++; Write-Host "Trim: $($_.Exception.Message)" -ForegroundColor Red }
        }

        Save-Backup $backup

        if ($fail -eq 0) {
            $status.Text = ($L.StatusOK -f $ok)
            $status.Foreground = "#4ADE80"
        } else {
            $status.Text = ($L.StatusWarn -f $ok, $fail)
            $status.Foreground = "#F59E0B"
        }
    })

    # ---- REVERT ----
    (N "BtnRevert").Add_Click({
        $L = $Lang[$script:CurrentLang]
        $backup = Load-Backup
        if ($backup.Count -eq 0) {
            $status.Text = $L.StatusNoBackup
            $status.Foreground = "#F59E0B"
            return
        }

        $status.Text = $L.StatusReverting
        $status.Foreground = "#C4B5FD"
        $window.Dispatcher.Invoke([Action]{}, "Render")

        $total = 0
        foreach ($id in $ActionDefs.Keys) {
            try { $total += Restore-RegistryList -List $ActionDefs[$id] -Backup $backup }
            catch { Write-Host "REVERT HATA ($id): $($_.Exception.Message)" -ForegroundColor Red }
        }

        # Backup temizle
        Remove-Item $backupPath -Force -ErrorAction SilentlyContinue

        $status.Text = ($L.StatusReverted -f $total)
        $status.Foreground = "#4ADE80"
    })

    # ---- AUTO-UPDATE KONTROLÜ ----
    $versionUrl = "https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/version.json"
    try {
        $remote = Invoke-RestMethod -Uri $versionUrl -TimeoutSec 6 -ErrorAction Stop
        if ($remote.version -and ([version]$remote.version -gt [version]$config.version)) {
            $btn = N "BtnUpdate"
            $btn.Tag = $remote
            $btn.Content = ($Lang[$script:CurrentLang].UpdateFound -f $remote.version)
            $btn.Width = 220
            $btn.Visibility = "Visible"

            $btn.Add_Click({
                $info = (N "BtnUpdate").Tag
                if ($info -and $info.url) {
                    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
                        "-NoProfile","-ExecutionPolicy","Bypass","-Command",
                        "irm $($info.url) | iex"
                    )
                }
            })
        } else {
            $status.Text = ($Lang[$script:CurrentLang].UpdateNone -f $config.version)
        }
    } catch {
        Write-Host "Update check failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    $window.ShowDialog() | Out-Null
}
catch {
    $err = "HATA: $($_.Exception.Message)`r`n`r`nSATIR: $($_.InvocationInfo.ScriptLineNumber)`r`n`r`nSTACK:`r`n$($_.ScriptStackTrace)"
    try { [System.IO.File]::WriteAllText($logPath, $err, [System.Text.Encoding]::UTF8) } catch {}
    try { [System.Windows.MessageBox]::Show($err, "Windows Optimizer - Hata", "OK", "Error") | Out-Null } catch { Write-Host $err -ForegroundColor Red }
    Read-Host "Kapatmak icin Enter"
}