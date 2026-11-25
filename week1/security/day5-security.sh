#!/usr/bin/env bash
# Day 5 - Security and compliance (30-Day Cloud Engineer plan, Week 1)
# Status: prepared 2026-11-16; first run 2026-11-17. The AWS Config
# section was patched the same day, after the live run exposed three
# defects: no step creating the Config service-linked role, no bucket
# policy on the delivery bucket, and two managed-rule identifiers that
# are not the uppercased rule name (see the Config section below).
#
# What this does, in guide order:
#   1. Enables GuardDuty and prints how to generate sample findings
#      (sample findings are a console-only action: Settings > Sample
#      findings; the script cannot do that step for you).
#   2. Enables AWS Config: creates the delivery bucket, the recorder
#      (all supported resources), and the five managed rules from the
#      guide. Waits, then prints the first compliance results.
#   3. Enables Amazon Inspector for EC2 and prints scan coverage.
#   4. Enables Security Hub with the AWS Foundational Security Best
#      Practices standard and prints the starting score location
#      (the score itself is read in the console; record it in notes.md).
#   5. Creates the deliberate misconfiguration: throwaway security
#      group w1-bad-sg in the Day 2 VPC allowing port 22 from
#      0.0.0.0/0, plus a throwaway S3 bucket. It does NOT remediate:
#      the "before" screenshot of the non-compliant Config evaluation
#      comes first. Remediation commands are printed at the end.
#
# Prerequisites: Days 2-4 complete (VPC vpc-0318b57b8c085ac94 with the
# per-tier security groups, the app instances from Day 3 running so
# Inspector has something to scan, RDS from Day 4 so the
# rds-instance-public-access-check rule has a resource to evaluate).
#
# Cost note: GuardDuty and Inspector run on free trials on first
# enablement in an account that has never used them; AWS Config bills
# per configuration item recorded and per rule evaluation, small at
# lab scale but not zero, against the $10/month budget guard (80%
# alert to dowusubekoe@gmail.com). If cost matters more than the
# Day 7 score comparison, the teardown block at the bottom stops the
# Config recorder and disables the services after Day 7.
#
# Idempotency: every enable step tolerates "already enabled" errors
# and continues; re-running is safe and will just re-print status.

set -uo pipefail

PROFILE="lab"
VPC_ID="vpc-0318b57b8c085ac94"
ACCOUNT_ID="$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)"
CONFIG_BUCKET="derek-lab-config-$ACCOUNT_ID"
BAD_BUCKET="derek-lab-bad-public-$ACCOUNT_ID"

echo "== Account $ACCOUNT_ID, VPC $VPC_ID =="

echo
echo "== 1. GuardDuty =="
aws guardduty create-detector --profile "$PROFILE" --enable 2>/dev/null \
  || echo "GuardDuty detector already exists (or see error above)."
aws guardduty list-detectors --profile "$PROFILE" --output table
echo "Next, in the console: GuardDuty > Settings > Sample findings >"
echo "Generate sample findings. Work two of them in notes.md, then check"
echo "the real findings list."

echo
echo "== 2. AWS Config =="
aws s3api create-bucket --profile "$PROFILE" --bucket "$CONFIG_BUCKET" 2>/dev/null \
  || echo "Config bucket $CONFIG_BUCKET already exists."
# Recorder role: the AWS-managed service-linked role. On a fresh account
# it does not exist yet and put-configuration-recorder fails without it
# (found live 2026-11-17), so create it first.
aws iam create-service-linked-role --profile "$PROFILE" \
  --aws-service-name config.amazonaws.com 2>/dev/null \
  || echo "Config service-linked role already exists."
# The delivery bucket needs the AWS Config bucket policy before
# put-delivery-channel will succeed (InsufficientDeliveryPolicyException
# otherwise, found live 2026-11-17).
cat > /tmp/config-bucket-policy.json <<POLICY
{"Version":"2012-10-17","Statement":[
{"Sid":"AWSConfigBucketPermissionsCheck","Effect":"Allow","Principal":{"Service":"config.amazonaws.com"},"Action":"s3:GetBucketAcl","Resource":"arn:aws:s3:::$CONFIG_BUCKET","Condition":{"StringEquals":{"AWS:SourceAccount":"$ACCOUNT_ID"}}},
{"Sid":"AWSConfigBucketExistenceCheck","Effect":"Allow","Principal":{"Service":"config.amazonaws.com"},"Action":"s3:ListBucket","Resource":"arn:aws:s3:::$CONFIG_BUCKET","Condition":{"StringEquals":{"AWS:SourceAccount":"$ACCOUNT_ID"}}},
{"Sid":"AWSConfigBucketDelivery","Effect":"Allow","Principal":{"Service":"config.amazonaws.com"},"Action":"s3:PutObject","Resource":"arn:aws:s3:::$CONFIG_BUCKET/AWSLogs/$ACCOUNT_ID/Config/*","Condition":{"StringEquals":{"s3:x-amz-acl":"bucket-owner-full-control","AWS:SourceAccount":"$ACCOUNT_ID"}}}]}
POLICY
aws s3api put-bucket-policy --profile "$PROFILE" --bucket "$CONFIG_BUCKET" \
  --policy file:///tmp/config-bucket-policy.json \
  || echo "Config bucket policy may already be set (or see error above)."
aws configservice put-configuration-recorder --profile "$PROFILE" \
  --configuration-recorder name=default,roleARN="arn:aws:iam::$ACCOUNT_ID:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig" \
  --recording-group allSupported=true,includeGlobalResourceTypes=true \
  || echo "Recorder already configured (or see error above)."
aws configservice put-delivery-channel --profile "$PROFILE" \
  --delivery-channel name=default,s3BucketName="$CONFIG_BUCKET" \
  || echo "Delivery channel already configured (or see error above)."
aws configservice start-configuration-recorder --profile "$PROFILE" \
  --configuration-recorder-name default \
  || echo "Recorder already running."

# Managed-rule identifiers are NOT always the uppercased rule name
# (found live 2026-11-17): restricted-common-ports is
# RESTRICTED_INCOMING_TRAFFIC and ec2-instance-managed-by-systems-manager
# is EC2_INSTANCE_MANAGED_BY_SSM. The other three do match the transform.
for RULE in s3-bucket-public-read-prohibited iam-user-mfa-enabled \
            rds-instance-public-access-check restricted-common-ports \
            ec2-instance-managed-by-systems-manager; do
  case "$RULE" in
    restricted-common-ports) IDENT="RESTRICTED_INCOMING_TRAFFIC" ;;
    ec2-instance-managed-by-systems-manager) IDENT="EC2_INSTANCE_MANAGED_BY_SSM" ;;
    *) IDENT="$(echo "$RULE" | tr 'a-z-' 'A-Z_')" ;;
  esac
  aws configservice put-config-rule --profile "$PROFILE" \
    --config-rule ConfigRuleName="$RULE",Source="{Owner=AWS,SourceIdentifier=$IDENT}" \
    >/dev/null 2>&1 && echo "Rule set: $RULE" || echo "Rule may already exist: $RULE"
done
# restricted-common-ports only flags the ports in its blockedPort
# parameters, and port 22 is not a default. Set them explicitly or the
# rule will not flag the deliberate SSH opening in step 5.
cat > /tmp/restricted-common-ports.json <<JSON
{"ConfigRuleName":"restricted-common-ports","Source":{"Owner":"AWS","SourceIdentifier":"RESTRICTED_INCOMING_TRAFFIC"},"InputParameters":"{\"blockedPort1\":\"22\",\"blockedPort2\":\"3389\",\"blockedPort3\":\"3306\",\"blockedPort4\":\"20\",\"blockedPort5\":\"21\"}"}
JSON
aws configservice put-config-rule --profile "$PROFILE" \
  --config-rule file:///tmp/restricted-common-ports.json \
  && echo "Rule parameters set: restricted-common-ports (blocked ports include 22)"

echo
echo "== 3. Amazon Inspector =="
aws inspector2 enable --profile "$PROFILE" \
  --account-ids "$ACCOUNT_ID" --resource-types EC2 2>/dev/null \
  || echo "Inspector already enabled (or see error above)."
aws inspector2 list-coverage --profile "$PROFILE" --output table 2>/dev/null \
  || echo "Coverage not readable yet; check the Inspector console after a few minutes."

echo
echo "== 4. Security Hub =="
aws securityhub enable-security-hub --profile "$PROFILE" \
  --enable-default-standards 2>/dev/null \
  || echo "Security Hub already enabled (or see error above)."
echo "In the console: Security Hub > Summary. Record the AWS Foundational"
echo "Security Best Practices starting score in notes.md for Day 7."

echo
echo "== 5. Deliberate misconfiguration (the finding you will fix) =="
BAD_SG_ID="$(aws ec2 create-security-group --profile "$PROFILE" \
  --group-name w1-bad-sg --description 'Day 5 deliberate misconfiguration - DELETE TODAY' \
  --vpc-id "$VPC_ID" --query GroupId --output text 2>/dev/null || true)"
if [ -n "${BAD_SG_ID:-}" ]; then
  aws ec2 authorize-security-group-ingress --profile "$PROFILE" \
    --group-id "$BAD_SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
  echo "Created w1-bad-sg: $BAD_SG_ID (22 open to 0.0.0.0/0)"
else
  echo "w1-bad-sg may already exist; look it up:"
  aws ec2 describe-security-groups --profile "$PROFILE" \
    --filters Name=group-name,Values=w1-bad-sg \
    --query 'SecurityGroups[].GroupId' --output text
fi
aws s3api create-bucket --profile "$PROFILE" --bucket "$BAD_BUCKET" 2>/dev/null \
  && echo "Created throwaway bucket $BAD_BUCKET (Block Public Access stays ON by default)" \
  || echo "Throwaway bucket may already exist: $BAD_BUCKET"

echo
echo "== Wait for Config to evaluate, then check compliance =="
echo "Waiting 120 seconds for the first evaluations..."
sleep 120
for RULE in s3-bucket-public-read-prohibited iam-user-mfa-enabled \
            rds-instance-public-access-check restricted-common-ports \
            ec2-instance-managed-by-systems-manager; do
  echo "-- $RULE"
  aws configservice get-compliance-details-by-config-rule --profile "$PROFILE" \
    --config-rule-name "$RULE" \
    --query 'EvaluationResults[].{Resource:EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,Result:ComplianceType}' \
    --output table 2>/dev/null || echo "   (no evaluations yet; re-check in the console)"
done

cat <<'EOF'

== STOP HERE. Before remediating: ==
1. Screenshot the NON-COMPLIANT evaluation for w1-bad-sg (the "before").
2. In CloudTrail > Event history, find the CreateSecurityGroup event for
   w1-bad-sg. Record event name, time, principal, source IP in notes.md.
3. Screenshot the Security Hub starting score.

== Remediation (run only after the screenshots) ==
  aws ec2 delete-security-group --profile lab --group-id <BAD_SG_ID>
  aws configservice start-config-rules-evaluation --profile lab \
    --config-rule-names restricted-common-ports
  aws s3 rb s3://derek-lab-bad-public-<ACCOUNT_ID>
Then re-check the rule: it should return COMPLIANT / no resources.
Screenshot that (the "after") and finish finding-note.md.

== Optional teardown after Day 7 (stops Config billing) ==
  aws configservice stop-configuration-recorder --profile lab \
    --configuration-recorder-name default
  aws guardduty delete-detector --profile lab --detector-id <ID>
  aws inspector2 disable --profile lab --account-ids <ACCOUNT_ID> \
    --resource-types EC2
  aws securityhub disable-security-hub --profile lab
EOF
