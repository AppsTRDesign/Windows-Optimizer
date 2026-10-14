# modules/BackgroundManager.ps1
function Set-Reg {
    param([string]$Path,[string]$Name,[int]$Value=0)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
}

function Disable-BackgroundApps {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
    foreach ($app in @("Microsoft.Windows.Cortana","Microsoft.WindowsFeedbackHub","Microsoft.GetHelp","Microsoft.XboxApp")) {
        try {
            Get-AppBackgroundTask -PackageFamilyName $app -ErrorAction SilentlyContinue |
                Disable-AppBackgroundTask -ErrorAction SilentlyContinue
        } catch {}
    }
}