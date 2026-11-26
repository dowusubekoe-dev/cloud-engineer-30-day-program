# Day 2 Screenshots: VPC Networking

Save PNGs in `week1/network/screenshots/` with the filenames below. Every shot must show the resource name or ID and its status; that is what makes it proof rather than decoration.

Standing pattern for every day (applies Days 1-30): (1) the resource exists, list or detail page with name/ID/status; (2) the day's key configuration close-up; (3) the security setting proof; (4) the test result; (5) the cost or budget view when the day creates billable resources.

1. `01-vpc-detail.png` — VPC → Your VPCs → lab-vpc: VPC ID vpc-0318b57b8c085ac94 and IPv4 CIDR 10.20.0.0/16.
2. `02-subnets.png` — VPC → Subnets: all six subnets with names, CIDRs, and AZs in one list shot.
3. `03-route-table-public.png` — VPC → Route tables → w1-public-rt → Routes: 0.0.0.0/0 pointing at the internet gateway.
4. `04-route-table-private.png` — w1-app-rt (or w1-data-rt) → Routes: 0.0.0.0/0 pointing at the NAT gateway, plus the S3 prefix-list route from the endpoint.
5. `05-igw-attached.png` — VPC → Internet gateways: igw-07d2ac783c35bfe01 with state Attached and the VPC ID.
6. `06-nat-gateway.png` — VPC → NAT gateways: the NAT in w1-public-a, status Available, Elastic IP visible. (This is also the day's billable resource.)
7. `07-sg-app-inbound.png` — VPC → Security groups → w1-app-sg → Inbound rules: 443 sourced from w1-public-sg, no CIDR rules.
8. `08-sg-data-inbound.png` — w1-data-sg → Inbound rules: 5432 and 3306 sourced from w1-app-sg only.
9. `09-s3-endpoint.png` — VPC → Endpoints: the S3 gateway endpoint, its type, and the route tables it is attached to.
10. `10-flow-logs-active.png` — Your VPCs → lab-vpc → Flow logs tab: fl-0d62187ae88cfecef with status Active.

## Recapture note, 2026-11-26

Items 2, 3, 4, 5, 6, 7, and 9 were replaced on 2026-11-26 with landscape captures (1069 x 769, account ID masked) of the Terraform-built w1-vpc, which follows the same design as the original hand-built lab-vpc. Portrait originals are backed up at week1-portrait-backup-2026-11-26. Items 1 and 8 were recaptured in landscape on 2026-11-21. Item 10 was NOT replaced: the Terraform VPC has no flow log, so the original Day 2 portrait (flow log Active on lab-vpc) stays, and the missing flow log is recorded as a Terraform parity gap.
