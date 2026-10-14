# Windows Optimizer

**🇹🇷 Türkçe** | [🇬🇧 English](README.md)

![Windows Optimizer](assets/banner.png)

Windows 10/11 için modüler, açık kaynaklı bir performans ve gizlilik aracı. Reklamları ve telemetriyi kapatır, arka plan etkinliğini azaltır ve RAM'i temizler. Canlı bellek grafiği sayesinde her optimizasyonun etkisini **gözünüzle görebilirsiniz**.

> **Sürüm 3.2**: Akıllı Bellek (akıllı standby temizleyici, verimlilik moduyla arka plan kısıtlayıcı, bellek sızıntısı dedektörü, sayfa dosyası danışmanı, tarayıcı bellek tasarrufu), imzalı ve SHA-256 doğrulamalı güncellemeler, temaya uygun yükleme ekranıyla daha hızlı açılış ve Windows Ayarları ile anlık senkron gizlilik anahtarları. MIT lisanslı, katkıya açık.

## ✨ Özellikler

| Sayfa | Ne yapar |
|-------|----------|
| 🏠 **Genel Bakış** | Canlı CPU / RAM / disk kullanımı ve mini grafikler, sistem bilgisi, optimizasyon skoru, hızlı işlemler |
| ⚡ **Optimizasyonlar** | 7 kategoride 50 ayar (Windows Update kontrolü dahil). Her ayarın **mevcut durumu sistemden okunur** ve Windows Ayarları'nda değiştirdiğiniz anda güncellenir; kapatırsanız Windows varsayılanına döner |
| 🧬 **Akıllı Bellek** | Akıllı standby temizleyici (yalnızca boş bellek eşiğin altına düşünce, istenirse sadece oyunda), arka plan kısıtlayıcı (düşük bellek önceliği + verimlilik modu, uygulama öne gelince anında kalkar), tepsi uyarılı ve yeniden başlat düğmeli bellek sızıntısı dedektörü, sayfa dosyası danışmanı, tarayıcı bellek tasarrufu |
| 🧠 **Bellek (RAM)** | Son 2 dakikanın canlı grafiği (kullanımda / değiştirilmiş / standby), tek tıkla temizlik, önce/sonra sonuçları, en çok bellek kullanan uygulamalar, kullanım eşiğine göre otomatik temizlik |
| 📈 **Performans** | İşlemci (çekirdek başına), ekran kartı, bellek, disk aktarım hızları ve ağ canlı izlenir; tek tıkla bellek, geçici dosya, DNS ve güç planı optimizasyonu |
| 🎮 **Oyun Modu** | Tek tuşla RAM temizliği, geçici Nihai Performans planı, bildirimleri susturma ve seçili arka plan uygulamalarını kapatma; bitince her şey eski haline döner |
| 🚀 **Başlangıç** | Windows açılırken çalışan tüm programlar (kayıt defteri, başlangıç klasörü, zamanlanmış görevler); simge, yayıncı ve komut satırıyla listelenir, tek tıkla açılıp kapatılır. Görev Yöneticisi ile uyumludur |
| 🔧 **Servisler** | 300 Windows servisini tarar; Windows bileşeni, üçüncü parti ve gereksiz olanları ayırır. Her öneriyi açıklar, güvenli olanları tek tıkla uygular, tüm değişiklikler geri alınabilir |
| 🧹 **Disk Temizleme** | Tüm disklerin kapasite kartları; geçici dosyalar, Windows Update önbelleği, tarayıcı önbellekleri, hata dökümleri, shader önbelleği, Geri Dönüşüm Kutusu taranır, boyutları gösterilir, seçilenler temizlenir |
| 🗺️ **Disk Analizi** | Klasörleri boyutlarına göre gösteren ağaç haritası (tıklayıp içine inilir) ve en büyük 50 dosya |
| 📦 **Uygulamalar** | Önceden yüklü gereksiz uygulamaları (Haberler, Clipchamp, Solitaire, Teams vb.) seçerek kaldırma; kritik paketler hiç listelenmez, kaldırılanlar Mağaza'dan geri yüklenebilir |
| 🌐 **Ağ** | Bağdaştırıcı bilgileri, gerçek sorgu süresiyle DNS hız testi ve tek tıkla DNS seçimi (Cloudflare, Google, Quad9, AdGuard…), DNS önbelleği / IP yenileme / ağ sıfırlama |
| 🩺 **Sağlık** | Disk SMART bilgileri (sıcaklık, SSD ömrü, çalışma saati), son 30 günün kararlılık özeti, canlı ilerlemeli SFC ve DISM onarımı (hızlı denetim ve ISO ile onarım dahil), disk hatası onarma (CHKDSK) |
| 🔍 **Gizlilik Raporu** | Kamera, mikrofon, konum ve ekran yakalamaya hangi uygulamanın ne zaman eriştiği; şu an kullanan varsa canlı gösterilir |
| ↩️ **Sıfırla** | Her ayarın orijinal değeri ilk değişiklikten önce kaydedilir; tek tıkla ilk duruma ya da Windows varsayılanlarına dönülür |
| ⚙️ **Ayarlar** | Profil dışa/içe aktarma, sistem tepsisi ve Windows ile başlatma, haftalık zamanlanmış bakım, dil (TR/EN), güncelleme denetimi, kısayol onarma, sistem geri yükleme noktası, günlük dosyası |

### Optimizasyon kategorileri

- **Reklamlar & Gizlilik:** Dosya Gezgini reklamları, kilit ekranı ipuçları, Ayarlar önerileri, Windows ipuçları, "Hoş geldiniz" ekranı, "Cihazınızı kurmayı bitirin" hatırlatıcısı, Başlat menüsü reklamları ve sessiz uygulama kurulumları, önerilen bildirimler, reklam kimliği, uyarlanmış deneyimler, etkinlik geçmişi
- **Gizlilik İzinleri:** Konum, mikrofon, kamera, kişisel verilere (kişiler, takvim, arama geçmişi, e-posta, mesajlar) erişim, uygulama tanılama, çevrimiçi konuşma tanıma, yazma kişiselleştirmesi
- **Arama, Edge & Copilot:** Başlat aramasındaki Bing sonuçları, Edge arama çubuğu, Edge önerileri, alışveriş asistanı ve kenar çubuğu, Windows Copilot, Pencere öğeleri / Haber ve ilgi alanları
- **Sistem & Telemetri:** Telemetri (DiagTrack servisi dahil), Cortana, tüketici özellikleri, geri bildirim istekleri, Windows Hata Raporlama
- **Performans:** Edge'in arka planda çalışması ve Startup Boost, başlangıç uygulaması gecikmesi, menü açılma gecikmesi, arka plandaki Mağaza uygulamaları, görsel efektler, şeffaflık, hazırda bekletme, güncellemelerin P2P paylaşımı
- **Oyun Performansı:** Oyun Modu, oyunlara yüksek CPU/GPU önceliği (MMCSS), Nihai Performans güç planı, donanım hızlandırmalı GPU zamanlaması, tam ekran optimizasyonları, fare ivmesi, Xbox Game DVR

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

Her sürüm **imzalıdır**: `version.json` her dosyanın SHA-256 özetini ve bu listenin RSA-3072 imzasını içerir. Uygulama ve `install.ps1`, içlerine gömülü açık anahtarla imzayı doğrular; özeti uyuşmayan dosyayı reddeder. Değiştirilmiş ya da ele geçirilmiş bir indirme asla kurulmaz.

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
    ├── Startup.ps1          # Başlangıç uygulamaları yöneticisi
    ├── DiskCleaner.ps1      # Disk kapasitesi + gereksiz dosya temizliği
    ├── Services.ps1         # Arka plan servisleri analizi
    └── Network.ps1          # Ağ bağdaştırıcıları ve DNS
pages/                       # Bağımsız sayfalar (kendi arayüzü + mantığı)
    ├── Game.ps1, Analyzer.ps1, Apps.ps1, Network.ps1
    ├── Health.ps1, Privacy.ps1, Monitor.ps1
    ├── SmartMem.ps1         # Akıllı standby, arka plan kısıtlayıcı, sızıntı dedektörü, sayfa dosyası danışmanı
    └── Extras.ps1           # Profil, sistem tepsisi, zamanlanmış bakım
tools/
    ├── release.ps1          # Sürümü imzalar: dosya başına SHA-256 + RSA imzası -> version.json
    └── public-key.xml       # Açık anahtar (özel anahtar asla depoda değildir)
```

## ⚠️ Notlar

- Windows 10/11 ve Windows PowerShell 5.1 (Windows ile birlikte gelir) gerekir. Uygulama yönetici izni ister.
- Değişiklik yapmadan önce bir **sistem geri yükleme noktası** oluşturmanız önerilir (Genel Bakış → Hızlı İşlemler).
- Bazı ayarlar Explorer yeniden başlatıldığında (uygulama bunu önerir) ya da oturum kapatılıp açıldığında etkinleşir.
- Günlük dosyası: `%TEMP%\WindowsOptimizer.log`

## 🤝 Katkı

Windows Optimizer [MIT Lisansı](LICENSE) ile açık kaynaktır. Hata bildirimleri, çeviriler ve yeni modüller memnuniyetle karşılanır; kod kuralları ve sürüm akışı için [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına bakın.

## 🔗 Bağlantılar

- **GitHub:** [AppsTRDesign](https://github.com/AppsTRDesign)
- **Instagram:** [@oztasonur1](https://instagram.com/oztasonur1)
- **Website:** [worldofwar.site](https://worldofwar.site)

---

**AppsTRDesign** tarafından geliştirildi
