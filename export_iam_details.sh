#!/bin/bash

# CSV File Header
echo "UserName,Groups,AttachedUserPolicies,InlineUserPolicies,GroupName,AttachedGroupPolicies,InlineGroupPolicies,RoleName,AttachedRolePolicies,InlineRolePolicies" > iam_details.csv

# List all IAM users
users=$(aws iam list-users --query 'Users[*].UserName' --output text)

# Loop through each user to get their group memberships, attached policies, and inline policies
for user in $users; do
    groups=$(aws iam list-groups-for-user --user-name $user --query 'Groups[*].GroupName' --output text | tr '\t' ',')
    attached_user_policies=$(aws iam list-attached-user-policies --user-name $user --query 'AttachedPolicies[*].PolicyName' --output text | tr '\t' ',')
    inline_user_policies=$(aws iam list-user-policies --user-name $user --query 'PolicyNames[*]' --output text | tr '\t' ',')
    
    echo "$user,$groups,$attached_user_policies,$inline_user_policies" >> iam_details.csv
done

# List all groups and their policies
groups=$(aws iam list-groups --query 'Groups[*].GroupName' --output text)

for group in $groups; do
    attached_group_policies=$(aws iam list-attached-group-policies --group-name $group --query 'AttachedPolicies[*].PolicyName' --output text | tr '\t' ',')
    inline_group_policies=$(aws iam list-group-policies --group-name $group --query 'PolicyNames[*]' --output text | tr '\t' ',')
    
    echo ",,$group,$attached_group_policies,$inline_group_policies" >> iam_details.csv
done

# List all roles and their policies
roles=$(aws iam list-roles --query 'Roles[*].RoleName' --output text)

for role in $roles; do
    attached_role_policies=$(aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[*].PolicyName' --output text | tr '\t' ',')
    inline_role_policies=$(aws iam list-role-policies --role-name $role --query 'PolicyNames[*]' --output text | tr '\t' ',')
    
    echo ",,,,,$role,$attached_role_policies,$inline_role_policies" >> iam_details.csv
done

echo "Export complete. File: iam_details.csv"
