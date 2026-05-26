import boto3
s3 = boto3.client('s3')

# Create S3 client
# s3 = boto3.client(
#     's3',
#     aws_access_key_id='YOUR_ACCESS_KEY',
#     aws_secret_access_key='YOUR_SECRET_KEY',
#     region_name='ap-south-1'
# )


# 1. Create Bucket
def create_bucket(bucket_name):
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={
            'LocationConstraint': 'ap-south-1'
        }
    )
    print("Bucket created successfully")


# 2. Upload File
def upload_file(file_name, bucket_name):
    s3.upload_file(
        file_name,
        bucket_name,
        file_name
    )
    print("File uploaded successfully")


# 3. Download File
def download_file(bucket_name, s3_file, local_file):
    s3.download_file(
        bucket_name,
        s3_file,
        local_file
    )
    print("File downloaded successfully")


# 4. Delete Bucket
def delete_bucket(bucket_name):
    s3.delete_bucket(Bucket=bucket_name)
    print("Bucket deleted successfully")


# Function Calls
create_bucket('avani-bucket-123')
upload_file('test.csv', 'avani-bucket-123')
download_file('avani-bucket-123', 'test.csv', 'downloaded.csv')
delete_bucket('avani-bucket-123')