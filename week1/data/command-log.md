# Day 4 Command Log

All commands run with `--profile lab` (account 428101261622, us-east-1) from `week1/data/`.
Status: scripts written and syntax-checked 2026-11-16; I ran BOTH parts on 2026-11-16 and verified them live on 2026-11-17 from RDS events and CloudTrail. Failover: Multi-AZ failover started 08:00:49 EST, completed 08:01:39 EST (about 50 seconds). Restore test: snapshot app-db-manual-1 created 08:11 EST, restore called 08:13 EST, restored instance backup finished 08:20 EST, test instance deleted 08:22 EST. Restore test COMPLETE; do not rerun the script as-is (the snapshot name already exists and step 1 will fail).

## Part 1: subnet group, primary, replica, failover

Scripted in full in `day4-rds.sh`. Run with:

```bash
bash day4-rds.sh
```

It creates: DB subnet group `data-subnets` (subnet-07d372477d86687b6, subnet-0bee8403720ad34ad); primary `app-db` (PostgreSQL 15.19, db.t3.micro, Multi-AZ, encrypted, private, SG sg-07a562a0cf5a8e3f2, 7-day backups); read replica `app-db-rr`; then a timed `reboot-db-instance --force-failover`. The master password is prompted for (hidden) or read from `$DB_MASTER_PASSWORD`; it appears in no file.

Record after the run: primary endpoint ______ · replica endpoint ______ · AZ before ______ · AZ after ______ · failover elapsed ______ sec.

## Part 2: snapshot restore test

Scripted in full in `day4-restore-test.sh`. Run with:

```bash
bash day4-restore-test.sh
```

It creates snapshot `app-db-manual-1`, restores it as `app-db-restore-test`, verifies it reaches `available`, prints the restore time, and deletes the test instance.

Record after the run: restore elapsed ______ sec. (Run 2026-11-16: about 7 minutes from the restore call to available, per RDS event timestamps; the test instance was then deleted, and snapshot app-db-manual-1 is kept.)

## Teardown (2026-11-17)

I deleted the replica app-db-rr and the Multi-AZ primary app-db on 2026-11-17 (skip-final-snapshot) and verified them gone live: 0 RDS instances remain, so the ~$1.30/day charge has stopped. Kept on purpose: manual snapshot app-db-manual-1 (available; the restore proof and a recovery point, pennies) and the data-subnets subnet group (free). Recreate with day4-rds.sh when a later day needs a database.
