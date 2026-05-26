from kaggle.api.kaggle_api_extended import KaggleApi
import boto3
s3 = boto3.client('s3')

# kaggle link
def load_kaggle(link):
    api = KaggleApi()
    api.authenticate()

    api.dataset_download_files(
        'mehmettahiraslan/customer-shopping-dataset',
        path='kaggle_data',
        unzip=True
    )

    print("dataset download")


# create bucket
def create_bucket(bucket_name):
    create_buc= s3.create_bucket( 
        Bucket = bucket_name,
        CreateBucketConfiguration={
            'LocationConstraint' : 'ap-south-1'
        }
    )
    print("bucket created")
    print(create_buc)



# upload data on s3 bucket 
def upload_data(file_name, bucket_name, object_name):
    
    s3.upload_file(file_name, bucket_name, object_name)
    print("uploaded")


# call functions
load_kaggle('mehmettahiraslan/customer-shopping-dataset')
create_bucket('avani-project')
upload_data(
    'kaggle_data/customer_shopping_data.csv',
    'avani-project',
    'customer_shopping_data.csv'
)