# Katkıda Bulunma / Contributing

[🇹🇷 Türkçe](#türkçe) | [🇬🇧 English](#english)

## Türkçe

Katkılarınızı memnuniyetle karşılıyoruz! Hata bildirimi, öneri ve kod katkısı için bu rehberi izleyin.

### Proje yapısı
| Klasör | İçerik |
|---|---|
| `WindowsOptimizer.ps1` | Ana pencere, tasarım sistemi (XAML stilleri), ortak yardımcılar, temel sayfalar |
| `modules/` | Arayüzden bağımsız mantık (arka plan işlerinde de kullanılır) |
| `pages/` | Bağımsız sayfalar: her dosya kendi XAML'ini, metinlerini (`Add-WoStrings`) ve olaylarını içerir |
| `tools/` | Geliştirici araçları (sürüm imzalama) |

### Yeni sayfa eklemek
1. `pages/Ornek.ps1` oluşturun; `Add-WoStrings` ile TR/EN metinleri, `Register-WoPage` ile sayfayı tanımlayın.
2. Stillerde `{DynamicResource ...}` kullanın (`Card`, `PrimaryBtn`, `SecondaryBtn`, `SegBtn`, `Check`, `Switch`…).
3. Sayfayı `WindowsOptimizer.ps1` içindeki sayfa yükleyici listesine ve `$NavGroups`'a ekleyin.
4. Dosyayı `version.json` → `files` listesine ekleyin (`tools/release.ps1` bunu otomatik yapar).

### Kurallar
- **Her değişiklik geri alınabilir olmalı.** Registry için `Set-WoRegValue` kullanın (orijinal değer otomatik kaydedilir).
- **Kullanıcı verisini silen her işlem onay penceresi (`Show-WoDialog`) göstermeli.**
- **PowerShell 5.1 uyumluluğu:** Değişken adları büyük/küçük harf duyarsızdır (`$r` ile `$R` aynıdır); `ConvertFrom-Json` dizileri tek nesne döndürür.
- **Dosyalar UTF-8 BOM ile kaydedilmeli** (`install.ps1` hariç: BOM'suz, yalnızca ASCII).
- Yavaş işler (WMI, ağ, disk) `Start-Bg` ile arka planda çalışmalı; arayüz donmamalı.
- Etkisi kanıtlanmamış "hızlandırma" ayarları eklemeyin; açıklamalar dürüst olmalı.

### Test
- Sayfa görüntüleri: `$env:WO_SNAP_PAGES="Home,Disk"; .\WindowsOptimizer.ps1 -Snapshot C:\temp\snap`
- Açılış süreleri: `$env:WO_PROFILE=1` (sonuçlar `%TEMP%\WindowsOptimizer.log`)
- Değişiklik yapan özellikleri yönetici olarak ve mümkünse sanal makinede deneyin.

### Sürüm yayınlama (yalnızca proje sahibi)
```powershell
.\tools\release.ps1 -Version 3.2.0 -Notes "Değişiklik notları"
```
Betik dosya listesini, her dosyanın SHA-256 özetini ve dijital imzayı `version.json`'a yazar. İmzasız veya özeti tutmayan güncellemeler istemciler tarafından reddedilir.

EXE paketleri (isteğe bağlı) imzalı sürümden üretilir ve GitHub → Releases'e eklenir (depoya değil):
```powershell
.\tools\build-exe.ps1   # dist\WindowsOptimizer-Setup-<sürüm>.exe, Portable.zip, SHA256SUMS.txt
```

---

## English

Contributions are welcome! Follow this guide for bug reports, suggestions and code.

- **Structure:** `modules/` = UI-independent logic, `pages/` = self-contained pages (XAML + strings + events), `tools/` = developer tools.
- **Every change must be reversible** — use `Set-WoRegValue` (original values are journaled automatically).
- **Anything that deletes user data must show a confirmation** (`Show-WoDialog`).
- **PowerShell 5.1:** variables are case-insensitive; `ConvertFrom-Json` returns arrays as a single object; save files as UTF-8 with BOM (except `install.ps1`).
- Run slow work in the background with `Start-Bg`.
- Releases are signed with `tools/release.ps1`; clients reject unsigned or tampered updates.

By contributing you agree that your contributions are licensed under the [MIT License](LICENSE).
