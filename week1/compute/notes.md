# Day 3 Notes: Compute and Storage

## What Day 3 builds

- IAM role `ec2-app-role` (trust: EC2 service only, `ec2-trust.json`) with `AmazonSSMManagedInstanceCore` attached, carried by instance profile `ec2-app-profile`. Instances get credentials from the role at runtime: **no access keys are ever stored on a box.**
- Launch template `app-lt`: Amazon Linux 2023 (`ami-096ef200a877f36af`, current as of 2026-11-15), t3.micro, IMDSv2 required, user data installs httpd and serves a page naming the host. A second template version adds the app security group once Day 2's groups exist.
- ALB `w1-alb` in the public subnets -> target group `w1-app-tg` -> ASG `app-asg` (min 2, max 4, desired 2) across the two app subnets, target tracking on average CPU at 50% (`tt.json`).
- S3 bucket `derek-lab-app-data`: versioning on, all four public-access-block settings on. Encryption is on by default (SSE-S3); a lifecycle rule is the remaining storage item.

## The two one-liners (Prove it)

- **S3 durability vs availability:** durability is about not *losing* the object (S3 is designed for 99.999999999%, eleven nines, by storing copies across at least three AZs); availability is about being able to *reach* it when you ask (99.99% for S3 Standard). A service can be highly durable and briefly unavailable: your data is safe, you just cannot get to it for a minute.
- **EBS vs instance store:** EBS is network-attached storage that survives the instance stopping or terminating (separately backed up, snapshotted, and billed); instance store is the physical disk inside the host, faster but gone forever when the instance stops or the host fails. Rule: instance store is a cache or scratch space, never the only copy of anything.

## Decisions and gaps found in the guide

- The guide referenced `ec2-trust.json`, `lt-data.json`, and `tt.json` without ever giving their contents (same gap as Day 1's budget files). All three now exist in this folder.
- The guide's ASG command contains placeholders (`<app-subnet-1>`, `<tg-arn>`) and no commands at all for the target group, ALB, or listener. `day3-alb-asg.sh` in this folder fills that gap with the real subnet IDs.
- **Dependency:** Day 3's ALB/ASG step needs Day 2's security groups, so `week1/network/day2-part2.sh` must run first.
- **Lab simplification, stated honestly:** Day 2's security group design is 443-based, which is the production pattern. This lab has no domain or TLS certificate, so the ALB listens on HTTP 80 and matching port-80 rules were added next to the 443 rules. In production: an ACM certificate, a 443 listener, and an 80-to-443 redirect, and the port-80 rules come off.
- Session Manager works because of the role, not because of any open port: there is no SSH rule (no port 22) on the app instances at all. That is deliberate. If you can administer a box without exposing a port, do that.

## Status (2026-11-15)

Bucket created with versioning and public access block verified live. Instance profile `ec2-app-profile` exists. Role, launch template, ALB, and ASG re-run cleanly now that the three JSON files exist.
