import boto3
import json
import logging
import os

from base64 import b64decode
from urlparse import parse_qs


logger = logging.getLogger()
logger.setLevel(logging.INFO)

QUEUE_NAME = "https://sqs.us-east-1.amazonaws.com/613751802309/gamebot_staging.fifo"
SQS = boto3.client("sqs")

def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else json.dumps(res) if res else None,
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def record(params):
    """The lambda handler"""

    if params.get("ssl_check", ["0"])[0] == "1":
        logger.debug("Got ssl_check")
        return
    
    logger.debug("Processing event %s", params)
    if 'text' in params:
        command_text = params['text'][0]
    else:
        command_text = ''
    data = {
        "channel": params["channel_id"][0],
        "text": command_text,
        "responseUrl": params["response_url"][0],
        "triggerId": params["trigger_id"][0],
        "command": params["command"][0]        
    }
    wrapper = {
        "type": "command",
        "team": params["team_id"][0],
        "user": params["user_id"][0],
        "data": data
    }
    try:
        logger.debug("Enqueuing %s", wrapper)
        resp = SQS.send_message(QueueUrl=QUEUE_NAME, MessageBody=json.dumps(wrapper), MessageGroupId="g")
        logger.debug("Send result: %s", resp)
    except Exception as e:
        raise Exception("Could not record link! %s" % e)

def lambda_handler(event, context):
    params = parse_qs(event['body'])
    #token = params['token'][0]
    #if token != expected_token:
    #    logger.error("Request token (%s) does not match expected", token)
    #    return respond(Exception('Invalid request token'))

    record(params)

    return respond(None, None)
