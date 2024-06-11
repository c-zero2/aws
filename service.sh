#!/bin/bash

# Helper function to write CSV headers
function write_csv_header {
    local file=$1
    local header=$2
    echo "$header" > "$file"
}

# Helper function to append data to CSV
function add_to_csv {
    local file=$1
    local data=$2
    echo "$data" >> "$file"
}

# File paths
vpc_file="vpc_details.csv"
subnet_file="subnet_details.csv"
sg_file="security_group_details.csv"
route_table_file="route_table_details.csv"
network_acl_file="network_acl_details.csv"
ec2_file="ec2_details.csv"
rds_file="rds_details.csv"
elb_file="elb_details.csv"
elbv2_file="elbv2_details.csv"

# Write CSV headers
write_csv_header "$vpc_file" "VpcId,State,CidrBlock,IsDefault,Tags"
write_csv_header "$subnet_file" "SubnetId,VpcId,State,CidrBlock,AvailabilityZone,Tags"
write_csv_header "$sg_file" "GroupId,VpcId,GroupName,Description,Tags"
write_csv_header "$route_table_file" "RouteTableId,VpcId,Associations,Routes,Tags"
write_csv_header "$network_acl_file" "NetworkAclId,VpcId,Entries,Associations,Tags"
write_csv_header "$ec2_file" "InstanceId,VpcId,InstanceType,State,PublicIpAddress,PrivateIpAddress,KeyName,Tags"
write_csv_header "$rds_file" "DBInstanceIdentifier,VpcId,DBInstanceClass,Engine,DBInstanceStatus,Endpoint,Tags"
write_csv_header "$elb_file" "LoadBalancerName,VpcId,DNSName,Instances,Tags"
write_csv_header "$elbv2_file" "LoadBalancerArn,VpcId,DNSName,Type,State,Tags"

# Fetch VPCs
vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,CidrBlock,IsDefault,Tags]' --output json)
for vpc in $(echo "$vpcs" | jq -c '.[]'); do
    vpc_id=$(echo "$vpc" | jq -r '.[0]')
    state=$(echo "$vpc" | jq -r '.[1]')
    cidr_block=$(echo "$vpc" | jq -r '.[2]')
    is_default=$(echo "$vpc" | jq -r '.[3]')
    tags=$(echo "$vpc" | jq -r '.[4] | to_entries | map("\(.key)=\(.value)") | join(",")')
    add_to_csv "$vpc_file" "$vpc_id,$state,$cidr_block,$is_default,\"$tags\""

    # Subnets
    subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].[SubnetId,VpcId,State,CidrBlock,AvailabilityZone,Tags]' --output json)
    for subnet in $(echo "$subnets" | jq -c '.[]'); do
        subnet_id=$(echo "$subnet" | jq -r '.[0]')
        subnet_vpc_id=$(echo "$subnet" | jq -r '.[1]')
        subnet_state=$(echo "$subnet" | jq -r '.[2]')
        subnet_cidr_block=$(echo "$subnet" | jq -r '.[3]')
        subnet_az=$(echo "$subnet" | jq -r '.[4]')
        subnet_tags=$(echo "$subnet" | jq -r '.[5] | to_entries | map("\(.key)=\(.value)") | join(",")')
        add_to_csv "$subnet_file" "$subnet_id,$subnet_vpc_id,$subnet_state,$subnet_cidr_block,$subnet_az,\"$subnet_tags\""
    done

    # Security Groups
    security_groups=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[*].[GroupId,VpcId,GroupName,Description,Tags]' --output json)
    for sg in $(echo "$security_groups" | jq -c '.[]'); do
        sg_id=$(echo "$sg" | jq -r '.[0]')
        sg_vpc_id=$(echo "$sg" | jq -r '.[1]')
        sg_name=$(echo "$sg" | jq -r '.[2]')
        sg_desc=$(echo "$sg" | jq -r '.[3]')
        sg_tags=$(echo "$sg" | jq -r '.[4] | to_entries | map("\(.key)=\(.value)") | join(",")')
        add_to_csv "$sg_file" "$sg_id,$sg_vpc_id,$sg_name,$sg_desc,\"$sg_tags\""
    done

    # Route Tables
    route_tables=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[*].[RouteTableId,VpcId,Associations,Routes,Tags]' --output json)
    for rt in $(echo "$route_tables" | jq -c '.[]'); do
        rt_id=$(echo "$rt" | jq -r '.[0]')
        rt_vpc_id=$(echo "$rt" | jq -r '.[1]')
        rt_associations=$(echo "$rt" | jq -r '.[2] | map("\(.RouteTableAssociationId)=\(.State)") | join(",")')
        rt_routes=$(echo "$rt" | jq -r '.[3] | map("\(.DestinationCidrBlock)=\(.State)") | join(",")')
        rt_tags=$(echo "$rt" | jq -r '.[4] | to_entries | map("\(.key)=\(.value)") | join(",")')
        add_to_csv "$route_table_file" "$rt_id,$rt_vpc_id,\"$rt_associations\",\"$rt_routes\",\"$rt_tags\""
    done

    # Network ACLs
    network_acls=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkAcls[*].[NetworkAclId,VpcId,Entries,Associations,Tags]' --output json)
    for acl in $(echo "$network_acls" | jq -c '.[]'); do
        acl_id=$(echo "$acl" | jq -r '.[0]')
        acl_vpc_id=$(echo "$acl" | jq -r '.[1]')
        acl_entries=$(echo "$acl" | jq -r '.[2] | map("\(.RuleNumber)=\(.RuleAction)") | join(",")')
        acl_associations=$(echo "$acl" | jq -r '.[3] | map("\(.NetworkAclAssociationId)=\(.SubnetId)") | join(",")')
        acl_tags=$(echo "$acl" | jq -r '.[4] | to_entries | map("\(.key)=\(.value)") | join(",")')
        add_to_csv "$network_acl_file" "$acl_id,$acl_vpc_id,\"$acl_entries\",\"$acl_associations\",\"$acl_tags\""
    done

    # EC2 Instances
    instances=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpc_id" --query 'Reservations[*].Instances[*].[InstanceId,VpcId,InstanceType,State.Name,PublicIpAddress,PrivateIpAddress,KeyName,Tags]' --output json)
    for instance in $(echo "$instances" | jq -c '.[] | .[]'); do
        instance_id=$(echo "$instance" | jq -r '.[0]')
        instance_vpc_id=$(echo "$instance" | jq -r '.[1]')
        instance_type=$(echo "$instance" | jq -r '.[2]')
        instance_state=$(echo "$instance" | jq -r '.[3]')
        instance_public_ip=$(echo "$instance" | jq -r '.[4]')
        instance_private_ip=$(echo "$instance" | jq -r '.[5]')
        instance_key_name=$(echo "$instance" | jq -r '.[6]')
        instance_tags=$(echo "$instance" | jq -r '.[7] | to_entries | map("\(.key)=\(.value)") | join(",")')
        add_to_csv "$ec2_file" "$instance_id,$instance_vpc_id,$instance_type,$instance_state,$instance_public_ip,$instance_private_ip,$instance_key_name,\"$instance_tags\""
    done

    # RDS Instances
    rds_instances=$(aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,VpcId,DBInstanceClass,Engine,DBInstanceStatus,Endpoint.Address,Tags]' --output json)
    for rds in $(echo "$rds_instances" | jq -c '.[]'); do
        rds_id=$(echo "$rds" | jq -r '.[0]')
        rds_vpc_id=$(echo "$rds" | jq -r '.[1]')
        rds_class=$(echo "$rds" | jq -r '.[2]')
        rds_engine=$(echo "$rds" | jq -r '.[3]')
        rds_status=$(echo "$rds" | jq -r '.[4]')
        rds_endpoint=$(echo "$rds" | jq -r '.[5]')
        rds_tags=$(echo "$rds" | jq -r '.[6] | to_entries | map("\(.key)=\(.value)") | join(",")')
        if [ "$rds_vpc_id" == "$vpc_id" ]; then
            add_to_csv "$rds_file" "$rds_id,$rds_vpc_id,$rds_class,$rds_engine,$rds_status,$rds_endpoint,\"$rds_tags\""
        fi
    done

    # Load Balancers (ELB)
    elbs=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].[LoadBalancerName,VPCId,DNSName,Instances[*].InstanceId,Tags]' --output json)
    for elb in $(echo "$elbs" | jq -c '.[]'); do
        elb_name=$(echo "$elb" | jq -r '.[0]')
        elb_vpc_id=$(echo "$elb" | jq -r '.[1]')
        elb_dns=$(echo "$elb" | jq -r '.[2]')
        elb_instances=$(echo "$elb" | jq -r '.[3] | join(",")')
        elb_tags=$(echo "$elb" | jq -r '.[4] | to_entries | map("\(.key)=\(.value)") | join(",")')
        if [ "$elb_vpc_id" == "$vpc_id" ]; then
            add_to_csv "$elb_file" "$elb_name,$elb_vpc_id,$elb_dns,\"$elb_instances\",\"$elb_tags\""
        fi
    done

    # Load Balancers (ELBv2)
    elbv2s=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerArn,VpcId,DNSName,Type,State.Code,Tags]' --output json)
    for elbv2 in $(echo "$elbv2s" | jq -c '.[]'); do
        elbv2_arn=$(echo "$elbv2" | jq -r '.[0]')
        elbv2_vpc_id=$(echo "$elbv2" | jq -r '.[1]')
        elbv2_dns=$(echo "$elbv2" | jq -r '.[2]')
        elbv2_type=$(echo "$elbv2" | jq -r '.[3]')
        elbv2_state=$(echo "$elbv2" | jq -r '.[4]')
        elbv2_tags=$(echo "$elbv2" | jq -r '.[5] | to_entries | map("\(.key)=\(.value)") | join(",")')
        if [ "$elbv2_vpc_id" == "$vpc_id" ]; then
            add_to_csv "$elbv2_file" "$elbv2_arn,$elbv2_vpc_id,$elbv2_dns,$elbv2_type,$elbv2_state,\"$elbv2_tags\""
        fi
    done
done

echo "Export complete. Files: vpc_details.csv, subnet_details.csv, security_group_details.csv, route_table_details.csv, network_acl_details.csv, ec2_details.csv, rds_details.csv, elb_details.csv, elbv2_details.csv"
