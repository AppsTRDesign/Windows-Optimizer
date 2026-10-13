# modules/AdsBlocker.ps1
# Windows 10/11 Reklam Engelleyici Modülü
# Kayıt defteri anahtarlarını değiştirerek sistem genelindeki reklamları devre dışı bırakır.

function Disable-WindowsAds {
    Write-Host "Reklamlar devre dışı bırakılıyor..." -ForegroundColor Cyan

    # 1. Başlat Menüsü'ndeki önerilen uygulamaları kapat
    $startMenuPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $startMenuPath -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $startMenuPath -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $startMenuPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force

    # 2. Dosya Gezgini'ndeki OneDrive reklamını kapat
    $explorerPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $explorerPath -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -Force

    # 3. Kilit ekranındaki reklamları ve ipuçlarını kapat
    $lockScreenPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $lockScreenPath -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $lockScreenPath -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force

    # 4. Bildirim merkezindeki önerileri kapat
    $notifPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.ActionCenter.SmartOptOut"
    if (-not (Test-Path $notifPath)) { New-Item -Path $notifPath -Force | Out-Null }
    Set-ItemProperty -Path $notifPath -Name "Enabled" -Value 0 -Type DWord -Force

    # 5. Reklam kimliğini devre dışı bırak (sistem geneli)
    $adIdPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $adIdPath)) { New-Item -Path $adIdPath -Force | Out-Null }
    Set-ItemProperty -Path $adIdPath -Name "Enabled" -Value 0 -Type DWord -Force

    Write-Host "Reklamlar başarıyla devre dışı bırakıldı." -ForegroundColor Green
}

# Modülü çalıştır
Disable-WindowsAds