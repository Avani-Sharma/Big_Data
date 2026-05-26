# using boto3 library you have to create bucket

import boto3
# S3 service connect
s3 = boto3.client('s3')
# Unique bucket name
bucket_name = 'avani-bucket-123'
# Bucket create
s3.create_bucket(
    Bucket=bucket_name,
    CreateBucketConfiguration={
        'LocationConstraint': 'ap-south-1'
    }
)
print("Bucket Created Successfully")


# to check the bucket
import boto3
s3 = boto3.client('s3')
response = s3.list_buckets()
print(response)