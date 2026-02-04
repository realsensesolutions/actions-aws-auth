import json
import os
import boto3

cognito = boto3.client("cognito-idp")
GROUP_NAME = os.environ.get("GROUP_NAME", "")


def lambda_handler(event, context):
    """Add user to group on login if not already a member."""
    print(json.dumps(event))

    if not GROUP_NAME:
        print("GROUP_NAME not configured, skipping group assignment")
        return event

    user_pool_id = event["userPoolId"]
    username = event["userName"]

    try:
        # Check if user is already in the group
        response = cognito.admin_list_groups_for_user(
            UserPoolId=user_pool_id,
            Username=username
        )
        current_groups = [g["GroupName"] for g in response.get("Groups", [])]

        if GROUP_NAME in current_groups:
            print(f"User {username} already in group {GROUP_NAME}")
            return event

        # Add user to group
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

    return event
