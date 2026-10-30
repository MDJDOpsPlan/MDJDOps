# 1. Connect to the target Government SharePoint site using SharePoint Online Management Shell Client ID & Device Login
$ClientId = "9bc3ab49-b65d-410a-85ad-de819febfddc" # Pre-approved SharePoint Online Management Shell Client ID
$TargetUrl = "https://mdcourts.sharepoint.com/sites/StrategicCampaign2024-2029/StandaloneTest" 

# Define blueprint path to be on your Desktop
$BlueprintPath = Join-Path $PSScriptRoot "Blueprint.xml"
try {
Write-Host "Clearing existing SharePoint connections..." -ForegroundColor Gray
Disconnect-PnPOnline -ClearPersistedLogin -ErrorAction SilentlyContinue | Out-Null

Write-Host "Connecting to target SharePoint Online site: $TargetUrl..." -ForegroundColor Cyan
Connect-PnPOnline -Url $TargetUrl -DeviceLogin -ClientId $ClientId -ErrorAction Stop

# 2. Apply the exact replica blueprint of the lists
Write-Host "Applying lists template from $BlueprintPath..." -ForegroundColor Cyan
Invoke-PnPSiteTemplate -Path $BlueprintPath -ErrorAction Stop

Write-Host "Lists replication and deployment completed successfully!" -ForegroundColor Green
}
catch {
Write-Error "An error occurred during deployment: $_"
}