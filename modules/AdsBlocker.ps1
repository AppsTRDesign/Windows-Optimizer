# Reklam engelleyici fonksiyonlar

function Set-Reg {
    param([string]$Path,[string]$Name,[int]$Value=0)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
}

function Disable-ExplorerAds {
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
}
function Disable-LockScreenAds {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "RotatingLockScreenOverlayEnabled" 0
    Set-Reg $p "SubscribedContent-338387Enabled" 0
}
function Disable-SettingsAds {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "SubscribedContent-338393Enabled" 0
    Set-Reg $p "SubscribedContent-353694Enabled" 0
    Set-Reg $p "SubscribedContent-353696Enabled" 0
}
function Disable-GeneralTips {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "SoftLandingEnabled" 0
    Set-Reg $p "SubscribedContent-310093Enabled" 0
}
function Disable-FinishSetupAds {
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0
}
function Disable-WelcomeExperience {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "SubscribedContent-338388Enabled" 0
    Set-Reg $p "SubscribedContent-338389Enabled" 0
}
function Disable-PersonalizedAds {
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    # HKLM - admin gerektirir, GUI zaten admin çalışıyor
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1
}
function Disable-TailoredExperiences {
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
}
function Disable-StartMenuAds {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "SubscribedContent-338388Enabled" 0
    Set-Reg $p "SystemPaneSuggestionsEnabled" 0
    Set-Reg $p "SilentInstalledAppsEnabled" 0
}
function Disable-NotificationSuggestions {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-Reg $p "SubscribedContent-338389Enabled" 0
    Set-Reg $p "SubscribedContent-314563Enabled" 0
    Set-Reg $p "SubscribedContent-88000326Enabled" 0
}
function Disable-BingSearch {
    $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    Set-Reg $p "BingSearchEnabled" 0
    Set-Reg $p "CortanaConsent" 0
    Set-Reg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
}
function Disable-EdgeSearchBar {
    $p = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
    Set-Reg $p "WebWidgetAllowed" 0
    Set-Reg $p "SearchbarAllowed" 0
}