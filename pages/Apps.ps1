# pages/Apps.ps1 - Onceden yuklu uygulama (bloatware) kaldirici
# Yalnizca kaldirilabilir Store paketleri listelenir; cerceveler, sistem bilesenleri ve Store/winget asla gosterilmez.

Add-WoStrings @{
    NavApps = "Uygulamalar"; Title_Apps = "Önceden Yüklü Uygulamalar"; Sub_Apps = "Gereksiz Windows uygulamalarını kaldırın — Mağaza'dan geri yüklenebilir"
    ApLoading = "Uygulamalar taranıyor…"; ApSummary = "{0} kaldırılabilir uygulama · {1} gereksiz olarak işaretli"
    ApHint = "Kritik sistem bileşenleri, Microsoft Store ve kodekler listelenmez. Kaldırılan uygulamalar Microsoft Store'dan yeniden yüklenebilir."
    BtnApRefresh = "Yenile"; BtnApSelRec = "Önerilenleri seç"; BtnApRemove = "Seçilenleri kaldır ({0})"
    ApFRec = "Gereksiz ({0})"; ApFAll = "Tümü ({0})"; ApFRemoved = "Kaldırılanlar ({0})"
    ApProvision = "Yeni kullanıcı hesapları için de kaldır"; ApBadgeRec = "GEREKSİZ"; ApBadgeCaution = "DİKKAT"
    ApStore = "Mağazada aç"; ApRemovedOn = "{0} tarihinde kaldırıldı"
    ApConfirmTitle = "Uygulamalar kaldırılsın mı?"; ApConfirmMsg = "{0} uygulama bu kullanıcı için kaldırılacak:"
    ApConfirmProv = "Yeni kullanıcı hesaplarına da yüklenmeyecek."; ApConfirmFoot = "Gerekirse Microsoft Store'dan yeniden yükleyebilirsiniz."
    ApConfirmOk = "Kaldır"; ApRemoving = "Uygulamalar kaldırılıyor… ({0})"; ApDone = "{0} uygulama kaldırıldı"; ApWarn = "{0} kaldırıldı, {1} başarısız (ayrıntılar günlükte)"
    ApEmpty = "Bu listede uygulama yok."; ApNoRemoved = "Henüz uygulama kaldırılmadı."
} @{
    NavApps = "Apps"; Title_Apps = "Preinstalled Apps"; Sub_Apps = "Remove unnecessary Windows apps — reinstallable from the Store"
    ApLoading = "Scanning apps…"; ApSummary = "{0} removable apps · {1} marked as unnecessary"
    ApHint = "Critical system components, Microsoft Store and codecs are not listed. Removed apps can be reinstalled from the Microsoft Store."
    BtnApRefresh = "Refresh"; BtnApSelRec = "Select recommended"; BtnApRemove = "Remove selected ({0})"
    ApFRec = "Unnecessary ({0})"; ApFAll = "All ({0})"; ApFRemoved = "Removed ({0})"
    ApProvision = "Also remove for new user accounts"; ApBadgeRec = "UNNECESSARY"; ApBadgeCaution = "CAUTION"
    ApStore = "Open in Store"; ApRemovedOn = "Removed on {0}"
    ApConfirmTitle = "Remove apps?"; ApConfirmMsg = "{0} apps will be removed for this user:"
    ApConfirmProv = "They won't be installed for new user accounts either."; ApConfirmFoot = "You can reinstall them from the Microsoft Store if needed."
    ApConfirmOk = "Remove"; ApRemoving = "Removing apps… ({0})"; ApDone = "{0} apps removed"; ApWarn = "{0} removed, {1} failed (see log)"
    ApEmpty = "No apps in this list."; ApNoRemoved = "No apps removed yet."
}

Register-WoPage @{
    Name = "Apps"; Icon = 0xE74C
    Loc = @("ApHint", "BtnApRefresh", "BtnApSelRec", "ApProvision")
    Xaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PageApps">
  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <Border Style="{DynamicResource Card}" Padding="18,12" Margin="0,0,14,0">
    <Grid>
      <StackPanel VerticalAlignment="Center" Margin="0,0,470,0">
        <TextBlock x:Name="ApSummary" FontSize="13.5" FontWeight="SemiBold" Foreground="{DynamicResource Txt}"/>
        <TextBlock x:Name="ApHint" Style="{DynamicResource Desc}" Margin="0,4,0,0"/>
      </StackPanel>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
        <Button x:Name="BtnApRefresh" Style="{DynamicResource SecondaryBtn}" Margin="0,0,8,0"/>
        <Button x:Name="BtnApSelRec" Style="{DynamicResource SecondaryBtn}" Margin="0,0,8,0"/>
        <Button x:Name="BtnApRemove" Style="{DynamicResource DangerBtn}" Height="36" IsEnabled="False"/>
      </StackPanel>
    </Grid>
  </Border>
  <Grid Grid.Row="1" Margin="0,12,14,0">
    <WrapPanel VerticalAlignment="Center">
      <RadioButton x:Name="ApFRec" GroupName="apf" Style="{DynamicResource SegBtn}" Tag="rec" IsChecked="True"/>
      <RadioButton x:Name="ApFAll" GroupName="apf" Style="{DynamicResource SegBtn}" Tag="all"/>
      <RadioButton x:Name="ApFRemoved" GroupName="apf" Style="{DynamicResource SegBtn}" Tag="removed"/>
    </WrapPanel>
    <CheckBox x:Name="ApProvision" Style="{DynamicResource Check}" Margin="0" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="{DynamicResource Txt2}" FontSize="12.5"/>
  </Grid>
  <ScrollViewer x:Name="ApScroll" Grid.Row="2" Margin="0,12,0,0">
    <StackPanel x:Name="AppList" Margin="0,0,14,20"/>
  </ScrollViewer>
</Grid>
'@
    OnShow = { if (-not $script:AppsLoaded) { Load-Apps } }
    OnLang = { if ($script:AppsLoaded) { Build-AppList } else { (N "ApSummary").Text = T "ApLoading" } }
}

# Ad deseni -> @(risk, TR ad, EN ad)   risk: rec | caution
$WoBloat = [ordered]@{
    "Microsoft.BingNews" = @("rec", "Haberler", "News"); "Microsoft.BingWeather" = @("rec", "Hava Durumu", "Weather")
    "Microsoft.BingSearch" = @("rec", "Bing Arama", "Bing Search"); "Microsoft.GetHelp" = @("rec", "Yardım Alın", "Get Help")
    "Microsoft.Getstarted" = @("rec", "İpuçları", "Tips"); "Microsoft.MicrosoftSolitaireCollection" = @("rec", "Solitaire Collection", "Solitaire Collection")
    "Microsoft.MicrosoftOfficeHub" = @("rec", "Microsoft 365 (Office)", "Microsoft 365 (Office)"); "Microsoft.People" = @("rec", "Kişiler", "People")
    "Microsoft.PowerAutomateDesktop" = @("rec", "Power Automate", "Power Automate"); "Microsoft.Todos" = @("rec", "Microsoft To Do", "Microsoft To Do")
    "Microsoft.WindowsFeedbackHub" = @("rec", "Geri Bildirim Merkezi", "Feedback Hub"); "Microsoft.WindowsMaps" = @("rec", "Haritalar", "Maps")
    "Microsoft.ZuneVideo" = @("rec", "Filmler ve TV", "Movies & TV"); "Microsoft.MixedReality.Portal" = @("rec", "Karma Gerçeklik Portalı", "Mixed Reality Portal")
    "Microsoft.SkypeApp" = @("rec", "Skype", "Skype"); "Microsoft.Microsoft3DViewer" = @("rec", "3D Görüntüleyici", "3D Viewer")
    "Microsoft.MSPaint" = @("rec", "Paint 3D", "Paint 3D"); "Microsoft.Wallet" = @("rec", "Cüzdan", "Wallet")
    "Clipchamp.Clipchamp" = @("rec", "Clipchamp", "Clipchamp"); "MicrosoftTeams" = @("rec", "Microsoft Teams (Kişisel)", "Microsoft Teams (Personal)")
    "MSTeams" = @("rec", "Microsoft Teams", "Microsoft Teams"); "Microsoft.549981C3F5F10" = @("rec", "Cortana", "Cortana")
    "Microsoft.Windows.DevHome" = @("rec", "Dev Home", "Dev Home"); "Microsoft.Copilot" = @("rec", "Copilot", "Copilot")
    "MicrosoftWindows.Client.WebExperience" = @("rec", "Pencere Öğeleri (Widgets)", "Widgets"); "Microsoft.XboxApp" = @("rec", "Xbox Konsol Yardımcısı", "Xbox Console Companion")
    "Microsoft.MicrosoftJournal" = @("rec", "Microsoft Journal", "Microsoft Journal"); "MicrosoftCorporationII.MicrosoftFamily" = @("rec", "Microsoft Aile", "Microsoft Family")
    "Microsoft.OutlookForWindows" = @("caution", "Outlook (yeni)", "Outlook (new)"); "Microsoft.YourPhone" = @("caution", "Telefon Bağlantısı", "Phone Link")
    "Microsoft.GamingApp" = @("caution", "Xbox", "Xbox"); "Microsoft.XboxGamingOverlay" = @("caution", "Xbox Game Bar", "Xbox Game Bar")
    "Microsoft.Xbox.TCUI" = @("caution", "Xbox TCUI", "Xbox TCUI"); "Microsoft.XboxSpeechToTextOverlay" = @("caution", "Xbox Konuşmadan Metne", "Xbox Speech To Text")
    "king.com.*" = @("rec", "", ""); "*CandyCrush*" = @("rec", "", ""); "SpotifyAB.SpotifyMusic" = @("rec", "Spotify", "Spotify")
    "*Disney*" = @("rec", "", ""); "*Netflix*" = @("rec", "", ""); "*TikTok*" = @("rec", "", ""); "*Instagram*" = @("rec", "", "")
    "*Facebook*" = @("rec", "", ""); "*LinkedIn*" = @("rec", "", ""); "*AmazonVideo*" = @("rec", "", ""); "*PrimeVideo*" = @("rec", "", "")
}
# Asla listelenmeyenler (kaldirilmasi Windows'u bozar ya da uygulama kurulumunu engeller)
$WoAppsNever = 'WindowsStore|StorePurchaseApp|DesktopAppInstaller|SecHealthUI|ShellExperienceHost|StartMenuExperienceHost|VCLibs|NET\.Native|UI\.Xaml|WindowsAppRuntime|Extension$|VP9|WebMedia|WebpImage|HEIF|HEVC|AV1|RawImage|Winget|Windows\.Photos|WindowsCalculator|WindowsNotepad|WindowsTerminal|ScreenSketch|Paint$|WindowsCamera|ApplicationCompatibilityEnhancements|LanguageExperiencePack|Client\.CBS|Client\.Core|Client\.AIX|CrossDevice|WidgetsPlatformRuntime|StartExperiencesApp'

$script:AppsLoaded = $false; $script:AppsBusy = $false; $script:Apps = @(); $script:AppSel = @{}; $script:AppFilter = "rec"
$WoAppsLogPath = Join-Path $AppDir "apps-removed.json"

function Get-WoRemovedApps {
    if (Test-Path $WoAppsLogPath) { try { return @(Get-Content $WoAppsLogPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {} }
    return @()
}

function Load-Apps {
    if ($script:AppsBusy) { return }
    $script:AppsBusy = $true
    (N "ApSummary").Text = T "ApLoading"
    (N "BtnApRefresh").IsEnabled = $false
    Start-Bg -Work {
        param($Never)
        foreach ($p in Get-AppxPackage) {
            if ($p.IsFramework -or $p.NonRemovable -or "$($p.SignatureKind)" -eq "System" -or $p.Name -match $Never) { continue }
            $disp = ""; $logo = ""
            try {
                $mf = Join-Path $p.InstallLocation "AppxManifest.xml"
                if (Test-Path -LiteralPath $mf) {
                    [xml]$x = Get-Content -LiteralPath $mf -Raw
                    $d = "$($x.Package.Properties.DisplayName)"
                    if ($d -and $d -notlike "ms-resource:*") { $disp = $d }
                    $rel = "$($x.Package.Properties.Logo)"
                    if ($rel) {
                        $dir = Join-Path $p.InstallLocation (Split-Path $rel -Parent)
                        $base = [IO.Path]::GetFileNameWithoutExtension($rel)
                        $cand = @(Get-ChildItem -LiteralPath $dir -Filter "$base*.png" -ErrorAction SilentlyContinue | Sort-Object Length)
                        $pick = $cand | Where-Object { $_.Name -match 'scale-100|targetsize-32|targetsize-48' } | Select-Object -First 1
                        if (-not $pick) { $pick = $cand | Select-Object -First 1 }
                        if ($pick) { $logo = $pick.FullName }
                    }
                }
            } catch {}
            [pscustomobject]@{ Name = $p.Name; FullName = $p.PackageFullName; Family = $p.PackageFamilyName; Publisher = ($p.Publisher -replace '^CN=([^,]+).*', '$1')
                               Version = "$($p.Version)"; Display = $disp; Logo = $logo }
        }
    } -ArgList @($WoAppsNever) -Done {
        param($out, $err)
        $script:AppsBusy = $false; $script:AppsLoaded = $true
        (N "BtnApRefresh").IsEnabled = $true
        if ($err) { Write-WoLog "Uygulama taramasi: $err" }
        $script:Apps = @($out | Where-Object { $_ -and $_.Name } | ForEach-Object {
            $a = $_; $info = $null
            foreach ($k in $WoBloat.Keys) { if ($a.Name -like $k) { $info = $WoBloat[$k]; break } }
            $name = if ($info -and $info[1]) { if ($script:Lang -eq "TR") { $info[1] } else { $info[2] } } elseif ($a.Display) { $a.Display } else { ($a.Name -split '\.')[-1] }
            $a | Add-Member -NotePropertyName Risk -NotePropertyValue $(if ($info) { $info[0] } else { "" }) -PassThru |
                 Add-Member -NotePropertyName Title -NotePropertyValue $name -PassThru
        } | Sort-Object @{ e = { $_.Risk -ne "rec" } }, Title)
        $script:AppSel = @{}
        Build-AppList
    }
}

function Update-AppButtons {
    $n = @($script:AppSel.Keys | Where-Object { $script:AppSel[$_] }).Count
    (N "BtnApRemove").Content = (T "BtnApRemove") -f $n
    (N "BtnApRemove").IsEnabled = ($n -gt 0) -and -not $script:AppsBusy
}

function Build-AppList {
    $list = N "AppList"; $list.Children.Clear()
    $removed = Get-WoRemovedApps
    $rec = @($script:Apps | Where-Object Risk -eq "rec")
    (N "ApSummary").Text = (T "ApSummary") -f $script:Apps.Count, $rec.Count
    (N "ApFRec").Content = (T "ApFRec") -f $rec.Count
    (N "ApFAll").Content = (T "ApFAll") -f $script:Apps.Count
    (N "ApFRemoved").Content = (T "ApFRemoved") -f $removed.Count
    Update-AppButtons

    $card = New-Object Windows.Controls.Border
    $card.Style = $window.FindResource("Card"); $card.Padding = New-Object Windows.Thickness(0)
    $stack = New-Object Windows.Controls.StackPanel; $card.Child = $stack
    $check = $window.FindResource("Check"); $sec = $window.FindResource("SecondaryBtn")

    if ($script:AppFilter -eq "removed") {
        if ($removed.Count -eq 0) { $e = New-Tb (T "ApNoRemoved") 13 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(6, 20, 0, 0); [void]$list.Children.Add($e); return }
        $first = $true
        foreach ($r in ($removed | Sort-Object Date -Descending)) {
            $row = New-Object Windows.Controls.Border; $row.Padding = New-Object Windows.Thickness(18, 12, 18, 12)
            if (-not $first) { $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0) }; $first = $false
            $g = New-Object Windows.Controls.Grid; New-Cols $g @("*", "Auto")
            $tx = New-Object Windows.Controls.StackPanel
            [void]$tx.Children.Add((New-Tb $r.Title 13.5 "#EDEDF5"))
            $m = New-Tb (((T "ApRemovedOn") -f $r.Date) + "  ·  " + $r.Name) 11 "#6A6A86"; $m.Margin = New-Object Windows.Thickness(0, 3, 0, 0); [void]$tx.Children.Add($m)
            $b = New-Object Windows.Controls.Button; $b.Style = $sec; $b.Content = T "ApStore"; $b.Tag = $r.Family; $b.Height = 32
            $b.Add_Click({ param($s) Start-Process "ms-windows-store://pdp/?PFN=$($s.Tag)" })
            [Windows.Controls.Grid]::SetColumn($b, 1)
            [void]$g.Children.Add($tx); [void]$g.Children.Add($b); $row.Child = $g
            [void]$stack.Children.Add($row)
        }
        [void]$list.Children.Add($card); return
    }

    $items = if ($script:AppFilter -eq "rec") { @($script:Apps | Where-Object { $_.Risk }) } else { $script:Apps }
    if ($items.Count -eq 0) { $e = New-Tb (T "ApEmpty") 13 "#7A7A94"; $e.Margin = New-Object Windows.Thickness(6, 20, 0, 0); [void]$list.Children.Add($e); return }
    $first = $true
    foreach ($a in $items) {
        $row = New-Object Windows.Controls.Border; $row.Padding = New-Object Windows.Thickness(18, 10, 18, 10)
        if (-not $first) { $row.BorderBrush = Brush "#1E1E32"; $row.BorderThickness = New-Object Windows.Thickness(0, 1, 0, 0) }; $first = $false
        $g = New-Object Windows.Controls.Grid; New-Cols $g @(34, 46, "*")
        $cb = New-Object Windows.Controls.CheckBox; $cb.Style = $check; $cb.Margin = New-Object Windows.Thickness(0); $cb.VerticalAlignment = "Center"
        $cb.Tag = $a.FullName; $cb.IsChecked = [bool]$script:AppSel[$a.FullName]; $cb.Focusable = $false
        $cb.Add_Click({ param($s) $script:AppSel[$s.Tag] = [bool]$s.IsChecked; Update-AppButtons })
        $ib = New-Object Windows.Controls.Border; $ib.Width = 34; $ib.Height = 34; $ib.CornerRadius = New-Object Windows.CornerRadius(9)
        $ib.Background = Brush "#1C1C2E"; $ib.HorizontalAlignment = "Left"
        $img = $null
        if ($a.Logo) { try { $img = New-Object Windows.Media.Imaging.BitmapImage; $img.BeginInit(); $img.UriSource = New-Object Uri($a.Logo); $img.DecodePixelWidth = 48; $img.CacheOption = "OnLoad"; $img.EndInit() } catch { $img = $null } }
        if ($img) { $im = New-Object Windows.Controls.Image; $im.Source = $img; $im.Width = 24; $im.Height = 24; $ib.Child = $im }
        else { $lt = New-Tb ("$($a.Title)".Substring(0, 1).ToUpper()) 14 "#A78BFA"; $lt.FontWeight = [Windows.FontWeights]::Bold; $lt.HorizontalAlignment = "Center"; $lt.VerticalAlignment = "Center"; $ib.Child = $lt }
        $tx = New-Object Windows.Controls.StackPanel; $tx.VerticalAlignment = "Center"
        $tr = New-Object Windows.Controls.WrapPanel
        [void]$tr.Children.Add((New-Tb $a.Title 13.5 "#EDEDF5"))
        if ($a.Risk -eq "rec") { [void]$tr.Children.Add((New-Badge (T "ApBadgeRec") "#1E2A44" "#7DD3FC")) }
        if ($a.Risk -eq "caution") { [void]$tr.Children.Add((New-Badge (T "ApBadgeCaution") "#3A2E10" "#FCD34D")) }
        $m = New-Tb "$($a.Publisher)  ·  $($a.Name)  ·  v$($a.Version)" 10.5 "#6A6A86"; $m.TextWrapping = "NoWrap"; $m.TextTrimming = "CharacterEllipsis"; $m.Margin = New-Object Windows.Thickness(0, 2, 0, 0)
        [void]$tx.Children.Add($tr); [void]$tx.Children.Add($m)
        [Windows.Controls.Grid]::SetColumn($ib, 1); [Windows.Controls.Grid]::SetColumn($tx, 2)
        [void]$g.Children.Add($cb); [void]$g.Children.Add($ib); [void]$g.Children.Add($tx)
        $row.Child = $g
        [void]$stack.Children.Add($row)
    }
    [void]$list.Children.Add($card)
}

function Remove-SelectedApps {
    $sel = @($script:Apps | Where-Object { $script:AppSel[$_.FullName] })
    if ($sel.Count -eq 0 -or $script:AppsBusy) { return }
    $prov = [bool](N "ApProvision").IsChecked
    $msg = ((T "ApConfirmMsg") -f $sel.Count) + "`n`n" + (($sel | Select-Object -First 12 | ForEach-Object { "•  $($_.Title)" }) -join "`n")
    if ($sel.Count -gt 12) { $msg += "`n•  …" }
    $msg += "`n`n" + $(if ($prov) { (T "ApConfirmProv") + " " } else { "" }) + (T "ApConfirmFoot")
    if (-not (Show-WoDialog -Title (T "ApConfirmTitle") -Message $msg -Kind "warn" -Ok (T "ApConfirmOk") -Cancel (T "DlgCancel") -Danger)) { return }
    $script:AppsBusy = $true; Update-AppButtons
    Set-Status ((T "ApRemoving") -f $sel.Count) "busy"
    $jobs = @($sel | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName; Family = $_.Family; Title = $_.Title } })
    Start-Bg -Work {
        param($Jobs, $Prov)
        $provList = if ($Prov) { @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) } else { @() }
        foreach ($j in $Jobs) {
            try {
                Remove-AppxPackage -Package $j.FullName -ErrorAction Stop
                foreach ($pp in ($provList | Where-Object DisplayName -eq $j.Name)) {
                    try { Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Stop | Out-Null } catch {}
                }
                [pscustomobject]@{ Job = $j; Ok = $true }
            } catch { [pscustomobject]@{ Job = $j; Ok = $false; Err = $_.Exception.Message } }
        }
    } -ArgList @($jobs, $prov) -Done {
        param($out, $err)
        $script:AppsBusy = $false
        $res = @($out | Where-Object Job)
        $ok = @($res | Where-Object Ok)
        foreach ($f in @($res | Where-Object { -not $_.Ok })) { Write-WoLog "Uygulama kaldirma ($($f.Job.Name)): $($f.Err)" }
        if ($ok.Count) {
            $log = @(Get-WoRemovedApps) + @($ok | ForEach-Object { [pscustomobject]@{ Name = $_.Job.Name; Family = $_.Job.Family; Title = $_.Job.Title; Date = (Get-Date -Format "yyyy-MM-dd HH:mm") } })
            ConvertTo-Json @($log) -Depth 3 | Set-Content $WoAppsLogPath -Encoding UTF8
        }
        if ($ok.Count -eq $res.Count) { Set-Status ((T "ApDone") -f $ok.Count) "ok" } else { Set-Status ((T "ApWarn") -f $ok.Count, ($res.Count - $ok.Count)) "warn" }
        Load-Apps
    }
}

(N "BtnApRefresh").Add_Click({ Load-Apps })
(N "BtnApRemove").Add_Click({ Remove-SelectedApps })
(N "BtnApSelRec").Add_Click({
    foreach ($a in $script:Apps) { if ($a.Risk -eq "rec") { $script:AppSel[$a.FullName] = $true } }
    Build-AppList
})
foreach ($f in @("ApFRec", "ApFAll", "ApFRemoved")) {
    (N $f).Add_Checked({ param($s) $script:AppFilter = $s.Tag; if ($script:AppsLoaded) { Build-AppList; (N "ApScroll").ScrollToTop() } })
}
