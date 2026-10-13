# modules/FeatureManager.ps1
# Gereksiz Windows özelliklerini açma/kapama modülü

function Set-FeatureState {
    param(
        [string]$FeatureName,
        [bool]$Enable  # $true = özelliği etkinleştir, $false = devre dışı bırak
    )

    switch ($FeatureName) {
        "BingSearch" {
            # Bing arama önerilerini kapat/aç
            $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
            Set-ItemProperty -Path $path -Name "BingSearchEnabled" -Value ([int]!$Enable) -Type DWord -Force
            $policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
            Set-ItemProperty -Path $policyPath -Name "DisableSearchBoxSuggestions" -Value ([int]!$Enable) -Type DWord -Force
            Write-Host "Bing Arama: $(if($Enable){'Etkin'}else{'Devre Dışı'})" -ForegroundColor Yellow
        }
        "Telemetry" {
            # Telemetri ve veri toplamayı kapat/aç
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value ([int]$Enable) -Type DWord -Force
            Write-Host "Telemetri: $(if($Enable){'Etkin'}else{'Devre Dışı'})" -ForegroundColor Yellow
        }
        "Cortana" {
            # Cortana'yı devre dışı bırak/etkinleştir
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AllowCortana" -Value ([int]$Enable) -Type DWord -Force
            Write-Host "Cortana: $(if($Enable){'Etkin'}else{'Devre Dışı'})" -ForegroundColor Yellow
        }
        "ConsumerFeatures" {
            # Tüketici özelliklerini (öneriler, ipuçları) kapat/aç
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisableWindowsConsumerFeatures" -Value ([int]!$Enable) -Type DWord -Force
            Write-Host "Tüketici Özellikleri: $(if($Enable){'Etkin'}else{'Devre Dışı'})" -ForegroundColor Yellow
        }
        default {
            Write-Host "Bilinmeyen özellik: $FeatureName" -ForegroundColor Red
        }
    }
}

# Örnek kullanım: Tüm gereksiz özellikleri devre dışı bırak
Set-FeatureState -FeatureName "BingSearch" -Enable $false
Set-FeatureState -FeatureName "Telemetry" -Enable $false
Set-FeatureState -FeatureName "Cortana" -Enable $false
Set-FeatureState -FeatureName "ConsumerFeatures" -Enable $false