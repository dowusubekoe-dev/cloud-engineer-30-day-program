# Day 6 - Terraform rebuild: notes and Prove-it package

Status: COMPLETED 2026-11-24 (evening session), including the
same-day destroy. I chose Path B at the start of the run: "Path B —
tear down and rebuild fresh". Data module: restore from snapshot
app-db-manual-1. Cost decision: destroy tonight, re-apply on Day 7
(my call, 2026-11-24).

## How the run went

1. Bootstrap (I ran this in the terminal): bucket
   derek-lab-tfstate created, versioning enabled. The lock table derek-lab-tflock already
   existed (ResourceInUseException on create = desired state);
   verified ACTIVE, PAY_PER_REQUEST, LockID HASH key. Bucket
   verified: AES256 default encryption, Block Public Access all on.
2. Inventory captured BEFORE teardown into inventory/ (JSON per
   service plus the launch template user data, both versions).
   Design: VPC 10.20.0.0/16; public 10.20.1.0/24 + 10.20.2.0/24;
   app 10.20.11.0/24 + 10.20.12.0/24; data 10.20.21.0/24 +
   10.20.22.0/24; SG chain public <- app <- data; ALB -> TG ->
   ASG (min 0 / desired 0 / max 4 at teardown, lab off); LT AMI
   ami-096ef200a877f36af, t3.micro, IMDSv2 required, user data =
   dnf httpd + hello page; snapshot app-db-manual-1 (postgres
   15.19, 20 GB, master user appadmin).
3. Teardown (scripted, teardown.log): ASG app-asg, LT app-lt,
   ALB w1-alb + listener + target group, SGs w1-public-sg /
   w1-app-sg / w1-data-sg (rules revoked first), 6 subnets, 3
   custom route tables, IGW — all deleted. EIP 3.93.229.127
   released (its ENI belonged to the ALB; account now holds zero
   addresses). First VPC delete failed: DependencyViolation — an
   S3 gateway VPC endpoint (vpce-0865d395b0fc01d99, Day 2 design)
   was still attached. Endpoint deleted, VPC delete verified
   (InvalidVpcID.NotFound for vpc-0318b57b8c085ac94).
   Untouched, as planned: tfstate bucket + lock table, snapshot
   app-db-manual-1, GuardDuty / Security Hub / Inspector / Config
   rules, the Day 5 EventBridge alert rule.
4. Modules written to match the captured design exactly, plus the
   one deliberate restoration: a NAT gateway (the original design
   had nat-088b4598c6227185c in both private route tables; it was
   deleted Nov 19). modules/network (VPC, subnets, IGW, NAT,
   route tables, S3 gateway endpoint, 3 SGs), modules/compute
   (ALB, listener, TG, LT with the captured user data, ASG),
   modules/data (subnet group + RDS restore from snapshot).
   Root main.tf: I kept my backend block; profile = "terraform"
   added to provider and backend so the project runs without
   shell env vars (original saved as main.tf.derek-orig).
   ASG set to min 2 / desired 2 (lab-on state) for verification.
5. init (S3 backend, provider aws v5.100.0), fmt, validate: clean.
   Plan saved to plan-output.txt: 39 to add, 0 to change,
   0 to destroy. Read before applying.
6. Apply completed ~19:32 ET: 39 added, 0 changed, 0 destroyed.
   New IDs: VPC vpc-07508b0cc13c602dc; NAT nat-05b2b704bdbb8f9d2;
   ALB w1-alb-1716628610.us-east-1.elb.amazonaws.com; instances
   i-00bd6315048e93bbf (1a), i-06e9876dd836a4eb5 (1b); RDS
   app-db.co16s6q6g4t2.us-east-1.rds.amazonaws.com.

## Prove-it checks

- [x] Live state re-checked at start (full inventory in inventory/)
- [x] Bootstrap: bucket created, versioning on, encryption on,
      public access blocked; lock table existed, verified ACTIVE
- [x] terraform init clean against the S3 backend
- [x] terraform fmt and terraform validate both clean
- [x] Path B teardown recorded (teardown.log), one entry per
      resource family with real IDs in the inventory files
- [x] terraform plan saved (-out=tfplan) and read before applying:
      39 creates, unexpected destroys: none
- [x] Apply done ~19:32 ET; NAT gateway nat-05b2b704bdbb8f9d2,
      route tables re-associated by Terraform
- [x] Private path retested through Terraform's NAT: both ASG
      instances Healthy + InService, both ALB targets healthy,
      and the ALB serves "hello from ip-10-20-11-188" and
      "hello from ip-10-20-12-63" — the user data's dnf install
      only succeeds with working private-subnet egress via NAT,
      so target health proves the NAT path end to end
- [x] RDS restored: status available, postgres 15.19,
      db.t3.micro, not publicly accessible
- [x] Teardown discipline same day: terraform destroy rehearsed
      YES — I chose to destroy tonight (reason: full-rate stack
      vs the $10 budget; apply took ~7 minutes, so Day 7 starts
      with one re-apply). Destroy completed ~19:47 ET: 39
      destroyed, exit 0, state empty (destroy-output.txt).
      Verified after: snapshot app-db-manual-1 still available,
      zero EIPs held, no w1 VPC, tfstate bucket intact.

## Cost note

Full-rate stack is about $75 to $80/month against the $10/month
budget guard; the NAT gateway is about $32 of it. The stack billed
only for the build-and-verify window (~19:32 to ~19:47 ET) before
the destroy. The tfstate bucket and lock table cost pennies and
stay. Day 7 note: the stack is currently DOWN (state empty);
Day 7 starts with terraform plan + apply to bring it back for the
HA/AZ test, and the Config recorder is still stopped from the
Day 5 lab-off, so lab-on applies there too. Screenshots: none
were captured for Day 6 (the run was terminal-driven; the
screenshots.md list remains the spec — capture during Day 7's
session while the stack is up, before its teardown).
