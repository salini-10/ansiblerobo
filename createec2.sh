#!/bin/bash

if [ -z "$1" ]; then
  echo -e "\e[31minput machine name is needed\e[0m"
  exit 1
  fi
  COMPONENT=$1
  ZONE_ID="Z0978146KR3LELI7PGRT"
  create_ec2() {

    PRIVATE_IP=$(aws ec2 run-instances \
    --image-id ${AMI_ID} \
     --instance-type t3.small \
      --tag-specifications "ResourceType=instance,Tags=[{Key=name,Value=${COMPONENT}}]" \
       --instance-market-options "MarketType=spot,SpotOptions={SpotInstanceType=persistent,InstanceInterruptionBehavior=stop}" \
        --security-group-ids=${SG_ID} \
         | jq '.Instances[].PrivateIpAddress' | sed -e 's/"//g')
  sed -e "s/IPADDRESS/${PRIVATE_IP}/" -e "s/COMPONENT/${COMPONENT}/" route53.json >/tmp/record.json
  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/record.json | jq
  }

AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=Centos-7-DevOps-Practice" | jq '.Images[].ImageId' | sed -e 's/"//g')
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=allow-all-from-public | jq '.SecurityGroups[].GroupId' | sed -e 's/"//g')


  if [ "$1" == "all" ]; then
    for component in catalogue cart frontend shipping payment rabbitmq mysql mongodb redis user ; do
         COMPONENT=$component
         create_ec2
    done
  else
  create_ec2
    fi


