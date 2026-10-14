# modules/Startup.ps1 - Baslangic uygulamalari yoneticisi
# Kaynaklar: Run anahtarlari (HKCU/HKLM/WOW6432Node), Baslangic klasorleri, oturum acilisinda calisan zamanlanmis gorevler.
# Acma/kapama Gorev Yoneticisi ile ayni yontemi kullanir (StartupApproved), yani orada da ayni gorunur.

$WoApprovedRoot = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved"

# Bilinen sistem / guvenlik bilesenleri: kapatilabilir ama uyari gosterilir
$WoStartupCritical = @("SecurityHealth", "Windows Defender", "MsMpEng", "RtkAudUService", "RTHDVCPL", "igfx", "Synaptics", "ETDCtrl", "Elan")

# Kapatilmasi guvenli, acilisi yavaslatan bilinen uygulamalar (gerektiginde elle acilirlar)
$WoStartupJunk = @("CopilotAutoLaunch", "mscopilot", "MicrosoftEdgeAutoLaunch", "Teams", "Spotify", "Steam", "EADM", "EpicGamesLauncher",
    "RiotClient", "Riot Client", "Discord", "NortonBrowserAutoLaunch", "AdobeAAMUpdater", "Adobe Acrobat Synchronizer", "SunJavaUpdateSched",
    "Opera scheduled", "Opera Browser Assistant", "GoogleUpdate", "CCleaner", "Skype", "iTunesHelper", "Lync", "Battle.net",
    "Ubisoft", "GalaxyClient", "Overwolf", "Wallpaper Engine", "Zoom", "WhatsApp", "Telegram")

function Split-WoCommand([string]$Cmd) {
    if (-not $Cmd) { return "" }
    $c = [Environment]::ExpandEnvironmentVariables($Cmd.Trim())
    if ($c.StartsWith('"')) {
        $end = $c.IndexOf('"', 1)
        if ($end -gt 0) { return $c.Substring(1, $end - 1) }
    }
    $m = [regex]::Match($c, '^(.+?\.(exe|cmd|bat|com|vbs|ps1|lnk))(\s|$)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    return ($c -split ' ')[0]
}

function Get-WoApprovedEnabled([string]$Hive, [string]$Sub, [string]$Name) {
    try { $b = (Get-ItemProperty -LiteralPath "$Hive`:\$WoApprovedRoot\$Sub" -Name $Name -ErrorAction Stop).$Name } catch { return $true }
    if ($b -is [byte[]] -and $b.Length -gt 0) { return (($b[0] -band 1) -eq 0) }
    return $true
}

function Set-WoApproved([string]$Hive, [string]$Sub, [string]$Name, [bool]$Enabled) {
    $p = "$Hive`:\$WoApprovedRoot\$Sub"
    if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
    $bytes = New-Object byte[] 12
    if ($Enabled) { $bytes[0] = 2 }
    else { $bytes[0] = 3; [BitConverter]::GetBytes([DateTime]::Now.ToFileTime()).CopyTo($bytes, 4) }
    New-ItemProperty -LiteralPath $p -Name $Name -Value $bytes -PropertyType Binary -Force -ErrorAction Stop | Out-Null
}

function Get-WoFileMeta([string]$Path) {
    $meta = @{ Publisher = ""; Description = ""; Exists = $false }
    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $meta.Exists = $true
        try {
            $vi = (Get-Item -LiteralPath $Path -Force).VersionInfo
            $meta.Publisher = "$($vi.CompanyName)".Trim()
            $meta.Description = "$($vi.FileDescription)".Trim()
        } catch {}
    }
    return $meta
}

function Get-WoStartupItems {
    $items = New-Object System.Collections.ArrayList
    $add = {
        param($Name, $Command, $Path, $Source, $Hive, $Sub, $ApprovedName, $TaskPath, $Enabled)
        $meta = Get-WoFileMeta $Path
        $crit = [bool]($WoStartupCritical | Where-Object { $Name -like "*$_*" -or $Path -like "*$_*" })
        $junk = (-not $crit) -and [bool]($WoStartupJunk | Where-Object { $Name -like "*$_*" -or $Path -like "*$_*" })
        [void]$items.Add([pscustomobject]@{
            Id = "$Source|$Hive|$Sub|$ApprovedName|$TaskPath"; Name = $Name; Command = $Command; Path = $Path
            Publisher = $meta.Publisher; Description = $meta.Description; Exists = $meta.Exists
            Source = $Source; Hive = $Hive; Sub = $Sub; ApprovedName = $ApprovedName; TaskPath = $TaskPath
            Enabled = $Enabled; Critical = $crit; Junk = $junk
        })
    }

    # 1) Run anahtarlari
    $runKeys = @(
        @{ Reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Hive = "HKCU"; Sub = "Run"; Src = "RegUser" }
        @{ Reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Hive = "HKLM"; Sub = "Run"; Src = "RegMachine" }
        @{ Reg = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Hive = "HKLM"; Sub = "Run32"; Src = "RegMachine" }
    )
    foreach ($rk in $runKeys) {
        if (-not (Test-Path $rk.Reg)) { continue }
        $props = Get-ItemProperty -LiteralPath $rk.Reg
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -like "PS*") { continue }
            $cmd = "$($p.Value)"
            & $add $p.Name $cmd (Split-WoCommand $cmd) $rk.Src $rk.Hive $rk.Sub $p.Name "" (Get-WoApprovedEnabled $rk.Hive $rk.Sub $p.Name)
        }
    }

    # 2) Baslangic klasorleri
    $ws = New-Object -ComObject WScript.Shell
    $folders = @(
        @{ Dir = [Environment]::GetFolderPath("Startup"); Hive = "HKCU"; Src = "FolderUser" }
        @{ Dir = [Environment]::GetFolderPath("CommonStartup"); Hive = "HKLM"; Src = "FolderCommon" }
    )
    foreach ($f in $folders) {
        if (-not $f.Dir -or -not (Test-Path $f.Dir)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $f.Dir -File -Force | Where-Object { $_.Name -ne "desktop.ini" }) {
            $target = $file.FullName; $cmd = $file.FullName
            if ($file.Extension -eq ".lnk") {
                try { $sc = $ws.CreateShortcut($file.FullName); $target = $sc.TargetPath; $cmd = "$($sc.TargetPath) $($sc.Arguments)".Trim() } catch {}
            }
            & $add $file.BaseName $cmd $target $f.Src $f.Hive "StartupFolder" $file.Name "" (Get-WoApprovedEnabled $f.Hive "StartupFolder" $file.Name)
        }
    }

    # 3) Oturum acilisinda / acilista calisan zamanlanmis gorevler (Microsoft'un kendi gorevleri haric)
    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop | Where-Object {
            $_.TaskPath -notlike "\Microsoft\*" -and
            ($_.Triggers | Where-Object { $_.CimClass.CimClassName -in @("MSFT_TaskLogonTrigger", "MSFT_TaskBootTrigger") })
        }
        foreach ($t in $tasks) {
            $act = $t.Actions | Select-Object -First 1
            $exe = [Environment]::ExpandEnvironmentVariables("$($act.Execute)".Trim('"'))
            & $add $t.TaskName ("$exe $($act.Arguments)".Trim()) $exe "Task" "" "" $t.TaskName $t.TaskPath ($t.State -ne "Disabled")
        }
    } catch {}

    return $items
}

function Set-WoStartupItem($Item, [bool]$Enabled) {
    if ($Item.Source -eq "Task") {
        if ($Enabled) { Enable-ScheduledTask -TaskPath $Item.TaskPath -TaskName $Item.ApprovedName -ErrorAction Stop | Out-Null }
        else { Disable-ScheduledTask -TaskPath $Item.TaskPath -TaskName $Item.ApprovedName -ErrorAction Stop | Out-Null }
    } else {
        Set-WoApproved $Item.Hive $Item.Sub $Item.ApprovedName $Enabled
    }
}
