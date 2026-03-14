import json
from datetime import datetime


def lambda_handler(event, context):
    """Simple Lambda function for POC testing."""
    name = event.get("name", "World")
    action = event.get("action", "greet")

    if action == "greet":
        message = f"Hello, {name}! Welcome to AWS Lambda."
    elif action == "time":
        message = f"Hi {name}, current UTC time is {datetime.utcnow().isoformat()}"
    elif action == "calculate":
        a = event.get("a", 0)
        b = event.get("b", 0)
        message = f"{name}, the sum of {a} + {b} = {a + b}"
    else:
        message = f"Unknown action: {action}"

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": message,
            "requestId": context.aws_request_id,
            "functionName": context.function_name,
        }),
    }
