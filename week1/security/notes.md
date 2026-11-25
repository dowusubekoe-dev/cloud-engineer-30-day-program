# Day 5 - Security and compliance: notes and Prove-it package

Status: I prepared this as a template on 2026-11-16, before the Day 5
build ran. I filled the bracketed fields from the actual run; nothing
here is backfilled from memory.

## What was turned on (fill in during the run)

- GuardDuty: detector ID 22d0f4c6310470d62ed524c7708fe30e, enabled
  during the Day 5 build (2026-11-17). I generated the sample
  findings in the console on 2026-11-23 at about 13:59 ET: 50 active findings on
  the API first page, all from the sample set. Two worked below.
- AWS Config: recorder running, delivery bucket
  derek-lab-config-428101261622. First evaluation results recorded
  2026-11-23 in the close-out session (see Config first evaluations
  below):
  s3-bucket-public-read-prohibited, iam-user-mfa-enabled,
  rds-instance-public-access-check, restricted-common-ports,
  ec2-instance-managed-by-systems-manager.
- Amazon Inspector: enabled for EC2 at account level, but scan
  coverage is 0 of 2 instances. Both ASG instances show as
  "Unmanaged EC2 instance" in Inspector (no SSM management), so
  nothing is actually being scanned and there are no findings.
  Coverage gap recorded honestly; making the instances SSM-managed
  is a follow-up, not part of Day 5 remediation.
- Security Hub: hub enabled 2026-11-17. On 2026-11-23 I found the
  AWS Foundational Security Best Practices v1.0.0 standard
  INCOMPLETE (it was subscribed during the build but the setup
  never finished). I re-enabled it, and it reached READY the same
  day (verified 2026-11-23 at about 14:32 ET) once Security Hub
  created its Config rules. CIS AWS Foundations Benchmark v1.2.0 was READY
  throughout. Starting scores recorded before any remediation on
  2026-11-23: Security Hub overall score 8 percent (11 passed, 47
  failed in the summary widget), CIS 6 percent (2 passed, 25
  failed). The Foundational score populates once its controls
  evaluate after enablement and will be recorded here when it
  appears. Day 7 compares against these starting numbers.

## GuardDuty sample findings worked (guide asks for two)

1. Finding type: attack sequence, "Potential data compromise of one
   or more S3 buckets involving a sequence of actions associated with
   IAMUser/john_doe", severity Critical, resource IAMUser/john_doe
   (principalId AIDA3UBBJ2K3TVEXAMPLE, sample account 111122223333).
   14 signals across 5 MITRE tactics (Exfiltration, Impact,
   Persistence, Defense Evasion, Discovery); sensitive APIs included
   cloudtrail:DeleteTrail, iam:AttachUserPolicy,
   s3:PutBucketPublicAccessBlock, s3:GetObject and s3:DeleteObject;
   the source was a known Tor exit node.
   Evidence I would check first: CloudTrail Event History for
   john_doe in the first-seen to last-seen window, in call order.
   DeleteTrail shows the actor blinding logging first,
   AttachUserPolicy shows the privilege he granted himself, and the
   S3 calls name the buckets and objects touched. Then check whether
   the same credentials were used from any other source IP and
   whether the user holds other active access keys or sessions,
   before disabling the key and scoping the data loss against
   bucket versioning.
2. Finding type: attack sequence, "Potential EC2 instance group
   compromise of one or more instances indicated by a sequence of
   actions", severity Critical, resource Auto Scaling Group
   sample-asg-name (9 sample instances, sample account
   111122223333). 3 signals across Exfiltration, Impact, and Command
   and Control; DNS queries to malicious C2 domains and 2 malicious
   processes detected; techniques include T1041 (Exfiltration over
   C2 Channel) and T1496 (Resource Hijacking).
   Evidence I would check first: the DNS and process evidence.
   GuardDuty DNS logs and any Route 53 resolver query logs for the
   named C2 domains, plus VPC Flow Logs for the instances outbound
   traffic, confirm the command-and-control channel. Then CloudTrail
   for how the instances were reached and whether their
   instance-role credentials were used anywhere else. Containment:
   isolate with a security group first, capture evidence, then
   terminate and let the ASG replace the instances.
Real findings list: none. Zero real active findings before sample
generation (verified 2026-11-21); every active finding now is a
generated sample.

## Config first evaluations

I pulled the evaluations by CLI on 2026-11-23 at about 14:22 ET,
lab on, and matched them against my console review in the same
session.

- s3-bucket-public-read-prohibited: COMPLIANT for all four buckets,
  including derek-lab-bad-public-428101261622. The throwaway
  bucket's Block Public Access held, so it never actually allowed
  public reads. It is still deleted in remediation as a throwaway
  resource, but the honest record is that this control worked.
- iam-user-mfa-enabled: NON_COMPLIANT for all three IAM users:
  cloud-eng-iac, derek-admin, and ad-groceries-github-actions.
  None has MFA enrolled. I am recording this as a real finding,
  not silently accepting it; MFA enrollment is my follow-up
  decision (console user cloud-eng-iac first).
- rds-instance-public-access-check: no evaluation results. No RDS
  instances exist after the Day 4 teardown (app-db was deleted),
  so nothing is in scope for this rule.
- restricted-common-ports: NON_COMPLIANT for exactly three
  security groups. sg-02873315ed049e15b (w1-bad-sg, port 22 from
  0.0.0.0/0) is the lab's deliberate violation and today's
  remediation target. sg-0aa1f7eab3ba43412
  (ad-groceries-backend-sg, port 22 from 0.0.0.0/0) is a real
  exposure in the agency project's backend: recorded for separate
  follow-up, NOT touched by Day 5 remediation. sg-0b528f2c93f9fad9d
  (ctf_sg, ports 22, 80, 8080, 8083 open) is a CTF lab group, open
  by design, also not touched. Every other evaluated security
  group is COMPLIANT.
- ec2-instance-managed-by-systems-manager: no evaluation results
  returned yet for the two ASG instances (i-0118d3139e7855c53,
  i-0c581d5c39aaa23a9). Consistent with Inspector showing both
  instances as Unmanaged. Re-checked before lab-off: still no
  evaluation results; the instances were never SSM-managed
  during Day 5.

## Prove-it checks

- [x] Deliberate misconfiguration created: w1-bad-sg
      sg-02873315ed049e15b, port 22 from 0.0.0.0/0, plus throwaway
      bucket derek-lab-bad-public-428101261622
- [ ] "Before" screenshot: non-compliant Config evaluation saved in
      week1/security/
- [x] CloudTrail traced: CreateSecurityGroup event at
      2026-11-19 05:25:33 ET, principal derek-admin, source IP
      65.34.64.90 (event ID 3fd67e91-0359-4b19-9362-747305b0375a;
      the recreation of the current SG, see command-log.md)
- [x] Remediation done: I deleted w1-bad-sg in the console
      on 2026-11-23 (verified by CLI at about 14:35 ET: the group
      returns NotFound) and restricted-common-ports re-evaluated.
      Config still showed the deleted group as NON_COMPLIANT at
      the last check (about 14:40 ET); that entry is stale and
      clears when Config records the deletion. Final state
      confirmed at the Step 7 re-check on 2026-11-23: the deleted
      group no longer appears in the rule's NON_COMPLIANT
      results; only ad-groceries-backend-sg and ctf_sg remain.
- [ ] "After" screenshot: compliant result saved in week1/security/
- [x] Throwaway bucket deleted 2026-11-23, verified by CLI at
      about 14:35 ET (HeadBucket returns 404)
- [x] Access Analyzer re-checked 2026-11-23: the account's only
      analyzer is the Security Hub unused-access analyzer, ACTIVE,
      with zero active findings. Nothing is flagged for the deleted
      bucket, consistent with its Block Public Access having held.
      No findings to close or explain.
- [x] Alert automation: EventBridge rule
      day5-config-noncompliant-alert created 2026-11-23 (CLI) and
      verified ENABLED. Pattern: source aws.config, detail type
      "Config Rules Compliance Change", complianceType
      NON_COMPLIANT, for the five lab rules. Target: CloudWatch
      Logs group /aws/events/day5-config-alerts (resource policy
      Day5EventBridgeToLogs in place), where firing events land
      for review.
- [x] Finding note completed (finding-note.md, half page, incident
      format; drafted 2026-11-23 from the verified record)

## CloudTrail clarification (added 2026-11-16, verified against AWS docs)

The empty Trails list in the management account (428101261622, verified
in console and by API on 2026-11-16) does NOT block Day 5. The Day 5
trace step uses CloudTrail Event history, which AWS keeps on by
default for the past 90 days of management events, is separate from
any trail, and works via the console Event history page or
`aws cloudtrail lookup-events` with no trail configured (AWS
CloudTrail FAQ and the "Working with CloudTrail event history" user
guide). CreateSecurityGroup is a management event, so the Day 5 trace
proceeds as scripted. Still open, but separate and not a Day 5
blocker: where the Control Tower organization trail lives (possibly
the CloudTrail-Admin account) and whether the management account
should have a trail of its own for retention past 90 days.

## Cost note

GuardDuty and Inspector are on first-use free trials if the account
has never enabled them; AWS Config bills per recorded item and per
rule evaluation, small at lab scale but real, against the $10/month
budget guard (80% alert to dowusubekoe@gmail.com). Keep the services
on through Day 7 (the score comparison needs them); the teardown
commands are at the bottom of day5-security.sh output.
Recorder stopped at: 2026-11-23, about 20:55 ET, when I ran
lab-off. Verified by CLI the same evening: recording = false,
last status SUCCESS; ASG app-asg at Min 0 / Desired 0 with both
instances terminated and no instances running in the lab VPC.
The security services themselves (GuardDuty, Security Hub,
Inspector, the Config rules) stay enabled through Day 7 as
planned; only the recorder and the lab instances are parked.
