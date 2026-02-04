import json
import os
import boto3

cognito = boto3.client("cognito-idp")
GROUP_NAME = os.environ.get("GROUP_NAME", "")


def lambda_handler(event, context):
    """Add user to group and inject group claim into token."""
    print(json.dumps(event))

    if not GROUP_NAME:
        print("GROUP_NAME not configured, skipping")
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

        if GROUP_NAME not in current_groups:
            # Add user to group
            cognito.admin_add_user_to_group(
                UserPoolId=user_pool_id,
                Username=username,
                GroupName=GROUP_NAME,
            )
            print(f"Added user {username} to group {GROUP_NAME}")

        # Get the group's IAM role ARN
        group_role_arn = None
        try:
            group_response = cognito.get_group(
                GroupName=GROUP_NAME,
                UserPoolId=user_pool_id
            )
            group_role_arn = group_response.get("Group", {}).get("RoleArn")
        except Exception as e:
            print(f"Could not get group role ARN: {e}")

        # Inject group into the token
        group_override = {
            "groupsToOverride": [GROUP_NAME]
        }
        
        if group_role_arn:
            group_override["iamRolesToOverride"] = [group_role_arn]
            group_override["preferredRole"] = group_role_arn

        event["response"]["claimsOverrideDetails"] = {
            "groupOverrideDetails": group_override
        }

    except Exception as e:
        print(f"Error: {e}")

    return event
