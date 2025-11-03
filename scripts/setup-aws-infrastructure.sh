#!/bin/bash
# AWS Infrastructure Setup Script for Chef Cookbook Testing

set -e

echo "🚀 Setting up AWS infrastructure for Chef cookbook testing..."

# Variables - Update these for your environment
AWS_REGION="us-west-2"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
KEY_NAME="chef-testing"

# Create VPC
echo "📝 Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=chef-testing-vpc},{Key=Project,Value=cookbook-testing}]' \
  --query 'Vpc.VpcId' \
  --output text \
  --region $AWS_REGION)

echo "✅ VPC created: $VPC_ID"

# Create Internet Gateway
echo "📝 Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=chef-testing-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text \
  --region $AWS_REGION)

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $AWS_REGION

echo "✅ Internet Gateway created and attached: $IGW_ID"

# Create Public Subnet
echo "📝 Creating public subnet..."
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_CIDR \
  --availability-zone "${AWS_REGION}a" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=chef-testing-subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text \
  --region $AWS_REGION)

echo "✅ Subnet created: $SUBNET_ID"

# Create Route Table
echo "📝 Creating route table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=chef-testing-rt}]' \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region $AWS_REGION)

# Create route to Internet Gateway
aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $AWS_REGION

# Associate route table with subnet
aws ec2 associate-route-table \
  --subnet-id $SUBNET_ID \
  --route-table-id $ROUTE_TABLE_ID \
  --region $AWS_REGION

echo "✅ Route table configured: $ROUTE_TABLE_ID"

# Create Security Group
echo "📝 Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name chef-testing-sg \
  --description "Security group for Chef cookbook testing" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=chef-testing-sg}]' \
  --query 'GroupId' \
  --output text \
  --region $AWS_REGION)

# Add SSH rule (port 22)
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

# Add WinRM rules (ports 5985, 5986)
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 5985 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 5986 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

# Add RDP rule (port 3389) - optional for Windows debugging
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 3389 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

echo "✅ Security group created: $SECURITY_GROUP_ID"

# Create Key Pair (if it doesn't exist)
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $AWS_REGION &>/dev/null; then
  echo "📝 Creating SSH key pair..."
  aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text \
    --region $AWS_REGION > ~/.ssh/${KEY_NAME}.pem
  
  chmod 600 ~/.ssh/${KEY_NAME}.pem
  echo "✅ SSH key pair created: ~/.ssh/${KEY_NAME}.pem"
else
  echo "✅ SSH key pair already exists: $KEY_NAME"
fi

echo ""
echo "🎉 AWS Infrastructure Setup Complete!"
echo ""
echo "📋 Configuration Summary:"
echo "Region: $AWS_REGION"
echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID"
echo "Security Group ID: $SECURITY_GROUP_ID"
echo "Key Pair: $KEY_NAME"
echo ""
echo "🔧 GitHub Secrets to Configure:"
echo "AWS_ACCESS_KEY_ID=<your-access-key>"
echo "AWS_SECRET_ACCESS_KEY=<your-secret-key>"
echo "AWS_SUBNET_ID=$SUBNET_ID"
echo "AWS_SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
echo ""
echo "🧪 Test Kitchen Environment Variables:"
echo "export AWS_SUBNET_ID=$SUBNET_ID"
echo "export AWS_SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
echo "export AWS_SSH_KEY_NAME=$KEY_NAME"
echo "export AWS_REGION=$AWS_REGION"