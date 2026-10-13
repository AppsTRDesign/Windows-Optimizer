# modules/BackgroundManager.ps1
# Gereksiz arka plan uygulamalarını ve servislerini yönetir

function Disable-BackgroundApps {
    Write-Host "Arka plan uygulamaları devre dışı bırakılıyor..." -ForegroundColor Cyan

    # Tüm kullanıcılar için arka plan uygulamalarını devre dışı bırak
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "LetAppsRunInBackground" -Value 2 -Type DWord -Force

    # Belirli uygulamaların arka plan görevlerini kapat
    $appsToDisable = @(
        "Microsoft.Windows.Cortana",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.GetHelp",
        "Microsoft.XboxApp"
    )

    foreach ($app in $appsToDisable) {
        try {
            Get-AppBackgroundTask -PackageFamilyName $app -ErrorAction SilentlyContinue | Disable-AppBackgroundTask -ErrorAction SilentlyContinue
            Write-Host "  $app arka plan görevi devre dışı." -ForegroundColor Gray
        } catch {
            # Uygulama yüklü değilse yoksay
        }
    }

    Write-Host "Arka plan yönetimi tamamlandı." -ForegroundColor Green
}

Disable-BackgroundApps