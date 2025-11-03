# AWS Testing Setup for time-cookbook

## 🚀 Quick Start AWS Testing

### Prerequisites
1. AWS CLI installed and configured
2. AWS account with EC2 permissions
3. Ruby and Chef Workstation installed

### Step 1: Set up AWS Infrastructure

Run the automated setup script:
```bash
cd time-cookbook
./scripts/setup-aws-infrastructure.sh
```

This creates:
- VPC with public subnet
- Security group (SSH, WinRM, RDP)
- SSH key pair
- Internet gateway and routing

### Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
```
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_SUBNET_ID=subnet-xxxxxxxxxxxxxxxxx
AWS_SECURITY_GROUP_ID=sg-xxxxxxxxxxxxxxxxx
```

### Step 3: Test Locally (Optional)

Install dependencies:
```bash
gem install kitchen-ec2 kitchen-inspec
```

Set environment variables:
```bash
export AWS_SUBNET_ID=subnet-xxxxxxxxxxxxxxxxx
export AWS_SECURITY_GROUP_ID=sg-xxxxxxxxxxxxxxxxx
export AWS_SSH_KEY_NAME=chef-testing
export AWS_REGION=us-west-2
```

Run tests:
```bash
export KITCHEN_YAML=.kitchen.aws.yml
kitchen list
kitchen test default-ubuntu-2004
```

### Step 4: Trigger GitHub Actions

Push to main branch or manually trigger the workflow:
- Go to Actions tab in GitHub
- Select "Chef Cookbook CI/CD" workflow
- Click "Run workflow"

## 🧪 Test Scenarios

### Default Test (`default-ubuntu-2004`)
- **Platform**: Ubuntu 20.04 LTS
- **Timezone**: America/Los_Angeles
- **NTP**: Traditional ntpd
- **Validation**: Service status, config files, time sync

### Enterprise Test (`enterprise-ubuntu-2004`)
- **Platform**: Ubuntu 20.04 LTS  
- **Timezone**: UTC
- **NTP**: Corporate servers with fallback
- **Validation**: Enterprise configuration

### Windows Test (`windows-test-windows-2019`)
- **Platform**: Windows Server 2019
- **Timezone**: Pacific Standard Time
- **NTP**: W32Time with Windows servers
- **Validation**: W32Time service and config

## 💰 Cost Optimization

- **Instance Type**: t3.small (~$0.0208/hour)
- **Test Duration**: ~10-15 minutes per platform
- **Auto-cleanup**: Instances destroyed after tests
- **Estimated Cost**: ~$0.20-0.30 per full test run

## 🔍 Monitoring Results

### GitHub Actions:
1. Go to Actions tab in your repository
2. Select the latest workflow run
3. View logs for each test platform
4. Check InSpec test results

### Manual Testing:
```bash
# Check test status
kitchen list

# View test logs
kitchen diagnose default-ubuntu-2004

# Connect to test instance (debugging)
kitchen login default-ubuntu-2004
```

## 🛠 Troubleshooting

### Common Issues:

1. **Permission Denied**:
   - Check AWS credentials and IAM permissions
   - Ensure EC2, VPC, and IAM read/write access

2. **Instance Launch Failed**:
   - Verify subnet and security group IDs
   - Check region consistency
   - Ensure AMI availability in your region

3. **SSH Connection Failed**:
   - Verify security group allows SSH (port 22)
   - Check SSH key pair exists
   - Ensure public IP assignment

4. **Test Kitchen Errors**:
   ```bash
   # Debug mode
   kitchen test -l debug default-ubuntu-2004
   
   # Check configuration
   kitchen diagnose default-ubuntu-2004
   ```

### Debug Commands:
```bash
# List AWS resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=cookbook-testing"
aws ec2 describe-subnets --filters "Name=tag:Name,Values=chef-testing-subnet"
aws ec2 describe-security-groups --filters "Name=group-name,Values=chef-testing-sg"

# Check running instances
aws ec2 describe-instances --filters "Name=tag:CreatedBy,Values=test-kitchen"
```

## 🚀 Next Steps

1. **Run the setup script** to create AWS infrastructure
2. **Configure GitHub secrets** with your AWS credentials
3. **Push a commit** to trigger the CI pipeline
4. **Monitor the results** in GitHub Actions
5. **Scale testing** by adding more platforms or regions

The AWS testing pipeline will validate your cookbook across real EC2 infrastructure, giving you confidence for production deployments!