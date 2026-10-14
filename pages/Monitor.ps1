# pages/Monitor.ps1 - Canli performans izleme + tek tikla optimizasyon
# Veriler surucu kurmadan, dil bagimsiz WMI performans siniflarindan okunur (Turkce Windows'ta sayac adlari yerellesir).
# Cekirdek sicakligi / RAM sicakligi / fan devri: Windows bunlari surucusuz vermez; sahte deger gosterilmez.

Add-WoStrings @{
    NavMonitor = "Performans"; Title_Monitor = "Performans İzleme"; Sub_Monitor = "İşlemci, ekran kartı, bellek, disk ve ağ — canlı"
    MnHeroTitle = "Tek tıkla performans optimizasyonu"
    MnHeroSub = "Belleği boşaltır, geçici dosyaları temizler, DNS önbelleğini yeniler ve Nihai Performans güç planını açar."
    BtnMnOptimize = "Şimdi Optimize Et"; MnOptimizing = "Optimize ediliyor…"
    MnConfirmTitle = "Performans optimize edilsin mi?"
    MnConfirmMsg = "•  Bellek (RAM) boşaltılacak`n•  Kullanıcı ve Windows geçici dosyaları silinecek (son 24 saattekiler korunur)`n•  DNS önbelleği temizlenecek`n•  Nihai Performans güç planı açılacak (Optimizasyonlar → Oyun Performansı'ndan geri alınabilir)"
    MnResult = "Son optimizasyon {0}: +{1} bellek · {2} geçici dosya · güç planı: {3}"; MnPlanUlt = "Nihai Performans"; MnPlanSame = "değişmedi"
    MnCpu = "İşlemci"; MnGpu = "Ekran kartı"; MnRam = "Bellek"; MnDisk = "Disk etkinliği"
    MnCpuSub = "{0:N2} GHz · {1} çekirdek / {2} iş parçacığı"; MnGpuSub = "VRAM {0} / {1}"; MnRamSub = "{0} / {1} · {2} MHz"; MnDiskSub = "En yoğun: {0}"
    MnCores = "Çekirdek kullanımı"; MnSensors = "Sensörler"; MnDisks = "Disk aktarım hızları"; MnNet = "Ağ"
    MnRead = "Okuma"; MnWrite = "Yazma"; MnDown = "İndirme"; MnUp = "Yükleme"; MnActive = "etkin %{0}"
    MnSenAcpi = "Anakart termal bölgesi (ACPI)"; MnSenDisk = "Disk sıcaklığı · {0}"
    MnSenCpuCore = "İşlemci çekirdek sıcaklığı"; MnSenGpuTemp = "Ekran kartı sıcaklığı"; MnSenRamTemp = "RAM sıcaklığı"; MnSenFan = "Fan hızları"
    MnNotSupported = "Okunamıyor"; MnFansFound = "{0} fan algılandı · devir bilgisi yok"
    MnWhyCore = "Windows çekirdek sıcaklığını yalnızca çekirdek düzeyi bir sürücüyle verir. Bu tür sürücüler (WinRing0) güvenlik açığı nedeniyle Microsoft Defender tarafından engellenir; güvenliğiniz için kullanılmaz. HWiNFO gibi imzalı araçlar kullanılabilir."
    MnWhyGpu = "AMD sürücüsü sıcaklığı Windows'a vermiyor; AMD Software: Adrenalin → Performans bölümünden görebilirsiniz. (NVIDIA kartlarda otomatik okunur.)"
    MnWhyRam = "Bellek modüllerindeki sıcaklık sensörüne yalnızca SMBus sürücüsüyle erişilebilir."
    MnWhyFan = "Fan devirleri anakart denetleyicisinden okunur; Windows bu bilgiyi sürücüsüz vermez."
} @{
    NavMonitor = "Performance"; Title_Monitor = "Performance Monitor"; Sub_Monitor = "CPU, GPU, memory, disk and network — live"
    MnHeroTitle = "One-click performance optimization"
    MnHeroSub = "Frees memory, cleans temp files, flushes DNS cache and enables the Ultimate Performance power plan."
    BtnMnOptimize = "Optimize Now"; MnOptimizing = "Optimizing…"
    MnConfirmTitle = "Optimize performance?"
    MnConfirmMsg = "•  Memory (RAM) will be freed`n•  User and Windows temp files will be deleted (last 24 hours kept)`n•  DNS cache will be flushed`n•  Ultimate Performance power plan will be enabled (revert in Optimizations → Gaming Performance)"
    MnResult = "Last optimization {0}: +{1} memory · {2} temp files · power plan: {3}"; MnPlanUlt = "Ultimate Performance"; MnPlanSame = "unchanged"
    MnCpu = "Processor"; MnGpu = "Graphics"; MnRam = "Memory"; MnDisk = "Disk activity"
    MnCpuSub = "{0:N2} GHz · {1} cores / {2} threads"; MnGpuSub = "VRAM {0} / {1}"; MnRamSub = "{0} / {1} · {2} MHz"; MnDiskSub = "Busiest: {0}"
    MnCores = "Core usage"; MnSensors = "Sensors"; MnDisks = "Disk throughput"; MnNet = "Network"
    MnRead = "Read"; MnWrite = "Write"; MnDown = "Download"; MnUp = "Upload"; MnActive = "active {0}%"
    MnSenAcpi = "Motherboard thermal zone (ACPI)"; MnSenDisk = "Disk temperature · {0}"
    MnSenCpuCore = "CPU core temperature"; MnSenGpuTemp = "GPU temperature"; MnSenRamTemp = "RAM temperature"; MnSenFan = "Fan speeds"
    MnNotSupported = "Not available"; MnFansFound = "{0} fans detected · no speed data"
    MnWhyCore = "Windows exposes core temperature only through a kernel-level driver. Such drivers (WinRing0) are blocked by Microsoft Defender due to a security flaw and are not used for your safety. Signed tools like HWiNFO can be used."
    MnWhyGpu = "The AMD driver doesn't expose temperature to Windows; see AMD Software: Adrenalin → Performance. (Read automatically on NVIDIA cards.)"
    MnWhyRam = "Memory module temperature sensors are only reachable through an SMBus driver."
    MnWhyFan = "Fan speeds come from the motherboard controller; Windows doesn't expose them without a driver."
}

Register-WoPage @{
    Name = "Monitor"; Icon = 0xEC4A
    Loc = @("MnHeroTitle", "MnHeroSub", "BtnMnOptimize", "MnCores", "MnSensors", "MnDisks", "MnNet")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageMonitor">
  <StackPanel Margin="0,0,14,20">
    <Border CornerRadius="14" Padding="24,18" BorderBrush="#3B2F7A" BorderThickness="1">
      <Border.Background>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
          <GradientStop Color="#2A1F5C" Offset="0"/><GradientStop Color="#14141F" Offset="1"/>
        </LinearGradientBrush>
      </Border.Background>
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel VerticalAlignment="Center" Margin="0,0,20,0">
          <TextBlock x:Name="MnHeroTitle" FontSize="17" FontWeight="SemiBold" Foreground="White"/>
          <TextBlock x:Name="MnHeroSub" FontSize="12" Foreground="#B4B4CC" Margin="0,5,0,0" TextWrapping="Wrap"/>
          <TextBlock x:Name="MnLastResult" FontSize="11.5" Foreground="#6EE7B7" Margin="0,8,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>
        </StackPanel>
        <Button x:Name="BtnMnOptimize" Grid.Column="1" Style="{DynamicResource PrimaryBtn}" Height="46" MinWidth="200" FontSize="14" VerticalAlignment="Center"/>
      </Grid>
    </Border>
    <UniformGrid x:Name="MnGauges" Columns="4" Margin="0,16,-12,0"/>
    <Grid Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="MnCores" Style="{DynamicResource CardTitle}" Margin="0,0,0,14"/>
          <UniformGrid x:Name="MnCoreBars" Rows="1" Height="130"/>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="MnSensors" Style="{DynamicResource CardTitle}" Margin="0,0,0,12"/>
          <StackPanel x:Name="MnSensorList"/>
        </StackPanel>
      </Border>
    </Grid>
    <Grid Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="MnDisks" Style="{DynamicResource CardTitle}" Margin="0,0,0,12"/>
          <StackPanel x:Name="MnDiskList"/>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}">
        <StackPanel>
          <TextBlock x:Name="MnNet" Style="{DynamicResource CardTitle}" Margin="0,0,0,12"/>
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel><TextBlock x:Name="MnDownL" FontSize="11" Foreground="{DynamicResource Muted}"/><TextBlock x:Name="MnDownV" FontSize="22" FontWeight="Bold" Foreground="#38BDF8"/></StackPanel>
            <StackPanel Grid.Column="1"><TextBlock x:Name="MnUpL" FontSize="11" Foreground="{DynamicResource Muted}"/><TextBlock x:Name="MnUpV" FontSize="22" FontWeight="Bold" Foreground="#A78BFA"/></StackPanel>
          </Grid>
          <Canvas x:Name="MnNetSpark" Height="60" Margin="0,12,0,0" ClipToBounds="True"/>
          <Canvas x:Name="MnNetSpark2" Height="0"/>
        </StackPanel>
      </Border>
    </Grid>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { if (-not $script:MnInfoLoaded) { Load-MnInfo }; Start-MnLoop; Build-MnStatic }
    OnLang = { if ($script:MnBuilt) { $script:MnBuilt = $false; Build-MnStatic } }
}

# ---------------- statik bilgiler (sayfa ilk acildiginda arka planda okunur; acilisi yavaslatmaz) ----------------
$script:MnInfo = @{ CpuName = ""; Cores = 0; Threads = [Environment]::ProcessorCount; GpuName = ""; Vram = 0; RamMhz = 0; RamDesc = ""; Fans = 0; Nvidia = $false; DiskNames = @{} }
$script:MnInfoLoaded = $false
function Load-MnInfo {
    if ($script:MnInfoLoading) { return }
    $script:MnInfoLoading = $true
    Start-Bg -Work {
        $cpu0 = Get-CimInstance Win32_Processor | Select-Object -First 1
        $vram = 0; $gpuName = ""
        foreach ($k in Get-ChildItem "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue) {
            $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
            if ($p.DriverDesc -and $p."HardwareInformation.qwMemorySize" -gt $vram) { $vram = [double]$p."HardwareInformation.qwMemorySize"; $gpuName = $p.DriverDesc }
        }
        $mods = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue)
        $names = @{}; foreach ($pd in @(Get-PhysicalDisk -ErrorAction SilentlyContinue)) { $names["$($pd.DeviceId)"] = "$($pd.FriendlyName)".Trim() }
        @{
            CpuName = "$($cpu0.Name)".Trim(); Cores = $cpu0.NumberOfCores; Threads = $cpu0.NumberOfLogicalProcessors
            GpuName = $gpuName; Vram = $vram; RamMhz = ($mods | Measure-Object ConfiguredClockSpeed -Maximum).Maximum
            RamCount = $mods.Count; RamCap = $(if ($mods.Count) { [double]$mods[0].Capacity } else { 0 }); RamMaker = $(if ($mods.Count) { "$($mods[0].Manufacturer)".Trim() } else { "" })
            Fans = @(Get-CimInstance Win32_Fan -ErrorAction SilentlyContinue).Count
            Nvidia = [bool](Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue)
            DiskNames = $names
        }
    } -Done {
        param($out, $err)
        $i0 = @($out) | Select-Object -Last 1
        if ($i0 -is [hashtable]) {
            $i0.RamDesc = "$($i0.RamCount) × $(Fmt-GB $i0.RamCap) · $($i0.RamMaker)"
            $script:MnInfo = $i0; $script:MnInfoLoaded = $true
            $MnSync.Nvidia = $i0.Nvidia
            $script:MnBuilt = $false; if ($script:Page -eq "Monitor") { Build-MnStatic }
        }
    }
}

# ---------------- arka plan olcum dongusu ----------------
$MnSync = [hashtable]::Synchronized(@{ Stop = $false; Active = $false; Running = $false; Stamp = $null })
$script:MnHist = @{ Cpu = New-Object System.Collections.ArrayList; Rx = New-Object System.Collections.ArrayList; Tx = New-Object System.Collections.ArrayList; Disk = @{} }

function Start-MnLoop {
    $MnSync.Active = $true
    if ($MnSync.Running) { return }
    $MnSync.Running = $true
    Start-Bg -Work {
        param($S)
        $n = 0
        while (-not $S.Stop) {
            if (-not $S.Active) { Start-Sleep -Milliseconds 1000; continue }
            try {
                $cpu = @(Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Property Name, PercentProcessorUtility, ProcessorFrequency, PercentProcessorPerformance)
                $t = $cpu | Where-Object Name -eq "_Total" | Select-Object -First 1
                $S.Cpu = [Math]::Min(100, [double]$t.PercentProcessorUtility)
                $S.Mhz = [double]$t.ProcessorFrequency * [double]$t.PercentProcessorPerformance / 100
                $S.Cores = @($cpu | Where-Object { $_.Name -match '^\d+,\d+$' } | Sort-Object { [int](($_.Name -split ',')[1]) } | ForEach-Object { [Math]::Min(100, [double]$_.PercentProcessorUtility) })
                $S.Disks = @(Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Property Name, DiskReadBytesPersec, DiskWriteBytesPersec, PercentIdleTime |
                    Where-Object Name -ne "_Total" | ForEach-Object { [pscustomobject]@{ Id = ($_.Name -split ' ')[0]; Letters = (($_.Name -split ' ', 2)[1]); Read = [double]$_.DiskReadBytesPersec; Write = [double]$_.DiskWriteBytesPersec; Active = [Math]::Max(0, 100 - [double]$_.PercentIdleTime) } })
                $net = @(Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface -Property BytesReceivedPersec, BytesSentPersec)
                $S.Rx = [double]($net | Measure-Object BytesReceivedPersec -Sum).Sum; $S.Tx = [double]($net | Measure-Object BytesSentPersec -Sum).Sum
                $eng = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -Property Name, UtilizationPercentage -ErrorAction SilentlyContinue | Where-Object Name -like "*engtype_3D")
                $S.Gpu = [Math]::Min(100, [double](($eng | Group-Object { ($_.Name -split '_phys')[0] -replace '^pid_\d+_', '' } | ForEach-Object { ($_.Group | Measure-Object UtilizationPercentage -Sum).Sum } | Measure-Object -Maximum).Maximum))
                $S.GpuMem = [double]((Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -Property DedicatedUsage -ErrorAction SilentlyContinue | Measure-Object DedicatedUsage -Maximum).Maximum)
                $tz = @(Get-CimInstance Win32_PerfFormattedData_Counters_ThermalZoneInformation -Property HighPrecisionTemperature -ErrorAction SilentlyContinue)
                $S.Acpi = if ($tz.Count) { (($tz | Measure-Object HighPrecisionTemperature -Maximum).Maximum / 10) - 273.15 } else { $null }
                if ($S.Nvidia -and $n % 2 -eq 0) {
                    $q = & nvidia-smi.exe --query-gpu=temperature.gpu,fan.speed,power.draw --format=csv,noheader,nounits 2>$null | Select-Object -First 1
                    if ($q) { $v = $q -split ',\s*'; $S.GpuTemp = [double]$v[0]; $S.GpuFan = $v[1]; $S.GpuPower = $v[2] }
                }
                if ($n % 10 -eq 0) {
                    $temps = @{}
                    foreach ($pd in @(Get-PhysicalDisk -ErrorAction SilentlyContinue)) {
                        $tv = $null; try { $tv = ($pd | Get-StorageReliabilityCounter -ErrorAction Stop).Temperature } catch {}
                        if (-not $tv -and "$($pd.BusType)" -eq "NVMe") { try { $h = [WoNvme]::Health([int]$pd.DeviceId); if ($h -and $h[0] -gt 0) { $tv = $h[0] } } catch {} }
                        if ($tv) { $temps["$($pd.DeviceId)"] = [int]$tv }
                    }
                    $S.DiskTemps = $temps
                }
                $S.Stamp = Get-Date
            } catch { $S.Error = "$_" }
            $n++
            Start-Sleep -Milliseconds 1500
        }
        $S.Running = $false
    } -ArgList @(, $MnSync)
}
$window.Add_Closed({ $MnSync.Stop = $true })

# ---------------- halka gosterge ----------------
function New-MnRing([string]$Color) {
    $g = New-Object Windows.Controls.Grid; $g.Width = 104; $g.Height = 104
    $tr = New-Object Windows.Shapes.Ellipse; $tr.Stroke = Brush "#23233A"; $tr.StrokeThickness = 9
    $path = New-Object Windows.Shapes.Path; $path.Stroke = Brush $Color; $path.StrokeThickness = 9
    $path.StrokeStartLineCap = "Round"; $path.StrokeEndLineCap = "Round"
    $sp = New-Object Windows.Controls.StackPanel; $sp.VerticalAlignment = "Center"; $sp.HorizontalAlignment = "Center"
    $v = New-Tb "0" 24 "#FFFFFF"; $v.FontWeight = [Windows.FontWeights]::Bold; $v.HorizontalAlignment = "Center"; $v.TextWrapping = "NoWrap"
    $u = New-Tb "%" 11 "#7A7A94"; $u.HorizontalAlignment = "Center"
    [void]$sp.Children.Add($v); [void]$sp.Children.Add($u)
    [void]$g.Children.Add($tr); [void]$g.Children.Add($path); [void]$g.Children.Add($sp)
    return @{ Root = $g; Path = $path; Val = $v; Unit = $u }
}
function Set-MnRing($R, [double]$Pct) {
    $p = [Math]::Max(0, [Math]::Min(99.9, $Pct)); $rad = 47.5; $cx = 52; $cy = 52
    $a0 = -[Math]::PI / 2; $a1 = $a0 + 2 * [Math]::PI * $p / 100
    $fig = New-Object Windows.Media.PathFigure
    $fig.StartPoint = New-Object Windows.Point(($cx + $rad * [Math]::Cos($a0)), ($cy + $rad * [Math]::Sin($a0)))
    $arc = New-Object Windows.Media.ArcSegment
    $arc.Point = New-Object Windows.Point(($cx + $rad * [Math]::Cos($a1)), ($cy + $rad * [Math]::Sin($a1)))
    $arc.Size = New-Object Windows.Size($rad, $rad); $arc.IsLargeArc = ($p -gt 50); $arc.SweepDirection = "Clockwise"
    [void]$fig.Segments.Add($arc)
    $geo = New-Object Windows.Media.PathGeometry; [void]$geo.Figures.Add($fig)
    $R.Path.Data = $geo
    $R.Val.Text = "{0:N0}" -f $Pct
    $R.Path.Stroke = Brush $(if ($Pct -ge 90) { "#F87171" } elseif ($Pct -ge 70) { "#FBBF24" } else { $R.Color })
}

$script:MnBuilt = $false; $script:MnRings = @{}; $script:MnCoreFills = @(); $script:MnDiskRows = @{}
function Build-MnStatic {
    if ($script:MnBuilt) { return }
    $script:MnBuilt = $true
    $grid = N "MnGauges"; $grid.Children.Clear()
    foreach ($k in @(@("Cpu", "MnCpu", "#8B5CF6"), @("Gpu", "MnGpu", "#F472B6"), @("Ram", "MnRam", "#38BDF8"), @("Disk", "MnDisk", "#34D399"))) {
        $card = New-Object Windows.Controls.Border; $card.Style = $window.FindResource("Card"); $card.Margin = New-Object Windows.Thickness(0, 0, 12, 0); $card.Padding = New-Object Windows.Thickness(16)
        $sp = New-Object Windows.Controls.StackPanel
        $t = New-Tb (T $k[1]) 13 "#B4B4CC"; $t.HorizontalAlignment = "Center"; [void]$sp.Children.Add($t)
        $ring = New-MnRing $k[2]; $ring.Color = $k[2]; $ring.Root.Margin = New-Object Windows.Thickness(0, 12, 0, 12); [void]$sp.Children.Add($ring.Root)
        $sub = New-Tb "" 11 "#7A7A94"; $sub.HorizontalAlignment = "Center"; $sub.TextAlignment = "Center"; $sub.TextWrapping = "NoWrap"; $sub.TextTrimming = "CharacterEllipsis"
        $sub2 = New-Tb "" 10.5 "#5E5E7A"; $sub2.HorizontalAlignment = "Center"; $sub2.TextWrapping = "NoWrap"; $sub2.TextTrimming = "CharacterEllipsis"
        [void]$sp.Children.Add($sub); [void]$sp.Children.Add($sub2)
        $ring.Sub = $sub; $ring.Sub2 = $sub2
        $card.Child = $sp; [void]$grid.Children.Add($card)
        $script:MnRings[$k[0]] = $ring
        Set-MnRing $ring 0
    }
    $script:MnRings.Cpu.Sub2.Text = $script:MnInfo.CpuName; $script:MnRings.Gpu.Sub2.Text = $script:MnInfo.GpuName; $script:MnRings.Ram.Sub2.Text = $script:MnInfo.RamDesc
    # cekirdek cubuklari
    $cb = N "MnCoreBars"; $cb.Children.Clear(); $script:MnCoreFills = @()
    for ($i = 0; $i -lt [Math]::Max(1, [int]$script:MnInfo.Threads); $i++) {
        $col = New-Object Windows.Controls.Grid; $col.Margin = New-Object Windows.Thickness(2, 0, 2, 0)
        $rd1 = New-Object Windows.Controls.RowDefinition; $rd1.Height = New-Object Windows.GridLength(1, "Star"); $rd2 = New-Object Windows.Controls.RowDefinition; $rd2.Height = [Windows.GridLength]::Auto
        $col.RowDefinitions.Add($rd1); $col.RowDefinitions.Add($rd2)
        $track = New-Object Windows.Controls.Border; $track.CornerRadius = New-Object Windows.CornerRadius(4); $track.Background = Brush "#1C1C2E"
        $fill = New-Object Windows.Controls.Border; $fill.CornerRadius = New-Object Windows.CornerRadius(4); $fill.VerticalAlignment = "Bottom"; $fill.Height = 0
        $fill.Background = $window.FindResource("AccentGrad"); $track.Child = $fill
        $lb = New-Tb "$i" 10 "#6A6A86"; $lb.HorizontalAlignment = "Center"; $lb.Margin = New-Object Windows.Thickness(0, 4, 0, 0)
        [Windows.Controls.Grid]::SetRow($lb, 1)
        [void]$col.Children.Add($track); [void]$col.Children.Add($lb)
        [void]$cb.Children.Add($col)
        $script:MnCoreFills += $fill
    }
    (N "MnDownL").Text = T "MnDown"; (N "MnUpL").Text = T "MnUp"
    $script:MnDiskRows = @{}; (N "MnDiskList").Children.Clear()
    Update-MnLive
}

function Add-MnSensor($List, [string]$Name, [string]$Value, [string]$Color, [string]$Tip) {
    $g = New-Object Windows.Controls.Grid; $g.Margin = New-Object Windows.Thickness(0, 0, 0, 10); New-Cols $g @("*", "Auto")
    $l = New-Tb $Name 12.5 "#B4B4CC"; $l.TextWrapping = "NoWrap"; $l.TextTrimming = "CharacterEllipsis"
    $v = New-Tb $Value 13 $Color; $v.FontWeight = [Windows.FontWeights]::SemiBold; $v.Margin = New-Object Windows.Thickness(12, 0, 0, 0)
    if ($Tip) { $g.ToolTip = $Tip; $l.Text = "$Name  ⓘ" }
    [Windows.Controls.Grid]::SetColumn($v, 1)
    [void]$g.Children.Add($l); [void]$g.Children.Add($v); [void]$List.Children.Add($g)
}

function Format-MnRate([double]$Bps) { if ($Bps -ge 1MB) { "{0:N1} MB/s" -f ($Bps / 1MB) } elseif ($Bps -ge 1KB) { "{0:N0} KB/s" -f ($Bps / 1KB) } else { "0 KB/s" } }
function Temp-Color([double]$C, [double]$Warn, [double]$Hot) { if ($C -ge $Hot) { "#F87171" } elseif ($C -ge $Warn) { "#FBBF24" } else { "#34D399" } }

function Update-MnLive {
    if (-not $script:MnBuilt) { return }
    $S = $MnSync; $info = $script:MnInfo
    # CPU
    $cpu = [double]$S.Cpu; Set-MnRing $script:MnRings.Cpu $cpu
    $script:MnRings.Cpu.Sub.Text = (T "MnCpuSub") -f ([double]$S.Mhz / 1000), $info.Cores, $info.Threads
    $cores = @($S.Cores)
    for ($i = 0; $i -lt $script:MnCoreFills.Count; $i++) {
        $v = if ($i -lt $cores.Count) { [double]$cores[$i] } else { 0 }
        $script:MnCoreFills[$i].Height = [Math]::Max(2, 112 * $v / 100)
        $script:MnCoreFills[$i].ToolTip = "#$i · {0:N0}%" -f $v
    }
    # GPU
    Set-MnRing $script:MnRings.Gpu ([double]$S.Gpu)
    $script:MnRings.Gpu.Sub.Text = (T "MnGpuSub") -f (Fmt-GB ([double]$S.GpuMem)), (Fmt-GB $info.Vram)
    # RAM
    $m = $script:LastMem
    if ($m) {
        Set-MnRing $script:MnRings.Ram ([double]$m.Load)
        $script:MnRings.Ram.Sub.Text = (T "MnRamSub") -f (Fmt-GB ($m.Total - $m.Avail)), (Fmt-GB $m.Total), $info.RamMhz
    }
    # Diskler
    $disks = @($S.Disks)
    $busy = $disks | Sort-Object Active -Descending | Select-Object -First 1
    if ($busy) {
        Set-MnRing $script:MnRings.Disk ([double]$busy.Active)
        $script:MnRings.Disk.Sub.Text = (T "MnDiskSub") -f $(if ($busy.Letters) { $busy.Letters } else { "#$($busy.Id)" })
    }
    $dl = N "MnDiskList"
    foreach ($d in ($disks | Sort-Object { [int]$_.Id })) {
        $key = "$($d.Id)"
        if (-not $script:MnHist.Disk[$key]) { $script:MnHist.Disk[$key] = New-Object System.Collections.ArrayList }
        Push-Hist $script:MnHist.Disk[$key] ([double]($d.Read + $d.Write)) 60
        $row = $script:MnDiskRows[$key]
        if (-not $row) {
            $g = New-Object Windows.Controls.Grid; $g.Margin = New-Object Windows.Thickness(0, 0, 0, 14); New-Cols $g @("*", 150)
            $sp = New-Object Windows.Controls.StackPanel
            $nm = New-Tb "" 12.5 "#EDEDF5"; $nm.TextWrapping = "NoWrap"; $nm.TextTrimming = "CharacterEllipsis"; $nm.FontWeight = [Windows.FontWeights]::SemiBold
            $rw = New-Tb "" 11.5 "#9C9CB8"; $rw.TextWrapping = "NoWrap"
            [void]$sp.Children.Add($nm); [void]$sp.Children.Add($rw)
            $cv = New-Object Windows.Controls.Canvas; $cv.Height = 34; $cv.ClipToBounds = $true; $cv.Margin = New-Object Windows.Thickness(10, 0, 0, 0)
            [Windows.Controls.Grid]::SetColumn($cv, 1)
            [void]$g.Children.Add($sp); [void]$g.Children.Add($cv); [void]$dl.Children.Add($g)
            $row = @{ Name = $nm; Rw = $rw; Spark = $cv }; $script:MnDiskRows[$key] = $row
        }
        $dn = $info.DiskNames[$key]; if (-not $dn) { $dn = "Disk $key" }
        $row.Name.Text = "$($d.Letters)  ·  $dn"
        $row.Rw.Text = "$(T 'MnRead') $(Format-MnRate $d.Read)  ·  $(T 'MnWrite') $(Format-MnRate $d.Write)  ·  $((T 'MnActive') -f [int]$d.Active)"
        $mx = [Math]::Max(1MB, ($script:MnHist.Disk[$key] | Measure-Object -Maximum).Maximum)
        Draw-Spark $row.Spark $script:MnHist.Disk[$key] $mx "#34D399"
    }
    # Ag
    Push-Hist $script:MnHist.Rx ([double]$S.Rx) 60; Push-Hist $script:MnHist.Tx ([double]$S.Tx) 60
    (N "MnDownV").Text = Format-MnRate ([double]$S.Rx); (N "MnUpV").Text = Format-MnRate ([double]$S.Tx)
    $nmx = [Math]::Max(64KB, (@($script:MnHist.Rx) + @($script:MnHist.Tx) | Measure-Object -Maximum).Maximum)
    Draw-Spark (N "MnNetSpark") $script:MnHist.Rx $nmx "#38BDF8"
    # Sensorler
    $sl = N "MnSensorList"; $sl.Children.Clear()
    if ($null -ne $S.Acpi) { Add-MnSensor $sl (T "MnSenAcpi") ("{0:N0} °C" -f $S.Acpi) (Temp-Color $S.Acpi 60 80) $null }
    $temps = $S.DiskTemps
    if ($temps) { foreach ($k in ($temps.Keys | Sort-Object { [int]$_ })) { $dn = $info.DiskNames[$k]; Add-MnSensor $sl ((T "MnSenDisk") -f $dn) ("$($temps[$k]) °C") (Temp-Color $temps[$k] 50 60) $null } }
    if ($null -ne $S.GpuTemp) { Add-MnSensor $sl (T "MnSenGpuTemp") ("{0:N0} °C" -f $S.GpuTemp) (Temp-Color $S.GpuTemp 75 85) $null }
    else { Add-MnSensor $sl (T "MnSenGpuTemp") (T "MnNotSupported") "#6A6A86" (T "MnWhyGpu") }
    Add-MnSensor $sl (T "MnSenCpuCore") (T "MnNotSupported") "#6A6A86" (T "MnWhyCore")
    Add-MnSensor $sl (T "MnSenRamTemp") (T "MnNotSupported") "#6A6A86" (T "MnWhyRam")
    Add-MnSensor $sl (T "MnSenFan") $(if ($info.Fans) { (T "MnFansFound") -f $info.Fans } else { T "MnNotSupported" }) "#6A6A86" (T "MnWhyFan")
}

$mnTimer = New-Object Windows.Threading.DispatcherTimer
$mnTimer.Interval = [TimeSpan]::FromMilliseconds(1500)
$mnTimer.Add_Tick({
    $vis = ($script:Page -eq "Monitor") -and $window.IsVisible
    $MnSync.Active = $vis
    if ($vis -and $MnSync.Stamp) { try { Update-MnLive } catch { Write-WoLog "Performans: $_ (satir $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim()))" } }
})
$mnTimer.Start()

# ---------------- tek tikla optimizasyon ----------------
(N "BtnMnOptimize").Add_Click({
    if ($script:GlobalBusy) { return }
    if (-not (Show-WoDialog -Title (T "MnConfirmTitle") -Message (T "MnConfirmMsg") -Kind "info" -Ok (T "BtnMnOptimize") -Cancel (T "DlgCancel"))) { return }
    Set-GlobalBusy $true
    (N "BtnMnOptimize").IsEnabled = $false; (N "BtnMnOptimize").Content = T "MnOptimizing"
    Set-Status (T "MnOptimizing") "busy"
    Start-Bg -Work {
        param($Mods, $DiskMod)
        foreach ($m in $Mods) { . $m }
        . $DiskMod
        $before = [WoNative]::GetMemInfo()
        $freed = 0.0
        foreach ($r in (Invoke-WoDiskClean @("UserTemp", "WinTemp"))) { $freed += [double]$r.Freed }
        [void][WoNative]::EnablePrivilege("SeProfileSingleProcessPrivilege"); [void][WoNative]::EnablePrivilege("SeIncreaseQuotaPrivilege")
        [void][WoNative]::MemCommand(2); [void][WoNative]::MemCommand(3); [void][WoNative]::MemCommand(4)
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        $plan = $false
        $t = Get-WoTweak "PowerPlan"
        if ($t -and -not (Test-WoTweak $t)) { try { Invoke-WoTweak $t; $plan = $true } catch {} }
        Start-Sleep -Milliseconds 300
        [pscustomobject]@{ Ram = [Math]::Max([double]0, [double]([WoNative]::GetMemInfo().Avail) - [double]$before.Avail); Disk = $freed; Plan = $plan }
    } -ArgList @($ModPaths, (Join-Path $AppDir "modules\DiskCleaner.ps1")) -Done {
        param($out, $err)
        Set-GlobalBusy $false
        (N "BtnMnOptimize").IsEnabled = $true; (N "BtnMnOptimize").Content = T "BtnMnOptimize"
        $r = @($out) | Select-Object -Last 1
        if ($err -or -not $r) { Set-Status "$err" "err"; return }
        $txt = (T "MnResult") -f (Get-Date -Format "HH:mm"), (Fmt-GB $r.Ram), (Fmt-Size $r.Disk), $(if ($r.Plan) { T "MnPlanUlt" } else { T "MnPlanSame" })
        (N "MnLastResult").Text = $txt; (N "MnLastResult").Visibility = "Visible"
        Set-Status $txt "ok"
        Refresh-TweakStates; Sync-TweakSwitches; Update-TweakSummary
    }
})
