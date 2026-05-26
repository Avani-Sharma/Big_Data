# using python you have to launch EC2 instance

import boto3

ec2 = boto3.resource('ec2')

instance = ec2.create_instances(
    ImageId='ami-0f58b397bc5c1f2e8',
    MinCount=1,
    MaxCount=1,
    InstanceType='t2.micro',
    KeyName='avanifile'
)

print("EC2 launched successfully")
print(instance[0].id)