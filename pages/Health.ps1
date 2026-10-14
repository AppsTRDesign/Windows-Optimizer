# pages/Health.ps1 - Sistem sagligi: disk SMART bilgileri (canli), kararlilik ozeti, DISM/SFC onarimi (canli ilerleme)

# NVMe saglik gunlugu: Windows'un guvenilirlik sayaci NVMe'de calisma suresi/hata vermeyebilir; dogrudan diskten okunur.
if (-not ("WoNvme" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class WoNvme {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr sa, uint disp, uint flags, IntPtr tmpl);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DeviceIoControl(SafeFileHandle h, uint code, byte[] inBuf, int inSize, byte[] outBuf, int outSize, out int ret, IntPtr ov);
    const uint IOCTL_STORAGE_QUERY_PROPERTY = 0x2D1400;

    // {sicaklikC, kullanilanOmur%, calismaSaati, medyaHatasi, guvensizKapanma, okunanBirim, yazilanBirim, yedekAlan%, kritikUyari} ya da null
    public static long[] Health(int disk) {
        using (SafeFileHandle h = CreateFile(@"\\.\PhysicalDrive" + disk, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero)) {
            if (h.IsInvalid) return null;
            const int dataLen = 512, protoLen = 40, hdr = 8;
            byte[] buf = new byte[hdr + protoLen + dataLen];
            BitConverter.GetBytes(50).CopyTo(buf, 0);         // StorageDeviceProtocolSpecificProperty
            BitConverter.GetBytes(0).CopyTo(buf, 4);          // PropertyStandardQuery
            BitConverter.GetBytes(3).CopyTo(buf, 8);          // ProtocolTypeNvme
            BitConverter.GetBytes(2).CopyTo(buf, 12);         // NVMeDataTypeLogPage
            BitConverter.GetBytes(2).CopyTo(buf, 16);         // NVME_LOG_PAGE_HEALTH_INFO
            BitConverter.GetBytes(0).CopyTo(buf, 20);
            BitConverter.GetBytes(protoLen).CopyTo(buf, 24);  // ProtocolDataOffset
            BitConverter.GetBytes(dataLen).CopyTo(buf, 28);   // ProtocolDataLength
            int ret;
            if (!DeviceIoControl(h, IOCTL_STORAGE_QUERY_PROPERTY, buf, buf.Length, buf, buf.Length, out ret, IntPtr.Zero)) return null;
            int off = hdr + BitConverter.ToInt32(buf, hdr + 16);   // STORAGE_PROTOCOL_DATA_DESCRIPTOR.ProtocolSpecificData.ProtocolDataOffset
            if (off + 192 > buf.Length) return null;
            int kelvin = BitConverter.ToUInt16(buf, off + 1);
            return new long[] {
                kelvin > 0 ? kelvin - 273 : -1, buf[off + 5], BitConverter.ToInt64(buf, off + 128), BitConverter.ToInt64(buf, off + 160),
                BitConverter.ToInt64(buf, off + 144), BitConverter.ToInt64(buf, off + 32), BitConverter.ToInt64(buf, off + 48), buf[off + 3], buf[off]
            };
        }
    }
}
"@
}

Add-WoStrings @{
    NavHealth = "Sağlık"; Title_Health = "Sistem Sağlığı"; Sub_Health = "Disk sağlığı, kararlılık ve sistem dosyası onarımı"
    HlDisks = "Fiziksel diskler"; HlLoading = "Okunuyor…"; HlHealthy = "SAĞLIKLI"; HlWarning = "UYARI"; HlUnhealthy = "SORUNLU"; HlUnknown = "BİLİNMİYOR"
    HlTemp = "Sıcaklık"; HlWear = "Kullanılan ömür"; HlHours = "Çalışma süresi"; HlErrors = "Okuma hataları"; HlSize = "Kapasite"; HlNA = "—"
    HlHoursFmt = "{0:N0} saat"; HlWearFmt = "%{0}"
    HlStabTitle = "Kararlılık (son 30 gün)"; HlBsod = "Mavi ekran (BSOD)"; HlCrash = "Beklenmedik kapanma"; HlAppCrash = "Uygulama çökmesi"
    HlStabGood = "Sisteminiz kararlı görünüyor."; HlStabBad = "Kararsızlık belirtileri var; sürücüleri güncellemeyi ve aşağıdaki onarımı çalıştırmayı düşünün."
    HlRepairTitle = "Sistem dosyası onarımı"; HlRepairSub = "Bozuk Windows dosyalarını bulur ve onarır. Sırayla çalıştırılması önerilir: önce DISM, sonra SFC."
    HlDismT = "1. Windows görüntüsünü onar (DISM)"; HlDismD = "Bileşen deposunu Windows Update'ten indirilen temiz kopyalarla onarır · 10–30 dk; %62 civarında uzun beklemesi normaldir"
    HlSfcT = "2. Sistem dosyalarını tara (SFC)"; HlSfcD = "Korunan sistem dosyalarını denetler ve onarır · 5–15 dk"
    HlCleanT = "Bileşen deposunu temizle (DISM)"; HlCleanD = "Eski güncelleme kalıntılarını kaldırır, birkaç GB yer açabilir · 5–15 dk"
    BtnHlRun = "Başlat"; BtnHlCancel = "Durdur"; HlRunning = "Çalışıyor…"; HlDone = "Tamamlandı"; HlFailed = "Hata (kod {0})"; HlCancelled = "Durduruldu"
    HlOutput = "Son çıktı"; HlBusy = "Başka bir onarım çalışıyor"; HlLive = "Canlı · 15 sn'de bir yenilenir"
    HlNvmeExtra = "Yazılan: {0} · Okunan: {1} · Güvenli olmayan kapanma: {2} · Yedek alan: %{3}"
    HlCheckT = "Hızlı sağlık denetimi (DISM CheckHealth)"; HlCheckD = "Bileşen deposunda bilinen bir bozulma var mı, saniyeler içinde söyler · önce bunu çalıştırın"
    HlState_Healthy = "Sağlıklı — onarım gerekmiyor"; HlState_Repairable = "Bozulma var ve onarılabilir — 'Windows görüntüsünü onar' adımını çalıştırın"
    HlState_NonRepairable = "Onarılamaz bozulma — Windows ISO ile onarım veya yerinde yükseltme gerekir"
    HlErrNoSource = "Onarım dosyaları Windows Update'te bulunamadı (0x800F0915). Bu, yeni Windows derlemelerinde sık görülür. Aynı sürümün Windows ISO dosyasıyla onarabilirsiniz."
    HlErrDownload = "Onarım dosyaları Windows Update'ten indirilemedi (internet bağlantısı veya güncelleme ilkesi). Windows ISO dosyasıyla onarabilirsiniz."
    BtnHlIso = "ISO ile onar"; HlIsoTitle = "Windows ISO ile onar"
    HlIsoMsg = "Onarım için bilgisayarınızdaki sürümle aynı (Windows 11 {0}, derleme {1}) bir Windows ISO dosyası gerekir. ISO bağlanır, içindeki temiz dosyalar kaynak olarak kullanılır ve iş bitince ayrılır.`n`nISO'nuz yoksa Microsoft'un resmi indirme sayfasından alabilirsiniz."
    HlIsoPick = "ISO dosyası seç"; HlIsoDownload = "İndirme sayfasını aç"; HlIsoNoEdition = "Bu ISO'da '{0}' sürümü bulunamadı"
    HlElapsed = "{0:mm\:ss}"
    HlChkT = "Disk hatalarını bul ve onar (CHKDSK)"; HlChkD = "Dosya sistemi hatalarını disk kullanımdayken tarar; bulunursa onarır. Sistem diskinin onarımı yeniden başlatmada yapılır."
    HlChkDrives = "Diskler:"; HlChk_NoErrorsFound = "{0}: hata yok"; HlChk_Fixed = "{0}: hatalar onarıldı"; HlChk_Scheduled = "{0}: onarım yeniden başlatmada yapılacak"
    HlChk_ErrorsFound = "{0}: hata bulundu, onarılamadı"; HlChk_Failed = "{0}: taranamadı ({1})"; HlChkNone = "En az bir disk seçin"
} @{
    NavHealth = "Health"; Title_Health = "System Health"; Sub_Health = "Disk health, stability and system file repair"
    HlDisks = "Physical disks"; HlLoading = "Reading…"; HlHealthy = "HEALTHY"; HlWarning = "WARNING"; HlUnhealthy = "UNHEALTHY"; HlUnknown = "UNKNOWN"
    HlTemp = "Temperature"; HlWear = "Life used"; HlHours = "Power-on time"; HlErrors = "Read errors"; HlSize = "Capacity"; HlNA = "—"
    HlHoursFmt = "{0:N0} hours"; HlWearFmt = "{0}%"
    HlStabTitle = "Stability (last 30 days)"; HlBsod = "Blue screens (BSOD)"; HlCrash = "Unexpected shutdowns"; HlAppCrash = "App crashes"
    HlStabGood = "Your system looks stable."; HlStabBad = "There are signs of instability; consider updating drivers and running the repair below."
    HlRepairTitle = "System file repair"; HlRepairSub = "Finds and repairs corrupted Windows files. Recommended order: DISM first, then SFC."
    HlDismT = "1. Repair Windows image (DISM)"; HlDismD = "Repairs the component store with clean copies from Windows Update · 10–30 min; long pauses around 62% are normal"
    HlSfcT = "2. Scan system files (SFC)"; HlSfcD = "Checks and repairs protected system files · 5–15 min"
    HlCleanT = "Clean up component store (DISM)"; HlCleanD = "Removes old update leftovers, can free a few GB · 5–15 min"
    BtnHlRun = "Start"; BtnHlCancel = "Stop"; HlRunning = "Running…"; HlDone = "Completed"; HlFailed = "Error (code {0})"; HlCancelled = "Stopped"
    HlOutput = "Last output"; HlBusy = "Another repair is running"; HlLive = "Live · refreshes every 15 s"
    HlNvmeExtra = "Written: {0} · Read: {1} · Unsafe shutdowns: {2} · Spare: {3}%"
    HlCheckT = "Quick health check (DISM CheckHealth)"; HlCheckD = "Tells within seconds whether the component store has known corruption · run this first"
    HlState_Healthy = "Healthy — no repair needed"; HlState_Repairable = "Corruption found and repairable — run 'Repair Windows image'"
    HlState_NonRepairable = "Non-repairable corruption — repair with a Windows ISO or in-place upgrade"
    HlErrNoSource = "Repair files were not found on Windows Update (0x800F0915). This is common on new Windows builds. You can repair using a Windows ISO of the same version."
    HlErrDownload = "Repair files could not be downloaded from Windows Update (internet connection or update policy). You can repair using a Windows ISO."
    BtnHlIso = "Repair with ISO"; HlIsoTitle = "Repair with Windows ISO"
    HlIsoMsg = "Repair needs a Windows ISO of the same version as this PC (Windows 11 {0}, build {1}). The ISO is mounted, its clean files are used as the source and it is unmounted afterwards.`n`nIf you don't have one, get it from Microsoft's official download page."
    HlIsoPick = "Choose ISO file"; HlIsoDownload = "Open download page"; HlIsoNoEdition = "Edition '{0}' was not found in this ISO"
    HlElapsed = "{0:mm\:ss}"
    HlChkT = "Find and fix disk errors (CHKDSK)"; HlChkD = "Scans the file system while the disk is in use and fixes errors. The system drive is repaired on restart."
    HlChkDrives = "Drives:"; HlChk_NoErrorsFound = "{0}: no errors"; HlChk_Fixed = "{0}: errors fixed"; HlChk_Scheduled = "{0}: repair scheduled for restart"
    HlChk_ErrorsFound = "{0}: errors found, could not fix"; HlChk_Failed = "{0}: could not scan ({1})"; HlChkNone = "Select at least one drive"
}

Register-WoPage @{
    Name = "Health"; Icon = 0xE95E
    Loc = @("HlDisks", "HlLive", "HlStabTitle", "HlRepairTitle", "HlRepairSub")
    Xaml = @'
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageHealth">
  <StackPanel Margin="0,0,14,20">
    <Grid Margin="4,0,0,8">
      <TextBlock x:Name="HlDisks" Style="{DynamicResource Caption}"/>
      <TextBlock x:Name="HlLive" FontSize="10.5" Foreground="#34D399" HorizontalAlignment="Right" Margin="0,0,14,0"/>
    </Grid>
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
$script:HlChkSel = @{}

$script:HlDiskBusy = $false
function Refresh-HlDisks {
    if ($script:HlDiskBusy) { return }
    $script:HlDiskBusy = $true
    Start-Bg -Work {
        foreach ($d in @(Get-PhysicalDisk -ErrorAction SilentlyContinue | Sort-Object { [int]$_.DeviceId })) {
            $r = $null; try { $r = $d | Get-StorageReliabilityCounter -ErrorAction Stop } catch {}
            $o = [ordered]@{
                Name = "$($d.FriendlyName)".Trim(); Media = "$($d.MediaType)"; Bus = "$($d.BusType)"; Size = [double]$d.Size; Health = "$($d.HealthStatus)"
                Temp = $(if ($r -and $r.Temperature) { [int]$r.Temperature } else { $null })
                Wear = $(if ($r -and $null -ne $r.Wear) { [int]$r.Wear } else { $null })
                Hours = $(if ($r -and $r.PowerOnHours) { [int]$r.PowerOnHours } else { $null })
                Errors = $(if ($r -and $null -ne $r.ReadErrorsTotal) { [int]$r.ReadErrorsTotal } else { $null })
                Nvme = $null
            }
            if ("$($d.BusType)" -eq "NVMe") {
                $h = $null; try { $h = [WoNvme]::Health([int]$d.DeviceId) } catch {}
                if ($h) {
                    if ($h[0] -gt 0) { $o.Temp = [int]$h[0] }
                    $o.Wear = [int]$h[1]; $o.Hours = [long]$h[2]; $o.Errors = [long]$h[3]
                    $o.Nvme = @{ Unsafe = [long]$h[4]; Read = [double]$h[5] * 512000; Written = [double]$h[6] * 512000; Spare = [int]$h[7]; Warn = [int]$h[8] }
                }
            }
            [pscustomobject]$o
        }
    } -Done {
        param($out, $err)
        $script:HlDiskBusy = $false
        $script:HlDisks = @($out | Where-Object { $_ -and $_.Name })
        Build-Disks
    }
}

function Load-Health {
    $script:HlLoaded = $true
    (N "HlDiskList").Children.Clear(); [void](N "HlDiskList").Children.Add((New-Tb (T "HlLoading") 12 "#7A7A94"))
    Refresh-HlDisks
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
        if ($d.Nvme) {
            $x = New-Tb ((T "HlNvmeExtra") -f (Fmt-Size $d.Nvme.Written), (Fmt-Size $d.Nvme.Read), $d.Nvme.Unsafe, $d.Nvme.Spare) 10.5 "#7A7A94"
            $x.Margin = New-Object Windows.Thickness(0, 10, 0, 0); [void]$sp.Children.Add($x)
        }
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
    check = @{ Cmdlet = $true; Key = "HlCheck" }
    chk   = @{ Custom = "chk"; Key = "HlChk" }
    dism  = @{ Exe = "dism.exe"; Args = "/Online /Cleanup-Image /RestoreHealth"; Enc = "oem"; Key = "HlDism" }
    sfc   = @{ Exe = "sfc.exe"; Args = "/scannow"; Enc = "unicode"; Key = "HlSfc" }
    clean = @{ Exe = "dism.exe"; Args = "/Online /Cleanup-Image /StartComponentCleanup"; Enc = "oem"; Key = "HlClean" }
}


# DISM hata kodlari -> aciklama (ISO onerilir)
$HlNoSource = @(-2146498283, -2146498529)     # 0x800F0915, 0x800F081F
$HlNoDownload = @(-2146498298, -2146498297)   # 0x800F0906, 0x800F0907

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
        if ($id -eq "chk") {
            $wp = New-Object Windows.Controls.WrapPanel; $wp.Margin = New-Object Windows.Thickness(0, 10, 0, 0)
            $cap = New-Tb (T "HlChkDrives") 11.5 "#7A7A94"; $cap.VerticalAlignment = "Center"; $cap.Margin = New-Object Windows.Thickness(0, 0, 10, 0); [void]$wp.Children.Add($cap)
            foreach ($dv in @(Get-WoDrives | Where-Object { $_.Format -in @("NTFS", "ReFS", "FAT32", "exFAT") })) {
                if ($null -eq $script:HlChkSel[$dv.Letter]) { $script:HlChkSel[$dv.Letter] = $true }
                $cb = New-Object Windows.Controls.CheckBox; $cb.Style = $window.FindResource("Check"); $cb.Margin = New-Object Windows.Thickness(0, 0, 14, 0)
                $cb.Content = "$($dv.Letter):"; $cb.Foreground = Brush "#EDEDF5"; $cb.Tag = $dv.Letter; $cb.IsChecked = $script:HlChkSel[$dv.Letter]; $cb.IsEnabled = -not $script:HlTask
                $cb.Add_Click({ param($s) $script:HlChkSel[$s.Tag] = [bool]$s.IsChecked })
                [void]$wp.Children.Add($cb)
            }
            [void]$sp.Children.Add($wp)
        }
        $res = $script:HlResults[$id]
        if ($running -or $res) {
            $pb = New-Object Windows.Controls.ProgressBar; $pb.Style = $slim; $pb.Maximum = 100; $pb.Height = 6; $pb.Margin = New-Object Windows.Thickness(0, 12, 0, 6)
            $pb.Name = "HlPb_$id"; $script:Named["HlPb_$id"] = $pb
            $line = New-Tb "" 11 "#9C9CB8"; $line.TextWrapping = "NoWrap"; $line.TextTrimming = "CharacterEllipsis"; $script:Named["HlLine_$id"] = $line
            if ($res) {
                $pb.Value = 100
                $ok = $res.Code -eq 0
                $pb.Foreground = Brush $(if ($res.State -eq "Repairable") { "#FBBF24" } elseif ($res.State -eq "NonRepairable") { "#F87171" } elseif ($ok) { "#34D399" } elseif ($res.Cancelled) { "#7A7A94" } else { "#F87171" })
                $hex = "0x{0:X8}" -f ([int64]$res.Code -band 4294967295L)
                $head = if ($res.Cancelled) { T "HlCancelled" } elseif ($ok) { T "HlDone" } else { (T "HlFailed") -f $hex }
                $msg = if ($res.Disks) {
                    ($res.Disks | ForEach-Object { if ($_.R -eq "Failed") { (T "HlChk_Failed") -f $_.L, $_.E } else { (T "HlChk_$($_.R)") -f $_.L } }) -join "  ·  "
                } elseif ($res.State) { T "HlState_$($res.State)" } elseif ($res.Code -in $HlNoSource) { T "HlErrNoSource" } elseif ($res.Code -in $HlNoDownload) { T "HlErrDownload" } else { $res.Line }
                if ($res.Secs) { $head += " · " + ((T "HlElapsed") -f [TimeSpan]::FromSeconds($res.Secs)) }
                $line.Text = "$head · $msg"; $line.ToolTip = "$msg`n$($res.Line)"; $line.TextWrapping = "Wrap"
                if (-not $ok -and $res.State -ne "Healthy") { $line.Foreground = Brush $(if ($res.State -eq "Repairable") { "#FCD34D" } else { "#FCA5A5" }) }
            }
            [void]$sp.Children.Add($pb); [void]$sp.Children.Add($line)
            if ($res -and $id -eq "dism" -and ($res.Code -in $HlNoSource -or $res.Code -in $HlNoDownload)) {
                $ib = New-Object Windows.Controls.Button; $ib.Style = $window.FindResource("PrimaryBtn"); $ib.Height = 32; $ib.Content = T "BtnHlIso"
                $ib.HorizontalAlignment = "Left"; $ib.Margin = New-Object Windows.Thickness(0, 10, 0, 0); $ib.IsEnabled = -not $script:HlTask
                $ib.Add_Click({ Start-HlIso }); [void]$sp.Children.Add($ib)
            }
        }
        $row.Child = $sp
        [void]$list.Children.Add($row)
    }
}

function Start-HlIso {
    $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $choice = Show-WoChoice -Title (T "HlIsoTitle") -Message ((T "HlIsoMsg") -f $cv.DisplayVersion, "$($cv.CurrentBuild).$($cv.UBR)") -Kind "info" -Ok (T "HlIsoPick") -Alt (T "HlIsoDownload") -Cancel (T "DlgCancel")
    if ($choice -eq "alt") { Start-Process "https://www.microsoft.com/software-download/windows11"; return }
    if ($choice -ne "ok") { return }
    $dlg = New-Object Microsoft.Win32.OpenFileDialog; $dlg.Filter = "Windows ISO (*.iso)|*.iso"
    if (-not $dlg.ShowDialog($window)) { return }
    Start-HlTool "dism" $dlg.FileName
}

function Start-HlTool([string]$Id, [string]$IsoPath = "") {
    if ($script:HlTask) { Set-Status (T "HlBusy") "warn"; return }
    $tool = $HlTools[$Id]
    $sync = [hashtable]::Synchronized(@{ Pct = 0; Line = ""; Pid = 0; Cancel = $false; Start = (Get-Date) })
    $script:HlTask = @{ Id = $Id; Sync = $sync }
    $script:HlResults.Remove($Id)
    Build-Repairs
    Set-Status ((T "$($tool.Key)T") + " — " + (T "HlRunning")) "busy"
    if ($tool.Custom -eq "chk") {
        $letters = @($script:HlChkSel.Keys | Where-Object { $script:HlChkSel[$_] } | Sort-Object)
        if ($letters.Count -eq 0) { $script:HlTask = $null; Build-Repairs; Set-Status (T "HlChkNone") "warn"; return }
        Start-Bg -Work {
            param($Letters, $Sync, $SysLetter)
            $disks = @(); $i = 0
            foreach ($l in $Letters) {
                $Sync.Line = "$($l): …"; $Sync.Pct = [int](100 * $i / $Letters.Count); $i++
                try {
                    $scan = "$(Repair-Volume -DriveLetter $l -Scan -ErrorAction Stop)"
                    if ($scan -eq "NoErrorsFound") { $disks += @{ L = $l; R = "NoErrorsFound" }; continue }
                    if ($l -eq $SysLetter) {
                        # Sistem diski kullanimda: hizli onarim yeniden baslatmaya zamanlanir
                        $o = "Y" | & chkdsk.exe "$($l):" /spotfix 2>&1
                        $disks += @{ L = $l; R = "Scheduled" }
                    } else {
                        $fix = "$(Repair-Volume -DriveLetter $l -SpotFix -ErrorAction Stop)"
                        $disks += @{ L = $l; R = $(if ($fix -eq "NoErrorsFound") { "Fixed" } else { "ErrorsFound" }) }
                    }
                } catch { $disks += @{ L = $l; R = "Failed"; E = $_.Exception.Message } }
            }
            $Sync.Pct = 100
            $bad = @($disks | Where-Object { $_.R -in @("ErrorsFound", "Failed") }).Count
            [pscustomobject]@{ Code = $(if ($bad) { 1 } else { 0 }); Line = ""; Disks = $disks; Reboot = [bool]($disks | Where-Object { $_.R -eq "Scheduled" }) }
        } -ArgList @($letters, $sync, $env:SystemDrive.Substring(0, 1)) -Done ${function:Complete-HlTool}
        return
    }
    if ($tool.Cmdlet) {
        Start-Bg -Work {
            $r = Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop
            [pscustomobject]@{ Code = 0; Line = "$($r.ImageHealthState)"; State = "$($r.ImageHealthState)" }
        } -Done ${function:Complete-HlTool}
        return
    }
    $edition = "$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID)"
    Start-Bg -Work {
        param($Exe, $ArgLine, $EncName, $Sync, $IsoPath, $Edition)
        $mounted = $null
        try {
            if ($IsoPath) {
                $Sync.Line = "ISO bağlanıyor…"
                $mounted = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
                $letter = ($mounted | Get-Volume).DriveLetter
                $img = @("wim", "esd") | ForEach-Object { $f = "$($letter):\sources\install.$_"; if (Test-Path $f) { @{ Kind = $_; Path = $f } } } | Select-Object -First 1
                if (-not $img) { throw "install.wim/esd bulunamadı" }
                $idx = @(Get-WindowsImage -ImagePath $img.Path -ErrorAction Stop | ForEach-Object { Get-WindowsImage -ImagePath $img.Path -Index $_.ImageIndex } |
                         Where-Object { $_.EditionId -eq $Edition } | Select-Object -First 1).ImageIndex
                if (-not $idx) { throw "ISO: $Edition" }
                $ArgLine += " /Source:$($img.Kind):$($img.Path):$idx /LimitAccess"
            }
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
        } finally {
            if ($mounted) { Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue | Out-Null }
        }
    } -ArgList @($tool.Exe, $tool.Args, $tool.Enc, $sync, $IsoPath, $edition) -Done ${function:Complete-HlTool}
}

function Complete-HlTool($out, $err) {
        $t = $script:HlTask; $script:HlTask = $null
        $r = @($out) | Select-Object -Last 1
        $res = @{ Code = $(if ($r) { $r.Code } else { -1 }); Line = $(if ($r -and $r.Line) { $r.Line } elseif ($err -match 'ISO: (.+)') { (T "HlIsoNoEdition") -f $Matches[1] } else { "$err" })
                  Cancelled = [bool]$t.Sync.Cancel; State = $(if ($r) { $r.State }); Secs = ((Get-Date) - $t.Sync.Start).TotalSeconds
                  Disks = $(if ($r -and $r.PSObject.Properties["Disks"]) { @($r.Disks) }) }
        if ($r -and $r.PSObject.Properties["Reboot"] -and $r.Reboot) { Set-RestartNeed "reboot" }
        $script:HlResults[$t.Id] = $res
        Build-Repairs
        $key = $HlTools[$t.Id].Key
        if ($res.Cancelled) { Set-Status ((T "$($key)T") + " — " + (T "HlCancelled")) "warn" }
        elseif ($res.Code -eq 0) { Set-Status ((T "$($key)T") + " — " + (T "HlDone")) "ok"; Show-WoTrayTip "Windows Optimizer" ((T "$($key)T") + " — " + (T "HlDone")) }
        else { Set-Status ((T "$($key)T") + " — " + ((T "HlFailed") -f ("0x{0:X8}" -f ([int64]$res.Code -band 4294967295L)))) "err" }
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
    if ($ln) { $ln.Text = "{0} · %{1:N0} · {2} · {3}" -f (T "HlRunning"), $t.Sync.Pct, ((T "HlElapsed") -f ((Get-Date) - $t.Sync.Start)), $t.Sync.Line; $ln.ToolTip = $t.Sync.Line }
})
$hlTimer.Start()

$hlLive = New-Object Windows.Threading.DispatcherTimer
$hlLive.Interval = [TimeSpan]::FromSeconds(15)
$hlLive.Add_Tick({ if ($script:Page -eq "Health" -and $window.IsVisible -and $script:HlLoaded) { Refresh-HlDisks } })
$hlLive.Start()
