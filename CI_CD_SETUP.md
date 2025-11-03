# CI/CD Testing Setup for time-cookbook

This cookbook includes comprehensive CI/CD testing capabilities for AWS, Azure, and Docker environments.

## 🚀 GitHub Actions Pipeline

The `.github/workflows/ci.yml` pipeline includes:

### 1. **Lint and Syntax Check**
- Ruby syntax validation
- Cookstyle linting
- Cookbook structure validation

### 2. **Unit Tests**
- ChefSpec unit tests
- Recipe logic validation

### 3. **Integration Tests**
- **Docker**: Fast containerized testing
- **AWS EC2**: Real cloud infrastructure testing
- **Azure VMs**: Cross-cloud validation

## 🔧 Setup Instructions

### Prerequisites

#### For AWS Testing:
1. **GitHub Secrets** (Repository Settings → Secrets and variables → Actions):
   ```
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   AWS_SUBNET_ID=subnet-xxxxxxxxx
   AWS_SECURITY_GROUP_ID=sg-xxxxxxxxx
   ```

2. **AWS Infrastructure**:
   - VPC with public subnet
   - Security group allowing SSH (22) and WinRM (5985/5986)
   - EC2 Key Pair named 'chef-testing'

#### For Azure Testing:
1. **GitHub Secrets**:
   ```
   AZURE_CREDENTIALS='{"clientId":"xxx","clientSecret":"xxx","subscriptionId":"xxx","tenantId":"xxx"}'
   AZURE_SUBSCRIPTION_ID=your_subscription_id
   ```

2. **Azure Service Principal**:
   ```bash
   az ad sp create-for-rbac --name "github-actions-chef-testing" \
     --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
     --sdk-auth
   ```

#### For Docker Testing:
- No additional setup required
- Runs on GitHub Actions runners

## 🧪 Manual Testing Commands

### Local Docker Testing:
```bash
# Install dependencies
gem install kitchen-docker kitchen-inspec

# Run Docker tests
export KITCHEN_YAML=.kitchen.docker.yml
kitchen test default-ubuntu-2004
kitchen test default-centos-8
```

### AWS EC2 Testing:
```bash
# Install dependencies
gem install kitchen-ec2 kitchen-inspec

# Set environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_SUBNET_ID=subnet-xxx
export AWS_SECURITY_GROUP_ID=sg-xxx
export AWS_SSH_KEY_NAME=your-key-name

# Run AWS tests
export KITCHEN_YAML=.kitchen.aws.yml
kitchen test default-ubuntu-2004
kitchen test default-windows-2019
```

### Azure VM Testing:
```bash
# Install dependencies
gem install kitchen-azurerm kitchen-inspec

# Azure login
az login

# Set environment variables
export AZURE_SUBSCRIPTION_ID=your_subscription_id

# Run Azure tests
export KITCHEN_YAML=.kitchen.azure.yml
kitchen test default-ubuntu-2004
kitchen test default-windows-2019
```

## 🎯 Test Scenarios

### Default Test Suite:
- **Platform**: Ubuntu 20.04, CentOS 8, Windows 2019
- **Timezone**: America/New_York (Linux), Pacific Standard Time (Windows)
- **NTP Service**: Traditional ntpd (Linux), W32Time (Windows)
- **Validation**: Service status, configuration files, time sync

### Chrony Test Suite:
- **Platform**: Ubuntu 20.04, CentOS 8
- **Timezone**: Europe/London
- **NTP Service**: Chrony (forced)
- **Validation**: Chrony-specific configuration and status

### Enterprise Test Suite:
- **Platform**: All Linux variants
- **Timezone**: UTC
- **NTP Servers**: Corporate NTP servers with fallback
- **Validation**: Enterprise-grade configuration

## 🔍 Pipeline Triggers

### Automatic Triggers:
- **Push to main/develop**: Full test suite
- **Pull Requests**: Lint, syntax, and Docker tests
- **Manual Dispatch**: All tests including cloud providers

### Test Results:
- Results appear in GitHub Actions tab
- Detailed logs available for each test phase
- Summary posted to GitHub Step Summary

## 🛠 Troubleshooting

### Common Issues:

1. **AWS EC2 Tests Failing**:
   - Verify subnet and security group IDs
   - Check AWS credentials and permissions
   - Ensure SSH key exists in specified region

2. **Azure VM Tests Failing**:
   - Verify service principal permissions
   - Check subscription ID
   - Ensure resource group permissions

3. **Docker Tests Failing**:
   - Usually due to systemd/init system requirements
   - Check Docker daemon permissions
   - Verify container image availability

### Debug Commands:
```bash
# Verbose Test Kitchen output
kitchen test -l debug

# Check Test Kitchen diagnose
kitchen diagnose

# Validate configuration
kitchen list
```

## 📊 Cost Optimization

### Resource Management:
- **Auto-cleanup**: VMs destroyed after tests
- **Small instances**: t3.small (AWS), Standard_B1s (Azure)
- **Short-lived**: Tests typically complete in 10-15 minutes
- **On-demand**: Cloud tests only on main branch or manual trigger

### Cost Estimates (per test run):
- **Docker**: Free (GitHub Actions)
- **AWS EC2**: ~$0.20 per instance per run
- **Azure VM**: ~$0.15 per instance per run

## 🚀 Next Steps

1. **Configure Secrets** in your GitHub repository
2. **Set up cloud infrastructure** (VPC, security groups, etc.)
3. **Test the pipeline** with a commit to main branch
4. **Monitor results** in GitHub Actions
5. **Customize test scenarios** as needed

The pipeline is designed to be robust and provide comprehensive validation across multiple platforms and cloud providers!