# Debug Chef Client Execution - Run on Windows Server
# Save as debug_timezone.ps1 and run on your Windows Server

Write-Host "=== CHEF TIMEZONE DEBUG SCRIPT ===" -ForegroundColor Green

# 1. Check current timezone
Write-Host "`n1. CURRENT TIMEZONE:" -ForegroundColor Yellow
Get-TimeZone | Format-Table Id, DisplayName, BaseUtcOffset

# 2. Check Chef client version and last run
Write-Host "`n2. CHEF CLIENT INFO:" -ForegroundColor Yellow
chef-client --version
$logPath = "C:\chef\log\client.log"
if (Test-Path $logPath) {
    Write-Host "Last Chef run entries:"
    Get-Content $logPath | Select-Object -Last 10
} else {
    Write-Host "Chef log not found at $logPath"
}

# 3. Check Chef node attributes (if chef-shell available)
Write-Host "`n3. CHECKING NODE ATTRIBUTES:" -ForegroundColor Yellow
try {
    $tempFile = "C:\temp\chef_attrs.rb"
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
    @'
puts "Time attributes:"
pp node["time"]
puts "Override timezone: #{node.override["time"]["timezone"] rescue "none"}"
puts "Default timezone: #{node.default["time"]["timezone"] rescue "none"}"
puts "Final timezone: #{node["time"]["timezone"]}"
'@ | Out-File -FilePath $tempFile -Encoding ASCII
    
    chef-shell -c $tempFile
    Remove-Item $tempFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "Could not check node attributes: $_"
}

# 4. Test manual timezone change
Write-Host "`n4. TESTING MANUAL TIMEZONE CHANGE:" -ForegroundColor Yellow
try {
    Write-Host "Available Eastern timezones:"
    Get-TimeZone -ListAvailable | Where-Object { $_.Id -like "*Eastern*" } | Format-Table Id, DisplayName
    
    Write-Host "Attempting to set Eastern Standard Time..."
    Set-TimeZone -Id "Eastern Standard Time" -ErrorAction Stop
    Write-Host "SUCCESS: Timezone changed manually"
    Get-TimeZone | Format-Table Id, DisplayName, BaseUtcOffset
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Check Chef client service
Write-Host "`n5. CHEF CLIENT SERVICE:" -ForegroundColor Yellow
Get-Service chef-client -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType

Write-Host "`n=== DEBUG COMPLETE ===" -ForegroundColor Green
Write-Host "If timezone changed manually but not via Chef, the issue is in Chef execution or policy application."