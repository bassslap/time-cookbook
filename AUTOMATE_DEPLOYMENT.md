# Chef Automate Deployment Guide

## Uploading to Chef Automate

### 1. Package the cookbook
```bash
# From the cookbook directory
tar -czf time-cookbook-1.0.0.tar.gz --exclude='.git' --exclude='.kitchen' .
```

### 2. Upload via Chef Automate UI
1. Navigate to your Chef Automate server
2. Go to **Applications** → **Chef Infra** → **Cookbooks**
3. Click **Upload Cookbook**
4. Select the `time-cookbook-1.0.0.tar.gz` file
5. Verify the cookbook appears in the list

### 3. Create/Update Policy
1. Go to **Applications** → **Chef Infra** → **Policies** 
2. Create new policy or edit existing one
3. Add `time-cookbook::default` to the run list
4. Configure attributes as needed:

```json
{
  "time": {
    "timezone": "America/New_York",
    "ntp_servers": [
      "0.north-america.pool.ntp.org",
      "1.north-america.pool.ntp.org", 
      "2.north-america.pool.ntp.org"
    ]
  }
}
```

### 4. Apply to Node Groups
1. Go to **Applications** → **Chef Infra** → **Node Management**
2. Select target nodes or create node groups
3. Apply the policy containing the time-cookbook

## Alternative: Using knife/chef CLI

### Upload cookbook
```bash
knife cookbook upload time-cookbook
```

### Using Policyfile
```bash
# Install policy dependencies
chef install Policyfile.rb

# Upload policy to Chef Automate
chef push production Policyfile.lock.json
```

## Environment-Specific Configurations

### Production Environment
```json
{
  "time": {
    "timezone": "UTC",
    "ntp_servers": [
      "ntp1.company.com",
      "ntp2.company.com", 
      "0.pool.ntp.org"
    ]
  }
}
```

### Development Environment  
```json
{
  "time": {
    "timezone": "America/Los_Angeles",
    "ntp_servers": [
      "pool.ntp.org"
    ]
  }
}
```

## Monitoring in Chef Automate

After deployment, you can monitor:

1. **Compliance**: Use the included InSpec tests
2. **Node Status**: Check Chef client run status
3. **Attributes**: Verify applied configuration
4. **Convergence**: Monitor cookbook execution logs

## Troubleshooting

### Common Issues:
- **Windows nodes**: Ensure WinRM is properly configured
- **Linux nodes**: Verify sudo/root access for service management
- **Network**: Ensure NTP servers are reachable from target nodes

### Viewing Logs in Automate:
1. Go to **Applications** → **Chef Infra** → **Client Runs**
2. Select the node and run to view detailed logs
3. Check for any cookbook execution errors