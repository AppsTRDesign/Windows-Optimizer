# modules/CapAccess.ps1 - Gizlilik izinlerini Windows Ayarlari'nin kendi arabirimiyle okur/yazar.
#
# Windows 11 24H2+ izinleri CapabilityAccessManager veritabaninda tutar; ConsentStore kayit defteri degerleri
# yalnizca bir kopyadir ve dogrudan yazilan degerler dikkate alinmaz. Bu betik Ayarlar uygulamasinin kullandigi
# SettingsHandlers_CapabilityAccess.dll (GetSetting -> ISettingItem) arabirimini cagirir.
#
# Bu arabirim belgelenmemistir ve bazi kimliklerde surecin cokmesine yol acabilir; bu yuzden ana uygulamaya
# dot-source EDILMEZ, her zaman ayri bir surec olarak calistirilir:
#   powershell -File CapAccess.ps1 -Mode get                      -> JSON durum
#   powershell -File CapAccess.ps1 -Mode set -Cap webcam -Allow 0 -> cihaz duzeyini yazar, yeni durumu JSON dondurur
# Cihaz duzeyi yonetici ister. Uygulama/masaustu duzeylerini Windows yalnizca kendi Ayarlar uygulamasina yazdirir.
param([ValidateSet("get", "set")][string]$Mode = "get", [string]$Cap, [int]$Allow = 1)
$ErrorActionPreference = "Stop"

$code = @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
[ComImport, Guid("40C037CC-D8BF-489E-8697-D66BAA3221BF"), InterfaceType(ComInterfaceType.InterfaceIsIInspectable)]
public interface IWoSettingItem {
    int Id { get; }
    int Type { get; }
    bool IsSetByGroupPolicy { get; }
    bool IsEnabled { get; }
    bool IsApplicable { get; }
    string Description { [return: MarshalAs(UnmanagedType.HString)] get; }
    bool IsUpdating { get; }
    [return: MarshalAs(UnmanagedType.IInspectable)] object GetValue([MarshalAs(UnmanagedType.HString)] string name);
    int SetValue([MarshalAs(UnmanagedType.HString)] string name, [MarshalAs(UnmanagedType.IInspectable)] object value);
}
public static class WoCapSet {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern IntPtr LoadLibrary(string p);
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi)] static extern IntPtr GetProcAddress(IntPtr h, string n);
    [UnmanagedFunctionPointer(CallingConvention.Winapi)]
    delegate int GetSettingFunc([MarshalAs(UnmanagedType.HString)] string id, out IWoSettingItem item, IntPtr r);
    static IWoSettingItem Get(string id) {
        string dll = null;
        using (RegistryKey k = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\SystemSettings\SettingId\" + id))
            if (k != null) dll = k.GetValue("DllPath") as string;
        if (dll == null) throw new Exception("setting yok: " + id);
        IntPtr h = LoadLibrary(Environment.ExpandEnvironmentVariables(dll));
        if (h == IntPtr.Zero) throw new Exception("LoadLibrary: " + dll);
        IntPtr f = GetProcAddress(h, "GetSetting");
        if (f == IntPtr.Zero) throw new Exception("GetSetting yok");
        GetSettingFunc fn = (GetSettingFunc)Marshal.GetDelegateForFunctionPointer(f, typeof(GetSettingFunc));
        IWoSettingItem it; int hr = fn(id, out it, IntPtr.Zero);
        if (hr != 0 || it == null) throw new Exception("GetSetting 0x" + hr.ToString("X8"));
        return it;
    }
    // "Allow" / "Deny" / "Policy:Allow" (grup ilkesiyle kilitli)
    public static string Read(string id) {
        IWoSettingItem it = Get(id);
        object v = it.GetValue("Value");
        string s = (v is bool && (bool)v) ? "Allow" : "Deny";
        return it.IsSetByGroupPolicy ? "Policy:" + s : s;
    }
    public static void Write(string id, bool allow) {
        int hr = Get(id).SetValue("Value", allow);
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);
    }
}
"@

# Derlenmis turu onbellekte tut (her calistirmada derleme ~1 sn)
if (-not ("WoCapSet" -as [type])) {
    $dir = Join-Path $env:LOCALAPPDATA "WindowsOptimizer\typecache"
    $sha = [Security.Cryptography.SHA256]::Create()
    $key = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($code + $PSVersionTable.CLRVersion))).Replace("-", "").Substring(0, 16)
    $dll = Join-Path $dir "WoCapSet-$key.dll"
    if (-not (Test-Path $dll)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Get-ChildItem $dir -Filter "WoCapSet-*.dll" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        $tmp = "$dll.$PID.tmp"
        Add-Type -TypeDefinition $code -OutputAssembly $tmp -OutputType Library
        Move-Item $tmp $dll -Force
    }
    Add-Type -Path $dll
}

# Izin -> Ayarlar kimlikleri (yalnizca test edilmis kimlikler; "UnverifiedGlobal" gibi bazilari sureci cokertir)
$ids = @{
    webcam                      = @{ Device = "Camera_SystemGlobal"; User = "Camera_UserGlobal"; Desktop = "Camera_ClassicGlobal" }
    microphone                  = @{ Device = "Microphone_SystemGlobal"; User = "Microphone_UserGlobal"; Desktop = "Microphone_ClassicGlobal" }
    location                    = @{ Device = "Location_SystemGlobal_WCOS_DO"; User = "Location_UserGlobal"; Desktop = "Location_ClassicGlobal" }
    graphicsCaptureProgrammatic = @{ Device = "GraphicsCaptureProgrammatic_SystemGlobal"; User = "GraphicsCaptureProgrammatic_UserGlobal"; Desktop = "GraphicsCaptureProgrammatic_ClassicGlobal" }
}

$result = [ordered]@{ ok = $true; error = $null; caps = [ordered]@{} }
if ($Mode -eq "set") {
    try {
        if (-not $ids[$Cap]) { throw "bilinmeyen izin: $Cap" }
        [WoCapSet]::Write("SystemSettings_CapabilityAccess_" + $ids[$Cap].Device, [bool]$Allow)
    } catch { $result.ok = $false; $result.error = $_.Exception.Message }
    # Ayni surecte yazdiktan hemen sonra okunan deger eskidir (ayar nesnesi onbellekli); dogrulamayi cagiran yeni surecle yapar
    [Console]::Out.Write(($result | ConvertTo-Json -Depth 4 -Compress)); return
}
foreach ($c in $ids.Keys) {
    $st = [ordered]@{}
    foreach ($lvl in "Device", "User", "Desktop") {
        try { $st[$lvl] = [WoCapSet]::Read("SystemSettings_CapabilityAccess_" + $ids[$c][$lvl]) } catch { $st[$lvl] = $null }
    }
    $result.caps[$c] = $st
}
[Console]::Out.Write(($result | ConvertTo-Json -Depth 4 -Compress))
