# WindowsOptimizer.ps1 - v1.1 (hata yakalama + -NoExit düzeltmesi)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Yönetici kontrolü ve otomatik yükseltme ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # >>> KRİTİK: -NoExit eklendi, hata olsa bile pencere açık kalır <<<
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile","-ExecutionPolicy","Bypass","-NoExit","-File","`"$PSCommandPath`""
    )
    exit
}

$logPath = "$env:TEMP\WindowsOptimizer-error.log"

try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    Set-Location $PSScriptRoot

    # --- Config oku ---
    $configPath = Join-Path $PSScriptRoot "config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $config = [PSCustomObject]@{
            author="Anonim"; github="#"; instagram="#"; website="#"; logo="assets/logo.png"
        }
    }

    # --- Modülleri yükle (var mı kontrol et) ---
    $mods = @("AdsBlocker","FeatureManager","RamCleaner","BackgroundManager")
    foreach ($m in $mods) {
        $p = Join-Path $PSScriptRoot "modules\$m.ps1"
        if (Test-Path $p) { . $p } else { throw "Modül bulunamadı: $p" }
    }

    # --- Logo yolu (boşluklu path güvenli) ---
    $logoPath = Join-Path $PSScriptRoot ($config.logo -replace '/','\')
    $logoUri  = $null
    if (Test-Path $logoPath) {
        try {
            $logoUri = New-Object System.Uri($logoPath, [System.UriKind]::Absolute)
        } catch {
            Write-Host "Logo URI hatası: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # --- XAML ---
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Optimizer" Height="760" Width="600"
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
      <Setter Property="FontSize" Value="14"/>
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

    <Style x:Key="ApplyBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="14"/>
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
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.88"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.7"/>
              </Trigger>
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
        <RowDefinition Height="78"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="96"/>
      </Grid.RowDefinitions>

      <Border Grid.Row="0" x:Name="HeaderBar" CornerRadius="14,14,0,0">
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
            <Button x:Name="BtnMin" Content="&#x2014;" Style="{StaticResource TitleBtn}"/>
            <Button x:Name="BtnClose" Content="&#x2715;" Style="{StaticResource TitleBtn}" Margin="4,0,0,0"/>
          </StackPanel>
        </Grid>
      </Border>

      <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,6,0,6">
        <StackPanel Margin="26,8,26,8">

          <TextBlock Text="REKLAMLAR &amp; GİZLİLİK" Foreground="#7C5CFF" FontSize="11"
                     FontWeight="Bold" Margin="0,10,0,8"/>
          <CheckBox x:Name="ChkExplorerAds"   Style="{StaticResource ModernCheck}" Content="Dosya Gezgini reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkLockScreen"    Style="{StaticResource ModernCheck}" Content="Kilit ekranı ipuçları ve reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkSettingsAds"   Style="{StaticResource ModernCheck}" Content="Ayarlar uygulaması reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkGeneralTips"   Style="{StaticResource ModernCheck}" Content="Genel ipuçları ve önerileri kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkFinishSetup"   Style="{StaticResource ModernCheck}" Content="'Kurulumu tamamla' reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkWelcome"       Style="{StaticResource ModernCheck}" Content="'Hoş geldiniz' deneyimi reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkPersonalAds"   Style="{StaticResource ModernCheck}" Content="Kişiselleştirilmiş reklamları kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkTailored"      Style="{StaticResource ModernCheck}" Content="'Uyarlanmış deneyimleri' kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkStartMenuAds"  Style="{StaticResource ModernCheck}" Content="Başlat menüsü reklamlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkNotifSugg"     Style="{StaticResource ModernCheck}" Content="Bildirim önerilerini kapat" IsChecked="True"/>

          <TextBlock Text="ARAMA &amp; WEB  (Yönetici)" Foreground="#7C5CFF" FontSize="11"
                     FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkBing"          Style="{StaticResource ModernCheck}" Content="Aramada Bing sonuçlarını kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkEdgeBar"       Style="{StaticResource ModernCheck}" Content="Edge arama çubuğu widget'ını kapat" IsChecked="True"/>

          <TextBlock Text="SİSTEM  (Yönetici)" Foreground="#7C5CFF" FontSize="11"
                     FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkTelemetry"     Style="{StaticResource ModernCheck}" Content="Telemetri ve veri toplamayı kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkCortana"       Style="{StaticResource ModernCheck}" Content="Cortana'yı devre dışı bırak" IsChecked="True"/>
          <CheckBox x:Name="ChkConsumer"      Style="{StaticResource ModernCheck}" Content="Tüketici özelliklerini kapat" IsChecked="True"/>
          <CheckBox x:Name="ChkBgApps"        Style="{StaticResource ModernCheck}" Content="Arka plan uygulamalarını kapat" IsChecked="True"/>

          <TextBlock Text="PERFORMANS" Foreground="#7C5CFF" FontSize="11"
                     FontWeight="Bold" Margin="0,18,0,8"/>
          <CheckBox x:Name="ChkRam"           Style="{StaticResource ModernCheck}" Content="RAM bekleme belleğini temizle (RAMMap indirir)"/>
        </StackPanel>
      </ScrollViewer>

      <Border Grid.Row="2" Background="#101020" CornerRadius="0,0,14,14">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="30"/>
          </Grid.RowDefinitions>
          <Grid Grid.Row="0" Margin="22,10,22,4">
            <TextBlock x:Name="StatusText" VerticalAlignment="Center" Foreground="#8888A8" FontSize="12"/>
            <Button x:Name="BtnApply" Content="UYGULA" Style="{StaticResource ApplyBtn}"
                    Width="160" Height="42" HorizontalAlignment="Right"/>
          </Grid>
          <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,8">
            <TextBlock x:Name="AuthorLabel" Foreground="#606080" FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Button x:Name="BtnGithub"    Content="GitHub"    Style="{StaticResource LinkBtn}" Margin="0,0,10,0"/>
            <Button x:Name="BtnInstagram" Content="Instagram" Style="{StaticResource LinkBtn}" Margin="0,0,10,0"/>
            <Button x:Name="BtnWebsite"   Content="Website"   Style="{StaticResource LinkBtn}"/>
          </StackPanel>
        </Grid>
      </Border>
    </Grid>
  </Border>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    function N($n) { $window.FindName($n) }

    # Logo yükle (güvenli)
    if ($logoUri) {
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource   = $logoUri
            $bmp.CacheOption = "OnLoad"
            $bmp.EndInit()
            (N "LogoImg").Source = $bmp
        } catch {
            Write-Host "Logo yüklenemedi: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    (N "SubTitle").Text     = "v1.1  -  Modüler Windows 10/11 Tweaker"
    (N "AuthorLabel").Text  = "by $($config.author)"

    (N "HeaderBar").Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
    (N "BtnMin").Add_Click({ $window.WindowState = "Minimized" })
    (N "BtnClose").Add_Click({ $window.Close() })

    foreach ($pair in @(@("BtnGithub","github"), @("BtnInstagram","instagram"), @("BtnWebsite","website"))) {
        $btn = N $pair[0]; $url = $config.($pair[1])
        if ($url -and $url -ne "#") {
            $u = $url
            $btn.Add_Click({ Start-Process $u }.GetNewClosure())
        } else { $btn.Visibility = "Collapsed" }
    }

    $status = N "StatusText"

    $actionMap = [ordered]@{
        ChkExplorerAds = { Disable-ExplorerAds }
        ChkLockScreen  = { Disable-LockScreenAds }
        ChkSettingsAds = { Disable-SettingsAds }
        ChkGeneralTips = { Disable-GeneralTips }
        ChkFinishSetup = { Disable-FinishSetupAds }
        ChkWelcome     = { Disable-WelcomeExperience }
        ChkPersonalAds = { Disable-PersonalizedAds }
        ChkTailored    = { Disable-TailoredExperiences }
        ChkStartMenuAds= { Disable-StartMenuAds }
        ChkNotifSugg   = { Disable-NotificationSuggestions }
        ChkBing        = { Disable-BingSearch }
        ChkEdgeBar     = { Disable-EdgeSearchBar }
        ChkTelemetry   = { Disable-Telemetry }
        ChkCortana     = { Disable-Cortana }
        ChkConsumer    = { Disable-ConsumerFeatures }
        ChkBgApps      = { Disable-BackgroundApps }
        ChkRam         = { Clear-StandbyMemory }
    }

    (N "BtnApply").Add_Click({
        $ok = 0; $fail = 0
        $status.Text = "Uygulanıyor..."
        $status.Foreground = "#C4B5FD"
        $window.Dispatcher.Invoke([Action]{}, "Render")

        foreach ($kv in $actionMap.GetEnumerator()) {
            $cb = N $kv.Key
            if ($cb -and $cb.IsChecked) {
                try { & $kv.Value; $ok++ }
                catch {
                    $fail++
                    Write-Host "HATA ($($kv.Key)): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        if ($fail -eq 0) {
            $status.Text = "OK - $ok değişiklik uygulandı"
            $status.Foreground = "#4ADE80"
        } else {
            $status.Text = "UYARI - $ok başarılı, $fail hata"
            $status.Foreground = "#F59E0B"
        }
    })

    $window.ShowDialog() | Out-Null
}
catch {
    $err = "HATA: $($_.Exception.Message)`r`n`r`nSATIR: $($_.InvocationInfo.ScriptLineNumber)`r`n`r`nSTACK:`r`n$($_.ScriptStackTrace)"
    try {
        [System.IO.File]::WriteAllText($logPath, $err, [System.Text.Encoding]::UTF8)
    } catch {}

    try {
        [System.Windows.MessageBox]::Show($err, "Windows Optimizer - Hata", "OK", "Error") | Out-Null
    } catch {
        Write-Host $err -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Detay log: $logPath" -ForegroundColor Yellow
    Read-Host "Kapatmak için Enter'a basın"
}
