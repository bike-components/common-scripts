#!/usr/bin/env bash




# Default values
GHCR_TOKEN=""
AWS_REGION=""
SOURCE_IMAGE=""
TARGET_REPO=""
TARGET_TAG=""

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "  --ghcr-token    GitHub Container Registry personal access token"
    echo "  --aws-region    AWS region for ECR"
    echo "  --source-image  Source image from GHCR (format: ghcr.io/owner/repo:tag)"
    echo "  --target-repo   Target ECR repository name"
    echo "  --target-tag    Target image tag (optional, defaults to source tag)"
    exit 1
}

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ghcr-token)
            GHCR_TOKEN="$2"
            shift 2
            ;;
        --aws-region)
            AWS_REGION="$2"
            shift 2
            ;;
        --source-image)
            SOURCE_IMAGE="$2"
            shift 2
            ;;
        --target-repo)
            TARGET_REPO="$2"
            shift 2
            ;;
        --target-tag)
            TARGET_TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$GHCR_TOKEN" ]] || [[ -z "$AWS_REGION" ]] || [[ -z "$SOURCE_IMAGE" ]] || [[ -z "$TARGET_REPO" ]]; then
    echo "Error: Missing required parameters"
    usage
fi

# If target tag is not specified, extract it from source image
if [[ -z "$TARGET_TAG" ]]; then
    TARGET_TAG=$(echo $SOURCE_IMAGE | cut -d ':' -f2)
    if [[ -z "$TARGET_TAG" ]]; then
        TARGET_TAG="latest"
    fi
fi

# Login to GHCR
echo "Logging in to GitHub Container Registry..."
echo $GHCR_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

if [ $? -ne 0 ]; then
    echo "Failed to login to GHCR"
    exit 1
fi


# Login to AWS ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo "Failed to login to ECR"
    exit 1
fi


# Pull the image from GHCR
echo "Pulling image from GHCR..."
docker pull $SOURCE_IMAGE

if [ $? -ne 0 ]; then
    echo "Failed to pull image from GHCR"
    exit 1
fi


# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"


# Tag the image for ECR
echo "Tagging image for ECR..."
docker tag $SOURCE_IMAGE $ECR_REPO_URI/$TARGET_REPO:$TARGET_TAG


if [ $? -ne 0 ]; then
    echo "Failed to tag image"
    exit 1
fi

# Push to ECR
echo "Pushing image to ECR..."
docker push $ECR_REPO_URI/$TARGET_REPO:$TARGET_TAG

if [ $? -ne 0 ]; then
    echo "Failed to push image to ECR"
    exit 1
fi

echo "Successfully transferred image from GHCR to ECR"
