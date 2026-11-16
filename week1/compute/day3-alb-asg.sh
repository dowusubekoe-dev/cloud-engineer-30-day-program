#!/usr/bin/env bash
# Day 3 part 2: target group, ALB, listener, ASG, scaling policy.
# Run AFTER: (1) the Day 3 role/launch-template commands, and
#           (2) week1/network/day2-part2.sh (this script looks up its security groups).
# Run from week1/compute:  bash day3-alb-asg.sh
set -e
P="--profile lab"
VPC=vpc-0318b57b8c085ac94
PUB_A=subnet-0937b3f3bac28d475
PUB_B=subnet-06ae6b4b3948ee6c8
APP_A=subnet-00a122ab6e0dd98b6
APP_B=subnet-0d1c54470bab5f591

SG_PUB=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=w1-public-sg $P --query "SecurityGroups[0].GroupId" --output text)
SG_APP=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=w1-app-sg $P --query "SecurityGroups[0].GroupId" --output text)
if [ "$SG_PUB" = "None" ] || [ "$SG_APP" = "None" ]; then
  echo "Day 2 security groups not found. Run week1/network/day2-part2.sh first."
  exit 1
fi

echo "== Lab simplification: the ALB speaks HTTP on port 80 =="
echo "Day 2's SG design is 443-based (the production pattern). This lab has no"
echo "domain or certificate, so port 80 rules are added alongside for the ALB."
aws ec2 authorize-security-group-ingress --group-id $SG_PUB --protocol tcp --port 80 --cidr 0.0.0.0/0 $P 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $SG_APP --protocol tcp --port 80 --source-group $SG_PUB $P 2>/dev/null || true

echo "== Point the launch template at the app security group (new default version) =="
aws ec2 create-launch-template-version --launch-template-name app-lt --source-version '$Default' \
  --launch-template-data "{\"SecurityGroupIds\":[\"$SG_APP\"]}" $P > /dev/null
VER=$(aws ec2 describe-launch-template-versions --launch-template-name app-lt --query "max(LaunchTemplateVersions[].VersionNumber)" --output text $P)
aws ec2 modify-launch-template --launch-template-name app-lt --default-version $VER $P > /dev/null
echo "app-lt default version is now $VER with $SG_APP"

echo "== Target group + ALB + listener =="
TG=$(aws elbv2 create-target-group --name w1-app-tg --protocol HTTP --port 80 --vpc-id $VPC \
  --health-check-path / --query TargetGroups[0].TargetGroupArn --output text $P)
ALB=$(aws elbv2 create-load-balancer --name w1-alb --type application \
  --subnets $PUB_A $PUB_B --security-groups $SG_PUB --query LoadBalancers[0].LoadBalancerArn --output text $P)
aws elbv2 create-listener --load-balancer-arn $ALB --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG $P > /dev/null
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB --query LoadBalancers[0].DNSName --output text $P)

echo "== Auto Scaling group + CPU target tracking (50%) =="
aws autoscaling create-auto-scaling-group --auto-scaling-group-name app-asg \
  --launch-template LaunchTemplateName=app-lt --min-size 2 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "$APP_A,$APP_B" --target-group-arns "$TG" $P
aws autoscaling put-scaling-policy --auto-scaling-group-name app-asg --policy-name cpu-tt \
  --policy-type TargetTrackingScaling --target-tracking-configuration file://tt.json $P

echo ""
echo "== Day 3 ALB/ASG complete =="
echo "ALB DNS: $ALB_DNS"
echo "Wait 2-3 minutes for instances to pass health checks, then: curl http://$ALB_DNS"
