from botocore.exceptions import ClientError
import boto3, os, uuid, hashlib, logging, json,base64

dynamodb_endpoint   = os.environ['DYNAMODB_ENDPOINT']
region              = os.environ['REGION']
kms_endpoint        = os.environ['KMS_ENDPOINT']
kms_key_id          = os.environ['KMS_KEY_ID']

def encrypt(secret, key_id):

    client = boto3.client(
        'kms',
        endpoint_url=kms_endpoint,
        region_name=region
    )

    ciphertext = client.encrypt(
        KeyId=key_id,
        Plaintext=bytes(secret, 'utf-8'),
    )

    return base64.b64encode(ciphertext['CiphertextBlob']).decode()

def get_token(hash, dynamodb=None):

    table = dynamodb.Table('tokens')

    try:
        response = table.get_item(Key={'hash': hash})
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        return response.get('Item')

def put_token(string, hash, dynamodb=None):

    table = dynamodb.Table('tokens')

    item = {
        'hash'      : hash,
        'ciphertext': encrypt(string, kms_key_id),
        'token'     : str(uuid.uuid4()),
    }

    response = table.put_item(
       Item = item
    )

    # remove the ciphertext because we don't need to return it
    item.pop('ciphertext')

    return item

def handler(event, context):

    event_body = json.loads(event['body'])
    string = event_body['string']

    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=dynamodb_endpoint,
        region_name=region
    )

    hash = (
        hashlib.
        sha256(
            string.encode()
        ).
        hexdigest()
    )

    token = get_token(hash, dynamodb) or put_token(string, hash, dynamodb)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(token)
    }
