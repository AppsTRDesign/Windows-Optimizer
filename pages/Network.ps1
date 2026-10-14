# pages/Network.ps1 - Ag araclari: bagdastiricilar, DNS secici (gercek sorgu suresiyle), onarim araclari

Add-WoStrings @{
    NavNetwork = "Ağ"; Title_Network = "Ağ Araçları"; Sub_Network = "DNS hızını ölçün, en hızlısını seçin, bağlantı sorunlarını onarın"
    NwAdapters = "Bağlı ağ bağdaştırıcıları"; NwNone = "Bağlı bir ağ bağdaştırıcısı bulunamadı."
    NwIp = "IP adresi"; NwGw = "Ağ geçidi"; NwDns = "DNS"; NwMac = "MAC"; NwSpeed = "Hız"
    NwDnsTitle = "DNS Sunucusu"; NwDnsSub = "Sorgu süresi bu bilgisayardan gerçek DNS sorgusuyla ölçülür. Daha düşük = daha hızlı sayfa açılışı."
    BtnNwTest = "Hızı ölç"; BtnNwRestore = "Eskiye döndür"; NwTesting = "Ölçülüyor…"; NwUse = "Kullan"; NwInUse = "KULLANILIYOR"; NwFastest = "EN HIZLI"
    NwUnreach = "ulaşılamadı"; NwMs = "{0} ms"; NwApplied = "DNS {0} olarak ayarlandı ({1} bağdaştırıcı)"; NwFail = "DNS değiştirilemedi: {0}"
    NwRestored = "DNS ayarları eski haline döndürüldü"; NwCustom = "Özel DNS kullanılıyor: {0}"
    Dns_auto = "Otomatik (modem / DHCP)"; DnsD_auto = "İnternet sağlayıcınızın veya modeminizin DNS'i"
    DnsD_cloudflare = "Çok hızlı, gizlilik odaklı; sorgu kayıtları 24 saatte silinir"; DnsD_google = "Güvenilir ve yaygın"
    DnsD_quad9 = "Zararlı ve oltalama sitelerini engeller"; DnsD_adguard = "Reklam ve izleyicileri DNS düzeyinde engeller"
    DnsD_opendns = "Cisco tarafından işletilir, oltalama koruması"; DnsD_cffamily = "Zararlı yazılım ve yetişkin içeriği engeller"
    NwToolsTitle = "Onarım Araçları"
    NwFlushT = "DNS önbelleğini temizle"; NwFlushD = "Açılmayan siteler veya eski adres sorunları için"; NwFlushed = "DNS önbelleği temizlendi"
    NwRenewT = "IP adresini yenile"; NwRenewD = "Modemden yeni adres alır; bağlantı birkaç saniye kesilir"; NwRenewing = "IP adresi yenileniyor…"; NwRenewed = "IP adresi yenilendi"
    NwResetT = "Ağ ayarlarını sıfırla"; NwResetD = "Winsock ve TCP/IP yığınını sıfırlar; yeniden başlatma gerekir"
    NwResetTitle = "Ağ ayarları sıfırlansın mı?"; NwResetMsg = "Winsock kataloğu ve TCP/IP ayarları varsayılana döner. VPN ve proxy ayarlarının yeniden yapılması gerekebilir. İşlem sonrası bilgisayarı yeniden başlatmanız gerekir."
    NwResetOk = "Sıfırla"; NwResetDone = "Ağ ayarları sıfırlandı — bilgisayarı yeniden başlatın"
    BtnNwRun = "Çalıştır"
} @{
    NavNetwork = "Network"; Title_Network = "Network Tools"; Sub_Network = "Measure DNS speed, pick the fastest, fix connection problems"
    NwAdapters = "Connected network adapters"; NwNone = "No connected network adapter found."
    NwIp = "IP address"; NwGw = "Gateway"; NwDns = "DNS"; NwMac = "MAC"; NwSpeed = "Speed"
    NwDnsTitle = "DNS Server"; NwDnsSub = "Query time is measured with real DNS queries from this PC. Lower = faster page loads."
    BtnNwTest = "Measure"; BtnNwRestore = "Restore"; NwTesting = "Measuring…"; NwUse = "Use"; NwInUse = "IN USE"; NwFastest = "FASTEST"
    NwUnreach = "unreachable"; NwMs = "{0} ms"; NwApplied = "DNS set to {0} ({1} adapters)"; NwFail = "Could not change DNS: {0}"
    NwRestored = "DNS settings restored"; NwCustom = "Custom DNS in use: {0}"
    Dns_auto = "Automatic (router / DHCP)"; DnsD_auto = "Your ISP's or router's DNS"
    DnsD_cloudflare = "Very fast, privacy-focused; query logs deleted within 24 hours"; DnsD_google = "Reliable and widely used"
    DnsD_quad9 = "Blocks malicious and phishing sites"; DnsD_adguard = "Blocks ads and trackers at DNS level"
    DnsD_opendns = "Run by Cisco, phishing protection"; DnsD_cffamily = "Blocks malware and adult content"
    NwToolsTitle = "Repair Tools"
    NwFlushT = "Flush DNS cache"; NwFlushD = "For sites that won't open or stale addresses"; NwFlushed = "DNS cache flushed"
    NwRenewT = "Renew IP address"; NwRenewD = "Gets a new address from the router; connection drops for a few seconds"; NwRenewing = "Renewing IP address…"; NwRenewed = "IP address renewed"
    NwResetT = "Reset network settings"; NwResetD = "Resets Winsock and the TCP/IP stack; restart required"
    NwResetTitle = "Reset network settings?"; NwResetMsg = "The Winsock catalog and TCP/IP settings return to defaults. VPN and proxy settings may need to be set up again. You will need to restart the PC afterwards."
    NwResetOk = "Reset"; NwResetDone = "Network settings reset — restart the PC"
    BtnNwRun = "Run"
}

Register-WoPage @{
    Name = "Network"; Icon = 0xE968
    Loc = @("NwAdapters", "NwDnsTitle", "NwDnsSub", "BtnNwTest", "BtnNwRestore", "NwToolsTitle", "NwFlushT", "NwFlushD", "NwRenewT", "NwRenewD", "NwResetT", "NwResetD")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageNetwork">
  <StackPanel Margin="0,0,14,20">
    <TextBlock x:Name="NwAdapters" Style="{DynamicResource Caption}" Margin="4,0,0,8"/>
    <UniformGrid x:Name="NwAdapterList" Columns="2"/>
    <Grid Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="320"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}" Padding="0">
        <StackPanel>
          <Grid Margin="20,16,20,12">
            <StackPanel Margin="0,0,230,0">
              <TextBlock x:Name="NwDnsTitle" Style="{DynamicResource CardTitle}"/>
              <TextBlock x:Name="NwDnsSub" Style="{DynamicResource Desc}" Margin="0,3,0,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
              <Button x:Name="BtnNwRestore" Style="{DynamicResource SecondaryBtn}" Margin="0,0,8,0" Visibility="Collapsed"/>
              <Button x:Name="BtnNwTest" Style="{DynamicResource SecondaryBtn}"/>
            </StackPanel>
          </Grid>
          <StackPanel x:Name="NwDnsList"/>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}" VerticalAlignment="Top">
        <StackPanel>
          <TextBlock x:Name="NwToolsTitle" Style="{DynamicResource CardTitle}" Margin="0,0,0,14"/>
          <Button x:Name="BtnNwFlush" Style="{DynamicResource ActionBtn}">
            <StackPanel><TextBlock x:Name="NwFlushT" FontSize="13" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="NwFlushD" FontSize="11" Foreground="{DynamicResource Muted}" TextWrapping="Wrap"/></StackPanel>
          </Button>
          <Button x:Name="BtnNwRenew" Style="{DynamicResource ActionBtn}">
            <StackPanel><TextBlock x:Name="NwRenewT" FontSize="13" Foreground="{DynamicResource Txt}"/><TextBlock x:Name="NwRenewD" FontSize="11" Foreground="{DynamicResource Muted}" TextWrapping="Wrap"/></StackPanel>
          </Button>
          <Button x:Name="BtnNwReset" Style="{DynamicResource ActionBtn}">
            <StackPanel><TextBlock x:Name="NwResetT" FontSize="13" Foreground="#FCA5A5"/><TextBlock x:Name="NwResetD" FontSize="11" Foreground="{DynamicResource Muted}" TextWrapping="Wrap"/></StackPanel>
          </Button>
        </StackPanel>
      </Border>
    </Grid>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { if (-not $script:NetLoaded) { Load-Network $true } }
    OnLang = { if ($script:NetLoaded) { Build-NetAdapters; Build-DnsList } }
}

$script:NetLoaded = $false; $script:NetBusy = $false; $script:NetAdapters = @(); $script:DnsLat = @{}; $script:DnsTesting = $false
$NetMods = @((Join-Path $AppDir "modules\Network.ps1"))

function Load-Network([bool]$Measure) {
    if ($script:NetBusy) { return }
    $script:NetBusy = $true
    Start-Bg -Work { param($M) . $M; @(Get-WoNetAdapters) } -ArgList @($NetMods[0]) -Done {
        param($out, $err)
        $script:NetBusy = $false; $script:NetLoaded = $true
        if ($err) { Write-WoLog "Ag: $err" }
        $script:NetAdapters = @($out | Where-Object { $_ -and $_.Name })
        Build-NetAdapters; Build-DnsList
    }
    if ($Measure) { Start-DnsTest }
}

function Build-NetAdapters {
    $grid = N "NwAdapterList"; $grid.Children.Clear()
    $grid.Margin = New-Object Windows.Thickness(0, 0, -12, 0)
    if ($script:NetAdapters.Count -eq 0) { [void]$grid.Children.Add((New-Tb (T "NwNone") 12.5 "#7A7A94")); return }
    $grid.Columns = [Math]::Min(2, $script:NetAdapters.Count)
    $iconFont = $window.FindResource("Icons")
    foreach ($a in $script:NetAdapters) {
        $card = New-Object Windows.Controls.Border; $card.Style = $window.FindResource("Card"); $card.Margin = New-Object Windows.Thickness(0, 0, 12, 0)
        $sp = New-Object Windows.Controls.StackPanel
        $head = New-Object Windows.Controls.Grid; New-Cols $head @(44, "*")
        $ib = New-Object Windows.Controls.Border; $ib.Width = 34; $ib.Height = 34; $ib.CornerRadius = New-Object Windows.CornerRadius(9); $ib.Background = Brush "#1E2A44"; $ib.HorizontalAlignment = "Left"
        $ic = New-Tb ([string][char]$(if ($a.Wifi) { 0xE701 } else { 0xE839 })) 16 "#7DD3FC"; $ic.FontFamily = $iconFont; $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"; $ib.Child = $ic
        $hs = New-Object Windows.Controls.StackPanel; $hs.VerticalAlignment = "Center"
        $t = New-Tb $a.Name 14 "#EDEDF5"; $t.FontWeight = [Windows.FontWeights]::SemiBold
        $d = New-Tb $a.Desc 11 "#7A7A94"; $d.TextWrapping = "NoWrap"; $d.TextTrimming = "CharacterEllipsis"
        [void]$hs.Children.Add($t); [void]$hs.Children.Add($d); [Windows.Controls.Grid]::SetColumn($hs, 1)
        [void]$head.Children.Add($ib); [void]$head.Children.Add($hs)
        [void]$sp.Children.Add($head)
        $info = New-Object Windows.Controls.Grid; New-Cols $info @(90, "*"); $info.Margin = New-Object Windows.Thickness(0, 12, 0, 0)
        $r = 0
        foreach ($pair in @(@("NwIp", $a.IPv4), @("NwGw", $a.Gateway), @("NwDns", $a.Dns), @("NwSpeed", $a.Speed), @("NwMac", $a.Mac))) {
            $rd = New-Object Windows.Controls.RowDefinition; $rd.Height = New-Object Windows.GridLength(24); $info.RowDefinitions.Add($rd)
            $l = New-Tb (T $pair[0]) 11.5 "#7A7A94"; $v = New-Tb "$($pair[1])" 12 "#D4D4E4"; $v.TextWrapping = "NoWrap"; $v.TextTrimming = "CharacterEllipsis"
            [Windows.Controls.Grid]::SetRow($l, $r); [Windows.Controls.Grid]::SetRow($v, $r); [Windows.Controls.Grid]::SetColumn($v, 1)
            [void]$info.Children.Add($l); [void]$info.Children.Add($v); $r++
        }
        [void]$sp.Children.Add($info)
        $card.Child = $sp
        [void]$grid.Children.Add($card)
    }
}

function Get-CurrentDnsProvider {
    $p = @($script:NetAdapters | ForEach-Object Provider | Select-Object -Unique)
    if ($p.Count -eq 1) { return $p[0] } else { return "custom" }
}

function Build-DnsList {
    $list = N "NwDnsList"; $list.Children.Clear()
    $cur = Get-CurrentDnsProvider
    (N "BtnNwRestore").Visibility = if ((Get-WoNetBackupCount) -gt 0) { "Visible" } else { "Collapsed" }
    $vals = @($script:DnsLat.Values | Where-Object { $_ -gt 0 })
    $min = if ($vals.Count) { ($vals | Measure-Object -Minimum).Minimum } else { -1 }
    $max = if ($vals.Count) { [Math]::Max(1, ($vals | Measure-Object -Maximum).Maximum) } else { 1 }
    $sec = $window.FindResource("SecondaryBtn"); $slim = $window.FindResource("Slim")
    foreach ($k in $WoDnsProviders.Keys) {
        $row = New-Object Windows.Controls.Border
        $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0); $row.Padding = New-Object Windows.Thickness(20, 11, 20, 11)
        if ($k -eq $cur) { $row.Background = Brush "#161A2E" }
        $g = New-Object Windows.Controls.Grid; New-Cols $g @("*", 150, 110)
        $tx = New-Object Windows.Controls.StackPanel
        $tr = New-Object Windows.Controls.WrapPanel
        $nm = if ($k -eq "auto") { T "Dns_auto" } else { $WoDnsProviders[$k].Name }
        [void]$tr.Children.Add((New-Tb $nm 13.5 "#EDEDF5"))
        if ($k -eq $cur) { [void]$tr.Children.Add((New-Badge (T "NwInUse") "#12302A" "#6EE7B7")) }
        $lat = $script:DnsLat[$k]
        if ($lat -gt 0 -and $lat -eq $min) { [void]$tr.Children.Add((New-Badge (T "NwFastest") "#2A2350" "#C4B5FD")) }
        $sub = (T "DnsD_$k")
        if ($k -ne "auto") { $sub += "  ·  " + ($WoDnsProviders[$k].V4 -join ", ") }
        $sd = New-Tb $sub 11 "#7A7A94"; $sd.Margin = New-Object Windows.Thickness(0, 2, 12, 0)
        [void]$tx.Children.Add($tr); [void]$tx.Children.Add($sd)
        # gecikme
        $lp = New-Object Windows.Controls.StackPanel; $lp.VerticalAlignment = "Center"; $lp.Margin = New-Object Windows.Thickness(0, 0, 14, 0)
        $ltxt = if ($script:DnsTesting -and $null -eq $lat) { T "NwTesting" } elseif ($null -eq $lat) { "—" } elseif ($lat -lt 0) { T "NwUnreach" } else { (T "NwMs") -f $lat }
        $lcol = if ($lat -gt 0 -and $lat -eq $min) { "#34D399" } elseif ($lat -lt 0 -and $null -ne $lat) { "#F87171" } else { "#EDEDF5" }
        $lt = New-Tb $ltxt 12.5 $lcol; $lt.FontWeight = [Windows.FontWeights]::SemiBold; $lt.HorizontalAlignment = "Right"
        [void]$lp.Children.Add($lt)
        if ($lat -gt 0) {
            $pb = New-Object Windows.Controls.ProgressBar; $pb.Style = $slim; $pb.Maximum = 100; $pb.Value = [Math]::Max(4, 100 * $lat / $max); $pb.Height = 4; $pb.Margin = New-Object Windows.Thickness(0, 5, 0, 0)
            $pb.Foreground = Brush $(if ($lat -eq $min) { "#34D399" } elseif ($lat -lt 60) { "#8B5CF6" } else { "#F59E0B" })
            [void]$lp.Children.Add($pb)
        }
        $b = New-Object Windows.Controls.Button; $b.Style = $sec; $b.Height = 32; $b.Content = T "NwUse"; $b.Tag = $k
        $b.IsEnabled = ($k -ne $cur) -and -not $script:NetBusy -and $script:NetAdapters.Count -gt 0
        $b.Add_Click({ param($s) Set-DnsUi $s.Tag })
        [Windows.Controls.Grid]::SetColumn($lp, 1); [Windows.Controls.Grid]::SetColumn($b, 2)
        [void]$g.Children.Add($tx); [void]$g.Children.Add($lp); [void]$g.Children.Add($b)
        $row.Child = $g
        [void]$list.Children.Add($row)
    }
}

function Start-DnsTest {
    if ($script:DnsTesting) { return }
    $script:DnsTesting = $true; $script:DnsLat = @{}
    (N "BtnNwTest").IsEnabled = $false; (N "BtnNwTest").Content = T "NwTesting"
    Build-DnsList
    $targets = [ordered]@{}
    foreach ($k in $WoDnsProviders.Keys) { if ($k -ne "auto") { $targets[$k] = $WoDnsProviders[$k].V4[0] } }
    Start-Bg -Work {
        param($M, $Targets)
        . $M
        $res = @{}
        # Otomatik: bagdastiricinin DHCP'den aldigi ilk DNS
        $auto = @(Get-WoNetAdapters | Where-Object Provider -eq "auto" | ForEach-Object { ($_.Dns -split ', ')[0] } | Where-Object { $_ }) | Select-Object -First 1
        if ($auto) { $res["auto"] = Test-WoDnsLatency $auto }
        foreach ($k in $Targets.Keys) { $res[$k] = Test-WoDnsLatency $Targets[$k] }
        $res
    } -ArgList @($NetMods[0], $targets) -Done {
        param($out, $err)
        $script:DnsTesting = $false
        (N "BtnNwTest").IsEnabled = $true; (N "BtnNwTest").Content = T "BtnNwTest"
        $r = @($out) | Select-Object -Last 1
        if ($r -is [hashtable]) { $script:DnsLat = $r }
        Build-DnsList
    }
}

function Set-DnsUi([string]$Provider) {
    if ($script:NetBusy) { return }
    $script:NetBusy = $true; $script:NetPending = $Provider; Build-DnsList
    Set-Status (T "Applying") "busy"
    Start-Bg -Work { param($M, $P) . $M; Set-WoDns $P } -ArgList @($NetMods[0], $Provider) -Done {
        param($out, $err)
        $script:NetBusy = $false
        $Provider = $script:NetPending
        $name = if ($Provider -eq "auto") { T "Dns_auto" } else { $WoDnsProviders[$Provider].Name }
        if ($err) { Set-Status ((T "NwFail") -f $err) "err" } else { Set-Status ((T "NwApplied") -f $name, (@($out) | Select-Object -Last 1)) "ok" }
        Load-Network $false
    }
}

(N "BtnNwTest").Add_Click({ Start-DnsTest })
(N "BtnNwRestore").Add_Click({
    if ($script:NetBusy) { return }
    $script:NetBusy = $true
    Start-Bg -Work { param($M) . $M; Restore-WoNetwork } -ArgList @($NetMods[0]) -Done {
        param($out, $err)
        $script:NetBusy = $false
        if ($err) { Set-Status ((T "NwFail") -f $err) "err" } else { Set-Status (T "NwRestored") "ok" }
        Load-Network $false
    }
})
(N "BtnNwFlush").Add_Click({
    try { Clear-DnsClientCache -ErrorAction Stop; Set-Status (T "NwFlushed") "ok" } catch { Set-Status "$($_.Exception.Message)" "err" }
})
(N "BtnNwRenew").Add_Click({
    if ($script:NetBusy) { return }
    $script:NetBusy = $true
    Set-Status (T "NwRenewing") "busy"
    Start-Bg -Work { & ipconfig.exe /release | Out-Null; & ipconfig.exe /renew | Out-Null } -Done {
        param($out, $err)
        $script:NetBusy = $false
        Set-Status (T "NwRenewed") "ok"
        Load-Network $false
    }
})
(N "BtnNwReset").Add_Click({
    if (-not (Show-WoDialog -Title (T "NwResetTitle") -Message (T "NwResetMsg") -Kind "warn" -Ok (T "NwResetOk") -Cancel (T "DlgCancel") -Danger)) { return }
    Start-Bg -Work { & netsh.exe winsock reset | Out-Null; & netsh.exe int ip reset | Out-Null } -Done {
        param($out, $err)
        Set-Status (T "NwResetDone") "warn"
        Set-RestartNeed "reboot"
    }
})
