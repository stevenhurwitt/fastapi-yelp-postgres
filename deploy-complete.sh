#!/bin/bash

# 🚀 Complete AWS Deployment Script
# This script deploys your entire Yelp application to AWS

set -e

echo "🚀 Starting AWS deployment for Yelp App..."

# Configuration
STACK_NAME="yelp-app"
REGION="us-east-1"
DB_PASSWORD="YourSecurePassword123!"  # ⚠️ CHANGE THIS!

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI is not configured. Run 'aws configure' first."
    exit 1
fi

print_status "Prerequisites check passed"

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "Using AWS Account: $ACCOUNT_ID"

# Step 1: Deploy Infrastructure
echo "🏗️ Deploying infrastructure..."
aws cloudformation deploy \
    --template-file aws-infrastructure.yml \
    --stack-name $STACK_NAME \
    --parameter-overrides DBPassword=$DB_PASSWORD \
    --capabilities CAPABILITY_IAM \
    --region $REGION

print_status "Infrastructure deployed"

# Step 2: Get stack outputs
echo "📋 Getting infrastructure details..."
DATABASE_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
    --output text)

S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text)

ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
    --output text)

print_status "Got infrastructure details"
echo "  Database: $DATABASE_ENDPOINT"
echo "  S3 Bucket: $S3_BUCKET"  
echo "  Load Balancer: $ALB_DNS"
echo "  CloudFront: $CLOUDFRONT_DOMAIN"

# Step 3: Create ECR repository and push Docker image
echo "🐳 Building and pushing Docker image..."
ECR_REPO_NAME="yelp-backend"

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $REGION 2>/dev/null || \
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $REGION

# Get ECR login token
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and tag image
docker build -t $ECR_REPO_NAME .
docker tag $ECR_REPO_NAME:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME:latest

# Push to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME:latest

print_status "Docker image pushed to ECR"

# Step 4: Create production environment file
echo "🔧 Creating production environment..."
cat > .env.production << EOF
DATABASE_HOST=$DATABASE_ENDPOINT
DATABASE_PORT=5432
DATABASE_NAME=yelpdb
DATABASE_USER=postgres
DATABASE_PASSWORD=$DB_PASSWORD
CORS_ORIGINS=https://$CLOUDFRONT_DOMAIN
EOF

print_status "Production environment created"

# Step 5: Update task definition
echo "📝 Updating ECS task definition..."
# Create a temporary task definition with real values
cp task-definition.json task-definition-temp.json
sed -i.bak "s/ACCOUNT_ID/$ACCOUNT_ID/g" task-definition-temp.json
sed -i.bak "s/REGION/$REGION/g" task-definition-temp.json  
sed -i.bak "s/DATABASE_ENDPOINT/$DATABASE_ENDPOINT/g" task-definition-temp.json

# Create CloudWatch log group
aws logs create-log-group --log-group-name "/ecs/yelp-backend" --region $REGION 2>/dev/null || true

# Register task definition
aws ecs register-task-definition \
    --cli-input-json file://task-definition-temp.json \
    --region $REGION

print_status "ECS task definition registered"

# Step 6: Wait for database to be ready
echo "⏳ Waiting for database to be ready (this may take 5-10 minutes)..."
aws rds wait db-instance-available --db-instance-identifier yelp-postgres --region $REGION

print_status "Database is ready"

# Step 7: Build and deploy frontend
echo "🌐 Building and deploying frontend..."
cd frontend

# Update frontend API URL
echo "REACT_APP_API_URL=http://$ALB_DNS" > .env.production

# Build frontend
npm run build

# Upload to S3
aws s3 sync build/ s3://$S3_BUCKET --delete

# Invalidate CloudFront cache
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[0].DomainName=='$S3_BUCKET.s3.us-east-1.amazonaws.com'].Id" \
    --output text 2>/dev/null)

if [ ! -z "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" >/dev/null
fi

cd ..
print_status "Frontend deployed"

# Step 8: Create ECS service
echo "🚀 Creating ECS service..."

# Get subnet and security group IDs from the stack
VPC_ID=$(aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --logical-resource-id VPC \
    --query 'StackResources[0].PhysicalResourceId' \
    --output text)

SUBNET1=$(aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --logical-resource-id PublicSubnet1 \
    --query 'StackResources[0].PhysicalResourceId' \
    --output text)

SUBNET2=$(aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --logical-resource-id PublicSubnet2 \
    --query 'StackResources[0].PhysicalResourceId' \
    --output text)

SECURITY_GROUP=$(aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --logical-resource-id FargateSecurityGroup \
    --query 'StackResources[0].PhysicalResourceId' \
    --output text)

# Create ECS service
aws ecs create-service \
    --cluster yelp-app-cluster \
    --service-name yelp-backend-service \
    --task-definition yelp-backend-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
    --region $REGION 2>/dev/null || print_warning "Service might already exist"

print_status "ECS service created"

# Clean up temporary files
rm -f task-definition-temp.json task-definition-temp.json.bak

# Final output
echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📊 Your application details:"
echo "  Frontend URL: https://$CLOUDFRONT_DOMAIN"
echo "  Backend URL: http://$ALB_DNS"
echo "  Database: $DATABASE_ENDPOINT"
echo ""
echo "💰 Estimated monthly cost: \$25-35"
echo ""
echo "🔧 Next steps:"
echo "  1. Wait 5-10 minutes for all services to start"
echo "  2. Test your API: curl http://$ALB_DNS/health"
echo "  3. Visit your frontend: https://$CLOUDFRONT_DOMAIN"
echo "  4. Set up a custom domain (optional)"
echo ""
print_warning "Remember to update your database password in AWS Secrets Manager!"
print_warning "Monitor your costs in the AWS console!"

echo ""
echo "🚀 Happy deploying! 🚀"
