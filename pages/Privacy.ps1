# pages/Privacy.ps1 - Gizlilik raporu: hangi uygulama kamera / mikrofon / konum / ekran yakalamaya ne zaman eristi
# Kaynak: Windows'un kendi kaydi (CapabilityAccessManager\ConsentStore, LastUsedTimeStart/Stop). Canli yenilenir.

Add-WoStrings @{
    NavPrivacy = "Gizlilik Raporu"; Title_Privacy = "Gizlilik Raporu"; Sub_Privacy = "Kameranıza, mikrofonunuza ve konumunuza hangi uygulama ne zaman erişti"
    PvCap_webcam = "Kamera"; PvCap_microphone = "Mikrofon"; PvCap_location = "Konum"; PvCap_graphicsCaptureProgrammatic = "Ekran yakalama"
    PvPartial = "Kısmen açık"; PvLevels = "Cihaz: {0} · Uygulamalar: {1} · Masaüstü: {2}"; PvOn = "açık"; PvOff = "kapalı"
    PvAllowed = "İzin açık"; PvDenied = "İzin kapalı"; PvInUse = "ŞU AN KULLANILIYOR"; PvApps7 = "Son 7 günde {0} uygulama"; PvNever = "Hiç erişim kaydı yok"
    PvOpenSettings = "Windows ayarları"; PvHistory = "Erişim geçmişi"; PvAll = "Tümü ({0})"; PvEmpty = "Bu filtrede erişim kaydı yok."
    PvNow = "Şu an kullanıyor"; PvJustNow = "az önce"; PvMin = "{0} dk önce"; PvHour = "{0} sa önce"; PvDay = "{0} gün önce"; PvDur = "{0} süre"; PvUnitH = "{0} sa {1} dk"; PvUnitM = "{0} dk"; PvUnitS = "{0} sn"
    PvNote = "Bu kayıtları Windows tutar; Windows Optimizer yalnızca okur. İzinleri kapatmak için Optimizasyonlar → Gizlilik İzinleri bölümünü kullanabilirsiniz."
} @{
    NavPrivacy = "Privacy Report"; Title_Privacy = "Privacy Report"; Sub_Privacy = "Which app accessed your camera, microphone and location, and when"
    PvCap_webcam = "Camera"; PvCap_microphone = "Microphone"; PvCap_location = "Location"; PvCap_graphicsCaptureProgrammatic = "Screen capture"
    PvPartial = "Partly allowed"; PvLevels = "Device: {0} · Apps: {1} · Desktop: {2}"; PvOn = "on"; PvOff = "off"
    PvAllowed = "Allowed"; PvDenied = "Blocked"; PvInUse = "IN USE NOW"; PvApps7 = "{0} apps in the last 7 days"; PvNever = "No access recorded"
    PvOpenSettings = "Windows settings"; PvHistory = "Access history"; PvAll = "All ({0})"; PvEmpty = "No access records in this filter."
    PvNow = "In use now"; PvJustNow = "just now"; PvMin = "{0} min ago"; PvHour = "{0} h ago"; PvDay = "{0} days ago"; PvDur = "{0} duration"; PvUnitH = "{0} h {1} min"; PvUnitM = "{0} min"; PvUnitS = "{0} s"
    PvNote = "Windows keeps these records; Windows Optimizer only reads them. To block access use Optimizations → Privacy Permissions."
}

Register-WoPage @{
    Name = "Privacy"; Icon = 0xE8D7
    Loc = @("PvHistory", "PvNote")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PagePrivacy">
  <StackPanel Margin="0,0,14,20">
    <UniformGrid x:Name="PvCards" Columns="4"/>
    <Border Style="{DynamicResource Card}" Padding="0" Margin="0,16,0,0">
      <StackPanel>
        <Grid Margin="20,16,20,12">
          <TextBlock x:Name="PvHistory" Style="{DynamicResource CardTitle}" VerticalAlignment="Center"/>
          <WrapPanel x:Name="PvFilters" HorizontalAlignment="Right"/>
        </Grid>
        <StackPanel x:Name="PvList"/>
      </StackPanel>
    </Border>
    <Border Background="#171726" CornerRadius="8" Padding="12,10" Margin="0,12,0,0">
      <TextBlock x:Name="PvNote" Style="{DynamicResource Desc}" FontSize="11"/>
    </Border>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { Load-Privacy }
    OnLang = { if ($script:PvData) { Build-Privacy } }
}

$PvCaps = @("webcam", "microphone", "location", "graphicsCaptureProgrammatic")
$PvIcons = @{ webcam = 0xE714; microphone = 0xE720; location = 0xE81D; graphicsCaptureProgrammatic = 0xE7F4 }
$PvColors = @{ webcam = "#F472B6"; microphone = "#38BDF8"; location = "#34D399"; graphicsCaptureProgrammatic = "#F59E0B" }
$PvSettingsUri = @{ webcam = "ms-settings:privacy-webcam"; microphone = "ms-settings:privacy-microphone"; location = "ms-settings:privacy-location"; graphicsCaptureProgrammatic = "ms-settings:privacy-graphicscaptureprogrammatic" }
$script:PvData = $null; $script:PvFilter = "all"; $script:PvMeta = @{}

function Get-WoPrivacyData {
    $out = @{ Status = @{}; Events = New-Object System.Collections.ArrayList }
    foreach ($hive in @("HKCU", "HKLM")) {
        $base = "$($hive):\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
        foreach ($cap in $PvCaps) {
            $k = Join-Path $base $cap
            if (-not (Test-Path $k)) { continue }
            if (-not $out.Status[$cap]) { $out.Status[$cap] = @{ Device = "Allow"; User = "Allow"; Desktop = "Allow" } }
            $val = $null; try { $val = (Get-ItemProperty $k -Name Value -ErrorAction Stop).Value } catch {}
            if ($val) { if ($hive -eq "HKLM") { $out.Status[$cap].Device = "$val" } else { $out.Status[$cap].User = "$val" } }
            if ($hive -eq "HKCU") { try { $np = (Get-ItemProperty (Join-Path $k "NonPackaged") -Name Value -ErrorAction Stop).Value; if ($np) { $out.Status[$cap].Desktop = "$np" } } catch {} }
            foreach ($sub in @(Get-ChildItem $k -Recurse -ErrorAction SilentlyContinue)) {
                $st = $sub.GetValue("LastUsedTimeStart"); if (-not $st) { continue }
                $sp = $sub.GetValue("LastUsedTimeStop")
                $nonPkg = $sub.PSParentPath -like "*NonPackaged"
                $id = $sub.PSChildName
                [void]$out.Events.Add([pscustomobject]@{
                    Cap = $cap; Id = $id; Packaged = -not $nonPkg
                    Path = $(if ($nonPkg) { $id -replace '#', '\' } else { "" })
                    Start = [DateTime]::FromFileTime([int64]$st); Stop = $(if ($sp -and [int64]$sp -gt 0) { [DateTime]::FromFileTime([int64]$sp) } else { $null })
                    Active = (-not $sp -or [int64]$sp -eq 0)
                })
            }
        }
    }
    return $out
}

function Get-PvAppName($e) {
    if ($script:PvMeta.ContainsKey($e.Id)) { return $script:PvMeta[$e.Id] }
    $n = $e.Id
    if ($e.Packaged) { $n = (($e.Id -split '_')[0] -split '\.')[-1] -creplace '([a-z])([A-Z])', '$1 $2' }
    elseif (Test-Path -LiteralPath $e.Path) {
        try { $d = "$((Get-Item -LiteralPath $e.Path).VersionInfo.FileDescription)".Trim(); if ($d) { $n = $d } else { $n = [IO.Path]::GetFileNameWithoutExtension($e.Path) } } catch {}
    } else { $n = [IO.Path]::GetFileNameWithoutExtension($e.Path) }
    $script:PvMeta[$e.Id] = $n
    return $n
}

function Format-PvAgo($e) {
    if ($e.Active) { return T "PvNow" }
    $m = ((Get-Date) - $e.Stop).TotalMinutes
    if ($m -lt 1) { return T "PvJustNow" }
    if ($m -lt 60) { return (T "PvMin") -f [int]$m }
    if ($m -lt 1440) { return (T "PvHour") -f [int]($m / 60) }
    return (T "PvDay") -f [int]($m / 1440)
}

function Load-Privacy {
    try { $script:PvData = Get-WoPrivacyData } catch { Write-WoLog "Gizlilik raporu: $_"; return }
    Build-Privacy
}

function Build-Privacy {
    $d = $script:PvData
    $cards = N "PvCards"; $cards.Children.Clear(); $cards.Margin = New-Object Windows.Thickness(0, 0, -12, 0)
    $iconFont = $window.FindResource("Icons"); $sec = $window.FindResource("SecondaryBtn")
    $weekAgo = (Get-Date).AddDays(-7)
    foreach ($cap in $PvCaps) {
        $ev = @($d.Events | Where-Object Cap -eq $cap)
        $active = @($ev | Where-Object Active)
        $recent = @($ev | Where-Object { $_.Active -or $_.Stop -gt $weekAgo } | ForEach-Object Id | Select-Object -Unique)
        $card = New-Object Windows.Controls.Border; $card.Style = $window.FindResource("Card"); $card.Margin = New-Object Windows.Thickness(0, 0, 12, 0); $card.Padding = New-Object Windows.Thickness(16, 14, 16, 14)
        if ($active.Count) { $card.BorderBrush = Brush "#F87171" }
        $sp = New-Object Windows.Controls.StackPanel
        $h = New-Object Windows.Controls.StackPanel; $h.Orientation = "Horizontal"
        $ib = New-Object Windows.Controls.Border; $ib.Width = 30; $ib.Height = 30; $ib.CornerRadius = New-Object Windows.CornerRadius(8); $ib.Background = Brush "#1C1C2E"
        $ic = New-Tb ([string][char]$PvIcons[$cap]) 14 $PvColors[$cap]; $ic.FontFamily = $iconFont; $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"; $ib.Child = $ic
        $t = New-Tb (T "PvCap_$cap") 13.5 "#EDEDF5"; $t.FontWeight = [Windows.FontWeights]::SemiBold; $t.VerticalAlignment = "Center"; $t.Margin = New-Object Windows.Thickness(10, 0, 0, 0)
        [void]$h.Children.Add($ib); [void]$h.Children.Add($t); [void]$sp.Children.Add($h)
        $st = $d.Status[$cap]; if (-not $st) { $st = @{ Device = "Allow"; User = "Allow"; Desktop = "Allow" } }
        $blocked = ($st.Device -eq "Deny") -or ($st.User -eq "Deny" -and $st.Desktop -eq "Deny")
        $partial = (-not $blocked) -and (($st.User -eq "Deny") -or ($st.Desktop -eq "Deny"))
        $allowed = -not $blocked
        $badgeRow = New-Object Windows.Controls.WrapPanel; $badgeRow.Margin = New-Object Windows.Thickness(-8, 10, 0, 0)
        [void]$badgeRow.Children.Add($(if ($blocked) { New-Badge (T "PvDenied") "#12302A" "#6EE7B7" } elseif ($partial) { New-Badge (T "PvPartial") "#3A2E10" "#FCD34D" } else { New-Badge (T "PvAllowed") "#1E2A44" "#7DD3FC" }))
        if ($active.Count) { [void]$badgeRow.Children.Add((New-Badge ("● " + (T "PvInUse")) "#3A1520" "#FCA5A5")) }
        [void]$sp.Children.Add($badgeRow)
        $sub = if ($ev.Count -eq 0) { T "PvNever" } else { (T "PvApps7") -f $recent.Count }
        $lvl = { param($v) if ($v -eq "Deny") { T "PvOff" } else { T "PvOn" } }
        $lv = New-Tb ((T "PvLevels") -f (& $lvl $st.Device), (& $lvl $st.User), (& $lvl $st.Desktop)) 10.5 "#6A6A86"
        $lv.Margin = New-Object Windows.Thickness(0, 8, 0, 0); $lv.TextWrapping = "Wrap"; [void]$sp.Children.Add($lv)
        $sb = New-Tb $sub 11.5 "#9C9CB8"; $sb.Margin = New-Object Windows.Thickness(0, 6, 0, 10); [void]$sp.Children.Add($sb)
        $b = New-Object Windows.Controls.Button; $b.Style = $sec; $b.Height = 30; $b.FontSize = 11.5; $b.Content = T "PvOpenSettings"; $b.Tag = $PvSettingsUri[$cap]
        $b.Add_Click({ param($s) Start-Process $s.Tag })
        [void]$sp.Children.Add($b)
        $card.Child = $sp
        [void]$cards.Children.Add($card)
    }
    # Filtreler
    $fp = N "PvFilters"; $fp.Children.Clear(); $seg = $window.FindResource("SegBtn")
    foreach ($f in @("all") + $PvCaps) {
        $cnt = if ($f -eq "all") { $d.Events.Count } else { @($d.Events | Where-Object Cap -eq $f).Count }
        $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $seg; $rb.GroupName = "pvf"; $rb.Tag = $f; $rb.FontSize = 11.5
        $rb.Content = if ($f -eq "all") { (T "PvAll") -f $cnt } else { "$(T "PvCap_$f") ($cnt)" }
        $rb.IsChecked = ($f -eq $script:PvFilter)
        $rb.Add_Checked({ param($s) $script:PvFilter = $s.Tag; Build-PvList })
        [void]$fp.Children.Add($rb)
    }
    Build-PvList
}

function Build-PvList {
    $list = N "PvList"; $list.Children.Clear()
    $ev = @($script:PvData.Events | Where-Object { $script:PvFilter -eq "all" -or $_.Cap -eq $script:PvFilter } |
            Sort-Object @{ e = { -not $_.Active } }, @{ e = { if ($_.Stop) { $_.Stop } else { [DateTime]::MaxValue } }; Descending = $true })
    if ($ev.Count -eq 0) { $e = New-Tb (T "PvEmpty") 12 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(20, 0, 20, 16); [void]$list.Children.Add($e); return }
    $iconFont = $window.FindResource("Icons")
    foreach ($e in ($ev | Select-Object -First 60)) {
        $row = New-Object Windows.Controls.Border; $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0); $row.Padding = New-Object Windows.Thickness(20, 10, 20, 10)
        if ($e.Active) { $row.Background = Brush "#22131A" }
        $g = New-Object Windows.Controls.Grid; New-Cols $g @(44, "*", "Auto")
        $ib = New-Object Windows.Controls.Border; $ib.Width = 32; $ib.Height = 32; $ib.CornerRadius = New-Object Windows.CornerRadius(8); $ib.Background = Brush "#1C1C2E"; $ib.HorizontalAlignment = "Left"
        $img = if ($e.Path) { Get-WoIcon $e.Path } else { $null }
        if ($img) { $im = New-Object Windows.Controls.Image; $im.Source = $img; $im.Width = 20; $im.Height = 20; $ib.Child = $im }
        else { $lt = New-Tb ([string][char]$PvIcons[$e.Cap]) 13 $PvColors[$e.Cap]; $lt.FontFamily = $iconFont; $lt.HorizontalAlignment = "Center"; $lt.VerticalAlignment = "Center"; $ib.Child = $lt }
        $tx = New-Object Windows.Controls.StackPanel; $tx.VerticalAlignment = "Center"
        $tr = New-Object Windows.Controls.WrapPanel
        $nm = New-Tb (Get-PvAppName $e) 13 "#EDEDF5"; [void]$tr.Children.Add($nm)
        $cb = New-Object Windows.Controls.Border; $cb.CornerRadius = New-Object Windows.CornerRadius(5); $cb.Padding = New-Object Windows.Thickness(6, 1, 6, 1); $cb.Margin = New-Object Windows.Thickness(8, 0, 0, 0); $cb.VerticalAlignment = "Center"
        $cc = [Windows.Media.ColorConverter]::ConvertFromString($PvColors[$e.Cap]); $cc.A = 40; $cb.Background = New-Object Windows.Media.SolidColorBrush($cc)
        $ct = New-Tb (T "PvCap_$($e.Cap)") 10 $PvColors[$e.Cap]; $ct.FontWeight = [Windows.FontWeights]::SemiBold; $cb.Child = $ct
        [void]$tr.Children.Add($cb)
        $pathTxt = if ($e.Path) { $e.Path } else { $e.Id }
        $pt = New-Tb $pathTxt 10.5 "#6A6A86"; $pt.TextWrapping = "NoWrap"; $pt.TextTrimming = "CharacterEllipsis"; $pt.Margin = New-Object Windows.Thickness(0, 2, 16, 0)
        [void]$tx.Children.Add($tr); [void]$tx.Children.Add($pt)
        $rt = New-Object Windows.Controls.StackPanel; $rt.VerticalAlignment = "Center"
        $ago = New-Tb (Format-PvAgo $e) 12 $(if ($e.Active) { "#F87171" } else { "#D4D4E4" }); $ago.HorizontalAlignment = "Right"; $ago.FontWeight = [Windows.FontWeights]::SemiBold
        [void]$rt.Children.Add($ago)
        if ($e.Stop -and $e.Stop -gt $e.Start) {
            $dur = $e.Stop - $e.Start
            $ds = if ($dur.TotalHours -ge 1) { (T "PvUnitH") -f [Math]::Floor($dur.TotalHours), $dur.Minutes } elseif ($dur.TotalMinutes -ge 1) { (T "PvUnitM") -f [Math]::Floor($dur.TotalMinutes) } else { (T "PvUnitS") -f [int][Math]::Max(1, $dur.TotalSeconds) }
            $dt = New-Tb ((T "PvDur") -f $ds) 10.5 "#6A6A86"; $dt.HorizontalAlignment = "Right"; [void]$rt.Children.Add($dt)
        }
        [Windows.Controls.Grid]::SetColumn($tx, 1); [Windows.Controls.Grid]::SetColumn($rt, 2)
        [void]$g.Children.Add($ib); [void]$g.Children.Add($tx); [void]$g.Children.Add($rt)
        $row.Child = $g
        [void]$list.Children.Add($row)
    }
}

# Sayfa acikken 5 sn'de bir canli yenile
$pvTimer = New-Object Windows.Threading.DispatcherTimer
$pvTimer.Interval = [TimeSpan]::FromSeconds(5)
$pvTimer.Add_Tick({ if ($script:Page -eq "Privacy" -and $window.IsVisible) { Load-Privacy } })
$pvTimer.Start()
