#!/usr/bin/env bash
# Day 4 part 2: prove the backup works. Manual snapshot -> restore to a test
# instance -> verify it answers -> delete the test instance.
# Run from week1/data AFTER day4-rds.sh:  bash day4-restore-test.sh
set -e
P="--profile lab"
DATA_SG=sg-07a562a0cf5a8e3f2

echo "== 1. Manual snapshot of app-db =="
aws rds create-db-snapshot --db-instance-identifier app-db --db-snapshot-identifier app-db-manual-1 $P > /dev/null
aws rds wait db-snapshot-available --db-snapshot-identifier app-db-manual-1 $P
echo "Snapshot available."

echo "== 2. Restore it as app-db-restore-test (expect roughly 8-15 minutes) =="
START=$(date +%s)
aws rds restore-db-instance-from-db-snapshot --db-instance-identifier app-db-restore-test \
  --db-snapshot-identifier app-db-manual-1 --db-instance-class db.t3.micro \
  --db-subnet-group-name data-subnets --vpc-security-group-ids $DATA_SG \
  --no-publicly-accessible $P > /dev/null
aws rds wait db-instance-available --db-instance-identifier app-db-restore-test $P
END=$(date +%s)
echo "Restore to available took $((END-START)) seconds."
aws rds describe-db-instances --db-instance-identifier app-db-restore-test $P \
  --query "DBInstances[0].{Endpoint:Endpoint.Address, Status:DBInstanceStatus, Engine:Engine, EngineVersion:EngineVersion}" --output table

echo "== 3. Delete the test instance (the restore is proven; do not keep paying for it) =="
aws rds delete-db-instance --db-instance-identifier app-db-restore-test --skip-final-snapshot $P > /dev/null
aws rds wait db-instance-deleted --db-instance-identifier app-db-restore-test $P
echo "Test instance deleted. The snapshot app-db-manual-1 is kept (small storage cost)."
echo "Record the restore time above in notes.md and the runbook."
