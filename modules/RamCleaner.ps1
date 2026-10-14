# modules/RamCleaner.ps1 - Canli bellek olcumu ve temizleme (harici arac gerektirmez)
# Olcum: GlobalMemoryStatusEx + NtQuerySystemInformation(SystemMemoryListInformation)
# Temizlik: NtSetSystemInformation komutlari (RAMMap / MemReduct ile ayni API)

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

Add-WoType "WoNative" @"
using System;
using System.Runtime.InteropServices;

public class WoMemInfo {
    public ulong Total, Avail, InUse, Standby, Modified, Free, CommitUsed, CommitLimit;
    public uint Load;
    public bool ListOk;
}

public static class WoNative {
    [StructLayout(LayoutKind.Sequential)]
    struct MEMORYSTATUSEX {
        public uint dwLength, dwMemoryLoad;
        public ulong ullTotalPhys, ullAvailPhys, ullTotalPageFile, ullAvailPageFile,
                     ullTotalVirtual, ullAvailVirtual, ullAvailExtendedVirtual;
    }
    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    struct TOKEN_PRIVILEGES { public int Count; public long Luid; public int Attr; }

    [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX m);
    [DllImport("kernel32.dll")] public static extern bool GetSystemTimes(out long idle, out long kernel, out long user);
    [DllImport("kernel32.dll")] public static extern ulong GetTickCount64();
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetSystemFileCacheSize(IntPtr min, IntPtr max, int flags);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("ntdll.dll")] static extern int NtQuerySystemInformation(int cls, IntPtr buf, int len, out int ret);
    [DllImport("ntdll.dll")] static extern int NtSetSystemInformation(int cls, IntPtr buf, int len);
    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr p, uint access, out IntPtr token);
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)] static extern bool LookupPrivilegeValue(string sys, string name, out long luid);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool AdjustTokenPrivileges(IntPtr t, bool all, ref TOKEN_PRIVILEGES s, int len, IntPtr prev, IntPtr ret);

    const int SystemMemoryListInformation = 80;
    public const int CmdEmptyWorkingSets = 2, CmdFlushModified = 3, CmdPurgeStandby = 4, CmdPurgeLowStandby = 5;

    public static bool EnablePrivilege(string name) {
        IntPtr token;
        if (!OpenProcessToken(GetCurrentProcess(), 0x0020 | 0x0008, out token)) return false;
        try {
            TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
            if (!LookupPrivilegeValue(null, name, out tp.Luid)) return false;
            tp.Count = 1; tp.Attr = 2;
            if (!AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero)) return false;
            return Marshal.GetLastWin32Error() == 0; // ERROR_NOT_ALL_ASSIGNED = 1300
        } finally { CloseHandle(token); }
    }

    public static WoMemInfo GetMemInfo() {
        WoMemInfo r = new WoMemInfo();
        MEMORYSTATUSEX m = new MEMORYSTATUSEX();
        m.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
        GlobalMemoryStatusEx(ref m);
        r.Total = m.ullTotalPhys; r.Avail = m.ullAvailPhys; r.Load = m.dwMemoryLoad;
        r.CommitLimit = m.ullTotalPageFile; r.CommitUsed = m.ullTotalPageFile - m.ullAvailPageFile;
        r.InUse = r.Total - r.Avail;

        int size = IntPtr.Size * 32, ret;
        IntPtr buf = Marshal.AllocHGlobal(size);
        try {
            if (NtQuerySystemInformation(SystemMemoryListInformation, buf, size, out ret) == 0) {
                ulong page = 4096;
                Func<int, ulong> at = i => (ulong)Marshal.ReadIntPtr(buf, i * IntPtr.Size).ToInt64();
                ulong standby = 0;
                for (int i = 5; i < 13; i++) standby += at(i);   // PageCountByPriority[8]
                r.Free = (at(0) + at(1)) * page;                // Zero + Free
                r.Modified = (at(2) + at(3)) * page;            // Modified + ModifiedNoWrite
                r.Standby = standby * page;
                ulong cached = r.Modified + r.Standby + r.Free;
                r.InUse = r.Total > cached ? r.Total - cached : 0;
                r.ListOk = true;
            }
        } finally { Marshal.FreeHGlobal(buf); }
        return r;
    }

    public static int MemCommand(int cmd) {
        IntPtr p = Marshal.AllocHGlobal(4);
        try { Marshal.WriteInt32(p, cmd); return NtSetSystemInformation(SystemMemoryListInformation, p, 4); }
        finally { Marshal.FreeHGlobal(p); }
    }

    public static bool FlushFileCache() {
        return SetSystemFileCacheSize(new IntPtr(-1), new IntPtr(-1), 0);
    }
}
"@


function Enable-WoMemPrivileges {
    $a = [WoNative]::EnablePrivilege("SeProfileSingleProcessPrivilege")
    $b = [WoNative]::EnablePrivilege("SeIncreaseQuotaPrivilege")
    return ($a -and $b)
}

# Arka plan runspace'inde calisir; WoNative tipi AppDomain'de oldugu icin erisilebilir.
$RamCleanJob = {
    param($Ops)
    [void][WoNative]::EnablePrivilege("SeProfileSingleProcessPrivilege")
    [void][WoNative]::EnablePrivilege("SeIncreaseQuotaPrivilege")
    $before = [WoNative]::GetMemInfo()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $codes = [ordered]@{}
    # Sira onemli: working set -> modified (standby'a duser) -> standby temizligi
    if ($Ops.WorkingSets) { $codes.WorkingSets = [WoNative]::MemCommand([WoNative]::CmdEmptyWorkingSets) }
    if ($Ops.FileCache)   { $codes.FileCache   = if ([WoNative]::FlushFileCache()) { 0 } else { [Runtime.InteropServices.Marshal]::GetLastWin32Error() } }
    if ($Ops.Modified)    { $codes.Modified    = [WoNative]::MemCommand([WoNative]::CmdFlushModified) }
    if ($Ops.Standby)     { $codes.Standby     = [WoNative]::MemCommand([WoNative]::CmdPurgeStandby) }
    elseif ($Ops.LowStandby) { $codes.LowStandby = [WoNative]::MemCommand([WoNative]::CmdPurgeLowStandby) }
    $sw.Stop()
    Start-Sleep -Milliseconds 300
    [pscustomobject]@{ Before = $before; After = [WoNative]::GetMemInfo(); Ms = $sw.ElapsedMilliseconds; Codes = $codes }
}
