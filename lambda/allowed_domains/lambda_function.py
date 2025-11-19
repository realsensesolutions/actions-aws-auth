import json
import os

ALLOWED_DOMAINS = os.environ["ALLOWED_DOMAINS"].lower().replace(" ", "").split(",")


def lambda_handler(event, context):
    print(json.dumps(event))

    # It sets the user pool autoConfirmUser flag after validating the email domain
    event["response"]["autoConfirmUser"] = False

    # Split the email address so we can compare domains
    address = event["request"]["userAttributes"]["email"].split("@")

    if address[1] not in ALLOWED_DOMAINS:
        raise Exception("email:{} is not a valid domain {}".format(address[1], ALLOWED_DOMAINS))

    # Return to Amazon Cognito
    return event

