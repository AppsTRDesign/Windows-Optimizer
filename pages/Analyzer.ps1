# pages/Analyzer.ps1 - Disk analizi: klasor boyutlari agac haritasi (treemap) + en buyuk 50 dosya
# Tarayici baglanti noktalarini (junction/symlink) izlemez; erisilemeyen klasorleri atlar.

if (-not ("WoScan2" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class WoNode {
    public string Name, Path; public long Size; public long Files; public bool IsFiles;
    public List<WoNode> Kids = new List<WoNode>();
}

// FindFirstFileEx + LARGE_FETCH: FileInfo nesnesi olusturmadan, toplu okuma ile hizli tarama
public static class WoScan2 {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 4)]
    struct WIN32_FIND_DATA {
        public uint dwFileAttributes; public long ftCreationTime, ftLastAccessTime, ftLastWriteTime;
        public uint nFileSizeHigh, nFileSizeLow, dwReserved0, dwReserved1;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string cFileName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string cAlternateFileName;
    }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr FindFirstFileEx(string name, int infoLevel, out WIN32_FIND_DATA data, int searchOp, IntPtr filter, int flags);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool FindNextFile(IntPtr h, out WIN32_FIND_DATA data);
    [DllImport("kernel32.dll")] static extern bool FindClose(IntPtr h);
    static readonly IntPtr INVALID = new IntPtr(-1);
    const uint DIR = 0x10, REPARSE = 0x400;

    public static volatile int Dirs; public static long FileCount; public static volatile string Current = "";
    public static volatile bool Cancel;
    static List<KeyValuePair<string, long>> big;

    public static WoNode Scan(string root) {
        Dirs = 0; FileCount = 0; Cancel = false; big = new List<KeyValuePair<string, long>>();
        string r = root.TrimEnd('\\');
        return Walk(r, r + "\\");
    }

    static WoNode Walk(string dir, string name) {
        WoNode n = new WoNode(); n.Name = name; n.Path = dir.Length == 2 ? dir + "\\" : dir;
        if (Cancel) return n;
        Dirs++; if ((Dirs & 127) == 0) Current = dir;
        long loose = 0, looseCount = 0;
        List<string> subs = new List<string>();
        WIN32_FIND_DATA fd;
        IntPtr h = FindFirstFileEx(@"\\?\" + dir + @"\*", 1, out fd, 0, IntPtr.Zero, 2);
        if (h != INVALID) {
            try {
                do {
                    string fn = fd.cFileName;
                    if ((fd.dwFileAttributes & DIR) != 0) {
                        if (fn == "." || fn == ".." || (fd.dwFileAttributes & REPARSE) != 0) continue;
                        subs.Add(fn);
                    } else {
                        long len = ((long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
                        loose += len; looseCount++;
                        if (len > 50L * 1024 * 1024) { big.Add(new KeyValuePair<string, long>(dir + "\\" + fn, len)); if (big.Count > 400) Trim(); }
                    }
                } while (FindNextFile(h, out fd));
            } finally { FindClose(h); }
        }
        FileCount += looseCount;
        foreach (string sn in subs) {
            WoNode k = Walk(dir + "\\" + sn, sn);
            n.Size += k.Size; n.Files += k.Files;
            if (k.Size > 0) n.Kids.Add(k);
        }
        if (loose > 0) {
            WoNode lf = new WoNode(); lf.Name = "*"; lf.Path = n.Path; lf.Size = loose; lf.Files = looseCount; lf.IsFiles = true;
            n.Kids.Add(lf);
        }
        n.Size += loose; n.Files += looseCount;
        n.Kids.Sort((a, b) => b.Size.CompareTo(a.Size));
        return n;
    }

    static void Trim() { big.Sort((a, b) => b.Value.CompareTo(a.Value)); big.RemoveRange(200, big.Count - 200); }

    public static List<KeyValuePair<string, long>> TopFiles(int count) {
        big.Sort((a, b) => b.Value.CompareTo(a.Value));
        return big.GetRange(0, Math.Min(count, big.Count));
    }
}
"@
}

Add-WoStrings @{
    NavAnalyzer = "Disk Analizi"; Title_Analyzer = "Disk Analizi"; Sub_Analyzer = "Diskinizde yer kaplayan klasörleri ve en büyük dosyaları bulun"
    AnDrive = "Disk"; BtnAnScan = "Tara"; BtnAnCancel = "Durdur"; AnScanning = "Taranıyor: {0:N0} klasör, {1:N0} dosya"; AnIdle = "Bir disk seçip 'Tara'ya basın. Tarama diskin boyutuna göre 10 sn – birkaç dakika sürer."
    AnDone = "{0} tarandı: {1} · {2:N0} dosya · {3:N1} sn"; AnUp = "Yukarı"; AnTreeTitle = "Klasör haritası"; AnTreeHint = "Bir kutuya tıklayarak içine girin · sağ tık: Gezgin'de aç"
    AnBigTitle = "En büyük 50 dosya"; AnBigNone = "Henüz tarama yapılmadı."; AnFiles = "(dosyalar)"; AnOther = "Diğer ({0} öğe)"; AnOpen = "Konumu aç"
} @{
    NavAnalyzer = "Disk Analyzer"; Title_Analyzer = "Disk Analyzer"; Sub_Analyzer = "Find the folders and largest files taking up space"
    AnDrive = "Drive"; BtnAnScan = "Scan"; BtnAnCancel = "Stop"; AnScanning = "Scanning: {0:N0} folders, {1:N0} files"; AnIdle = "Pick a drive and press 'Scan'. Takes 10 s to a few minutes depending on drive size."
    AnDone = "{0} scanned: {1} · {2:N0} files · {3:N1} s"; AnUp = "Up"; AnTreeTitle = "Folder map"; AnTreeHint = "Click a box to drill in · right-click: open in Explorer"
    AnBigTitle = "50 largest files"; AnBigNone = "No scan yet."; AnFiles = "(files)"; AnOther = "Other ({0} items)"; AnOpen = "Open location"
}

Register-WoPage @{
    Name = "Analyzer"; Icon = 0xEB05
    Loc = @("AnDrive", "AnTreeTitle", "AnTreeHint", "AnBigTitle", "BtnAnUp")
    Xaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageAnalyzer">
  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <Border Style="{DynamicResource Card}" Padding="18,12" Margin="0,0,14,0">
    <Grid>
      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock x:Name="AnDrive" Style="{DynamicResource Caption}" VerticalAlignment="Center" Margin="0,0,10,0"/>
        <WrapPanel x:Name="AnDrives" VerticalAlignment="Center"/>
      </StackPanel>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
        <TextBlock x:Name="AnStatus" FontSize="12" Foreground="{DynamicResource Muted}" VerticalAlignment="Center" Margin="0,0,14,0" MaxWidth="420" TextTrimming="CharacterEllipsis"/>
        <Button x:Name="BtnAnScan" Style="{DynamicResource PrimaryBtn}" Height="36" MinWidth="110"/>
      </StackPanel>
    </Grid>
  </Border>
  <Grid Grid.Row="1" Margin="0,14,14,16">
    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="340"/></Grid.ColumnDefinitions>
    <Border Style="{DynamicResource Card}" Padding="16">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Grid Margin="0,0,0,12">
          <StackPanel>
            <TextBlock x:Name="AnTreeTitle" Style="{DynamicResource CardTitle}"/>
            <TextBlock x:Name="AnCrumb" FontSize="11.5" Foreground="{DynamicResource Txt2}" Margin="0,3,0,0" TextTrimming="CharacterEllipsis"/>
          </StackPanel>
          <Button x:Name="BtnAnUp" Style="{DynamicResource SecondaryBtn}" Height="30" HorizontalAlignment="Right" VerticalAlignment="Center" IsEnabled="False"/>
        </Grid>
        <Canvas x:Name="AnMap" Grid.Row="1" ClipToBounds="True" Background="#101019"/>
        <TextBlock x:Name="AnTreeHint" Grid.Row="1" Style="{DynamicResource Desc}" FontSize="11" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="0,0,6,4" IsHitTestVisible="False"/>
      </Grid>
    </Border>
    <Border Grid.Column="2" Style="{DynamicResource Card}" Padding="0">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <TextBlock x:Name="AnBigTitle" Style="{DynamicResource CardTitle}" Margin="18,16,18,10"/>
        <ScrollViewer Grid.Row="1"><StackPanel x:Name="AnBigList" Margin="0,0,0,10"/></ScrollViewer>
      </Grid>
    </Border>
  </Grid>
</Grid>
'@
    OnShow = { Build-AnDrives; if ($Snapshot -and $env:WO_SNAP_ANSCAN -and -not $script:AnBusy -and -not $script:AnRoot) { $script:AnDrive = $env:WO_SNAP_ANSCAN; Start-AnScan }; if (-not $script:AnRoot) { (N "AnStatus").Text = T "AnIdle"; Build-AnBig } else { Draw-AnMap } }
    OnLang = { (N "BtnAnScan").Content = if ($script:AnBusy) { T "BtnAnCancel" } else { T "BtnAnScan" }; (N "BtnAnUp").Content = T "AnUp"; Build-AnBig; if ($script:AnRoot) { Draw-AnMap } }
}
Add-WoStrings @{ BtnAnUp = "Yukarı" } @{ BtnAnUp = "Up" }

$script:AnDrive = $env:SystemDrive.Substring(0, 1); $script:AnRoot = $null; $script:AnStack = New-Object System.Collections.ArrayList
$script:AnBusy = $false; $script:AnTop = @()
$AnColors = @("#7C5CFF", "#38BDF8", "#34D399", "#F59E0B", "#F472B6", "#A78BFA", "#22D3EE", "#FB923C", "#4ADE80", "#E879F9", "#60A5FA", "#FACC15")

function Build-AnDrives {
    $wp = N "AnDrives"; $wp.Children.Clear()
    $seg = $window.FindResource("SegBtn")
    foreach ($d in @(Get-WoDrives)) {
        $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $seg; $rb.GroupName = "andrv"; $rb.Tag = $d.Letter
        $rb.Content = "$($d.Letter):  $(Fmt-GB ($d.Total - $d.Free))"; $rb.IsChecked = ($d.Letter -eq $script:AnDrive); $rb.IsEnabled = -not $script:AnBusy
        $rb.Add_Checked({ param($s) $script:AnDrive = $s.Tag })
        [void]$wp.Children.Add($rb)
    }
    (N "BtnAnScan").Content = if ($script:AnBusy) { T "BtnAnCancel" } else { T "BtnAnScan" }
    (N "BtnAnUp").Content = T "AnUp"
}

function Start-AnScan {
    if ($script:AnBusy) { [WoScan2]::Cancel = $true; return }
    $script:AnBusy = $true; $script:AnStarted = Get-Date
    Build-AnDrives
    $root = "$($script:AnDrive):\"
    Start-Bg -Work { param($R) [pscustomobject]@{ Root = [WoScan2]::Scan($R); Top = [WoScan2]::TopFiles(50) } } -ArgList @($root) -Done {
        param($out, $err)
        $script:AnBusy = $false
        $r = @($out) | Select-Object -Last 1
        if ($r -and $r.Root -and -not [WoScan2]::Cancel) {
            $script:AnRoot = $r.Root; $script:AnTop = @($r.Top)
            $script:AnStack.Clear(); [void]$script:AnStack.Add($script:AnRoot)
            $secs = ((Get-Date) - $script:AnStarted).TotalSeconds
            (N "AnStatus").Text = (T "AnDone") -f "$($script:AnDrive):", (Fmt-GB $script:AnRoot.Size), $script:AnRoot.Files, $secs
            Draw-AnMap; Build-AnBig
        } else { (N "AnStatus").Text = T "AnIdle" }
        if ($err) { Write-WoLog "Disk analizi: $err" }
        Build-AnDrives
    }
}

# Squarified treemap: alanlari dikdortgenlere yerlestirir (en-boy oranini 1'e yakin tutar)
function Get-AnLayout([double[]]$Sizes, [double]$X, [double]$Y, [double]$W, [double]$H) {
    $rects = New-Object System.Collections.ArrayList
    $sum = ($Sizes | Measure-Object -Sum).Sum
    if ($sum -le 0 -or $W -le 0 -or $H -le 0) { return $rects }
    $scale = ($W * $H) / $sum
    $areas = @($Sizes | ForEach-Object { $_ * $scale })
    $worst = { param($row, $side)
        $s = ($row | Measure-Object -Sum).Sum; $mx = ($row | Measure-Object -Maximum).Maximum; $mn = ($row | Measure-Object -Minimum).Minimum
        [Math]::Max($side * $side * $mx / ($s * $s), ($s * $s) / ($side * $side * $mn)) }
    $i = 0; $n = $areas.Count
    while ($i -lt $n) {
        $side = [Math]::Min($W, $H)
        $row = @($areas[$i]); $j = $i + 1; $wv = & $worst $row $side
        while ($j -lt $n) {
            $cand = $row + $areas[$j]; $w2 = & $worst $cand $side
            if ($w2 -le $wv) { $row = $cand; $wv = $w2; $j++ } else { break }
        }
        $rs = ($row | Measure-Object -Sum).Sum
        if ($W -ge $H) {
            $cw = $rs / $H; $yy = $Y
            foreach ($a in $row) { $hh = $a / $cw; [void]$rects.Add(@($X, $yy, $cw, $hh)); $yy += $hh }
            $X += $cw; $W -= $cw
        } else {
            $rh = $rs / $W; $xx = $X
            foreach ($a in $row) { $ww = $a / $rh; [void]$rects.Add(@($xx, $Y, $ww, $rh)); $xx += $ww }
            $Y += $rh; $H -= $rh
        }
        $i = $j
    }
    return $rects
}

function Draw-AnMap {
    $c = N "AnMap"; $c.Children.Clear()
    if ($script:AnStack.Count -eq 0) { return }
    $node = $script:AnStack[$script:AnStack.Count - 1]
    (N "AnCrumb").Text = "$($node.Path)  ·  $(Fmt-GB $node.Size)"
    (N "BtnAnUp").IsEnabled = $script:AnStack.Count -gt 1
    $W = $c.ActualWidth; $H = $c.ActualHeight
    if ($W -lt 20 -or $H -lt 20) { return }
    # En buyuk 30 oge + kalanlar "Diger"
    $kids = @($node.Kids)
    $items = @($kids | Select-Object -First 30)
    if ($kids.Count -gt 30) {
        $rest = ($kids | Select-Object -Skip 30 | Measure-Object Size -Sum).Sum
        if ($rest -gt 0) { $items += [pscustomobject]@{ Name = "?"; Size = [long]$rest; IsFiles = $true; Other = $kids.Count - 30; Kids = @() } }
    }
    $items = @($items | Where-Object { $_.Size -gt 0 })
    if ($items.Count -eq 0) { return }
    $rects = Get-AnLayout ([double[]]@($items | ForEach-Object { [double]$_.Size })) 0 0 $W $H
    for ($k = 0; $k -lt $items.Count; $k++) {
        $it = $items[$k]; $r = $rects[$k]
        $col = if ($it.IsFiles) { "#3A3A52" } else { $AnColors[$k % $AnColors.Count] }
        $b = New-Object Windows.Controls.Border
        $b.Width = [Math]::Max(0, $r[2] - 2); $b.Height = [Math]::Max(0, $r[3] - 2)
        $b.CornerRadius = New-Object Windows.CornerRadius(4)
        $cc = [Windows.Media.ColorConverter]::ConvertFromString($col)
        $c1 = $cc; $c1.A = 230; $c2 = $cc; $c2.A = 150
        $b.Background = New-Object Windows.Media.LinearGradientBrush($c1, $c2, 90)
        $label = if ($it.PSObject.Properties["Other"] -and $it.Other) { (T "AnOther") -f $it.Other } elseif ($it.IsFiles) { T "AnFiles" } else { $it.Name }
        $b.ToolTip = "$label`n$(Fmt-GB $it.Size)`n$($it.Path)"
        if ($r[2] -gt 60 -and $r[3] -gt 30) {
            $sp = New-Object Windows.Controls.StackPanel; $sp.Margin = New-Object Windows.Thickness(8, 6, 6, 4)
            $t1 = New-Tb $label 12 "#FFFFFF"; $t1.FontWeight = [Windows.FontWeights]::SemiBold; $t1.TextWrapping = "NoWrap"; $t1.TextTrimming = "CharacterEllipsis"
            [void]$sp.Children.Add($t1)
            if ($r[3] -gt 46) { [void]$sp.Children.Add((New-Tb (Fmt-GB $it.Size) 11 "#E6E6F2")) }
            $b.Child = $sp
        }
        if (-not $it.IsFiles -and @($it.Kids).Count -gt 0) {
            $b.Cursor = "Hand"; $b.Tag = $it
            $b.Add_MouseLeftButtonUp({ param($s) [void]$script:AnStack.Add($s.Tag); Draw-AnMap })
        }
        if ($it.Path) { $b.Add_MouseRightButtonUp({ param($s) $p = ($s.ToolTip -split "`n")[-1]; if ($p -and (Test-Path -LiteralPath $p)) { Start-Process explorer.exe "`"$p`"" } }) }
        [Windows.Controls.Canvas]::SetLeft($b, $r[0] + 1); [Windows.Controls.Canvas]::SetTop($b, $r[1] + 1)
        [void]$c.Children.Add($b)
    }
}

function Build-AnBig {
    $list = N "AnBigList"; $list.Children.Clear()
    if ($script:AnTop.Count -eq 0) { $e = New-Tb (T "AnBigNone") 12 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(18, 0, 18, 0); [void]$list.Children.Add($e); return }
    $max = [double]$script:AnTop[0].Value
    $slim = $window.FindResource("Slim"); $tb = $window.FindResource("TitleBtn")
    foreach ($f in $script:AnTop) {
        $row = New-Object Windows.Controls.Grid; $row.Margin = New-Object Windows.Thickness(18, 0, 10, 10); New-Cols $row @("*", "Auto", 34)
        $sp = New-Object Windows.Controls.StackPanel
        $nm = New-Tb ([IO.Path]::GetFileName($f.Key)) 12 "#EDEDF5"; $nm.TextWrapping = "NoWrap"; $nm.TextTrimming = "CharacterEllipsis"; $nm.ToolTip = $f.Key
        $dir = New-Tb ([IO.Path]::GetDirectoryName($f.Key)) 10 "#6A6A86"; $dir.TextWrapping = "NoWrap"; $dir.TextTrimming = "CharacterEllipsis"
        $pb = New-Object Windows.Controls.ProgressBar; $pb.Style = $slim; $pb.Maximum = 100; $pb.Value = 100 * $f.Value / $max; $pb.Height = 3; $pb.Margin = New-Object Windows.Thickness(0, 4, 0, 0)
        [void]$sp.Children.Add($nm); [void]$sp.Children.Add($dir); [void]$sp.Children.Add($pb)
        $sz = New-Tb (Fmt-GB $f.Value) 12 "#EDEDF5"; $sz.FontWeight = [Windows.FontWeights]::SemiBold; $sz.Margin = New-Object Windows.Thickness(10, 0, 4, 0); $sz.VerticalAlignment = "Center"
        $op = New-Object Windows.Controls.Button; $op.Style = $tb; $op.Content = [string][char]0xE838; $op.ToolTip = T "AnOpen"; $op.Tag = $f.Key; $op.Width = 30
        $op.Add_Click({ param($s) Start-Process explorer.exe "/select,`"$($s.Tag)`"" })
        [Windows.Controls.Grid]::SetColumn($sz, 1); [Windows.Controls.Grid]::SetColumn($op, 2)
        [void]$row.Children.Add($sp); [void]$row.Children.Add($sz); [void]$row.Children.Add($op)
        [void]$list.Children.Add($row)
    }
}

(N "BtnAnScan").Add_Click({ Start-AnScan })
(N "BtnAnUp").Add_Click({ if ($script:AnStack.Count -gt 1) { $script:AnStack.RemoveAt($script:AnStack.Count - 1); Draw-AnMap } })
(N "AnMap").Add_SizeChanged({ if ($script:AnRoot) { Draw-AnMap } })

$anTimer = New-Object Windows.Threading.DispatcherTimer
$anTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$anTimer.Add_Tick({
    if ($script:AnBusy -and $script:Page -eq "Analyzer") {
        (N "AnStatus").Text = ((T "AnScanning") -f [WoScan2]::Dirs, [WoScan2]::FileCount)
        (N "AnStatus").ToolTip = [WoScan2]::Current
    }
})
$anTimer.Start()
