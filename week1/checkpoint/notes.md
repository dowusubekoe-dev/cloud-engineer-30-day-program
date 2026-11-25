# Day 7 — HA, cost, and Week 1 review (notes)

Date: 2026-11-25. Goal: prove the design survives an AZ failure, know what
it costs, and close Week 1 honestly.

## Session plan (from the Week 1 README)
1. Re-apply the Day 6 Terraform stack (39 resources) and lab-on
   (Config recorder back on).
2. HA test: kill one AZ's instances from the ASG, watch it heal into the
   other AZ, note recovery time.
3. Security Hub: read the Foundational Security Best Practices score and
   compare with the Day 5 starting numbers (overall 8%, CIS 6%, recorded
   2026-11-23 before remediation).
4. Cost pass: Cost Explorer top five resources by cost for the lab
   account, plus the tear-down order for anything outside the checkpoint
   stack.
5. Architecture diagram (one page) + self-review (half page) into week1/.
6. Drill: re-answer the Day 1 IAM design question and the Day 2 S3
   troubleshooting question, cold, recorded.

## Pre-flight (verified 2026-11-25 ~09:40 ET)
- Terraform state after the Day 6 destroy: 0 resources.
- Snapshot app-db-manual-1: available.
- Config recorder: stopped (recording=False) since Day 5 lab-off.
- EIPs held: 0. ASGs: 0.

## Run record (2026-11-25)
- Plan: 39 to add, 0 to change, 0 to destroy (plan-output-day7.txt).
  I approved the plan; the apply launched 09:43 ET, complete ~09:51 ET:
  39 added, 0 changed, 0 destroyed (apply-output-day7.txt).
- Lab-on: Config recorder "default" started, recording=True.
- Verification: ASG app-asg 2/2 InService + Healthy (i-0aebe67216f3affbc
  in us-east-1a, i-023e34f7acb53c9bf in us-east-1b); both ALB targets
  healthy; ALB w1-alb-1879191279.us-east-1.elb.amazonaws.com served the
  hello page from both app subnets (10.20.11.37, 10.20.12.240); RDS
  app-db available (restored from app-db-manual-1).

### HA test (evidence: ha-test.log in this folder)
Method: I removed subnet w1-app-a (us-east-1a) from the ASG's zone list,
which is what an AZ failure looks like to an ASG: it terminated the 1a
instance and replaced it inside the surviving AZ.
- 09:53:23 T0: us-east-1a removed from app-asg.
- 09:53:41 (+18s): replacement i-036be434267a75a9e Pending in us-east-1b.
- 09:54:00 (+37s): replacement InService; the 1a instance Terminating,
  its target draining.
- Service continuity: the surviving 1b instance answered every ALB
  request during the test. Zero downtime observed.
- 09:56:54 (+3m31s): replacement target healthy. Full capacity restored.
  The InService-to-healthy gap is user data (dnf install httpd over the
  NAT path) plus the target group's health-check thresholds.
- 09:57:35: us-east-1a restored to the ASG. Rebalance completed: new 1a
  instance i-0f0d642f24eddb5a0 InService with a healthy target, one 1b
  instance kept, the spare 1b instance terminated. ALB serving from both
  app subnets again (10.20.11.236, 10.20.12.86).
Recovery time to record: 37 seconds to a running replacement, 3m31s to
full healthy capacity, 0 seconds of downtime.

### Security Hub scores (CLI, from ACTIVE findings; scripts in this folder)
- Overall, each consolidated control counted once: 296 passed /
  94 failed = 76% (390 controls evaluated).
- AWS Foundational Security Best Practices v1.0.0: 292 passed /
  71 failed = 80% (363 of 366 enabled controls evaluated).
- CIS AWS Foundations v1.2.0 cannot be scored this way from the CLI:
  its control IDs are legacy (CIS.x.y) and do not join to finding
  GeneratorIds. The comparable CIS number is the console's (Day 5's 6%
  was a console read); see screenshots list item 6.
- Honest comparison with Day 5: the Day 5 console snapshot (overall 8%,
  11 passed / 47 failed) was taken minutes after the Foundational
  standard finished enabling, when most controls had never evaluated.
  Today's higher numbers are partly that wider evaluation and partly
  real: the Day 5 remediation (bad SG and bucket deleted) and the clean
  Terraform rebuild removed the lab's own failures. The remaining
  94 failed controls / 164 failed findings are mostly account hygiene
  outside the lab stack: ECR lifecycle and tag-immutability (10 repos
  each), S3 access logging / TLS-only / lifecycle on 4 buckets,
  DynamoDB point-in-time recovery and deletion protection, EBS
  encryption, default security groups, VPC endpoint coverage.

### Cost pass (Cost Explorer, lab account 428101261622, Nov 1-25)
1. Elastic Load Balancing $4.61
2. EC2 - Other (EBS, EIP, transfer) $3.38
3. AWS Config $3.26
4. VPC (NAT gateway hours + data) $1.81
5. EC2 Compute $1.63
6. RDS $1.54 (for reference)
Month to date $16.37 against the $10 monthly-guard budget; forecast
$19.73. GuardDuty, Security Hub, and Inspector do not appear in the
top ten: all three are still inside the 30-day free trials started
2026-11-17 (the expiry check runs 2026-12-14). AWS Config is the real
standing cost of the Day 5 security layer.
Tear-down order for anything outside the checkpoint stack: nothing else
is running that bills materially. Standing items kept on purpose: the
app-db-manual-1 snapshot (the Day 7 stack restores from it), the
tfstate bucket and lock table (about $0.00), the Day 5 security
services (trials + Config). If the checkpoint stack is destroyed, the
order Terraform already follows is: ASG and instances, ALB, RDS, NAT +
EIP, then the VPC shell.

## Prove it
- [x] Stack re-applied and verified (ASG 2/2 healthy, ALB targets healthy, RDS available)
- [x] Config recorder recording again (lab-on)
- [x] HA test done, recovery time noted (37s replacement, 3m31s full health, 0 downtime)
- [x] Security Hub Foundational score read (80% CLI) and compared with Day 5 baseline with the method caveat
- [x] Cost pass: top five + tear-down order written
- [x] Architecture diagram in week1/ (architecture-diagram.md)
- [x] Self-review in week1/ (self-review.md, half page)
- [ ] Drill recorded (Day 1 + Day 2 questions, cold) — my recording to make; script ready in this folder
- [x] Teardown decision made and executed

## Teardown (2026-11-25, my decision: destroy, Week 1 done)
- Config recorder stopped first (lab-off), then terraform destroy:
  39 destroyed, 0 errors (destroy-output-day7.txt). The ASG deletion
  was the slow last step (about 9 minutes in destroy total).
- Verified after: Terraform state 0 resources; snapshot
  app-db-manual-1 still available; EIPs 0; no w1 VPC; ASGs 0; RDS
  instances 0; recorder recording=False; tfstate bucket intact.
- Screenshots: none captured for Day 7 (same tooling limit as Days 5-6:
  the browser can photograph console pages but cannot save PNG files).
  The evidence for the day is this notes file, ha-test.log, and the
  plan/apply/destroy outputs in week1/terraform/.
