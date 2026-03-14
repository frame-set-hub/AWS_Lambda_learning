#!/bin/bash
# =============================================================
# Deploy Lambda Function via AWS CLI
# Prerequisites: AWS CLI configured (aws configure)
# =============================================================

set -euo pipefail

# Load .env file if exists
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading credentials from .env..."
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

FUNCTION_NAME="${LAMBDA_FUNCTION_NAME:-poc-hello-lambda}"
RUNTIME="python3.12"
HANDLER="lambda_function.lambda_handler"
ROLE_NAME="poc-lambda-execution-role"
REGION="${AWS_REGION:-ap-southeast-1}"
ZIP_FILE="lambda-function.zip"

echo "=== AWS Lambda POC Deployment ==="
echo "Region: $REGION"
echo ""

# Step 1: Create IAM Role (if not exists)
echo "[1/4] Creating IAM execution role..."
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}'

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)

if [ -z "$ROLE_ARN" ] || [ "$ROLE_ARN" = "None" ]; then
    ROLE_ARN=$(aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --query 'Role.Arn' --output text)

    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

    echo "  Role created: $ROLE_ARN"
    echo "  Waiting 10s for IAM propagation..."
    sleep 10
else
    echo "  Role exists: $ROLE_ARN"
fi

# Step 2: Package Lambda function
echo "[2/4] Packaging Lambda function..."
cd "$(dirname "$0")/lambda-function"
zip -j "../$ZIP_FILE" lambda_function.py
cd ..

# Step 3: Create or Update Lambda function
echo "[3/4] Deploying Lambda function..."
EXISTING=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null || true)

if [ -z "$EXISTING" ]; then
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime "$RUNTIME" \
        --handler "$HANDLER" \
        --role "$ROLE_ARN" \
        --zip-file "fileb://$ZIP_FILE" \
        --region "$REGION" \
        --timeout 30 \
        --memory-size 128 \
        --query 'FunctionArn' --output text
    echo "  Function created!"
else
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://$ZIP_FILE" \
        --region "$REGION" \
        --query 'FunctionArn' --output text
    echo "  Function updated!"
fi

# Step 4: Test invoke
echo "[4/4] Testing Lambda invocation..."
aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --payload '{"name": "Developer", "action": "greet"}' \
    --cli-binary-format raw-in-base64-out \
    /tmp/lambda-response.json

echo ""
echo "=== Lambda Response ==="
cat /tmp/lambda-response.json | python3 -m json.tool
echo ""

# Cleanup zip
rm -f "$ZIP_FILE"

echo "=== Deployment Complete ==="
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo ""
echo "Use this in your Spring Boot application.yml:"
echo "  aws.lambda.function-name: $FUNCTION_NAME"
echo "  aws.region: $REGION"
