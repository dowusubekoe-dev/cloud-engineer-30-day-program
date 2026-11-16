# Day 4 Screenshots: RDS and Data

Save PNGs in `week1/data/screenshots/` with the filenames below. Every shot must show the resource name or ID and its status; that is what makes it proof rather than decoration.

**Timing matters today:** shots 5 and 7 must be captured during the run, before you delete anything. The rest can be taken any time before teardown.

Standing pattern for every day (applies Days 1-30): (1) the resource exists, list or detail page with name/ID/status; (2) the day's key configuration close-up; (3) the security setting proof; (4) the test result; (5) the cost or budget view when the day creates billable resources.

1. `01-subnet-group.png` — RDS → Subnet groups → data-subnets: both data subnets and their AZs.
2. `02-primary-details.png` — RDS → Databases → app-db → Summary/Configuration: Multi-AZ **Yes**, storage encrypted, instance class db.t3.micro, engine PostgreSQL 15.19.
3. `03-primary-network.png` — app-db → Connectivity & security: the VPC, data security group sg-07a562a0cf5a8e3f2, and **Publicly accessible: No**. This is the day's security proof.
4. `04-replica.png` — RDS → Databases → app-db-rr: role Read replica, source app-db, status Available.
5. `05-failover-event.png` — RDS → Events (or app-db → Logs & events): the failover event after the forced reboot, showing the AZ change. **Capture during the run.**
6. `06-snapshot.png` — RDS → Snapshots: app-db-manual-1 with status Available.
7. `07-restored-instance.png` — RDS → Databases → app-db-restore-test while it exists during day4-restore-test.sh: status Available and its endpoint. **Capture before the script deletes it**; if you miss it, shots 5 and 6 plus the RDS Events page still evidence the restore.
8. `08-budget-check.png` — AWS Budgets → monthly-guard after teardown: the day's spend impact against the $10 budget.
