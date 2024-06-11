#!/bin/bash

# CSV File Header
echo "InstanceId,InstanceType,State,PublicIpAddress,PrivateIpAddress,KeyName,Tags" > ec2_details.csv

# Fetch all EC2 instances details
instances=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress,PrivateIpAddress,KeyName,Tags]' --output text)

# Loop through each instance and format it into CSV
while read -r instance; do
    instance_id=$(echo $instance | awk '{print $1}')
    instance_type=$(echo $instance | awk '{print $2}')
    state=$(echo $instance | awk '{print $3}')
    public_ip=$(echo $instance | awk '{print $4}')
    private_ip=$(echo $instance | awk '{print $5}')
    key_name=$(echo $instance | awk '{print $6}')
    
    # Get tags
    tags=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" --query 'Tags[*].[Key,Value]' --output text | tr '\n' ',' | sed 's/,$//')
    
    # Add to CSV
    echo "$instance_id,$instance_type,$state,$public_ip,$private_ip,$key_name,$tags" >> ec2_details.csv
done <<< "$instances"

echo "Export complete. File: ec2_details.csv"
