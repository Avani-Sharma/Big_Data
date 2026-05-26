# create bucket boto3 in case it is not available in S3

import boto3
from botocore.exceptions import ClientError
# S3 client
s3 = boto3.client('s3')
# Bucket name
bucket_name = 'avani-bucket-2026-786'

try:
    # Check bucket exists or not
    s3.head_bucket(Bucket=bucket_name)
    print("Bucket already exists")
    
except ClientError:
    # Create bucket if not exists
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={
            'LocationConstraint': 'ap-south-1'
        }
    )
    print("Bucket created successfully")