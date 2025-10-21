#!/bin/bash

# Deployment script for AWS

set -e

echo "🚀 Deploying Yelp App to AWS..."

# Configuration
STACK_NAME="yelp-app-stack"
REGION="us-east-1"  # Change to your preferred region
DB_PASSWORD="YourSecurePassword123!"  # Change this!

# Build frontend
echo "📦 Building frontend..."
cd frontend
npm run build
cd ..

# Deploy CloudFormation stack
echo "☁️ Deploying infrastructure..."
aws cloudformation deploy \
  --template-file aws-infrastructure.yml \
  --stack-name $STACK_NAME \
  --parameter-overrides DBPassword=$DB_PASSWORD \
  --capabilities CAPABILITY_IAM \
  --region $REGION

# Get outputs
echo "📋 Getting stack outputs..."
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

CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
  --output text)

# Upload frontend to S3
echo "📤 Uploading frontend to S3..."
aws s3 sync frontend/build/ s3://$S3_BUCKET --delete

# Create production environment file
echo "🔧 Creating production environment..."
cat > .env.production << EOF
DATABASE_HOST=$DATABASE_ENDPOINT
DATABASE_PORT=5432
DATABASE_NAME=yelpdb
DATABASE_USER=postgres
DATABASE_PASSWORD=$DB_PASSWORD
CORS_ORIGINS=https://$CLOUDFRONT_DOMAIN
EOF

# Build and push Docker image to ECR (optional)
echo "🐳 Building Docker image..."
docker build -t yelp-backend .

echo "✅ Deployment complete!"
echo "📱 Frontend URL: https://$CLOUDFRONT_DOMAIN"
echo "🗄️ Database Endpoint: $DATABASE_ENDPOINT"
echo ""
echo "💡 Next steps:"
echo "1. Update your backend configuration with the database endpoint"
echo "2. Deploy your backend to Fargate (see deploy-fargate.sh)"
echo "3. Update frontend API URL to point to your load balancer"
