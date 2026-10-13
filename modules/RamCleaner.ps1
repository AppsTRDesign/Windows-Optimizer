# modules/RamCleaner.ps1
# RAMMap kullanarak bekleme belleğini temizleyen modül

function Clear-StandbyMemory {
    $ramMapUrl = "https://live.sysinternals.com/RAMMap.exe"
    $ramMapPath = "$env:TEMP\RAMMap.exe"

    if (-not (Test-Path $ramMapPath)) {
        Write-Host "RAMMap indiriliyor..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ramMapUrl -OutFile $ramMapPath -UseBasicParsing
    }

    Write-Host "Bekleme belleği temizleniyor..." -ForegroundColor Cyan
    # -Et parametresi bekleme listesini boşaltır
    Start-Process -FilePath $ramMapPath -ArgumentList "-Et" -Wait -NoNewWindow
    Write-Host "RAM temizleme tamamlandı." -ForegroundColor Green
}

Clear-StandbyMemory