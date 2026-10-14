# pages/Health.ps1 - Sistem sagligi: disk SMART bilgileri, kararlilik ozeti, SFC/DISM onarimi (canli ilerleme)

Add-WoStrings @{
    NavHealth = "Sağlık"; Title_Health = "Sistem Sağlığı"; Sub_Health = "Disk sağlığı, kararlılık ve sistem dosyası onarımı"
    HlDisks = "Fiziksel diskler"; HlLoading = "Okunuyor…"; HlHealthy = "SAĞLIKLI"; HlWarning = "UYARI"; HlUnhealthy = "SORUNLU"; HlUnknown = "BİLİNMİYOR"
    HlTemp = "Sıcaklık"; HlWear = "Kullanılan ömür"; HlHours = "Çalışma süresi"; HlErrors = "Okuma hataları"; HlSize = "Kapasite"; HlNA = "—"
    HlHoursFmt = "{0:N0} saat"; HlWearFmt = "%{0}"
    HlStabTitle = "Kararlılık (son 30 gün)"; HlBsod = "Mavi ekran (BSOD)"; HlCrash = "Beklenmedik kapanma"; HlAppCrash = "Uygulama çökmesi"
    HlStabGood = "Sisteminiz kararlı görünüyor."; HlStabBad = "Kararsızlık belirtileri var; sürücüleri güncellemeyi ve aşağıdaki onarımı çalıştırmayı düşünün."
    HlRepairTitle = "Sistem dosyası onarımı"; HlRepairSub = "Bozuk Windows dosyalarını bulur ve onarır. Sırayla çalıştırılması önerilir: önce DISM, sonra SFC."
    HlDismT = "1. Windows görüntüsünü onar (DISM)"; HlDismD = "Bileşen deposunu Windows Update'ten indirilen temiz kopyalarla onarır · 5–20 dk"
    HlSfcT = "2. Sistem dosyalarını tara (SFC)"; HlSfcD = "Korunan sistem dosyalarını denetler ve onarır · 5–15 dk"
    HlCleanT = "Bileşen deposunu temizle (DISM)"; HlCleanD = "Eski güncelleme kalıntılarını kaldırır, birkaç GB yer açabilir · 5–15 dk"
    BtnHlRun = "Başlat"; BtnHlCancel = "Durdur"; HlRunning = "Çalışıyor…"; HlDone = "Tamamlandı"; HlFailed = "Hata (kod {0})"; HlCancelled = "Durduruldu"
    HlOutput = "Son çıktı"; HlBusy = "Başka bir onarım çalışıyor"
} @{
    NavHealth = "Health"; Title_Health = "System Health"; Sub_Health = "Disk health, stability and system file repair"
    HlDisks = "Physical disks"; HlLoading = "Reading…"; HlHealthy = "HEALTHY"; HlWarning = "WARNING"; HlUnhealthy = "UNHEALTHY"; HlUnknown = "UNKNOWN"
    HlTemp = "Temperature"; HlWear = "Life used"; HlHours = "Power-on time"; HlErrors = "Read errors"; HlSize = "Capacity"; HlNA = "—"
    HlHoursFmt = "{0:N0} hours"; HlWearFmt = "{0}%"
    HlStabTitle = "Stability (last 30 days)"; HlBsod = "Blue screens (BSOD)"; HlCrash = "Unexpected shutdowns"; HlAppCrash = "App crashes"
    HlStabGood = "Your system looks stable."; HlStabBad = "There are signs of instability; consider updating drivers and running the repair below."
    HlRepairTitle = "System file repair"; HlRepairSub = "Finds and repairs corrupted Windows files. Recommended order: DISM first, then SFC."
    HlDismT = "1. Repair Windows image (DISM)"; HlDismD = "Repairs the component store with clean copies from Windows Update · 5–20 min"
    HlSfcT = "2. Scan system files (SFC)"; HlSfcD = "Checks and repairs protected system files · 5–15 min"
    HlCleanT = "Clean up component store (DISM)"; HlCleanD = "Removes old update leftovers, can free a few GB · 5–15 min"
    BtnHlRun = "Start"; BtnHlCancel = "Stop"; HlRunning = "Running…"; HlDone = "Completed"; HlFailed = "Error (code {0})"; HlCancelled = "Stopped"
    HlOutput = "Last output"; HlBusy = "Another repair is running"
}

Register-WoPage @{
    Name = "Health"; Icon = 0xE95E
    Loc = @("HlDisks", "HlStabTitle", "HlRepairTitle", "HlRepairSub")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageHealth">
  <StackPanel Margin="0,0,14,20">
    <TextBlock x:Name="HlDisks" Style="{DynamicResource Caption}" Margin="4,0,0,8"/>
    <UniformGrid x:Name="HlDiskList" Columns="2"/>
    <Grid Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="300"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Style="{DynamicResource Card}" VerticalAlignment="Top">
        <StackPanel>
          <TextBlock x:Name="HlStabTitle" Style="{DynamicResource CardTitle}" Margin="0,0,0,14"/>
          <StackPanel x:Name="HlStab"/>
          <TextBlock x:Name="HlStabNote" Style="{DynamicResource Desc}" FontSize="11.5" Margin="0,10,0,0"/>
        </StackPanel>
      </Border>
      <Border Grid.Column="2" Style="{DynamicResource Card}" Padding="0">
        <StackPanel>
          <StackPanel Margin="20,16,20,12">
            <TextBlock x:Name="HlRepairTitle" Style="{DynamicResource CardTitle}"/>
            <TextBlock x:Name="HlRepairSub" Style="{DynamicResource Desc}" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel x:Name="HlRepairList"/>
        </StackPanel>
      </Border>
    </Grid>
  </StackPanel>
</ScrollViewer>
'@
    OnShow = { if (-not $script:HlLoaded) { Load-Health }; Build-Repairs }
    OnLang = { if ($script:HlLoaded) { Build-Disks; Build-Stability }; Build-Repairs }
}

$script:HlLoaded = $false; $script:HlDisks = @(); $script:HlStab = $null
$script:HlTask = $null      # @{ Id; Sync; Proc }
$script:HlResults = @{}

function Load-Health {
    $script:HlLoaded = $true
    (N "HlDiskList").Children.Clear(); [void](N "HlDiskList").Children.Add((New-Tb (T "HlLoading") 12 "#7A7A94"))
    Start-Bg -Work {
        foreach ($d in @(Get-PhysicalDisk -ErrorAction SilentlyContinue | Sort-Object DeviceId)) {
            $r = $null; try { $r = $d | Get-StorageReliabilityCounter -ErrorAction Stop } catch {}
            [pscustomobject]@{
                Name = "$($d.FriendlyName)".Trim(); Media = "$($d.MediaType)"; Bus = "$($d.BusType)"; Size = [double]$d.Size; Health = "$($d.HealthStatus)"
                Temp = $(if ($r -and $r.Temperature) { [int]$r.Temperature } else { $null })
                Wear = $(if ($r -and $null -ne $r.Wear) { [int]$r.Wear } else { $null })
                Hours = $(if ($r -and $r.PowerOnHours) { [int]$r.PowerOnHours } else { $null })
                Errors = $(if ($r -and $null -ne $r.ReadErrorsTotal) { [int]$r.ReadErrorsTotal } else { $null })
            }
        }
    } -Done {
        param($out, $err)
        $script:HlDisks = @($out | Where-Object { $_ -and $_.Name })
        Build-Disks
    }
    Start-Bg -Work {
        $since = (Get-Date).AddDays(-30)
        $count = { param($f) try { @(Get-WinEvent -FilterHashtable $f -ErrorAction Stop).Count } catch { 0 } }
        [pscustomobject]@{
            Bsod  = & $count @{ LogName = "System"; ProviderName = "Microsoft-Windows-WER-SystemErrorReporting"; Id = 1001; StartTime = $since }
            Crash = & $count @{ LogName = "System"; ProviderName = "Microsoft-Windows-Kernel-Power"; Id = 41; StartTime = $since }
            Apps  = & $count @{ LogName = "Application"; ProviderName = "Application Error"; Id = 1000; StartTime = $since }
        }
    } -Done {
        param($out, $err)
        $script:HlStab = @($out) | Select-Object -Last 1
        Build-Stability
    }
}

function Build-Disks {
    $grid = N "HlDiskList"; $grid.Children.Clear(); $grid.Margin = New-Object Windows.Thickness(0, 0, -12, 0)
    $grid.Columns = [Math]::Max(1, [Math]::Min(2, $script:HlDisks.Count))
    $iconFont = $window.FindResource("Icons")
    foreach ($d in $script:HlDisks) {
        $card = New-Object Windows.Controls.Border; $card.Style = $window.FindResource("Card"); $card.Margin = New-Object Windows.Thickness(0, 0, 12, 12)
        $sp = New-Object Windows.Controls.StackPanel
        $head = New-Object Windows.Controls.Grid; New-Cols $head @(44, "*", "Auto")
        $ib = New-Object Windows.Controls.Border; $ib.Width = 34; $ib.Height = 34; $ib.CornerRadius = New-Object Windows.CornerRadius(9); $ib.Background = Brush "#173328"; $ib.HorizontalAlignment = "Left"
        $ic = New-Tb ([string][char]0xEDA2) 15 "#34D399"; $ic.FontFamily = $iconFont; $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"; $ib.Child = $ic
        $hs = New-Object Windows.Controls.StackPanel; $hs.VerticalAlignment = "Center"
        $t = New-Tb $d.Name 13.5 "#EDEDF5"; $t.FontWeight = [Windows.FontWeights]::SemiBold; $t.TextWrapping = "NoWrap"; $t.TextTrimming = "CharacterEllipsis"
        $media = if ($d.Media -eq "SSD") { "SSD" } elseif ($d.Media -eq "HDD") { "HDD" } else { $d.Media }
        [void]$hs.Children.Add($t); [void]$hs.Children.Add((New-Tb "$media · $($d.Bus) · $(Fmt-GB $d.Size)" 11 "#7A7A94"))
        $hk = switch ($d.Health) { "Healthy" { @("HlHealthy", "#12302A", "#6EE7B7") } "Warning" { @("HlWarning", "#3A2E10", "#FCD34D") } "Unhealthy" { @("HlUnhealthy", "#3A1520", "#FCA5A5") } default { @("HlUnknown", "#1C1C2C", "#8A8AA6") } }
        $bd = New-Badge (T $hk[0]) $hk[1] $hk[2]
        [Windows.Controls.Grid]::SetColumn($hs, 1); [Windows.Controls.Grid]::SetColumn($bd, 2)
        [void]$head.Children.Add($ib); [void]$head.Children.Add($hs); [void]$head.Children.Add($bd)
        [void]$sp.Children.Add($head)
        $stats = New-Object Windows.Controls.Primitives.UniformGrid; $stats.Columns = 4; $stats.Margin = New-Object Windows.Thickness(0, 14, 0, 0)
        $vals = @(
            @("HlTemp", $(if ($null -ne $d.Temp) { "$($d.Temp) °C" } else { T "HlNA" }), $(if ($d.Temp -ge 60) { "#F87171" } elseif ($d.Temp -ge 50) { "#FBBF24" } else { "#EDEDF5" })),
            @("HlWear", $(if ($null -ne $d.Wear) { (T "HlWearFmt") -f $d.Wear } else { T "HlNA" }), $(if ($d.Wear -ge 80) { "#F87171" } elseif ($d.Wear -ge 50) { "#FBBF24" } else { "#EDEDF5" })),
            @("HlHours", $(if ($null -ne $d.Hours) { (T "HlHoursFmt") -f $d.Hours } else { T "HlNA" }), "#EDEDF5"),
            @("HlErrors", $(if ($null -ne $d.Errors) { "$($d.Errors)" } else { T "HlNA" }), $(if ($d.Errors -gt 0) { "#FBBF24" } else { "#EDEDF5" }))
        )
        foreach ($v in $vals) {
            $c = New-Object Windows.Controls.StackPanel
            [void]$c.Children.Add((New-Tb (T $v[0]) 10.5 "#7A7A94"))
            $vt = New-Tb $v[1] 15 $v[2]; $vt.FontWeight = [Windows.FontWeights]::SemiBold; $vt.Margin = New-Object Windows.Thickness(0, 3, 0, 0); [void]$c.Children.Add($vt)
            [void]$stats.Children.Add($c)
        }
        [void]$sp.Children.Add($stats)
        $card.Child = $sp
        [void]$grid.Children.Add($card)
    }
}

function Build-Stability {
    $p = N "HlStab"; $p.Children.Clear()
    $s = $script:HlStab
    if (-not $s) { [void]$p.Children.Add((New-Tb (T "HlLoading") 12 "#7A7A94")); return }
    foreach ($row in @(@("HlBsod", $s.Bsod, 1), @("HlCrash", $s.Crash, 1), @("HlAppCrash", $s.Apps, 10))) {
        $g = New-Object Windows.Controls.Grid; New-Cols $g @("*", "Auto"); $g.Margin = New-Object Windows.Thickness(0, 0, 0, 10)
        $l = New-Tb (T $row[0]) 12.5 "#B4B4CC"
        $col = if ($row[1] -ge $row[2]) { "#F87171" } elseif ($row[1] -gt 0) { "#FBBF24" } else { "#34D399" }
        $v = New-Tb "$($row[1])" 16 $col; $v.FontWeight = [Windows.FontWeights]::Bold
        [Windows.Controls.Grid]::SetColumn($v, 1)
        [void]$g.Children.Add($l); [void]$g.Children.Add($v); [void]$p.Children.Add($g)
    }
    (N "HlStabNote").Text = if (($s.Bsod + $s.Crash) -eq 0 -and $s.Apps -lt 10) { T "HlStabGood" } else { T "HlStabBad" }
}

$HlTools = [ordered]@{
    dism  = @{ Exe = "dism.exe"; Args = "/Online /Cleanup-Image /RestoreHealth"; Enc = "oem"; Key = "HlDism" }
    sfc   = @{ Exe = "sfc.exe"; Args = "/scannow"; Enc = "unicode"; Key = "HlSfc" }
    clean = @{ Exe = "dism.exe"; Args = "/Online /Cleanup-Image /StartComponentCleanup"; Enc = "oem"; Key = "HlClean" }
}

function Build-Repairs {
    $list = N "HlRepairList"; $list.Children.Clear()
    $sec = $window.FindResource("SecondaryBtn"); $slim = $window.FindResource("Slim")
    foreach ($id in $HlTools.Keys) {
        $tool = $HlTools[$id]
        $row = New-Object Windows.Controls.Border
        $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0); $row.Padding = New-Object Windows.Thickness(20, 14, 20, 14)
        $sp = New-Object Windows.Controls.StackPanel
        $g = New-Object Windows.Controls.Grid; New-Cols $g @("*", "Auto")
        $tx = New-Object Windows.Controls.StackPanel
        [void]$tx.Children.Add((New-Tb (T "$($tool.Key)T") 13.5 "#EDEDF5"))
        $d = New-Tb (T "$($tool.Key)D") 11.5 "#7A7A94"; $d.Margin = New-Object Windows.Thickness(0, 2, 12, 0); [void]$tx.Children.Add($d)
        $running = $script:HlTask -and $script:HlTask.Id -eq $id
        $b = New-Object Windows.Controls.Button; $b.Style = $sec; $b.Height = 34; $b.Tag = $id; $b.VerticalAlignment = "Center"
        $b.Content = if ($running) { T "BtnHlCancel" } else { T "BtnHlRun" }
        $b.IsEnabled = $running -or -not $script:HlTask
        $b.Add_Click({ param($s) if ($script:HlTask -and $script:HlTask.Id -eq $s.Tag) { Stop-HlTool } else { Start-HlTool $s.Tag } })
        [Windows.Controls.Grid]::SetColumn($b, 1)
        [void]$g.Children.Add($tx); [void]$g.Children.Add($b); [void]$sp.Children.Add($g)
        $res = $script:HlResults[$id]
        if ($running -or $res) {
            $pb = New-Object Windows.Controls.ProgressBar; $pb.Style = $slim; $pb.Maximum = 100; $pb.Height = 6; $pb.Margin = New-Object Windows.Thickness(0, 12, 0, 6)
            $pb.Name = "HlPb_$id"; $script:Named["HlPb_$id"] = $pb
            $line = New-Tb "" 11 "#9C9CB8"; $line.TextWrapping = "NoWrap"; $line.TextTrimming = "CharacterEllipsis"; $script:Named["HlLine_$id"] = $line
            if ($res) {
                $pb.Value = 100
                $pb.Foreground = Brush $(if ($res.Code -eq 0) { "#34D399" } elseif ($res.Cancelled) { "#7A7A94" } else { "#F87171" })
                $head = if ($res.Cancelled) { T "HlCancelled" } elseif ($res.Code -eq 0) { T "HlDone" } else { (T "HlFailed") -f $res.Code }
                $line.Text = "$head · $($res.Line)"; $line.ToolTip = $res.Line
            }
            [void]$sp.Children.Add($pb); [void]$sp.Children.Add($line)
        }
        $row.Child = $sp
        [void]$list.Children.Add($row)
    }
}

function Start-HlTool([string]$Id) {
    if ($script:HlTask) { Set-Status (T "HlBusy") "warn"; return }
    $tool = $HlTools[$Id]
    $sync = [hashtable]::Synchronized(@{ Pct = 0; Line = ""; Pid = 0; Cancel = $false })
    $script:HlTask = @{ Id = $Id; Sync = $sync }
    $script:HlResults.Remove($Id)
    Build-Repairs
    Set-Status ((T "$($tool.Key)T") + " — " + (T "HlRunning")) "busy"
    Start-Bg -Work {
        param($Exe, $ArgLine, $EncName, $Sync)
        $psi = New-Object Diagnostics.ProcessStartInfo($Exe, $ArgLine)
        $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.CreateNoWindow = $true
        $psi.StandardOutputEncoding = if ($EncName -eq "unicode") { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage) }
        $p = [Diagnostics.Process]::Start($psi)
        $Sync.Pid = $p.Id
        $buf = New-Object char[] 512; $acc = New-Object Text.StringBuilder; $last = ""
        while (($n = $p.StandardOutput.Read($buf, 0, $buf.Length)) -gt 0) {
            [void]$acc.Append($buf, 0, $n)
            $txt = $acc.ToString()
            $parts = $txt -split "[\r\n]+"
            $acc.Clear() | Out-Null; [void]$acc.Append($parts[-1])
            foreach ($l in $parts[0..([Math]::Max(0, $parts.Count - 2))]) {
                $l = ($l -replace "`0", "").Trim()
                if (-not $l) { continue }
                $m = [regex]::Match($l, '(\d{1,3}(?:[.,]\d)?)\s*%|%\s*(\d{1,3})')
                if ($m.Success) {
                    $v = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
                    $Sync.Pct = [Math]::Min(100, [double]($v -replace ',', '.'))
                }
                if ($l -notmatch '^\[?=*\s*\d') { $last = $l; $Sync.Line = $l }
            }
            $tail = ($acc.ToString() -replace "`0", "").Trim()
            $m2 = [regex]::Match($tail, '(\d{1,3}(?:[.,]\d)?)\s*%|%\s*(\d{1,3})')
            if ($m2.Success) { $v = if ($m2.Groups[1].Success) { $m2.Groups[1].Value } else { $m2.Groups[2].Value }; $Sync.Pct = [Math]::Min(100, [double]($v -replace ',', '.')) }
        }
        $p.WaitForExit()
        [pscustomobject]@{ Code = $p.ExitCode; Line = $last }
    } -ArgList @($tool.Exe, $tool.Args, $tool.Enc, $sync) -Done {
        param($out, $err)
        $t = $script:HlTask; $script:HlTask = $null
        $r = @($out) | Select-Object -Last 1
        $res = @{ Code = $(if ($r) { $r.Code } else { -1 }); Line = $(if ($r -and $r.Line) { $r.Line } else { "$err" }); Cancelled = [bool]$t.Sync.Cancel }
        $script:HlResults[$t.Id] = $res
        Build-Repairs
        $key = $HlTools[$t.Id].Key
        if ($res.Cancelled) { Set-Status ((T "$($key)T") + " — " + (T "HlCancelled")) "warn" }
        elseif ($res.Code -eq 0) { Set-Status ((T "$($key)T") + " — " + (T "HlDone")) "ok"; Show-WoTrayTip "Windows Optimizer" ((T "$($key)T") + " — " + (T "HlDone")) }
        else { Set-Status ((T "$($key)T") + " — " + ((T "HlFailed") -f $res.Code)) "err" }
    }
}

function Stop-HlTool {
    $t = $script:HlTask
    if (-not $t) { return }
    $t.Sync.Cancel = $true
    if ($t.Sync.Pid) { Stop-Process -Id $t.Sync.Pid -Force -ErrorAction SilentlyContinue }
}

# Ilerlemeyi canli goster
$hlTimer = New-Object Windows.Threading.DispatcherTimer
$hlTimer.Interval = [TimeSpan]::FromMilliseconds(400)
$hlTimer.Add_Tick({
    $t = $script:HlTask
    if (-not $t -or $script:Page -ne "Health") { return }
    $pb = $script:Named["HlPb_$($t.Id)"]; $ln = $script:Named["HlLine_$($t.Id)"]
    if ($pb) { $pb.Value = $t.Sync.Pct }
    if ($ln) { $ln.Text = "{0} · %{1:N0} · {2}" -f (T "HlRunning"), $t.Sync.Pct, $t.Sync.Line; $ln.ToolTip = $t.Sync.Line }
})
$hlTimer.Start()
