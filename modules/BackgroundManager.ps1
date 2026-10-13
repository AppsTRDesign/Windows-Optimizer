function Disable-BackgroundApps {
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
    foreach ($app in @("Microsoft.Windows.Cortana","Microsoft.WindowsFeedbackHub","Microsoft.GetHelp","Microsoft.XboxApp")) {
        try { Get-AppBackgroundTask -PackageFamilyName $app -ErrorAction SilentlyContinue |
              Disable-AppBackgroundTask -ErrorAction SilentlyContinue } catch {}
    }
}