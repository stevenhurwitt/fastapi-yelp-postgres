# ECS Task Definition and Fargate Deployment

# Build and push to ECR
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_NAME="yelp-backend"
IMAGE_TAG="latest"

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $REGION || \
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $REGION

# Get ECR login token
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and tag image
docker build -t $ECR_REPO_NAME .
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

# Push to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

echo "Image pushed to: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"
