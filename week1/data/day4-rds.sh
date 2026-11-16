#!/usr/bin/env bash
# Day 4 part 1: RDS subnet group, Multi-AZ Postgres primary, read replica, failover test.
# Run from week1/data:  bash day4-rds.sh
# The master password is never written down: set DB_MASTER_PASSWORD in the environment
# from your password manager, or the script prompts for it (input hidden).
set -e
P="--profile lab"
DATA_A=subnet-07d372477d86687b6   # 10.20.21.0/24 us-east-1a
DATA_B=subnet-0bee8403720ad34ad   # 10.20.22.0/24 us-east-1b
DATA_SG=sg-07a562a0cf5a8e3f2      # w1-data-sg (5432/3306 from w1-app-sg only)

if [ -z "$DB_MASTER_PASSWORD" ]; then
  read -s -p "Master password for appadmin (from your password manager): " DB_MASTER_PASSWORD
  echo
fi
if [ ${#DB_MASTER_PASSWORD} -lt 8 ]; then
  echo "Password too short (RDS needs 8+ characters). Stopping."
  exit 1
fi

echo "== 1. DB subnet group across both data subnets =="
aws rds create-db-subnet-group --db-subnet-group-name data-subnets \
  --db-subnet-group-description "Data tier" --subnet-ids $DATA_A $DATA_B $P

echo "== 2. Primary instance: Postgres 15.19, db.t3.micro, Multi-AZ, private, encrypted =="
echo "This takes roughly 5-10 minutes to become available."
aws rds create-db-instance --db-instance-identifier app-db --db-instance-class db.t3.micro \
  --engine postgres --engine-version 15.19 --master-username appadmin \
  --master-user-password "$DB_MASTER_PASSWORD" --allocated-storage 20 \
  --db-subnet-group-name data-subnets --vpc-security-group-ids $DATA_SG \
  --multi-az --backup-retention-period 7 --storage-encrypted --no-publicly-accessible $P > /dev/null
aws rds wait db-instance-available --db-instance-identifier app-db $P
echo "app-db is available."

echo "== 3. Read replica =="
aws rds create-db-instance-read-replica --db-instance-identifier app-db-rr \
  --source-db-instance-identifier app-db $P > /dev/null
aws rds wait db-instance-available --db-instance-identifier app-db-rr $P
echo "app-db-rr is available."

echo "== Endpoints =="
aws rds describe-db-instances $P --query "DBInstances[?starts_with(DBInstanceIdentifier, 'app-db')].{DB:DBInstanceIdentifier, Endpoint:Endpoint.Address, AZ:AvailabilityZone, MultiAZ:MultiAZ}" --output table

echo "== 4. Failover test (timed): reboot with forced failover =="
echo "Watch the primary's AZ flip. Typical RDS Multi-AZ failover: 60-120 seconds of downtime."
START=$(date +%s)
aws rds reboot-db-instance --db-instance-identifier app-db --force-failover $P > /dev/null
aws rds wait db-instance-available --db-instance-identifier app-db $P
END=$(date +%s)
echo "Failover sequence completed in $((END-START)) seconds (includes reboot + availability wait)."
aws rds describe-db-instances --db-instance-identifier app-db $P --query "DBInstances[0].{AZ:AvailabilityZone, MultiAZ:MultiAZ, Status:DBInstanceStatus}" --output table

echo ""
echo "== Day 4 part 1 complete =="
echo "COST NOTE: Multi-AZ primary + replica bill roughly \$0.05-0.06/hr combined (~\$1.30/day)"
echo "against your \$10 budget. Do the restore test (day4-restore-test.sh), then delete both:"
echo "  aws rds delete-db-instance --db-instance-identifier app-db-rr --skip-final-snapshot --profile lab"
echo "  aws rds delete-db-instance --db-instance-identifier app-db --skip-final-snapshot --profile lab"
unset DB_MASTER_PASSWORD
