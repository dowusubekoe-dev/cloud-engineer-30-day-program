# Day 5 command log

Fill from the actual run, in order. Times are local (America/New_York).

| Time | Command or console action | Result |
|------|---------------------------|--------|
| 07:47 | bash day5-security.sh (discovery + enable) | GuardDuty detector created 07:47:34; Config bucket created 07:47:38; 3 of 5 Config rules set 07:47:50 to 07:47:59; Inspector EC2 enabling; Security Hub subscribed 07:48:07. Config recorder initially failed (service-linked role missing, delivery bucket had no Config policy, two rule identifiers wrong). Fixed 07:52 to 07:57: role created 07:52:54, bucket policy added, delivery channel set 07:53:31, recorder started 07:53:33 and verified recording; missing rules added with corrected identifiers RESTRICTED_INCOMING_TRAFFIC and EC2_INSTANCE_MANAGED_BY_SSM, with port 22 in the blocked-port parameters. day5-security.sh patched in both copies so a rerun does all of this |
|      | GuardDuty console: generate sample findings | |
|      | Worked sample finding 1 | |
|      | Worked sample finding 2 | |
| 08:50 | Config: first rule evaluations checked | Evaluation triggered for restricted-common-ports after the fix; rule invoked successfully 08:09 but recorded zero evaluations and compliance stayed INSUFFICIENT_DATA on recheck at 08:50. w1-bad-sg is attached to 0 network interfaces, and this rule evaluates security groups in use, so it may never evaluate the deliberate SG. Evidence decision: the CloudTrail record (CreateSecurityGroup 07:48:11, AuthorizeSecurityGroupIngress 07:48:13) stands as the violation evidence in the finding note instead of a Config non-compliant screenshot |
|      | Inspector: coverage checked | |
|      | Security Hub: starting score recorded | |
| 07:48 | w1-bad-sg created (script step 5) | Created sg-01d92b45ea62f9aaa at 07:48:11; port 22 from 0.0.0.0/0 authorized 07:48:13 |
|      | Screenshot: non-compliant evaluation ("before") | |
|      | CloudTrail: CreateSecurityGroup event traced | |
|      | aws ec2 delete-security-group (w1-bad-sg) | |
|      | Config rule re-evaluation started | |
|      | Screenshot: compliant result ("after") | |
|      | Throwaway bucket deleted | |
|      | Access Analyzer re-checked vs Day 1 | |
|      | Alert rule created or design documented | |

## Verification, 2026-11-19 (live API check)

I re-ran day5-security.sh; the script is idempotent and reported already-exists throughout, no harm done. Verified live: GuardDuty detector 22d0f4c6310470d62ed524c7708fe30e ENABLED; Config recorder recording=true, lastStatus SUCCESS, all five lab rules present; Inspector ENABLED with agent-based package scans ACTIVE on both app-asg instances (last scanned 2026-11-19 01:52 EST); Security Hub subscribed 2026-11-17. Remediation still open: w1-bad-sg sg-01d92b45ea62f9aaa still present (tcp 22 from 0.0.0.0/0) and throwaway bucket derek-lab-bad-public-428101261622 still exists.

## Correction, 2026-11-21 (live API + CloudTrail check)

The 2026-11-19 verification above is superseded on the security group ID. Live check 2026-11-21: sg-01d92b45ea62f9aaa no longer exists. CloudTrail shows it was deleted 2026-11-19 04:58 ET (principal cloud-eng-iac) and w1-bad-sg was recreated 2026-11-19 05:25 ET by derek-admin as sg-02873315ed049e15b (CreateSecurityGroup event 3fd67e91-0359-4b19-9362-747305b0375a), in the same VPC vpc-0318b57b8c085ac94, still with tcp 22 from 0.0.0.0/0 and attached to 0 interfaces. Remediation on Mon Nov 23 targets sg-02873315ed049e15b, not the old ID. Also verified 2026-11-21: throwaway bucket derek-lab-bad-public-428101261622 still exists; GuardDuty detector 22d0f4c6310470d62ed524c7708fe30e present; app-asg at 0/0 (lab off).

## Close-out session, 2026-11-23 (Day 5 completed)

- lab-on verified: ASG app-asg Min 2 / Desired 2, instances
  i-0118d3139e7855c53 and i-0c581d5c39aaa23a9 Healthy/InService,
  Config recorder recording.
- GuardDuty sample findings generated in console (about 13:59 ET);
  two attack-sequence samples worked into notes.md. Real active
  findings: 0.
- Config first evaluations recorded for all five lab rules.
  restricted-common-ports NON_COMPLIANT x3: w1-bad-sg (lab),
  ad-groceries-backend-sg (real exposure, separate follow-up),
  ctf_sg (by design). iam-user-mfa-enabled NON_COMPLIANT for all
  three IAM users. s3 rule COMPLIANT incl. the throwaway bucket
  (Block Public Access held). rds rule: nothing in scope.
  ec2-instance-managed-by-systems-manager: no results; instances
  never SSM-managed (Inspector coverage 0 of 2, Unmanaged).
- Security Hub: AWS Foundational standard found INCOMPLETE,
  re-enabled via batch-enable-standards, reached READY the same
  day. Starting scores before remediation: overall 8%, CIS 6%.
- Remediation (me, in the console): I deleted w1-bad-sg and the
  throwaway bucket; both verified by CLI (NotFound / 404, about
  14:35 ET). Config's stale NON_COMPLIANT entry for the deleted
  group cleared by the final re-check.
- Alert automation built: EventBridge rule
  day5-config-noncompliant-alert (ENABLED) to CloudWatch Logs
  /aws/events/day5-config-alerts. Access Analyzer: zero active
  findings.
- finding-note.md completed from the verified record.
- Screenshots: the seven before-state pages were captured in the
  browser session (1827x1080) but the capture tooling cannot save
  PNG files, so no screenshot files exist in screenshots/; the
  evidence is carried in notes.md and finding-note.md.
- I ran lab-off; verified about 20:55 ET: ASG 0/0,
  instances terminated, Config recording = false. Day 5 complete.
