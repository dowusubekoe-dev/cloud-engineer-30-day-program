#!/usr/bin/env bash
# Day 7 HA test watcher: log ASG instance states + ALB target health
# every 15s for up to ~8 minutes, timestamped, to ha-test.log.
LOG="$HOME/my-workspace/01-cloud-computing_devops/courses/cloud-engineer-30/week1/checkpoint/ha-test.log"
TG=$(aws elbv2 describe-target-groups --names w1-app-tg --profile lab --region us-east-1 --query "TargetGroups[0].TargetGroupArn" --output text)
for i in $(seq 1 32); do
  TS=$(date '+%H:%M:%S')
  INST=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names app-asg --profile lab --region us-east-1 --query "AutoScalingGroups[0].Instances[].join(':',[InstanceId,AvailabilityZone,LifecycleState,HealthStatus])" --output text)
  TGT=$(aws elbv2 describe-target-health --target-group-arn "$TG" --profile lab --region us-east-1 --query "TargetHealthDescriptions[].join(':',[Target.Id,TargetHealth.State])" --output text)
  echo "$TS | ASG: $INST | TG: $TGT" >> "$LOG"
  sleep 15
done
echo "$(date '+%H:%M:%S') | watcher done" >> "$LOG"
