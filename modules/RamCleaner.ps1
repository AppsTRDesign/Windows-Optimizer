# modules/RamCleaner.ps1 - Self-contained RAM cleaner (harici dosya indirmez)

if (-not ("RamCleaner" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class RamCleaner {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hProcess);

    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);

    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
        ref TOKEN_PRIVILEGES NewState, uint BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("ntdll.dll")]
    public static extern int NtSetSystemInformation(int InfoClass, IntPtr Info, int Length);

    [StructLayout(LayoutKind.Sequential, Pack=1)]
    public struct TOKEN_PRIVILEGES {
        public int PrivilegeCount;
        public long Luid;
        public int Attributes;
    }

    public static void EnablePrivilege() {
        IntPtr token;
        OpenProcessToken(GetCurrentProcess(), 0x0020 | 0x0008, out token);
        long luid;
        LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out luid);
        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        tp.PrivilegeCount = 1;
        tp.Luid = luid;
        tp.Attributes = 0x00000002;
        AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }

    public static void ClearStandbyList() {
        EnablePrivilege();
        IntPtr ptr = Marshal.AllocHGlobal(4);
        Marshal.WriteInt32(ptr, 4); // MemoryPurgeStandbyList
        NtSetSystemInformation(80, ptr, 4); // SystemMemoryListInformation
        Marshal.FreeHGlobal(ptr);
    }

    public static int TrimWorkingSets() {
        int count = 0;
        foreach (var p in System.Diagnostics.Process.GetProcesses()) {
            try { if (EmptyWorkingSet(p.Handle) != 0) count++; } catch {}
        }
        return count;
    }
}
"@ -ErrorAction SilentlyContinue
}

function Clear-StandbyMemory {
    try {
        [RamCleaner]::ClearStandbyList()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch {}
        return $true
    } catch {
        Write-Host "Standby temizleme hatasi: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Trim-WorkingSets {
    try {
        $n = [RamCleaner]::TrimWorkingSets()
        return $n
    } catch {
        Write-Host "Working set trim hatasi: $($_.Exception.Message)" -ForegroundColor Yellow
        return 0
    }
}