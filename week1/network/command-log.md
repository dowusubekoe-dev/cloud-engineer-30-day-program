# Day 2 Command Log

All commands run with `--profile lab` (account 428101261622, us-east-1) from `week1/network/`.
Part 1 run 2026-11-15; part 2 scripted 2026-11-15, run pending.

## Part 1: VPC, subnets, IGW, flow logs (ran clean after the Day 2 README patch)

```bash
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text --profile lab)
# -> vpc-0318b57b8c085ac94
aws ec2 create-tags --resources $VPC --tags Key=Name,Value=lab-vpc --profile lab

aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.1.0/24  --availability-zone us-east-1a --profile lab  # subnet-0937b3f3bac28d475
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.2.0/24  --availability-zone us-east-1b --profile lab  # subnet-06ae6b4b3948ee6c8
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.11.0/24 --availability-zone us-east-1a --profile lab  # subnet-00a122ab6e0dd98b6
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.12.0/24 --availability-zone us-east-1b --profile lab  # subnet-0d1c54470bab5f591
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.21.0/24 --availability-zone us-east-1a --profile lab  # subnet-07d372477d86687b6
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.20.22.0/24 --availability-zone us-east-1b --profile lab  # subnet-0bee8403720ad34ad

IGW=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text --profile lab)
# -> igw-07d2ac783c35bfe01
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC --profile lab

aws logs create-log-group --log-group-name /vpc/flowlogs --profile lab
aws iam create-role --role-name w1-flowlogs-role --assume-role-policy-document file://flowlogs-trust.json --profile lab
aws iam put-role-policy --role-name w1-flowlogs-role --policy-name flowlogs-write --policy-document file://flowlogs-perms.json --profile lab
ROLE_ARN=$(aws iam get-role --role-name w1-flowlogs-role --query Role.Arn --output text --profile lab)
aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC --traffic-type ALL \
  --log-destination-type cloud-watch-logs --log-group-name /vpc/flowlogs \
  --deliver-logs-permission-arn $ROLE_ARN --profile lab
# -> fl-0d62187ae88cfecef, verified ACTIVE

aws ec2 modify-subnet-attribute --subnet-id subnet-0937b3f3bac28d475 --map-public-ip-on-launch --profile lab
aws ec2 modify-subnet-attribute --subnet-id subnet-06ae6b4b3948ee6c8 --map-public-ip-on-launch --profile lab
```

## Part 2: NAT, route tables, security groups, S3 endpoint

Scripted in full in `day2-part2.sh` (same folder). Run with:

```bash
bash day2-part2.sh
```

It creates: one NAT gateway in w1-public-a with an Elastic IP; route tables w1-public-rt (0.0.0.0/0 to IGW), w1-app-rt and w1-data-rt (0.0.0.0/0 to NAT); security groups w1-public-sg (443 from 0.0.0.0/0), w1-app-sg (443 from w1-public-sg), w1-data-sg (5432 and 3306 from w1-app-sg); and the S3 gateway endpoint on the app and data route tables. It prints all new IDs at the end; paste them here after the run.

## Errors hit and fixed on the way

- `InvalidSubnet.Conflict`: the original guide loop reused CIDR 10.20.1.0/24 for both AZs. Every subnet needs its own CIDR. Guide patched.
- `InvalidParameter` on CreateFlowLogs ("DeliverLogsPermissionArn can't be empty"): CloudWatch destination requires an IAM role ARN and an existing log group. Guide patched.
- First build attempt left two partial VPCs tangled (vpc-0eea4604f7b3a4f13, vpc-015bdbac6d757965a); both were torn down fully (subnets, flow logs, IGWs, log group, role) before the clean run above. Day 1 IAM work was not touched.

## NAT gateway deleted, 2026-11-19 (my cost cut)

nat-088b4598c6227185c deleted and its Elastic IP eipalloc-0965394e90c6fa682 released, verified live (0 NAT gateways remain). Reason: NAT hours were the largest line on the November bill ($2.52 month to date, about $32/month at full rate) against a $10 budget. The private route table still points at the deleted NAT (harmless blackhole). Day 6 Terraform rebuild recreates the NAT gateway and a fresh EIP as code. ALB w1-alb and ASG app-asg deliberately kept as Day 6 reference.
