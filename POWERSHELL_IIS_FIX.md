# PowerShell IIS Module Fix

## Problem
The error `Get-Website is not recognized` occurs because IIS PowerShell cmdlets require the WebAdministration module to be imported.

## Solution

### Option 1: Import WebAdministration Module (Recommended)
Add this to the beginning of your PowerShell script:

```powershell
powershell_script 'final_website_creation' do
  code <<-EOH
    # Import IIS WebAdministration module
    Import-Module WebAdministration -Force -ErrorAction Stop
    
    === FINAL WEBSITE CREATION ===
    Applying the proven method after all files are deployed...
    STEP 0: Verifying files exist...
    SUCCESS: index.html exists: 9413 bytes
    STEP 1: Removing any existing websites that might conflict...
    
    # Now Get-Website will work
    $existingWebsites = Get-Website
    # ... rest of your script
  EOH
  action :run
end
```

### Option 2: Use windows_feature to Install IIS First
Ensure IIS is properly installed with PowerShell module:

```ruby
# Install IIS with management tools
windows_feature 'IIS-WebServerRole' do
  action :install
end

windows_feature 'IIS-WebServerManagementTools' do
  action :install
end

windows_feature 'IIS-ManagementConsole' do
  action :install
end

# Then your PowerShell script with module import
powershell_script 'final_website_creation' do
  code <<-EOH
    Import-Module WebAdministration -Force
    
    # Your IIS configuration code here
    $websites = Get-Website
    # etc...
  EOH
  action :run
end
```

### Option 3: Use Direct IIS Provider Commands
Instead of PowerShell cmdlets, use Chef's built-in IIS resources:

```ruby
# Remove existing default website
iis_site 'Default Web Site' do
  action :delete
  not_if { Dir.glob("#{ENV['SYSTEMDRIVE']}/inetpub/wwwroot/*").empty? }
end

# Create new website
iis_site 'MyWebsite' do
  protocol :http
  port 80
  path 'C:/inetpub/wwwroot'
  action [:add, :start]
end
```

### Option 4: Check and Install IIS Module Explicitly
```powershell
powershell_script 'ensure_iis_module' do
  code <<-EOH
    # Check if WebAdministration module is available
    $module = Get-Module -ListAvailable -Name WebAdministration
    if (-not $module) {
      Write-Host "WebAdministration module not found. Installing IIS Management Tools..."
      Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -All -NoRestart
      Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -All -NoRestart
    }
    
    # Import the module
    Import-Module WebAdministration -Force -ErrorAction Stop
    Write-Host "WebAdministration module loaded successfully"
    
    # Verify it works
    $websites = Get-Website
    Write-Host "Found $($websites.Count) existing websites"
  EOH
  action :run
end
```

## Quick Fix for Your Current Script

The immediate fix is to add one line at the top of your PowerShell script:

```powershell
Import-Module WebAdministration -Force
```

So your script becomes:
```powershell
powershell_script 'final_website_creation' do
  code <<-EOH
    Import-Module WebAdministration -Force
    
    === FINAL WEBSITE CREATION ===
    Applying the proven method after all files are deployed...
    STEP 0: Verifying files exist...
    SUCCESS: index.html exists: 9413 bytes
    STEP 1: Removing any existing websites that might conflict...
    
    # Now this will work:
    $existingWebsites = Get-Website
    # ... rest of your existing script
  EOH
  action :run
end
```

## Root Cause
Windows Server doesn't automatically load the IIS PowerShell module. Even if IIS is installed, the `WebAdministration` module must be explicitly imported before using cmdlets like:
- `Get-Website`
- `New-Website`
- `Remove-Website`
- `Start-Website`
- `Stop-Website`

This is a common issue in Chef Windows cookbooks that manage IIS.