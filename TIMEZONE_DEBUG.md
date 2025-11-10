# Timezone Still UTC - Troubleshooting Guide

## Quick Debugging Steps

### 1. Verify Chef Client Execution
```powershell
# On the Windows Server, check last Chef run
chef-client --version
Get-Content C:\chef\log\client.log | Select-Object -Last 50
```

### 2. Check Current Cookbook Version on Server
```bash
# On Chef Automate/Server
knife cookbook show enterprise-time
# Should show version 3.1.1
```

### 3. Verify Node Policy Assignment
```bash
# Check what policy is assigned to your Windows node
knife node show YOUR_WINDOWS_NODE_NAME -a policy_name -a policy_group
```

### 4. Force Chef Client Run
```powershell
# On Windows Server - force immediate Chef run
chef-client --local-mode --override-runlist enterprise-time::default
# OR if using Chef Automate
chef-client
```

### 5. Check Chef Logs for Timezone Errors
```powershell
# Look for timezone-related errors in Chef logs
Get-Content C:\chef\log\client.log | Select-String "timezone|TimeZone|EST|Eastern"
```

## Common Issues & Solutions

### Issue 1: Cookbook Version Not Updated on Server
**Problem**: Server still has old cookbook version
**Solution**: 
```bash
knife cookbook upload enterprise-time --force
# OR update policy
chef push production Policyfile.lock.json --force
```

### Issue 2: Policy Not Applied to Node
**Problem**: Windows node not using updated policy
**Solution**:
```bash
# Assign policy to node
knife node policy set YOUR_NODE_NAME production enterprise_time_policy
```

### Issue 3: Chef Client Service Not Running
**Problem**: Chef client not executing automatically
**Solution**:
```powershell
# Check and start Chef client service
Get-Service chef-client
Start-Service chef-client
```

### Issue 4: Attribute Override Conflict
**Problem**: Other attributes overriding timezone setting
**Check**: Look for competing timezone attributes in roles, environments, or node attributes

## Immediate Debug Commands

Run these on your Windows Server to see what's happening:

```powershell
# Check current timezone
Get-TimeZone

# Check if Chef is finding the cookbook
chef-client --why-run --log-level debug

# Look for timezone attribute values
chef-shell -c 'pp node["time"]'
```

## Expected Debug Output

When working correctly, you should see in Chef logs:
```
[timestamp] INFO: 🔍 Windows timezone mapping input: 'Eastern Standard Time'
[timestamp] INFO: 🔧 PRODUCTION FIX: Forcing America/New_York -> Eastern Standard Time  
[timestamp] INFO: Setting timezone to Eastern Standard Time...
[timestamp] INFO: Successfully set timezone to Eastern Standard Time
```

## Quick Fix Options

### Option A: Manual PowerShell Test
```powershell
# Test the timezone change manually
Set-TimeZone -Id "Eastern Standard Time"
Get-TimeZone
```

### Option B: Force Cookbook Execution
```bash
# Re-upload cookbook with force flag
knife cookbook upload enterprise-time --force

# Force policy update
chef push production Policyfile.lock.json --force

# Trigger immediate Chef run on Windows node
knife ssh "name:YOUR_WINDOWS_NODE" "chef-client" -x administrator
```