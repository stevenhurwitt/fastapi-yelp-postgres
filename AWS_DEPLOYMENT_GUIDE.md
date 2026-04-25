# 🚀 AWS Deployment Guide - Cheapest Setup ($15-25/month)

This guide will deploy your full-stack Yelp application to AWS using the most cost-effective approach.

## 📋 Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret, Region (us-east-1 recommended), and output format (json)
   ```

2. **Docker installed**
   ```bash
   docker --version
   ```

3. **AWS Account with these services enabled:**
   - EC2 (for Fargate)
   - RDS (for PostgreSQL)
   - S3 (for frontend hosting)
   - CloudFront (for CDN)
   - ECR (for Docker images)

## 🎯 Cost Breakdown

| Service | Monthly Cost |
|---------|-------------|
| RDS PostgreSQL (db.t3.micro) | ~$13-15 |
| Fargate (0.25 vCPU, 0.5GB) | ~$7-10 |
| S3 + CloudFront | ~$1-3 |
| Application Load Balancer | ~$16 |
| **Total** | **~$37-44/month** |

### 💡 Cost Optimization Options:
- **Remove ALB**: Use direct Fargate access (-$16/month) → **~$21-28/month**
- **Use Lambda instead of Fargate**: (-$7-10/month) → **~$14-18/month** (with cold starts)

## 🔧 Step-by-Step Deployment

### Step 1: Prepare Your Environment

```bash
# Clone your repository (if not already local)
cd fastapi-yelp-postgres

# Set deployment variables
export AWS_REGION="us-east-1"
export STACK_NAME="yelp-app"
export DB_PASSWORD="YourSecurePassword123!"  # Change this!
```

### Step 2: Deploy Infrastructure

```bash
# Deploy the CloudFormation stack
aws cloudformation deploy \
  --template-file aws-infrastructure.yml \
  --stack-name $STACK_NAME \
  --parameter-overrides DBPassword=$DB_PASSWORD \
  --capabilities CAPABILITY_IAM \
  --region $AWS_REGION
```

This creates:
- ✅ VPC with public/private subnets
- ✅ RDS PostgreSQL database
- ✅ S3 bucket for frontend
- ✅ CloudFront distribution
- ✅ Application Load Balancer
- ✅ ECS Cluster for Fargate

### Step 3: Get Infrastructure Details

```bash
# Get stack outputs
DATABASE_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
  --output text)

S3_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
  --output text)

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
  --output text)

echo "Database: $DATABASE_ENDPOINT"
echo "S3 Bucket: $S3_BUCKET"  
echo "Load Balancer: $ALB_DNS"
echo "CloudFront: $CLOUDFRONT_DOMAIN"
```

### Step 4: Migrate Your Database

```bash
# Update your .env file with production database
cat > .env.production << EOF
DATABASE_HOST=$DATABASE_ENDPOINT
DATABASE_PORT=5432
DATABASE_NAME=yelpdb
DATABASE_USER=postgres
DATABASE_PASSWORD=$DB_PASSWORD
CORS_ORIGINS=https://$CLOUDFRONT_DOMAIN
EOF

# If you need to migrate your existing data:
# 1. Export from your local PostgreSQL
pg_dump -h 192.168.0.123 -p 5433 -U your_user your_db > yelp_data.sql

# 2. Import to AWS RDS (wait 5-10 minutes for RDS to be ready)
psql -h $DATABASE_ENDPOINT -p 5432 -U postgres -d yelpdb < yelp_data.sql
```

### Step 5: Build and Deploy Backend

```bash
# Create ECR repository and push Docker image
./deploy-ecr.sh

# Get your AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Update task definition with real values
sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" task-definition.json
sed -i "s/REGION/$AWS_REGION/g" task-definition.json  
sed -i "s/DATABASE_ENDPOINT/$DATABASE_ENDPOINT/g" task-definition.json

# Create CloudWatch log group
aws logs create-log-group --log-group-name "/ecs/yelp-backend" --region $AWS_REGION

# Register task definition
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region $AWS_REGION

# Create ECS service (this will take a few minutes)
aws ecs create-service \
  --cluster yelp-app-cluster \
  --service-name yelp-backend-service \
  --task-definition yelp-backend-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --region $AWS_REGION
```

### Step 6: Deploy Frontend

```bash
# Update frontend API URL
echo "REACT_APP_API_URL=http://$ALB_DNS" > frontend/.env.production

# Build frontend
cd frontend
npm run build

# Upload to S3
aws s3 sync build/ s3://$S3_BUCKET --delete

# Invalidate CloudFront cache
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Aliases.Items[0]=='$CLOUDFRONT_DOMAIN'].Id" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

cd ..
```

### Step 7: Test Your Deployment

```bash
# Test backend health
curl http://$ALB_DNS/health

# Test API endpoint  
curl http://$ALB_DNS/api/v1/businesses/?limit=5

# Your frontend will be available at:
echo "🎉 Your app is live at: https://$CLOUDFRONT_DOMAIN"
```

## 🔧 Post-Deployment Configuration

### Set up Custom Domain (Optional)

1. **Buy a domain** in Route53 or use existing domain
2. **Create SSL certificate** in AWS Certificate Manager
3. **Update CloudFront** to use your domain and SSL certificate
4. **Update API URL** to use your custom domain

### Monitor Costs

```bash
# Set up billing alerts
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "yelp-app-budget",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

## 🚨 Troubleshooting

### Common Issues:

1. **Database connection fails**
   - Check security groups allow port 5432
   - Verify database endpoint is correct
   - Ensure database is in "available" state

2. **Frontend shows API errors**
   - Verify CORS settings in FastAPI
   - Check ALB health checks are passing
   - Confirm API URL in frontend .env

3. **High costs**
   - Stop/start RDS during development
   - Use CloudWatch to monitor usage
   - Consider spot instances for development

## 💰 Ultra-Budget Alternative (Lambda - $8-15/month)

If you want to go even cheaper, replace Fargate with Lambda:

```bash
# Install Serverless Framework
npm install -g serverless

# Create serverless.yml (I can provide this configuration)
# Deploy with: serverless deploy
```

This setup eliminates the ALB ($16/month) and Fargate costs (~$10/month), bringing total cost to ~$8-15/month.

## 🎯 Next Steps

1. **Set up CI/CD** with GitHub Actions
2. **Add monitoring** with CloudWatch/X-Ray  
3. **Implement caching** with ElastiCache
4. **Add search** with OpenSearch/Elasticsearch
5. **Scale** with auto-scaling groups

Your application should now be live and accessible! 🚀
