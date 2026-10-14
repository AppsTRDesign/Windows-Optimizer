# Windows Optimizer

**🇹🇷 Türkçe** | [🇬🇧 English](README.md)

![Windows Optimizer](assets/banner.png)

Windows 10/11 için modüler, açık kaynaklı bir performans ve gizlilik aracı. Reklamları ve telemetriyi kapatır, arka plan etkinliğini azaltır ve RAM'i temizler. Canlı bellek grafiği sayesinde her optimizasyonun etkisini **gözünüzle görebilirsiniz**.

> **Sürüm 2.0**: Yeni arayüz, canlı RAM izleme, gerçek durumu gösterilen ve geri alınabilen 26 optimizasyon, ilerleme çubuklu güvenli uygulama içi güncelleme.

## ✨ Özellikler

| Sayfa | Ne yapar |
|-------|----------|
| 🏠 **Genel Bakış** | Canlı CPU / RAM / disk kullanımı ve mini grafikler, sistem bilgisi, optimizasyon skoru, hızlı işlemler |
| ⚡ **Optimizasyonlar** | 4 kategoride 26 ayar. Her ayarın **mevcut durumu sistemden okunur**; kapatırsanız Windows varsayılanına döner |
| 🧠 **Bellek (RAM)** | Son 2 dakikanın canlı grafiği (kullanımda / değiştirilmiş / standby), tek tıkla temizlik, önce/sonra sonuçları, en çok bellek kullanan uygulamalar, kullanım eşiğine göre otomatik temizlik |
| ⚙️ **Ayarlar** | Dil (TR/EN), güncelleme denetimi, kısayol onarma, sistem geri yükleme noktası, günlük dosyası |

### Optimizasyon kategorileri

- **Reklamlar & Gizlilik:** Dosya Gezgini reklamları, kilit ekranı ipuçları, Ayarlar önerileri, Windows ipuçları, "Hoş geldiniz" ekranı, "Cihazınızı kurmayı bitirin" hatırlatıcısı, Başlat menüsü reklamları ve sessiz uygulama kurulumları, önerilen bildirimler, reklam kimliği, uyarlanmış deneyimler, etkinlik geçmişi
- **Arama, Edge & Copilot:** Başlat aramasındaki Bing sonuçları, Edge arama çubuğu, Edge önerileri, alışveriş asistanı ve kenar çubuğu, Windows Copilot, Pencere öğeleri / Haber ve ilgi alanları
- **Sistem & Telemetri:** Telemetri (DiagTrack servisi dahil), Cortana, tüketici özellikleri, geri bildirim istekleri, Windows Hata Raporlama
- **Performans:** Edge'in arka planda çalışması ve Startup Boost, başlangıç uygulaması gecikmesi, menü açılma gecikmesi, Xbox Game DVR, arka plandaki Mağaza uygulamaları

**ÖNERİLEN** etiketli ayarlar çoğu kullanıcı için güvenlidir. Genel Bakış sayfasındaki **Önerilenleri Uygula** düğmesi hepsini tek seferde etkinleştirir.

### RAM temizleme

RAMMap / MemReduct ile aynı Windows API'lerini kullanır; harici bir araç indirilmez.

| Seçenek | Etkisi |
|---------|--------|
| Working set'leri boşalt | Süreçlerin kullanmadığı sayfaları RAM'den çıkarır |
| Değiştirilmiş listeyi yaz | Bekleyen sayfaları diske yazıp serbest bırakır |
| Standby listesini temizle | Tüm önbelleği boşaltır (en büyük etki) |
| Sadece düşük öncelikli standby | Daha yumuşak; sık kullanılan önbelleği korur |
| Sistem dosya önbelleğini boşalt | Dosya sistemi önbelleğini sıfırlar |

> Windows boş RAM'i önbellek (standby) olarak kullanır ve bu normaldir. Temizlik en çok bir oyun veya ağır bir uygulama açmadan önce, ya da bellek sıkıştığında işe yarar.

## 🚀 Tek tıkla kurulum

**PowerShell**'i açın ve şu komutu çalıştırın:

```powershell
irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
```

Kurulum betiği:
- tüm dosyaları önce geçici bir klasöre indirir ve kurulumunuza dokunmadan önce doğrular,
- `%USERPROFILE%\Windows-Optimizer` klasörüne kurar (`settings.json` dosyanız korunur),
- **Masaüstü** ve **Başlat menüsü** kısayollarını oluşturur (yönetici olarak, konsol penceresi açmadan çalışır),
- uygulamayı başlatır.

## 🔄 Güncelleme

Yeni bir sürüm çıktığında sol menüde bir kart görünür. **Şimdi güncelle** düğmesine tıklayın:

1. Dosyalar ilerleme çubuğuyla indirilir ve doğrulanır,
2. uygulama kapanır, yeni dosyalar eskilerin üzerine kopyalanır,
3. kısayollar yeniden oluşturulur ve uygulama kendiliğinden yeniden açılır.

Bir sorun çıkarsa mevcut kurulumunuz değiştirilmez. Güncelleme günlüğü `%TEMP%\WindowsOptimizer-update.log` dosyasına yazılır.

## 🗑️ Kaldırma

```powershell
Remove-Item "$env:USERPROFILE\Windows-Optimizer" -Recurse -Force -ErrorAction SilentlyContinue
```
```powershell
Remove-Item "$([Environment]::GetFolderPath('Desktop'))\Windows Optimizer.lnk", "$([Environment]::GetFolderPath('Programs'))\Windows Optimizer.lnk" -Force -ErrorAction SilentlyContinue
```

Uygulamayı kaldırmak, yapılan optimizasyonları geri almaz. Geri almak istiyorsanız kaldırmadan önce uygulamadaki anahtarları kapatın.

## 📁 Proje yapısı

```
Windows-Optimizer/
├── WindowsOptimizer.ps1     # Ana uygulama (WPF arayüzü)
├── install.ps1              # Kurulum / eski sürümler için güncelleme
├── version.json             # Sürüm, sürüm notları, dosya listesi
├── config.json              # Yazar ve bağlantılar
├── assets/
│   ├── logo.png
│   └── banner.png
└── modules/
    ├── Tweaks.ps1           # Optimizasyon kataloğu + uygulama/geri alma motoru
    ├── RamCleaner.ps1       # Canlı bellek ölçümü + temizlik (yerel API)
    └── Updater.ps1          # Sürüm denetimi, indirme, kısayollar
```

## ⚠️ Notlar

- Windows 10/11 ve Windows PowerShell 5.1 (Windows ile birlikte gelir) gerekir. Uygulama yönetici izni ister.
- Değişiklik yapmadan önce bir **sistem geri yükleme noktası** oluşturmanız önerilir (Genel Bakış → Hızlı İşlemler).
- Bazı ayarlar Explorer yeniden başlatıldığında (uygulama bunu önerir) ya da oturum kapatılıp açıldığında etkinleşir.
- Günlük dosyası: `%TEMP%\WindowsOptimizer.log`

## 🔗 Bağlantılar

- **GitHub:** [AppsTRDesign](https://github.com/AppsTRDesign)
- **Instagram:** [@oztasonur1](https://instagram.com/oztasonur1)
- **Website:** [worldofwar.site](https://worldofwar.site)

---

**AppsTRDesign** tarafından geliştirildi
