#!/usr/bin/env python3

from http import HTTPStatus
import json
from os import environ, path
import sys
from typing import Dict, Optional


KEY_ENV_VAR = "X_WEBHOOK_TUTORIAL_KEY"


def read_from_local_file(path: str) -> str:
    """
    For use when testing this script locally. This function will not be
    used when this script runs in Lambda behind API Gateway.

    Reads the content of the file given by `path`.
    """
    if path == "-":
        path = "/dev/stdin"

    with open(path, "r") as f:
        buf = f.read()

    return buf


def api_gw_response(status_code: int, error_code: Optional[str], error_message: Optional[str], response: Dict):
    if error_code is not None:
        error = {
            "code": error_code,
            "message": error_message,
        }
    else:
        error = None

    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": error, "response": response}),
    }


def authorized(event: Dict) -> bool:
    request_key = event.get("headers", {}).get("x-webhook-tutorial-key", None)

    try:
        if request_key == environ[KEY_ENV_VAR]:
            return True
    except KeyError:
        pass

    return False


def lambda_handler(event: Dict, context: object):
    if not authorized(event):
        return api_gw_response(HTTPStatus.UNAUTHORIZED, "unauthorized", "invalid key", {})

    body = event.get("body", None)
    bad_body_msg = "expected posted body to be valid JSON"
    if body is None:
        return api_gw_response(HTTPStatus.BAD_REQUEST, "null_body", bad_body_msg, {})

    try:
        posted_json = json.loads(body)
    except json.JSONDecodeError:
        return api_gw_response(HTTPStatus.BAD_REQUEST, "invalid_json", bad_body_msg, {})

    alert_types = set()
    try:
        for o in posted_json["response"]:
            alert_types.add(o["details"]["type"])

    except (IndexError, KeyError):
        return api_gw_response(
            HTTPStatus.BAD_REQUEST, "invalid_object", "posted JSON object did not contain expected elements", {}
        )

    if len(alert_types) == 0:
        response_msg = "posted data contained no alerts"
    else:
        response_msg = f"posted data contained alert types: {', '.join(alert_types)}"

    return api_gw_response(HTTPStatus.OK, None, None, {"message": response_msg})


if __name__ == "__main__":
    try:
        data_path = sys.argv[1]
    except IndexError:
        data_path = "/dev/stdin"

    body = read_from_local_file(data_path)
    tutorial_key_path = path.join(path.dirname(__file__), "terraform", "outputs", "x-webhook-tutorial-key.txt")
    tutorial_key = read_from_local_file(tutorial_key_path).strip()

    # Set the environment variable holding the API key for the webhook
    # so that the authorization check that occurs locally is the same
    # one that occurs when this function is published to Lambda.
    #
    # Users can set the environment variable to a bogus value themselves
    # in order to test an authentication failure.
    if environ.get(KEY_ENV_VAR, None) is None:
        environ[KEY_ENV_VAR] = tutorial_key

    mock_event = {
        "headers": {"x-webhook-tutorial-key": tutorial_key},
        "body": body,
    }
    response = lambda_handler(mock_event, None)
    print(response)
