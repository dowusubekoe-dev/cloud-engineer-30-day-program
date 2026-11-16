# Day 2 Network Diagram: w1-vpc (lab-vpc)

VPC `vpc-0318b57b8c085ac94` · CIDR 10.20.0.0/16 · Region us-east-1 · Built 2026-11-15
Flow logs: `fl-0d62187ae88cfecef` (ALL traffic) to CloudWatch Logs `/vpc/flowlogs`, via IAM role `w1-flowlogs-role`

```
                              Internet
                                  |
                    +-------------+--------------+
                    |  IGW igw-07d2ac783c35bfe01 |
                    +-------------+--------------+
                                  |
        +-------------------------+-------------------------+
        |              VPC 10.20.0.0/16                     |
        |                                                   |
        |   us-east-1a                    us-east-1b        |
        |  +----------------+            +----------------+ |
        |  | PUBLIC         |            | PUBLIC         | |
        |  | 10.20.1.0/24   |            | 10.20.2.0/24   | |
        |  | subnet-0937... |            | subnet-06ae... | |
        |  | [NAT gateway]  |            |                | |
        |  +-------+--------+            +----------------+ |
        |          | NAT (egress only)                      |
        |  +-------+-----------------------------+          |
        |  | APP                                 |          |
        |  | 10.20.11.0/24 (1a) subnet-00a1...   |          |
        |  | 10.20.12.0/24 (1b) subnet-0d1c...   |          |
        |  +-------+-----------------------------+          |
        |          | 5432 / 3306, app SG only               |
        |  +-------+-----------------------------+          |
        |  | DATA                                |          |
        |  | 10.20.21.0/24 (1a) subnet-07d3...   |          |
        |  | 10.20.22.0/24 (1b) subnet-0bee...   |          |
        |  +-------------------------------------+          |
        |                                                   |
        |   S3 Gateway Endpoint (vpce, part 2)              |
        |   attached to app + data route tables             |
        +---------------------------------------------------+
                                  |
                          Amazon S3 (AWS backbone,
                          no NAT data charges)
```

## Traffic flow

- **Inbound:** Internet -> IGW -> public tier only. App and data tiers have no route from the IGW and no public IPs, so nothing on the internet can initiate a connection to them.
- **Outbound from private tiers:** app/data -> NAT gateway (in public-a) -> IGW -> internet. NAT is outbound-only; return traffic for established connections is allowed, new inbound connections are not.
- **To S3:** app/data route tables carry the S3 gateway endpoint prefix list, so S3 traffic stays on the AWS backbone and never touches the NAT (no NAT data-processing charge for it).
- **Tier to tier:** app accepts 443 only from the public security group; data accepts 5432/3306 only from the app security group. Security groups are chained by reference, not by IP.

## Build status (2026-11-15)

Live now: VPC, six subnets, IGW attached, public IPs on the public subnets, flow logs ACTIVE.
Scripted in `day2-part2.sh`, not yet run: NAT gateway, per-tier route tables, per-tier security groups, S3 gateway endpoint.
