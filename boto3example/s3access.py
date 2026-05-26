# to access S3

import boto3

# print(dir(boto3))
var = boto3.client(
    's3'
#     aws_access_key_id = 'access key' ,
#     aws_secret_access_key = 'secret access key',
#     region_name = 'region'
)

print(var)

print(var.list_buckets() )