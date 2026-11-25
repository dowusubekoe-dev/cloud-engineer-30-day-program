# Day 5 session guide - Steps 2 to 7 (lab already ON and verified)

Verified starting state, 2026-11-23: app-asg Min 2 / Desired 2, instances
i-0118d3139e7855c53 and i-0c581d5c39aaa23a9 Healthy and InService.
Config recorder recording = true, last status SUCCESS.
GuardDuty detector: 22d0f4c6310470d62ed524c7708fe30e.
Remediation targets: sg-02873315ed049e15b (w1-bad-sg) and bucket
derek-lab-bad-public-428101261622.
Screenshots: landscape, 1600 px wide or more, PNG, into screenshots/.

## Step 2 - GuardDuty sample findings
Console: GuardDuty > Findings. Gear/Settings: Generate sample findings.
Wait 1-2 minutes, refresh Findings. Pick TWO sample findings and note:
type, severity, resource type and ID. Write the first evidence you would
check for each (see notes.md template). Note the real (non-sample) active
finding count separately.

## Step 3 - Config first evaluations (BEFORE evidence)
Console: Config > Rules. Open each lab rule and record compliance and any
non-compliant resource:
- restricted-common-ports: expect w1-bad-sg NON_COMPLIANT.
- s3-bucket-public-read-prohibited: expect the bad bucket flagged.
- iam-user-mfa-enabled: record honestly whatever it shows.
- rds-instance-public-access-check: no RDS exists (Day 4 teardown);
  expect no resources in scope.
- ec2-instance-managed-by-systems-manager: record result for the 2 ASG
  instances as shown.
SCREENSHOT (before): restricted-common-ports detail showing
sg-02873315ed049e15b non-compliant.

## Step 4 - Security Hub starting score (BEFORE remediation)
Console: Security Hub > Security standards > AWS Foundational Security
Best Practices v1.0.0. Record the security score percent exactly as
shown. Day 7 compares against this number.
SCREENSHOT: the standards page showing the score.

## Step 5 - Remediation
1. EC2 > Security Groups > sg-02873315ed049e15b: confirm no attached
   network interfaces, then Actions > Delete security group.
2. S3 > derek-lab-bad-public-428101261622: Empty the bucket if it holds
   objects, then Delete bucket and confirm by name.
3. Config > Rules > restricted-common-ports: confirm the deleted SG no
   longer shows as non-compliant (deletion triggers re-evaluation; use
   Re-evaluate if the console offers it and the result is stale).
SCREENSHOT (after): the rule page with the non-compliant SG gone.

## Step 6 - Access Analyzer and alert automation
IAM > Access Analyzer: record current findings; each one is either
resolved by the remediation or explained in notes.md (the bad bucket
finding should clear).
Alert automation, pick one (template accepts either):
- Fast: EventBridge > Rules > Create rule named
  day5-config-noncompliant-alert, event source AWS events, source
  aws.config, detail type "Config Rules Compliance Change". Target can
  be left as a log group or SNS if one exists; record the rule name.
- Or document the design in finding-note.md: trigger, event pattern,
  target, and why. Do not fake a created rule.

## Step 7 - Write-up, screenshots, lab-off
- Fill every bracketed field in notes.md from the real values above.
- Complete finding-note.md in incident format: Detection, Evidence,
  Impact, Remediation, Verification, Follow-up.
- Confirm all screenshots from screenshots.md are saved as PNG in
  screenshots/.
- Run ./lab-off.sh, then verify ASG 0/0 and Config recording = false
  before Day 5 is marked complete.
