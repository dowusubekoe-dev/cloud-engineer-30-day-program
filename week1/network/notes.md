# Day 2 Notes: VPC Networking

## What was built

VPC `vpc-0318b57b8c085ac94` (Name: lab-vpc), 10.20.0.0/16, us-east-1.

| Tier | Subnet | CIDR | AZ | Subnet ID |
|------|--------|------|----|-----------|
| Public | w1-public-a | 10.20.1.0/24 | us-east-1a | subnet-0937b3f3bac28d475 |
| Public | w1-public-b | 10.20.2.0/24 | us-east-1b | subnet-06ae6b4b3948ee6c8 |
| App | w1-app-a | 10.20.11.0/24 | us-east-1a | subnet-00a122ab6e0dd98b6 |
| App | w1-app-b | 10.20.12.0/24 | us-east-1b | subnet-0d1c54470bab5f591 |
| Data | w1-data-a | 10.20.21.0/24 | us-east-1a | subnet-07d372477d86687b6 |
| Data | w1-data-b | 10.20.22.0/24 | us-east-1b | subnet-0bee8403720ad34ad |

Internet gateway `igw-07d2ac783c35bfe01` attached to the VPC. Public subnets set to auto-assign public IPs; app and data subnets are private (no public IPs, no IGW route).
Flow logs: `fl-0d62187ae88cfecef`, ALL traffic, to CloudWatch Logs group `/vpc/flowlogs` using IAM role `w1-flowlogs-role`. Status ACTIVE.

Routing design (applied by `day2-part2.sh`): public route table sends 0.0.0.0/0 to the IGW; app and data route tables send 0.0.0.0/0 to the NAT gateway. The data tier has no direct internet route back: NAT only forwards traffic for connections the inside started, so the data tier can reach out but the internet cannot reach in.

## NAT cost trade-off: one NAT vs one per AZ

This build uses **one NAT gateway** in public-a for both AZs.

- Cost of one NAT: about $0.045/hour (roughly $32/month) plus $0.045 per GB processed. One per AZ doubles the hourly cost.
- Risk accepted: the NAT lives in us-east-1a. If that AZ fails, private subnets in us-east-1b also lose internet egress, even though they are healthy. Cross-AZ traffic to the NAT also incurs small cross-AZ data charges.
- Production pattern: one NAT per AZ, each AZ's private route table pointing at its own AZ's NAT. Pay double, remove the cross-AZ dependency.
- Verdict for this lab: one NAT is the right call. The dependency is understood and documented, and the saving matters more than AZ-independent egress for a training build. This is the exact trade-off to name in an interview: state the failure mode you accepted and what it would cost to remove it.

## Security groups vs NACLs

| | Security group | Network ACL (NACL) |
|---|---|---|
| Scope | Attached to an instance's ENI | Attached to a subnet, covers everything in it |
| State | **Stateful**: return traffic is allowed automatically | **Stateless**: return traffic must be allowed explicitly (including ephemeral ports) |
| Rules | Allow rules only; anything not allowed is denied | Allow **and** deny rules; deny is how you block a specific bad source |
| Evaluation | All rules considered together | Rules evaluated in number order, first match wins |
| Default | New SG denies all inbound, allows all outbound | Default NACL allows everything in and out; a custom NACL denies everything until you add rules |
| Typical job | The primary firewall for instances: least-privilege, chained by SG reference | A coarse second layer at the subnet edge: guardrails and explicit blocks |

**How this build uses them:** security groups do the real work. They are chained by reference: `w1-app-sg` accepts 443 only from `w1-public-sg`, and `w1-data-sg` accepts 5432/3306 only from `w1-app-sg`. Because the reference is to the group, not an IP range, the rule stays correct when instances are replaced or scaled. The default NACL is left in place as the subnet-level backstop. Rule of thumb: reach for SGs first (stateful, per-instance, least privilege); add NACL rules when you need an explicit deny or a subnet-wide guardrail, and remember NACLs are stateless, so a blocked ephemeral port range is a classic self-inflicted outage.

## Drill: "A private instance cannot reach S3. Walk me through your checks."

In this order:

1. **Route table.** Is the instance's subnet associated with the route table I think it is? Does that table have a working path to S3: either the gateway endpoint's prefix-list route (`pl-...` -> `vpce-...`) or a 0.0.0.0/0 route to a healthy NAT? A subnet silently falls back to the main route table if its association was never made, which is the most common cause.
2. **Endpoint.** Does the S3 gateway endpoint exist, is it attached to this route table, and does its endpoint policy allow the bucket and action? An endpoint that exists but is not associated with this subnet's route table does nothing.
3. **DNS.** Does the bucket name resolve from the instance (`nslookup` / `dig`)? With VPC DNS resolution and DNS hostnames enabled, S3 names resolve to the endpoint path. If DNS is broken or the instance points at a wrong resolver, nothing downstream matters.
4. **Security group egress.** Does the instance's security group allow outbound 443 to S3 (to the S3 prefix list or 0.0.0.0/0)? Security groups are stateful, so only the outbound side needs the rule; a tightened egress is a frequent silent blocker.
5. **NACL.** Do the subnet NACLs allow the traffic **both ways**? NACLs are stateless: outbound 443 must be allowed, and the return traffic on ephemeral ports (1024-65535) must be allowed inbound, or the response dies at the subnet edge.