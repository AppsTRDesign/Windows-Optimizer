# Windows Optimizer

Türkçe | [🇬🇧 English](README.md)

Windows 10/11 için modüler, açık kaynak optimizasyon aracı. Reklamları kapat, gereksiz özellikleri yönet, RAM'i temizle ve arka plan süreçlerini tek tıkla kontrol et.

![Windows Optimizer](assets/banner.png)

## ✨ Özellikler

| Modül | Açıklama |
|-------|----------|
| 🛡️ **Reklam Engelleyici** | Dosya Gezgini, Kilit Ekranı, Başlat Menüsü, Ayarlar ve Bildirimlerdeki reklamları kapatır |
| 🔍 **Özellik Yöneticisi** | Bing Arama, Telemetri, Cortana ve Tüketici Özelliklerini açar/kapatır |
| 🧠 **RAM Temizleyici** | Microsoft RAMMap ile bekleme belleğini temizler |
| ⚙️ **Arka Plan Yöneticisi** | Gereksiz arka plan uygulamalarını devre dışı bırakır |

## 🚀 Tek Tıkla Kurulum

**PowerShell'i Yönetici olarak açın** ve şu komutu çalıştırın:

# Kurulum
```powershell
irm https://raw.githubusercontent.com/AppsTRDesign/Windows-Optimizer/main/install.ps1 | iex
```
# Kaldırma
```powershell
Remove-Item "$env:USERPROFILE\Windows-Optimizer" -Recurse -Force -ErrorAction SilentlyContinue
```
```powershell
Remove-Item "$env:USERPROFILE\Desktop\Windows Optimizer.lnk" -Force -ErrorAction SilentlyContinue
```
