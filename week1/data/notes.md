# Day 4 Notes: RDS and Data

## Design

- DB subnet group `data-subnets`: subnet-07d372477d86687b6 (10.20.21.0/24, us-east-1a) and subnet-0bee8403720ad34ad (10.20.22.0/24, us-east-1b). RDS lives only in the data tier.
- Primary `app-db`: PostgreSQL 15.19 (latest 15.x verified 2026-11-16), db.t3.micro, 20 GB, Multi-AZ, storage encrypted, **not** publicly accessible, automated backups retained 7 days.
- Security group `sg-07a562a0cf5a8e3f2` (w1-data-sg): 5432 and 3306 accepted only from the app security group. There is no path from the internet, or from any other tier, to this database.
- Read replica `app-db-rr`: same class, for read scaling and as a promotable copy. A replica is **not** a backup and **not** automatic failover; Multi-AZ is the failover mechanism, backups are the recovery mechanism. Three different tools, three different jobs.
- Master username `appadmin`. The password comes from my password manager at run time; it is never written into any file or script.

## Cost note (read before running)

Multi-AZ roughly doubles the primary's instance cost, and the replica is a second instance: combined roughly **$0.05-0.06/hour, about $1.30/day**, against a $10 monthly budget. This day is a drill, not a deployment: run it, do the failover and restore tests, record the timings, and delete the replica and primary the same session. The manual snapshot can stay (pennies).

## What to record during the run

- Time for the primary to reach `available` (expect 5-10 minutes)
- Failover: the primary's AZ before and after, and the elapsed time the script prints (typical Multi-AZ failover downtime is 60-120 seconds; the script's number includes the reboot and wait, so it reads longer)
- Restore: seconds from `day4-restore-test.sh` (expect 8-15 minutes to available for a small, mostly empty database)

## Decisions

- Engine version pinned to 15.19 rather than the guide's bare "15", so the build is reproducible and the exact version is on record.
- The guide's commands ran the replica and failover immediately; RDS rejects operations on an instance that is still creating, so both scripts use `aws rds wait` between steps. README patched to match.
- Failover is tested with `reboot-db-instance --force-failover`, the deliberate, reversible way. Deleting the primary to "test" HA would test the restore path instead, which part 2 covers separately.
