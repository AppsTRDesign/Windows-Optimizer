# modules/Network.ps1 - Ag bagdastiricilari ve DNS yonetimi
# Ilk DNS degisikliginden once her bagdastiricinin orijinal ayari network-backup.json'a yazilir.

$WoNetBackupPath = Join-Path (Split-Path $PSScriptRoot -Parent) "network-backup.json"

$WoDnsProviders = [ordered]@{
    auto       = @{ Name = "Auto"; V4 = @() }
    cloudflare = @{ Name = "Cloudflare"; V4 = @("1.1.1.1", "1.0.0.1") }
    google     = @{ Name = "Google"; V4 = @("8.8.8.8", "8.8.4.4") }
    quad9      = @{ Name = "Quad9"; V4 = @("9.9.9.9", "149.112.112.112") }
    adguard    = @{ Name = "AdGuard"; V4 = @("94.140.14.14", "94.140.15.15") }
    opendns    = @{ Name = "OpenDNS"; V4 = @("208.67.222.222", "208.67.220.220") }
    cffamily   = @{ Name = "Cloudflare Family"; V4 = @("1.1.1.3", "1.0.0.3") }
}

function Get-WoStaticDns([string]$Guid) {
    $v = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$Guid", "NameServer", "")
    return @("$v" -split '[,\s]+' | Where-Object { $_ })
}

function Get-WoNetAdapters {
    foreach ($a in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq "Up")) {
        $cfg = Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue
        $dns = @((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses)
        $static = @(Get-WoStaticDns $a.InterfaceGuid)
        $prov = "custom"
        if ($static.Count -eq 0) { $prov = "auto" }
        else { foreach ($k in $WoDnsProviders.Keys) { if ($k -ne "auto" -and $WoDnsProviders[$k].V4[0] -eq $static[0]) { $prov = $k; break } } }
        [pscustomobject]@{
            Index = $a.ifIndex; Guid = "$($a.InterfaceGuid)"; Name = $a.Name; Desc = $a.InterfaceDescription; Mac = $a.MacAddress
            Speed = $a.LinkSpeed; Wifi = ($a.PhysicalMediaType -match '802\.11|Wireless' -or $a.InterfaceDescription -match 'Wi-?Fi|Wireless')
            IPv4 = @($cfg.IPv4Address | ForEach-Object IPAddress) -join ", "; Gateway = @($cfg.IPv4DefaultGateway | ForEach-Object NextHop) -join ", "
            Dns = $dns -join ", "; Provider = $prov
        }
    }
}

# Bir DNS sunucusunun sorgu suresi (ms, en iyi 3 deneme); ulasilamazsa -1
function Test-WoDnsLatency([string]$Server) {
    $best = -1
    foreach ($h in @("www.microsoft.com", "www.google.com", "www.wikipedia.org")) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        try {
            Resolve-DnsName -Name $h -Server $Server -DnsOnly -NoHostsFile -QuickTimeout -Type A -ErrorAction Stop | Out-Null
            $ms = [int]$sw.ElapsedMilliseconds
            if ($best -lt 0 -or $ms -lt $best) { $best = $ms }
        } catch {}
    }
    return $best
}

function Save-WoNetBackup($Adapters) {
    $b = [pscustomobject]@{}
    if (Test-Path $WoNetBackupPath) { try { $b = Get-Content $WoNetBackupPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }
    $changed = $false
    foreach ($a in $Adapters) {
        if ($b.PSObject.Properties[$a.Guid]) { continue }
        $b | Add-Member -NotePropertyName $a.Guid -NotePropertyValue ([pscustomobject]@{ Name = $a.Name; Index = $a.Index; Servers = @(Get-WoStaticDns $a.Guid) })
        $changed = $true
    }
    if ($changed) { $b | ConvertTo-Json -Depth 4 | Set-Content $WoNetBackupPath -Encoding UTF8 }
}

function Set-WoDns([string]$Provider) {
    $adapters = @(Get-WoNetAdapters)
    Save-WoNetBackup $adapters
    $p = $WoDnsProviders[$Provider]
    foreach ($a in $adapters) {
        if ($Provider -eq "auto") { Set-DnsClientServerAddress -InterfaceIndex $a.Index -ResetServerAddresses -ErrorAction Stop }
        else { Set-DnsClientServerAddress -InterfaceIndex $a.Index -ServerAddresses $p.V4 -ErrorAction Stop }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    return $adapters.Count
}

function Get-WoNetBackupCount {
    if (-not (Test-Path $WoNetBackupPath)) { return 0 }
    try { return @((Get-Content $WoNetBackupPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties).Count } catch { return 0 }
}

function Restore-WoNetwork {
    if (-not (Test-Path $WoNetBackupPath)) { return }
    $b = Get-Content $WoNetBackupPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in @($b.PSObject.Properties)) {
        $e = $p.Value
        try {
            $ad = Get-NetAdapter -ErrorAction Stop | Where-Object { "$($_.InterfaceGuid)" -eq $p.Name } | Select-Object -First 1
            if (-not $ad) { throw "Bagdastirici bulunamadi" }
            $servers = @($e.Servers | Where-Object { $_ })
            if ($servers.Count -eq 0) { Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ResetServerAddresses -ErrorAction Stop }
            else { Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses $servers -ErrorAction Stop }
            [pscustomobject]@{ Name = "DNS: $($e.Name)"; Ok = $true }
        } catch { [pscustomobject]@{ Name = "DNS: $($e.Name)"; Ok = $false; Err = $_.Exception.Message } }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Remove-Item $WoNetBackupPath -Force -ErrorAction SilentlyContinue
}
