import requests
import json

def post_json_request(url, payload, additional_headers=None):
    # Set default headers
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }

    # Merge with additional headers if provided
    if additional_headers:
        headers.update(additional_headers)

    # Perform the POST request
    response = requests.post(url, data=json.dumps(payload), headers=headers)

    # Return the response
    return response