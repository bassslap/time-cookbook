# Quick Fix for Direct Deployment Without Policyfile

Since you deployed without using a Policyfile, the issue is that the cookbook is using the default attribute `'America/New_York'` which needs to be mapped to Windows format.

## Option 1: Quick Role/Environment Override (Recommended)

Create a role or set node attributes to override the timezone:

### Via Role:
```ruby
# Create role: roles/windows_est.rb
name 'windows_est'
description 'Windows servers with EST timezone'
run_list 'recipe[enterprise-time::default]'

default_attributes(
  'time' => {
    'timezone' => 'Eastern Standard Time'  # Direct Windows format
  }
)
```

### Via Node Attribute (Chef Automate UI):
1. Go to Node Management in Chef Automate
2. Select your Windows node
3. Add attribute: `time.timezone = "Eastern Standard Time"`

### Via Knife Command:
```bash
knife node edit YOUR_WINDOWS_NODE_NAME
# Add this to the node JSON:
{
  "default": {
    "time": {
      "timezone": "Eastern Standard Time"
    }
  }
}
```

## Option 2: Update Cookbook Default (What I just did)

The cookbook now has better mapping logic, but let me also ensure the debug output helps identify the issue.

## Option 3: Manual Chef Run with Override

```powershell
# On Windows Server - override the timezone attribute
chef-client --json-attributes C:\temp\timezone.json

# Where timezone.json contains:
{
  "time": {
    "timezone": "Eastern Standard Time"
  }
}
```

## Immediate Debug Steps

1. **Check what timezone value Chef is receiving:**
   ```powershell
   # Look in Chef logs for these debug lines:
   # "🔍 Windows timezone mapping input: '...'"
   # "🔧 PRODUCTION FIX: Forcing America/New_York -> Eastern Standard Time"
   ```

2. **Force Chef run with debug:**
   ```powershell
   chef-client --log-level debug
   ```

3. **Check if mapping is working:**
   Look for the PowerShell output in Chef logs showing timezone change attempt.

The quickest fix is Option 1 - set a node attribute directly to `"Eastern Standard Time"` to bypass the mapping completely.