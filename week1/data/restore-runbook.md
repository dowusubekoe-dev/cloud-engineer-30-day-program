# RDS Restore Runbook: app-db

Purpose: recover the Day 4 PostgreSQL database (`app-db`) from backup, two ways: from a snapshot, and by point-in-time recovery (PITR). A restore always creates a **new** instance with a **new endpoint**; RDS never restores over the top of the original. Plan for an application config change (new endpoint) as part of every restore.

## Before you start

- Know which failure you are solving. Instance/AZ failure with healthy data: Multi-AZ failover is faster and keeps the endpoint. Deleted or corrupted data: restore from backup, accepting data loss back to the snapshot or chosen point in time.
- Confirm the target: snapshot ID, or a timestamp inside the backup retention window (7 days on app-db). Check the latest restorable time first:
  `aws rds describe-db-instances --db-instance-identifier app-db --query "DBInstances[0].LatestRestorableTime" --profile lab`

## Path A: restore from the manual snapshot

1. `aws rds create-db-snapshot --db-instance-identifier app-db --db-snapshot-identifier app-db-manual-1 --profile lab` (skip if restoring an existing snapshot)
2. `aws rds wait db-snapshot-available --db-snapshot-identifier app-db-manual-1 --profile lab` — expect 2-5 minutes for a small database.
3. Restore, naming a NEW instance and re-specifying the network placement (restores do not inherit the subnet group or security group automatically):
   `aws rds restore-db-instance-from-db-snapshot --db-instance-identifier app-db-restored --db-snapshot-identifier app-db-manual-1 --db-instance-class db.t3.micro --db-subnet-group-name data-subnets --vpc-security-group-ids sg-07a562a0cf5a8e3f2 --no-publicly-accessible --profile lab`
4. `aws rds wait db-instance-available --db-instance-identifier app-db-restored --profile lab` — expect 8-15 minutes for 20 GB mostly empty.
5. Verify before calling it done: endpoint resolves, connect from an app-tier instance only (the data SG allows nothing else), engine version matches, and a known table or row count checks out.
6. Point the application at the new endpoint, then decide the original instance's fate. Delete the restored copy once it has served its purpose if this was a test.

`day4-restore-test.sh` runs exactly this path end to end and deletes its test instance at the end.

## Path B: point-in-time recovery

1. Pick the timestamp: the moment just before the bad change, in UTC, inside the retention window and after the earliest restorable time.
2. `aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier app-db --target-db-instance-identifier app-db-pitr --restore-time 2026-11-16T12:00:00Z --db-subnet-group-name data-subnets --vpc-security-group-ids sg-07a562a0cf5a8e3f2 --no-publicly-accessible --profile lab`
3. Wait for `available` (same 8-15 minute expectation), verify as in Path A step 5, then cut the application over to the new endpoint.
4. PITR granularity is the transaction log: you can land within about 5 minutes of any moment in the window. Anything written after the chosen timestamp is gone from the restored copy; if it matters, export it from the original before deleting anything.

## Expected timings (Day 4 lab scale, 20 GB, mostly empty)

| Step | Expected |
|---|---|
| Manual snapshot to available | 2-5 min |
| Restore (either path) to available | 8-15 min |
| Multi-AZ failover downtime | 60-120 sec |
| Read replica creation | 5-10 min |

Timings grow with data volume and snapshot size. A restore you have never tested is a hope, not a backup: this runbook exists because Day 4 actually ran the restore.

## Gotchas

- New endpoint every time. Anything with the old endpoint hard-coded breaks until updated.
- Restores do not copy tags, and the option/parameter groups default unless specified.
- A read replica is not a backup: it faithfully replicates a `DROP TABLE` too.
- Deleting the source instance does not delete manual snapshots; automated backups are deleted with the instance unless retained.
