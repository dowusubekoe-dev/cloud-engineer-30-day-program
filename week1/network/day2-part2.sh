#!/usr/bin/env bash
# Day 2 part 2: routing, NAT, security groups, S3 endpoint
# Builds on part 1 (VPC vpc-0318b57b8c085ac94, six subnets, IGW attached, flow logs ACTIVE)
# Run from week1/network:  bash day2-part2.sh
set -e
P="--profile lab"

VPC=vpc-0318b57b8c085ac94
IGW=igw-07d2ac783c35bfe01
PUB_A=subnet-0937b3f3bac28d475   # 10.20.1.0/24  us-east-1a
PUB_B=subnet-06ae6b4b3948ee6c8   # 10.20.2.0/24  us-east-1b
APP_A=subnet-00a122ab6e0dd98b6   # 10.20.11.0/24 us-east-1a
APP_B=subnet-0d1c54470bab5f591   # 10.20.12.0/24 us-east-1b
DATA_A=subnet-07d372477d86687b6  # 10.20.21.0/24 us-east-1a
DATA_B=subnet-0bee8403720ad34ad  # 10.20.22.0/24 us-east-1b

echo "== 1. Name the subnets and make the public tier public =="
aws ec2 create-tags --resources $PUB_A  --tags Key=Name,Value=w1-public-a $P
aws ec2 create-tags --resources $PUB_B  --tags Key=Name,Value=w1-public-b $P
aws ec2 create-tags --resources $APP_A  --tags Key=Name,Value=w1-app-a $P
aws ec2 create-tags --resources $APP_B  --tags Key=Name,Value=w1-app-b $P
aws ec2 create-tags --resources $DATA_A --tags Key=Name,Value=w1-data-a $P
aws ec2 create-tags --resources $DATA_B --tags Key=Name,Value=w1-data-b $P
aws ec2 modify-subnet-attribute --subnet-id $PUB_A --map-public-ip-on-launch $P
aws ec2 modify-subnet-attribute --subnet-id $PUB_B --map-public-ip-on-launch $P

echo "== 2. One NAT gateway in public-a (about \$0.045/hr while it exists) =="
# One NAT for both AZs is the Day 2 cost trade-off: cheaper, but if AZ-a fails,
# private subnets in AZ-b lose internet egress too. Production would use one per AZ.
EIP=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text $P)
NAT=$(aws ec2 create-nat-gateway --subnet-id $PUB_A --allocation-id $EIP --query NatGateway.NatGatewayId --output text $P)
echo "NAT gateway $NAT creating, waiting until available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT $P

echo "== 3. Route tables, one per tier =="
RT_PUB=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text $P)
aws ec2 create-tags --resources $RT_PUB --tags Key=Name,Value=w1-public-rt $P
aws ec2 create-route --route-table-id $RT_PUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW $P
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_A $P > /dev/null
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_B $P > /dev/null

RT_APP=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text $P)
aws ec2 create-tags --resources $RT_APP --tags Key=Name,Value=w1-app-rt $P
aws ec2 create-route --route-table-id $RT_APP --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT $P
aws ec2 associate-route-table --route-table-id $RT_APP --subnet-id $APP_A $P > /dev/null
aws ec2 associate-route-table --route-table-id $RT_APP --subnet-id $APP_B $P > /dev/null

RT_DATA=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text $P)
aws ec2 create-tags --resources $RT_DATA --tags Key=Name,Value=w1-data-rt $P
# NAT is outbound-only: the data tier can reach out (updates, S3 via endpoint below)
# but nothing on the internet can initiate a connection back in.
aws ec2 create-route --route-table-id $RT_DATA --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT $P
aws ec2 associate-route-table --route-table-id $RT_DATA --subnet-id $DATA_A $P > /dev/null
aws ec2 associate-route-table --route-table-id $RT_DATA --subnet-id $DATA_B $P > /dev/null

echo "== 4. Security groups, one per tier, chained by reference =="
SG_PUB=$(aws ec2 create-security-group --group-name w1-public-sg --description "Public tier: HTTPS from the internet" --vpc-id $VPC --query GroupId --output text $P)
aws ec2 authorize-security-group-ingress --group-id $SG_PUB --protocol tcp --port 443 --cidr 0.0.0.0/0 $P > /dev/null

SG_APP=$(aws ec2 create-security-group --group-name w1-app-sg --description "App tier: HTTPS only from the public tier" --vpc-id $VPC --query GroupId --output text $P)
aws ec2 authorize-security-group-ingress --group-id $SG_APP --protocol tcp --port 443 --source-group $SG_PUB $P > /dev/null

SG_DATA=$(aws ec2 create-security-group --group-name w1-data-sg --description "Data tier: Postgres/MySQL only from the app tier" --vpc-id $VPC --query GroupId --output text $P)
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 5432 --source-group $SG_APP $P > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 3306 --source-group $SG_APP $P > /dev/null

echo "== 5. S3 gateway endpoint on the private route tables (free, no NAT data charges for S3) =="
aws ec2 create-vpc-endpoint --vpc-id $VPC --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids $RT_APP $RT_DATA $P

echo ""
echo "== Day 2 part 2 complete =="
echo "NAT: $NAT (EIP alloc: $EIP)"
echo "Route tables: public $RT_PUB | app $RT_APP | data $RT_DATA"
echo "Security groups: public $SG_PUB | app $SG_APP | data $SG_DATA"
