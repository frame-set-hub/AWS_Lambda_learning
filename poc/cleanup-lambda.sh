#!/bin/bash
# =============================================================
# Cleanup Lambda POC Resources
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

FUNCTION_NAME="${LAMBDA_FUNCTION_NAME:-poc-hello-lambda}"
ROLE_NAME="poc-lambda-execution-role"
REGION="${AWS_REGION:-ap-southeast-1}"

echo "=== Cleaning up Lambda POC Resources ==="

echo "[1/3] Deleting Lambda function..."
aws lambda delete-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null && echo "  Deleted." || echo "  Not found, skipping."

echo "[2/3] Detaching role policy..."
aws iam detach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null && echo "  Detached." || echo "  Not found, skipping."

echo "[3/3] Deleting IAM role..."
aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted." || echo "  Not found, skipping."

echo ""
echo "=== Cleanup Complete ==="
