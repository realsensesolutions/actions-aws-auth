import json
import os
import boto3

cognito = boto3.client("cognito-idp")

GROUP_NAME = os.environ.get("GROUP_NAME", "")


def lambda_handler(event, context):
    """Add confirmed user to Cognito group."""
    print(json.dumps(event))

    if not GROUP_NAME:
        print("GROUP_NAME not configured, skipping group assignment")
        return event

    user_pool_id = event["userPoolId"]
    username = event["userName"]

    try:
        cognito.admin_add_user_to_group(
            UserPoolId=user_pool_id,
            Username=username,
            GroupName=GROUP_NAME,
        )
        print(f"Added user {username} to group {GROUP_NAME}")
    except cognito.exceptions.ResourceNotFoundException:
        print(f"Group {GROUP_NAME} not found in user pool {user_pool_id}")
    except Exception as e:
        print(f"Failed to add user to group: {e}")
        # Don't raise - user should still be confirmed even if group assignment fails

    return event
