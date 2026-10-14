# pages/Analyzer.ps1 - Disk analizi
#   Liste gorunumu (klasorler, oranlar) · agac haritasi · tiklanabilir yol · en buyuk dosyalar · dosya turu dagilimi
# Tarayici FindFirstFileEx (LARGE_FETCH) kullanir; baglanti noktalarini (junction/symlink) izlemez.

Add-WoType "WoScan3" @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class WoNode {
    public string Name, Path; public long Size; public long Files; public long Dirs; public bool IsFiles;
    public List<WoNode> Kids = new List<WoNode>();
}

public static class WoScan3 {
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
    static Dictionary<string, long[]> ext;

    public static WoNode Scan(string root) {
        Dirs = 0; FileCount = 0; Cancel = false;
        big = new List<KeyValuePair<string, long>>(); ext = new Dictionary<string, long[]>(StringComparer.OrdinalIgnoreCase);
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
                        int dot = fn.LastIndexOf('.');
                        string e = (dot > 0 && fn.Length - dot <= 8) ? fn.Substring(dot + 1) : "";
                        long[] st; if (!ext.TryGetValue(e, out st)) { st = new long[2]; ext[e] = st; }
                        st[0] += len; st[1]++;
                        if (len > 50L * 1024 * 1024) { big.Add(new KeyValuePair<string, long>(dir + "\\" + fn, len)); if (big.Count > 400) Trim(); }
                    }
                } while (FindNextFile(h, out fd));
            } finally { FindClose(h); }
        }
        FileCount += looseCount;
        foreach (string sn in subs) {
            WoNode k = Walk(dir + "\\" + sn, sn);
            n.Size += k.Size; n.Files += k.Files; n.Dirs += k.Dirs + 1;
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
    public static Dictionary<string, long[]> ExtStats() { return ext; }
}
"@


Add-WoStrings @{
    NavAnalyzer = "Disk Analizi"; Title_Analyzer = "Disk Analizi"; Sub_Analyzer = "Diskinizde yer kaplayan klasörleri ve en büyük dosyaları bulun"
    AnDrive = "Disk"; BtnAnScan = "Tara"; BtnAnCancel = "Durdur"; AnScanning = "Taranıyor: {0:N0} klasör, {1:N0} dosya"
    AnIdle = "Disk seçin ve Tara'ya basın"; AnIdleTip = "Tarama diskin boyutuna göre 10 saniye ile birkaç dakika arası sürer; istediğiniz an durdurabilirsiniz."
    AnDone = "{0} tarandı: {1} · {2:N0} dosya · {3:N1} sn"; AnUp = "Yukarı"; BtnAnUp = "Yukarı"
    AnDelta = "Taramadan beri diskte {0} {1} · güncel liste için yeniden tarayın"; AnDeltaFreed = "boşaldı"; AnDeltaUsed = "doldu"
    AnViewList = "Liste"; AnViewMap = "Harita"; AnFolderInfo = "{0}  ·  {1:N0} dosya  ·  {2:N0} klasör  ·  sürücünün %{3:N1}'i"
    AnEmptyTitle = "Henüz tarama yapılmadı"; AnEmptyMsg = "Yukarıdan bir disk seçip Tara'ya basın. Klasörler boyutlarına göre sıralanır; bir klasöre tıklayarak içine inebilirsiniz."
    AnFiles = "Bu klasördeki dosyalar"; AnOther = "Diğer {0} öğe"; AnOpen = "Gezgin'de aç"; AnFilesN = "{0:N0} dosya"; AnDirsN = "{0:N0} klasör"
    AnTabBig = "En büyük dosyalar"; AnTabTypes = "Dosya türleri"; AnBigNone = "Henüz tarama yapılmadı."; AnTypesNote = "Taranan diskin tamamı"
    AnMapHint = "Kutuya tıklayın: içine girin · Sağ tık: Gezgin'de açın"
    Ft_video = "Video"; Ft_image = "Görsel"; Ft_audio = "Ses"; Ft_archive = "Arşiv ve disk kalıbı"; Ft_doc = "Belgeler"; Ft_exe = "Programlar ve kurulum"
    Ft_game = "Oyun ve uygulama verisi"; Ft_dev = "Geliştirme"; Ft_system = "Sistem dosyaları"; Ft_db = "Veritabanı ve önbellek"; Ft_other = "Diğer"
} @{
    NavAnalyzer = "Disk Analyzer"; Title_Analyzer = "Disk Analyzer"; Sub_Analyzer = "Find the folders and largest files taking up space"
    AnDrive = "Drive"; BtnAnScan = "Scan"; BtnAnCancel = "Stop"; AnScanning = "Scanning: {0:N0} folders, {1:N0} files"
    AnIdle = "Pick a drive and press Scan"; AnIdleTip = "Takes 10 seconds to a few minutes depending on drive size; you can stop it anytime."
    AnDone = "{0} scanned: {1} · {2:N0} files · {3:N1} s"; AnUp = "Up"; BtnAnUp = "Up"
    AnDelta = "Since the scan, {0} {1} on the drive · rescan for an up-to-date list"; AnDeltaFreed = "freed"; AnDeltaUsed = "used"
    AnViewList = "List"; AnViewMap = "Map"; AnFolderInfo = "{0}  ·  {1:N0} files  ·  {2:N0} folders  ·  {3:N1}% of drive"
    AnEmptyTitle = "No scan yet"; AnEmptyMsg = "Pick a drive above and press Scan. Folders are sorted by size; click a folder to drill in."
    AnFiles = "Files in this folder"; AnOther = "{0} more items"; AnOpen = "Open in Explorer"; AnFilesN = "{0:N0} files"; AnDirsN = "{0:N0} folders"
    AnTabBig = "Largest files"; AnTabTypes = "File types"; AnBigNone = "No scan yet."; AnTypesNote = "Entire scanned drive"
    AnMapHint = "Click a box: drill in · Right-click: open in Explorer"
    Ft_video = "Video"; Ft_image = "Images"; Ft_audio = "Audio"; Ft_archive = "Archives & disk images"; Ft_doc = "Documents"; Ft_exe = "Programs & installers"
    Ft_game = "Game & app data"; Ft_dev = "Development"; Ft_system = "System files"; Ft_db = "Databases & caches"; Ft_other = "Other"
}

Register-WoPage @{
    Name = "Analyzer"; Icon = 0xEB05
    Loc = @("AnDrive", "BtnAnUp")
    Xaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageAnalyzer">
  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <Border Style="{DynamicResource Card}" Padding="18,12" Margin="0,0,14,0">
    <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock x:Name="AnDrive" Style="{DynamicResource Caption}" VerticalAlignment="Center" Margin="0,0,10,0"/>
        <WrapPanel x:Name="AnDrives" VerticalAlignment="Center"/>
      </StackPanel>
      <TextBlock x:Name="AnStatus" Grid.Column="1" FontSize="12" Foreground="{DynamicResource Muted}" VerticalAlignment="Center"
                 HorizontalAlignment="Right" TextAlignment="Right" TextTrimming="CharacterEllipsis" TextWrapping="NoWrap" Margin="16,0,14,0"/>
      <Button x:Name="BtnAnScan" Grid.Column="2" Style="{DynamicResource PrimaryBtn}" Height="36" MinWidth="110"/>
    </Grid>
  </Border>
  <Grid Grid.Row="1" Margin="0,14,14,16">
    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="330"/></Grid.ColumnDefinitions>
    <Border Style="{DynamicResource Card}" Padding="0">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border BorderBrush="#1E1E32" BorderThickness="0,0,0,1" Padding="18,14,16,12">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel VerticalAlignment="Center" Margin="0,0,12,0">
              <WrapPanel x:Name="AnCrumbs"/>
              <TextBlock x:Name="AnFolderInfo" FontSize="11.5" Foreground="{DynamicResource Muted}" Margin="2,5,0,0" TextTrimming="CharacterEllipsis"/>
              <TextBlock x:Name="AnDeltaText" FontSize="11.5" Margin="2,3,0,0" TextTrimming="CharacterEllipsis" Visibility="Collapsed"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
              <Button x:Name="BtnAnUp" Style="{DynamicResource SecondaryBtn}" Height="30" FontSize="12" Margin="0,0,10,0" IsEnabled="False"/>
              <RadioButton x:Name="AnViewList" GroupName="anv" Style="{DynamicResource SegBtn}" FontSize="12" IsChecked="True"/>
              <RadioButton x:Name="AnViewMap" GroupName="anv" Style="{DynamicResource SegBtn}" FontSize="12" Margin="0"/>
            </StackPanel>
          </Grid>
        </Border>
        <Grid Grid.Row="1">
          <ScrollViewer x:Name="AnListScroll"><StackPanel x:Name="AnList" Margin="0,4,0,8"/></ScrollViewer>
          <Grid x:Name="AnMapHost" Visibility="Collapsed" Margin="14,12,14,12">
            <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Canvas x:Name="AnMap" ClipToBounds="True" Background="Transparent"/>
            <TextBlock x:Name="AnMapHint" Grid.Row="1" Style="{DynamicResource Desc}" FontSize="11" Margin="2,8,0,0"/>
          </Grid>
          <StackPanel x:Name="AnEmpty" VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="380">
            <TextBlock Text="&#xEB05;" FontFamily="{DynamicResource Icons}" FontSize="42" Foreground="#3A3A58" HorizontalAlignment="Center"/>
            <TextBlock x:Name="AnEmptyTitle" FontSize="15" FontWeight="SemiBold" Foreground="{DynamicResource Txt}" HorizontalAlignment="Center" Margin="0,14,0,6"/>
            <TextBlock x:Name="AnEmptyMsg" Style="{DynamicResource Desc}" TextAlignment="Center"/>
          </StackPanel>
        </Grid>
      </Grid>
    </Border>
    <Border Grid.Column="2" Style="{DynamicResource Card}" Padding="0">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border BorderBrush="#1E1E32" BorderThickness="0,0,0,1" Padding="14,14,14,12">
          <WrapPanel>
            <RadioButton x:Name="AnTabBig" GroupName="ant" Style="{DynamicResource SegBtn}" FontSize="12" IsChecked="True"/>
            <RadioButton x:Name="AnTabTypes" GroupName="ant" Style="{DynamicResource SegBtn}" FontSize="12" Margin="0"/>
          </WrapPanel>
        </Border>
        <ScrollViewer x:Name="AnSideScroll" Grid.Row="1"><StackPanel x:Name="AnSide" Margin="0,10,0,10"/></ScrollViewer>
      </Grid>
    </Border>
  </Grid>
</Grid>
'@
    OnShow = {
        Build-AnDrives
        if ($Snapshot -and $env:WO_SNAP_ANSCAN -and -not $script:AnBusy -and -not $script:AnRoot) { $script:AnDrive = $env:WO_SNAP_ANSCAN; Start-AnScan }
        if (-not $script:AnRoot -and -not $script:AnBusy) { (N "AnStatus").Text = T "AnIdle"; (N "AnStatus").ToolTip = T "AnIdleTip" }
        if ($Snapshot -and $env:WO_SNAP_ANVIEW -eq "map") { (N "AnViewMap").IsChecked = $true; (N "AnTabTypes").IsChecked = $true }
        Update-AnView
    }
    OnLang = { Build-AnDrives; Update-AnView }
}

$script:AnDrive = $env:SystemDrive.Substring(0, 1); $script:AnRoot = $null; $script:AnStack = New-Object System.Collections.ArrayList
$script:AnBusy = $false; $script:AnTop = @(); $script:AnTypes = @(); $script:AnView = "list"; $script:AnTab = "big"; $script:AnDriveTotal = 0
$AnColors = @("#7C5CFF", "#38BDF8", "#34D399", "#F59E0B", "#F472B6", "#A78BFA", "#22D3EE", "#FB923C", "#4ADE80", "#E879F9", "#60A5FA", "#FACC15")

# Uzanti -> kategori
$AnTypeMap = @{
    video = "mp4 mkv avi mov wmv flv webm m4v ts mts m2ts mpg mpeg vob 3gp"
    image = "jpg jpeg png gif bmp webp heic heif tif tiff raw cr2 nef arw dng psd svg ico tga"
    audio = "mp3 wav flac aac ogg m4a wma opus aiff mid"
    archive = "zip rar 7z tar gz tgz bz2 xz iso img vhd vhdx wim esd cab"
    doc = "pdf doc docx xls xlsx ppt pptx txt rtf odt ods odp csv md epub xps one"
    exe = "exe msi msix appx appxbundle msixbundle msp dll sys ocx"
    game = "pak bin dat bundle assets vpk pck upk uasset ubulk forge arc big wad bsa ba2 ucas utoc"
    dev = "js ts jsx tsx py cs cpp c h hpp java kt go rs rb php json xml yml yaml lock map node pdb obj lib o class jar"
    system = "etl evtx log dmp mui cat manifest pf"
    db = "db sqlite sqlite3 ldb edb mdb accdb cache tmp temp blob idx pack"
}
$script:AnExtCat = @{}
foreach ($k in $AnTypeMap.Keys) { foreach ($e in ($AnTypeMap[$k] -split ' ')) { $script:AnExtCat[$e] = $k } }
$AnTypeColors = @{ video = "#F472B6"; image = "#38BDF8"; audio = "#A78BFA"; archive = "#F59E0B"; doc = "#34D399"; exe = "#7C5CFF"; game = "#FB923C"; dev = "#22D3EE"; system = "#94A3B8"; db = "#E879F9"; other = "#4B4B66" }

function Build-AnDrives {
    $wp = N "AnDrives"; $wp.Children.Clear()
    $seg = $window.FindResource("SegBtn")
    foreach ($d in @(Get-WoDrives)) {
        $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $seg; $rb.GroupName = "andrv"; $rb.Tag = $d.Letter; $rb.FontSize = 12
        $rb.Content = "$($d.Letter):  $(Fmt-GB ($d.Total - $d.Free))"; $rb.IsChecked = ($d.Letter -eq $script:AnDrive); $rb.IsEnabled = -not $script:AnBusy
        $rb.ToolTip = "$(if ($d.Label) { $d.Label } else { T 'DriveLocal' }) ($($d.Letter):) · $((T 'DriveFree') -f (Fmt-GB $d.Free), (Fmt-GB $d.Total))"
        $rb.Add_Checked({ param($s) $script:AnDrive = $s.Tag })
        [void]$wp.Children.Add($rb)
    }
    (N "BtnAnScan").Content = if ($script:AnBusy) { T "BtnAnCancel" } else { T "BtnAnScan" }
    (N "BtnAnUp").Content = T "AnUp"
    (N "AnViewList").Content = T "AnViewList"; (N "AnViewMap").Content = T "AnViewMap"
    (N "AnTabBig").Content = T "AnTabBig"; (N "AnTabTypes").Content = T "AnTabTypes"
    (N "AnEmptyTitle").Text = T "AnEmptyTitle"; (N "AnEmptyMsg").Text = T "AnEmptyMsg"; (N "AnMapHint").Text = T "AnMapHint"
}

function Start-AnScan {
    if ($script:AnBusy) { [WoScan3]::Cancel = $true; return }
    $script:AnBusy = $true; $script:AnStarted = Get-Date
    $drv = @(Get-WoDrives | Where-Object Letter -eq $script:AnDrive) | Select-Object -First 1
    $script:AnDriveTotal = if ($drv) { [double]$drv.Total } else { 0 }
    $script:AnUsedAtScan = if ($drv) { [double]($drv.Total - $drv.Free) } else { 0 }
    $script:AnScanLetter = $script:AnDrive
    Build-AnDrives
    Start-Bg -Work {
        param($R)
        $root = [WoScan3]::Scan($R)
        [pscustomobject]@{ Root = $root; Top = [WoScan3]::TopFiles(50); Ext = [WoScan3]::ExtStats() }
    } -ArgList @("$($script:AnDrive):\") -Done {
        param($out, $err)
        $script:AnBusy = $false
        $r = @($out) | Select-Object -Last 1
        if ($r -and $r.Root -and -not [WoScan3]::Cancel) {
            $script:AnRoot = $r.Root; $script:AnTop = @($r.Top)
            # Uzantilari kategorilere topla
            $cats = @{}
            foreach ($kv in $r.Ext.GetEnumerator()) {
                $c = $script:AnExtCat["$($kv.Key)".ToLower()]; if (-not $c) { $c = "other" }
                if (-not $cats[$c]) { $cats[$c] = @{ Size = 0.0; Count = 0; Exts = @{} } }
                $cats[$c].Size += $kv.Value[0]; $cats[$c].Count += $kv.Value[1]
                $cats[$c].Exts["$($kv.Key)".ToLower()] = [double]$kv.Value[0]
            }
            $script:AnTypes = @($cats.Keys | ForEach-Object { [pscustomobject]@{ Cat = $_; Size = $cats[$_].Size; Count = $cats[$_].Count
                    Top = (($cats[$_].Exts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 4 | ForEach-Object { if ($_.Key) { ".$($_.Key)" } }) -join " ") } } |
                Sort-Object Size -Descending)
            $script:AnStack.Clear(); [void]$script:AnStack.Add($script:AnRoot)
            $secs = ((Get-Date) - $script:AnStarted).TotalSeconds
            (N "AnStatus").Text = (T "AnDone") -f "$($script:AnDrive):", (Fmt-GB $script:AnRoot.Size), $script:AnRoot.Files, $secs
            (N "AnStatus").ToolTip = (N "AnStatus").Text
        } elseif (-not $script:AnRoot) { (N "AnStatus").Text = T "AnIdle" }
        if ($err) { Write-WoLog "Disk analizi: $err" }
        Build-AnDrives; Update-AnView
    }
}

function Get-AnCurrent { if ($script:AnStack.Count) { $script:AnStack[$script:AnStack.Count - 1] } else { $null } }

function Enter-AnFolder($Node) { [void]$script:AnStack.Add($Node); Update-AnView; (N "AnListScroll").ScrollToTop() }

function Update-AnView {
    $has = [bool]$script:AnRoot
    (N "AnEmpty").Visibility = if ($has) { "Collapsed" } else { "Visible" }
    (N "AnListScroll").Visibility = if ($has -and $script:AnView -eq "list") { "Visible" } else { "Collapsed" }
    (N "AnMapHost").Visibility = if ($has -and $script:AnView -eq "map") { "Visible" } else { "Collapsed" }
    Build-AnCrumbs
    if ($has) { if ($script:AnView -eq "list") { Build-AnList } else { Draw-AnMap } }
    Build-AnSide
}

function Build-AnCrumbs {
    $wp = N "AnCrumbs"; $wp.Children.Clear()
    $node = Get-AnCurrent
    (N "BtnAnUp").IsEnabled = $script:AnStack.Count -gt 1
    if (-not $node) { $t = New-Tb (T "Title_Analyzer") 14 "#EDEDF5"; $t.FontWeight = [Windows.FontWeights]::SemiBold; [void]$wp.Children.Add($t); (N "AnFolderInfo").Text = ""; return }
    for ($i = 0; $i -lt $script:AnStack.Count; $i++) {
        $n = $script:AnStack[$i]; $last = ($i -eq $script:AnStack.Count - 1)
        if ($i -gt 0) { $sep = New-Tb "  ›  " 13 "#5A5A78"; $sep.VerticalAlignment = "Center"; [void]$wp.Children.Add($sep) }
        $label = if ($i -eq 0) { "$($script:AnDrive):" } else { $n.Name }
        $tb = New-Tb $label 14 $(if ($last) { "#FFFFFF" } else { "#A78BFA" }); $tb.TextWrapping = "NoWrap"; $tb.VerticalAlignment = "Center"
        if ($last) { $tb.FontWeight = [Windows.FontWeights]::SemiBold }
        else {
            $tb.Cursor = "Hand"; $tb.Tag = $i
            $tb.Add_MouseLeftButtonUp({ param($s) while ($script:AnStack.Count -gt ([int]$s.Tag + 1)) { $script:AnStack.RemoveAt($script:AnStack.Count - 1) }; Update-AnView })
        }
        [void]$wp.Children.Add($tb)
    }
    $pct = if ($script:AnDriveTotal -gt 0) { 100 * $node.Size / $script:AnDriveTotal } else { 0 }
    (N "AnFolderInfo").Text = (T "AnFolderInfo") -f (Fmt-GB $node.Size), $node.Files, $node.Dirs, $pct
}

function Get-AnItems($Node, [int]$Max) {
    $kids = @($Node.Kids)
    $items = @($kids | Select-Object -First $Max)
    if ($kids.Count -gt $Max) {
        $rest = ($kids | Select-Object -Skip $Max | Measure-Object Size -Sum).Sum
        if ($rest -gt 0) { $items += [pscustomobject]@{ Name = ""; Path = $Node.Path; Size = [long]$rest; Files = 0; Dirs = 0; IsFiles = $true; Other = $kids.Count - $Max; Kids = @() } }
    }
    return $items
}

function Get-AnLabel($It) {
    if ($It.PSObject.Properties["Other"] -and $It.Other) { return (T "AnOther") -f $It.Other }
    if ($It.IsFiles) { return T "AnFiles" }
    return $It.Name
}

function Build-AnList {
    $list = N "AnList"; $list.Children.Clear()
    $node = Get-AnCurrent; if (-not $node) { return }
    $items = @(Get-AnItems $node 150)
    $iconFont = $window.FindResource("Icons"); $tb = $window.FindResource("TitleBtn")
    $parent = [Math]::Max([double]1, [double]$node.Size)
    $i = 0
    foreach ($it in $items) {
        $color = if ($it.IsFiles) { "#5A5A78" } else { $AnColors[$i % $AnColors.Count] }
        $canEnter = -not $it.IsFiles -and @($it.Kids).Count -gt 0
        $row = New-Object Windows.Controls.Border; $row.Padding = New-Object Windows.Thickness(16, 8, 12, 8); $row.Background = Brush "#00000000"
        $row.Margin = New-Object Windows.Thickness(6, 0, 6, 0); $row.CornerRadius = New-Object Windows.CornerRadius(8)
        $row.Add_MouseEnter({ param($s) $s.Background = Brush "#1A1A2B" }); $row.Add_MouseLeave({ param($s) $s.Background = Brush "#00000000" })
        $g = New-Object Windows.Controls.Grid; New-Cols $g @(40, "*", 170, 86, 36)
        # simge
        $ib = New-Object Windows.Controls.Border; $ib.Width = 30; $ib.Height = 30; $ib.CornerRadius = New-Object Windows.CornerRadius(8); $ib.HorizontalAlignment = "Left"
        $cc = [Windows.Media.ColorConverter]::ConvertFromString($color); $cc.A = 45; $ib.Background = New-Object Windows.Media.SolidColorBrush($cc)
        $ic = New-Tb ([string][char]$(if ($it.IsFiles) { 0xE7C3 } else { 0xE8B7 })) 14 $color; $ic.FontFamily = $iconFont; $ic.HorizontalAlignment = "Center"; $ic.VerticalAlignment = "Center"; $ib.Child = $ic
        # ad + alt bilgi
        $tx = New-Object Windows.Controls.StackPanel; $tx.VerticalAlignment = "Center"; $tx.Margin = New-Object Windows.Thickness(0, 0, 14, 0)
        $nm = New-Tb (Get-AnLabel $it) 13 $(if ($it.IsFiles) { "#B4B4CC" } else { "#EDEDF5" }); $nm.TextWrapping = "NoWrap"; $nm.TextTrimming = "CharacterEllipsis"
        if (-not $it.IsFiles) { $nm.FontWeight = [Windows.FontWeights]::SemiBold }
        $sub = if ($it.IsFiles) { (T "AnFilesN") -f $it.Files } else { ((T "AnFilesN") -f $it.Files) + "  ·  " + ((T "AnDirsN") -f $it.Dirs) }
        $st = New-Tb $sub 10.5 "#6A6A86"; $st.TextWrapping = "NoWrap"
        [void]$tx.Children.Add($nm); [void]$tx.Children.Add($st)
        # oran cubugu
        $pct = 100 * $it.Size / $parent
        $bar = New-Object Windows.Controls.Grid; $bar.VerticalAlignment = "Center"; New-Cols $bar @("*", 46)
        $track = New-Object Windows.Controls.Border; $track.Height = 6; $track.CornerRadius = New-Object Windows.CornerRadius(3); $track.Background = Brush "#23233A"; $track.VerticalAlignment = "Center"
        $fill = New-Object Windows.Controls.Border; $fill.Height = 6; $fill.CornerRadius = New-Object Windows.CornerRadius(3); $fill.Background = Brush $color; $fill.HorizontalAlignment = "Left"
        $fill.Width = [Math]::Max(3, 112 * $pct / 100)
        $track.Child = $fill
        $pt = New-Tb ("{0:N1}%" -f $pct) 11 "#9C9CB8"; $pt.HorizontalAlignment = "Right"; $pt.VerticalAlignment = "Center"
        [Windows.Controls.Grid]::SetColumn($pt, 1)
        [void]$bar.Children.Add($track); [void]$bar.Children.Add($pt)
        # boyut
        $sz = New-Tb (Fmt-GB $it.Size) 13 "#EDEDF5"; $sz.FontWeight = [Windows.FontWeights]::SemiBold; $sz.HorizontalAlignment = "Right"; $sz.VerticalAlignment = "Center"
        # Gezgin'de ac
        $op = New-Object Windows.Controls.Button; $op.Style = $tb; $op.Content = [string][char]0xE838; $op.ToolTip = T "AnOpen"; $op.Width = 30; $op.Tag = $(if ($it.IsFiles) { $node.Path } else { $it.Path })
        $op.HorizontalAlignment = "Right"
        $op.Add_Click({ param($s) if (Test-Path -LiteralPath $s.Tag) { Start-Process explorer.exe "`"$($s.Tag)`"" } })
        foreach ($pair in @(@($tx, 1), @($bar, 2), @($sz, 3), @($op, 4))) { [Windows.Controls.Grid]::SetColumn($pair[0], $pair[1]) }
        [void]$g.Children.Add($ib); [void]$g.Children.Add($tx); [void]$g.Children.Add($bar); [void]$g.Children.Add($sz); [void]$g.Children.Add($op)
        $row.Child = $g
        if ($canEnter) { $row.Cursor = "Hand"; $row.Tag = $it; $row.Add_MouseLeftButtonUp({ param($s, $e) if ($e.OriginalSource -isnot [Windows.Controls.TextBlock] -or $e.OriginalSource.Text -ne [string][char]0xE838) { Enter-AnFolder $s.Tag } }) }
        [void]$list.Children.Add($row)
        $i++
    }
}

# Squarified treemap
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
    $node = Get-AnCurrent; if (-not $node) { return }
    $W = $c.ActualWidth; $H = $c.ActualHeight
    if ($W -lt 20 -or $H -lt 20) { return }
    # Okunabilirlik: en fazla 18 kutu; %0.8'den kucukler "Diger"e
    $min = $node.Size * 0.008
    $kids = @($node.Kids)
    $big = @($kids | Where-Object { $_.Size -ge $min } | Select-Object -First 18)
    $restItems = @($kids | Where-Object { $big -notcontains $_ })
    $items = @($big)
    if ($restItems.Count) {
        $rest = ($restItems | Measure-Object Size -Sum).Sum
        if ($rest -gt 0) { $items += [pscustomobject]@{ Name = ""; Path = $node.Path; Size = [long]$rest; Files = 0; IsFiles = $true; Other = $restItems.Count; Kids = @() } }
    }
    $rects = Get-AnLayout ([double[]]@($items | ForEach-Object { [double]$_.Size })) 0 0 $W $H
    for ($k = 0; $k -lt $items.Count; $k++) {
        $it = $items[$k]; $r = $rects[$k]
        $col = if ($it.IsFiles) { "#3A3A52" } else { $AnColors[$k % $AnColors.Count] }
        $b = New-Object Windows.Controls.Border
        $b.Width = [Math]::Max(0, $r[2] - 3); $b.Height = [Math]::Max(0, $r[3] - 3)
        $b.CornerRadius = New-Object Windows.CornerRadius(6)
        $cc = [Windows.Media.ColorConverter]::ConvertFromString($col); $c1 = $cc; $c1.A = 235; $c2 = $cc; $c2.A = 165
        $b.Background = New-Object Windows.Media.LinearGradientBrush($c1, $c2, 90)
        $b.BorderBrush = Brush "#00FFFFFF"; $b.BorderThickness = New-Object Windows.Thickness(2)
        $label = Get-AnLabel $it
        $pct = 100 * $it.Size / [Math]::Max([double]1, [double]$node.Size)
        $b.ToolTip = "$label`n$(Fmt-GB $it.Size)  ·  {0:N1}%`n$($it.Path)" -f $pct
        if ($r[2] -gt 70 -and $r[3] -gt 34) {
            $sp = New-Object Windows.Controls.StackPanel; $sp.Margin = New-Object Windows.Thickness(10, 8, 8, 6)
            $t1 = New-Tb $label 12.5 "#FFFFFF"; $t1.FontWeight = [Windows.FontWeights]::SemiBold; $t1.TextWrapping = "NoWrap"; $t1.TextTrimming = "CharacterEllipsis"
            [void]$sp.Children.Add($t1)
            if ($r[3] -gt 54) { [void]$sp.Children.Add((New-Tb ("{0}  ·  {1:N1}%" -f (Fmt-GB $it.Size), $pct) 11 "#ECECF6")) }
            $b.Child = $sp
        }
        $b.Add_MouseEnter({ param($s) $s.BorderBrush = Brush "#E6FFFFFF" }); $b.Add_MouseLeave({ param($s) $s.BorderBrush = Brush "#00FFFFFF" })
        if (-not $it.IsFiles -and @($it.Kids).Count -gt 0) { $b.Cursor = "Hand"; $b.Tag = $it; $b.Add_MouseLeftButtonUp({ param($s) Enter-AnFolder $s.Tag }) }
        $b.Uid = "$($it.Path)"
        $b.Add_MouseRightButtonUp({ param($s) if ($s.Uid -and (Test-Path -LiteralPath $s.Uid)) { Start-Process explorer.exe "`"$($s.Uid)`"" } })
        [Windows.Controls.Canvas]::SetLeft($b, $r[0] + 1.5); [Windows.Controls.Canvas]::SetTop($b, $r[1] + 1.5)
        [void]$c.Children.Add($b)
    }
}

function Build-AnSide {
    $list = N "AnSide"; $list.Children.Clear()
    if ($script:AnTab -eq "big") {
        if ($script:AnTop.Count -eq 0) { $e = New-Tb (T "AnBigNone") 12 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(16, 4, 16, 0); [void]$list.Children.Add($e); return }
        $max = [double]$script:AnTop[0].Value
        $tb = $window.FindResource("TitleBtn")
        foreach ($f in $script:AnTop) {
            $row = New-Object Windows.Controls.Grid; $row.Margin = New-Object Windows.Thickness(16, 0, 8, 12); New-Cols $row @("*", "Auto", 32)
            $sp = New-Object Windows.Controls.StackPanel
            $nm = New-Tb ([IO.Path]::GetFileName($f.Key)) 12 "#EDEDF5"; $nm.TextWrapping = "NoWrap"; $nm.TextTrimming = "CharacterEllipsis"; $nm.ToolTip = $f.Key
            $dir = New-Tb ([IO.Path]::GetDirectoryName($f.Key)) 10 "#6A6A86"; $dir.TextWrapping = "NoWrap"; $dir.TextTrimming = "CharacterEllipsis"; $dir.ToolTip = $f.Key
            $track = New-Object Windows.Controls.Border; $track.Height = 3; $track.CornerRadius = New-Object Windows.CornerRadius(2); $track.Background = Brush "#23233A"; $track.Margin = New-Object Windows.Thickness(0, 5, 0, 0)
            $fill = New-Object Windows.Controls.Border; $fill.Height = 3; $fill.CornerRadius = New-Object Windows.CornerRadius(2); $fill.Background = $window.FindResource("AccentGrad"); $fill.HorizontalAlignment = "Left"
            $fill.Width = [Math]::Max(3, 200 * $f.Value / $max); $track.Child = $fill
            [void]$sp.Children.Add($nm); [void]$sp.Children.Add($dir); [void]$sp.Children.Add($track)
            $sz = New-Tb (Fmt-GB $f.Value) 12 "#EDEDF5"; $sz.FontWeight = [Windows.FontWeights]::SemiBold; $sz.Margin = New-Object Windows.Thickness(10, 0, 2, 0); $sz.VerticalAlignment = "Center"
            $op = New-Object Windows.Controls.Button; $op.Style = $tb; $op.Content = [string][char]0xE838; $op.ToolTip = T "AnOpen"; $op.Tag = $f.Key; $op.Width = 30
            $op.Add_Click({ param($s) Start-Process explorer.exe "/select,`"$($s.Tag)`"" })
            [Windows.Controls.Grid]::SetColumn($sz, 1); [Windows.Controls.Grid]::SetColumn($op, 2)
            [void]$row.Children.Add($sp); [void]$row.Children.Add($sz); [void]$row.Children.Add($op)
            [void]$list.Children.Add($row)
        }
        return
    }
    # Dosya turleri
    if ($script:AnTypes.Count -eq 0) { $e = New-Tb (T "AnBigNone") 12 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(16, 4, 16, 0); [void]$list.Children.Add($e); return }
    $total = [Math]::Max([double]1, ($script:AnTypes | Measure-Object Size -Sum).Sum)
    $note = New-Tb (T "AnTypesNote") 11 "#7A7A94"; $note.Margin = New-Object Windows.Thickness(16, 0, 16, 8); [void]$list.Children.Add($note)
    # yigilmis dagilim cubugu
    $stack = New-Object Windows.Controls.Grid; $stack.Height = 12; $stack.Margin = New-Object Windows.Thickness(16, 0, 16, 16)
    foreach ($t in $script:AnTypes) {
        $cd = New-Object Windows.Controls.ColumnDefinition; $cd.Width = New-Object Windows.GridLength([Math]::Max(0.002, $t.Size / $total), "Star"); $stack.ColumnDefinitions.Add($cd)
    }
    $ci = 0
    foreach ($t in $script:AnTypes) {
        $bd = New-Object Windows.Controls.Border; $bd.Background = Brush $AnTypeColors[$t.Cat]; $bd.Margin = New-Object Windows.Thickness(0, 0, 1, 0)
        $bd.ToolTip = "$(T "Ft_$($t.Cat)")  ·  $(Fmt-GB $t.Size)"
        if ($ci -eq 0) { $bd.CornerRadius = New-Object Windows.CornerRadius(6, 0, 0, 6) }
        if ($ci -eq $script:AnTypes.Count - 1) { $bd.CornerRadius = New-Object Windows.CornerRadius(0, 6, 6, 0) }
        [Windows.Controls.Grid]::SetColumn($bd, $ci); [void]$stack.Children.Add($bd); $ci++
    }
    [void]$list.Children.Add($stack)
    foreach ($t in $script:AnTypes) {
        $row = New-Object Windows.Controls.Grid; $row.Margin = New-Object Windows.Thickness(16, 0, 16, 12); New-Cols $row @(18, "*", "Auto")
        $dot = New-Object Windows.Controls.Border; $dot.Width = 10; $dot.Height = 10; $dot.CornerRadius = New-Object Windows.CornerRadius(3); $dot.Background = Brush $AnTypeColors[$t.Cat]; $dot.VerticalAlignment = "Top"; $dot.Margin = New-Object Windows.Thickness(0, 4, 0, 0)
        $sp = New-Object Windows.Controls.StackPanel
        [void]$sp.Children.Add((New-Tb (T "Ft_$($t.Cat)") 12.5 "#EDEDF5"))
        $s2 = New-Tb ((T "AnFilesN") -f $t.Count + $(if ($t.Top) { "  ·  $($t.Top)" } else { "" })) 10.5 "#6A6A86"; $s2.TextWrapping = "NoWrap"; $s2.TextTrimming = "CharacterEllipsis"
        [void]$sp.Children.Add($s2)
        $rt = New-Object Windows.Controls.StackPanel; $rt.HorizontalAlignment = "Right"
        $a = New-Tb (Fmt-Size $t.Size) 12.5 "#EDEDF5"; $a.FontWeight = [Windows.FontWeights]::SemiBold; $a.HorizontalAlignment = "Right"
        $b = New-Tb ("{0:N1}%" -f (100 * $t.Size / $total)) 10.5 "#7A7A94"; $b.HorizontalAlignment = "Right"
        [void]$rt.Children.Add($a); [void]$rt.Children.Add($b)
        [Windows.Controls.Grid]::SetColumn($sp, 1); [Windows.Controls.Grid]::SetColumn($rt, 2)
        [void]$row.Children.Add($dot); [void]$row.Children.Add($sp); [void]$row.Children.Add($rt)
        [void]$list.Children.Add($row)
    }
}

(N "BtnAnScan").Add_Click({ Start-AnScan })
(N "BtnAnUp").Add_Click({ if ($script:AnStack.Count -gt 1) { $script:AnStack.RemoveAt($script:AnStack.Count - 1); Update-AnView } })
(N "AnViewList").Add_Checked({ $script:AnView = "list"; Update-AnView })
(N "AnViewMap").Add_Checked({ $script:AnView = "map"; Update-AnView; [void]$window.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Loaded, [Action]{ Draw-AnMap }) })
(N "AnTabBig").Add_Checked({ $script:AnTab = "big"; Build-AnSide; (N "AnSideScroll").ScrollToTop() })
(N "AnTabTypes").Add_Checked({ $script:AnTab = "types"; Build-AnSide; (N "AnSideScroll").ScrollToTop() })
(N "AnMap").Add_SizeChanged({ if ($script:AnRoot -and $script:AnView -eq "map") { Draw-AnMap } })

$anTimer = New-Object Windows.Threading.DispatcherTimer
$anTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$anTimer.Add_Tick({
    if ($script:AnBusy -and $script:Page -eq "Analyzer") {
        (N "AnStatus").Text = ((T "AnScanning") -f [WoScan3]::Dirs, [WoScan3]::FileCount)
        (N "AnStatus").ToolTip = [WoScan3]::Current
    }
})
$anTimer.Start()

# Taramadan sonra diskte bosalan/dolan alani canli goster (silinen dosyalar aninda yansir)
$anLive = New-Object Windows.Threading.DispatcherTimer
$anLive.Interval = [TimeSpan]::FromSeconds(3)
$anLive.Add_Tick({
    if ($script:Page -ne "Analyzer" -or $script:AnBusy -or -not $script:AnRoot -or -not $window.IsVisible) { return }
    try {
        $d = New-Object IO.DriveInfo($script:AnScanLetter)
        $delta = ([double]($d.TotalSize - $d.AvailableFreeSpace)) - $script:AnUsedAtScan
        $info = N "AnDeltaText"
        if ([Math]::Abs($delta) -lt 1MB) { $info.Visibility = "Collapsed"; return }
        $info.Visibility = "Visible"
        $info.Text = (T "AnDelta") -f (Fmt-Size ([Math]::Abs($delta))), $(if ($delta -lt 0) { T "AnDeltaFreed" } else { T "AnDeltaUsed" })
        $info.Foreground = Brush $(if ($delta -lt 0) { "#34D399" } else { "#FBBF24" })
    } catch {}
})
$anLive.Start()
