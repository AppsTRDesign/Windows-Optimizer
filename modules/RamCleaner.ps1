function Clear-StandbyMemory {
    $url  = "https://live.sysinternals.com/RAMMap.exe"
    $path = "$env:TEMP\RAMMap.exe"
    if (-not (Test-Path $path)) {
        Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
    }
    Start-Process -FilePath $path -ArgumentList "-Et" -Wait -NoNewWindow
}