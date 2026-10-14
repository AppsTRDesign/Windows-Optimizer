# modules/DiskCleaner.ps1 - Disk kapasitesi ve gereksiz dosya temizligi
# Guvenlik: baglanti noktalarini (junction/symlink) asla izlemez; Temp klasorlerinde son 24 saatte
# degisen dosyalara dokunmaz; kullanimdaki dosyalar atlanir.

# Derlenmis C# tiplerini onbellege alir: ilk acilista derlenip DLL olarak saklanir, sonraki acilislarda dogrudan yuklenir.
if (-not (Get-Command Add-WoType -ErrorAction SilentlyContinue)) {
    function Add-WoType([string]$Name, [string]$Code, [string[]]$Refs = @()) {
        if ($Name -as [type]) { return }
        try {
            $dir = Join-Path $env:LOCALAPPDATA "WindowsOptimizer\typecache"
            $sha = [Security.Cryptography.SHA256]::Create()
            $key = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Code + ($Refs -join ",") + $PSVersionTable.CLRVersion))).Replace("-", "").Substring(0, 16)
            $dll = Join-Path $dir "$Name-$key.dll"
            if (-not (Test-Path $dll)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Get-ChildItem $dir -Filter "$Name-*.dll" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                $tmp = "$dll.$PID.tmp"
                if ($Refs.Count) { Add-Type -TypeDefinition $Code -ReferencedAssemblies $Refs -OutputAssembly $tmp -OutputType Library }
                else { Add-Type -TypeDefinition $Code -OutputAssembly $tmp -OutputType Library }
                Move-Item $tmp $dll -Force
            }
            Add-Type -Path $dll
        } catch {}
        if (-not ($Name -as [type])) {
            if ($Refs.Count) { Add-Type -TypeDefinition $Code -ReferencedAssemblies $Refs } else { Add-Type -TypeDefinition $Code }
        }
    }
}

Add-WoType "WoDisk" @"
using System;
using System.IO;

public static class WoDisk {
    // {bayt, dosya}
    public static long[] Scan(string root, string pattern, double minAgeHours, bool recurse) {
        long[] r = new long[2];
        if (!Directory.Exists(root)) return r;
        Walk(new DirectoryInfo(root), pattern, DateTime.UtcNow.AddHours(-minAgeHours), recurse, false, false, r);
        return r;
    }
    // {bosaltilan bayt, silinen dosya, silinemeyen dosya}
    public static long[] Clean(string root, string pattern, double minAgeHours, bool recurse, bool removeDirs) {
        long[] r = new long[3];
        if (!Directory.Exists(root)) return r;
        Walk(new DirectoryInfo(root), pattern, DateTime.UtcNow.AddHours(-minAgeHours), recurse, true, removeDirs, r);
        return r;
    }
    static void Walk(DirectoryInfo dir, string pattern, DateTime cutoff, bool recurse, bool delete, bool removeDirs, long[] r) {
        FileInfo[] files;
        try { files = dir.GetFiles(pattern); } catch { return; }
        foreach (FileInfo f in files) {
            try {
                if (f.LastWriteTimeUtc > cutoff) continue;
                long len = f.Length;
                if (delete) {
                    if ((f.Attributes & FileAttributes.ReadOnly) != 0) f.Attributes = FileAttributes.Normal;
                    f.Delete();
                }
                r[0] += len; r[1]++;
            } catch { if (delete) r[2]++; }
        }
        if (!recurse) return;
        DirectoryInfo[] subs;
        try { subs = dir.GetDirectories(); } catch { return; }
        foreach (DirectoryInfo d in subs) {
            if ((d.Attributes & FileAttributes.ReparsePoint) != 0) continue;   // junction/symlink izleme
            Walk(d, pattern, cutoff, true, delete, removeDirs, r);
            if (delete && removeDirs) {
                try { if (d.GetFileSystemInfos().Length == 0) d.Delete(); } catch { }
            }
        }
    }
}
"@


# Anlik algilama: kategori klasorlerini izler; olaylar C# icinde toplanir (PowerShell betigi baska is parcaciginda calistirilmaz)
Add-WoType "WoWatch" @"
using System;
using System.IO;
using System.Collections.Generic;
public static class WoWatch {
    static readonly List<FileSystemWatcher> ws = new List<FileSystemWatcher>();
    static readonly HashSet<string> dirty = new HashSet<string>();
    static readonly object gate = new object();
    public static int Count { get { return ws.Count; } }
    public static void Add(string id, string path, string filter) {
        try {
            if (!Directory.Exists(path)) return;
            FileSystemWatcher w = new FileSystemWatcher(path, string.IsNullOrEmpty(filter) ? "*" : filter);
            w.IncludeSubdirectories = true; w.InternalBufferSize = 65536;
            w.NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.Size;
            FileSystemEventHandler h = delegate { lock (gate) { dirty.Add(id); } };
            w.Created += h; w.Deleted += h; w.Changed += h;
            w.Renamed += delegate { lock (gate) { dirty.Add(id); } };
            w.Error += delegate { lock (gate) { dirty.Add(id); } };
            w.EnableRaisingEvents = true;
            ws.Add(w);
        } catch { }
    }
    public static string[] Take() { lock (gate) { string[] a = new string[dirty.Count]; dirty.CopyTo(a); dirty.Clear(); return a; } }
    public static void Clear() { foreach (FileSystemWatcher w in ws) { try { w.EnableRaisingEvents = false; w.Dispose(); } catch { } } ws.Clear(); }
}
"@


$L = $env:LOCALAPPDATA
$W = $env:SystemRoot
# Her kategori: Paths (P=yol, joker karakter destekli; F=dosya deseni; A=en az yas saat; R=alt klasorler)
$DiskCategories = @(
    @{ Id = "UserTemp"; Rec = $true
       TR = @("Geçici dosyalar (kullanıcı)", "Uygulamaların bıraktığı geçici dosyalar. Son 24 saattekiler korunur.")
       EN = @("Temporary files (user)", "Leftover temp files from apps. Files from the last 24 hours are kept.")
       Paths = @(@{ P = $env:TEMP; A = 24 }) }
    @{ Id = "WinTemp"; Rec = $true
       TR = @("Geçici dosyalar (Windows)", "Windows ve kurulum programlarının geçici dosyaları. Son 24 saattekiler korunur.")
       EN = @("Temporary files (Windows)", "Temp files from Windows and installers. Files from the last 24 hours are kept.")
       Paths = @(@{ P = "$W\Temp"; A = 24 }) }
    @{ Id = "WUCache"; Rec = $true; Services = @("wuauserv", "bits")
       TR = @("Windows Update önbelleği", "Önceden indirilmiş ve kurulmuş güncelleme dosyaları.")
       EN = @("Windows Update cache", "Previously downloaded and installed update files.")
       Paths = @(@{ P = "$W\SoftwareDistribution\Download" }) }
    @{ Id = "DOCache"; Rec = $true; Services = @("DoSvc")
       TR = @("Teslim İyileştirme önbelleği", "Diğer bilgisayarlarla paylaşım için tutulan güncelleme parçaları.")
       EN = @("Delivery Optimization cache", "Update chunks kept for sharing with other PCs.")
       Paths = @(@{ P = "$W\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache" }) }
    @{ Id = "Browser"; Rec = $true
       TR = @("Tarayıcı önbellekleri", "Chrome, Edge, Brave, Opera ve Firefox önbelleği. Geçmiş, şifre ve çerezler SİLİNMEZ. Açık tarayıcının dosyaları atlanır.")
       EN = @("Browser caches", "Chrome, Edge, Brave, Opera and Firefox cache. History, passwords and cookies are NOT deleted. Files of open browsers are skipped.")
       Paths = @(
           foreach ($b in @("Google\Chrome", "Microsoft\Edge", "BraveSoftware\Brave-Browser")) {
               foreach ($c in @("Cache", "Code Cache", "GPUCache")) { @{ P = "$L\$b\User Data\*\$c" } }
           }
           @{ P = "$env:APPDATA\Opera Software\Opera Stable\Cache" }
           @{ P = "$L\Opera Software\Opera Stable\Cache" }
           @{ P = "$L\Opera Software\Opera GX Stable\Cache" }
           @{ P = "$L\Mozilla\Firefox\Profiles\*\cache2" }
       ) }
    @{ Id = "Dumps"; Rec = $true
       TR = @("Hata raporları ve bellek dökümleri", "Çökme dökümleri ve Windows Hata Raporlama arşivi.")
       EN = @("Error reports & memory dumps", "Crash dumps and the Windows Error Reporting archive.")
       Paths = @(
           @{ P = "$L\CrashDumps" }, @{ P = "$W\Minidump" }, @{ P = $W; F = "MEMORY.DMP"; R = $false }
           @{ P = "$env:ProgramData\Microsoft\Windows\WER\ReportArchive" }, @{ P = "$env:ProgramData\Microsoft\Windows\WER\ReportQueue" }
           @{ P = "$L\Microsoft\Windows\WER" }
       ) }
    @{ Id = "Thumbs"; Rec = $false
       TR = @("Küçük resim önbelleği", "Dosya Gezgini önizlemeleri; gerektiğinde yeniden oluşturulur. Kullanımdakiler atlanır.")
       EN = @("Thumbnail cache", "File Explorer previews; rebuilt when needed. Files in use are skipped.")
       Paths = @(@{ P = "$L\Microsoft\Windows\Explorer"; F = "thumbcache_*.db"; R = $false }) }
    @{ Id = "Shader"; Rec = $false
       TR = @("GPU gölgelendirici önbelleği", "DirectX/NVIDIA/AMD shader önbelleği. Temizlenirse oyunların ilk açılışında kısa takılma olabilir.")
       EN = @("GPU shader cache", "DirectX/NVIDIA/AMD shader cache. Games may stutter briefly on first launch after cleaning.")
       Paths = @(@{ P = "$L\D3DSCache" }, @{ P = "$L\NVIDIA\DXCache" }, @{ P = "$L\NVIDIA\GLCache" }, @{ P = "$L\AMD\DxCache" }, @{ P = "$L\AMD\DxcCache" }) }
    @{ Id = "Logs"; Rec = $false
       TR = @("Windows günlük dosyaları", "CBS/DISM kurulum günlükleri. 7 günden eski olanlar silinir.")
       EN = @("Windows log files", "CBS/DISM setup logs. Files older than 7 days are deleted.")
       Paths = @(@{ P = "$W\Logs\CBS"; A = 168 }, @{ P = "$W\Logs\DISM"; A = 168 }) }
    @{ Id = "Recycle"; Rec = $false; Special = "recycle"
       TR = @("Geri Dönüşüm Kutusu", "Tüm disklerdeki Geri Dönüşüm Kutusu kalıcı olarak boşaltılır.")
       EN = @("Recycle Bin", "Permanently empties the Recycle Bin on all drives.")
       Paths = @() }
)

function Resolve-WoCleanPaths($Cat) {
    if ($Cat.Special -eq "recycle") {
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        return @([IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and $_.DriveType -eq "Fixed" } |
            ForEach-Object { @{ P = "$($_.Name)`$Recycle.Bin\$sid"; F = "*"; A = 0; R = $true } })
    }
    foreach ($p in $Cat.Paths) {
        $dirs = if ($p.P -match '[\*\?]') { @(Get-Item -Path $p.P -Force -ErrorAction SilentlyContinue | Where-Object PSIsContainer | ForEach-Object FullName) } else { @($p.P) }
        foreach ($d in $dirs) {
            @{ P = $d; F = $(if ($p.F) { $p.F } else { "*" }); A = $(if ($p.A) { $p.A } else { 0 }); R = $(if ($null -ne $p.R) { $p.R } else { $true }) }
        }
    }
}

function Get-WoDiskScan([string[]]$Ids) {
    foreach ($c in ($DiskCategories | Where-Object { -not $Ids -or $_.Id -in $Ids })) {
        $bytes = 0L; $files = 0L
        foreach ($p in (Resolve-WoCleanPaths $c)) {
            $r = [WoDisk]::Scan($p.P, $p.F, $p.A, $p.R)
            $bytes += $r[0]; $files += $r[1]
        }
        [pscustomobject]@{ Id = $c.Id; Bytes = $bytes; Files = $files }
    }
}

function Invoke-WoDiskClean([string[]]$Ids) {
    foreach ($c in ($DiskCategories | Where-Object { $_.Id -in $Ids })) {
        $freed = 0L; $deleted = 0L; $failed = 0L
        $stopped = @()
        foreach ($s in $c.Services) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                try { Stop-Service -Name $s -Force -ErrorAction Stop; $stopped += $s } catch {}
            }
        }
        try {
            if ($c.Special -eq "recycle") {
                foreach ($p in (Resolve-WoCleanPaths $c)) { $r = [WoDisk]::Scan($p.P, "*", 0, $true); $freed += $r[0]; $deleted += $r[1] }
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            } else {
                foreach ($p in (Resolve-WoCleanPaths $c)) {
                    $r = [WoDisk]::Clean($p.P, $p.F, $p.A, $p.R, $true)
                    $freed += $r[0]; $deleted += $r[1]; $failed += $r[2]
                }
            }
        } finally {
            foreach ($s in $stopped) { Start-Service -Name $s -ErrorAction SilentlyContinue }
        }
        [pscustomobject]@{ Id = $c.Id; Freed = $freed; Deleted = $deleted; Failed = $failed }
    }
}

function Start-WoDiskWatch {
    [WoWatch]::Clear()
    foreach ($c in $DiskCategories) {
        foreach ($p in (Resolve-WoCleanPaths $c)) { [WoWatch]::Add($c.Id, $p.P, $(if ($p.F -and $p.F -ne "*" -and -not $p.R) { $p.F } else { "*" })) }
    }
}

function Get-WoDrives {
    $sys = $env:SystemDrive.Substring(0, 1)
    foreach ($d in [IO.DriveInfo]::GetDrives()) {
        if (-not $d.IsReady -or $d.DriveType -notin @("Fixed", "Removable")) { continue }
        [pscustomobject]@{
            Letter = $d.Name.Substring(0, 1); Label = $d.VolumeLabel; Format = $d.DriveFormat; Type = "$($d.DriveType)"
            Total = [double]$d.TotalSize; Free = [double]$d.AvailableFreeSpace; System = ($d.Name.Substring(0, 1) -eq $sys)
        }
    }
}
