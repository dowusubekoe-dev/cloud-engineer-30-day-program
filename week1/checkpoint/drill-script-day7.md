# Day 7 drill — cold re-answers

Two questions from earlier in the week, answered cold and recorded,
before looking at the reference answers below. Two takes each, no more.

## Question 1 (Day 1): "Design IAM for a 3-team company."

Answer out loud, record it, THEN compare with the reference.

### Reference (from week1/iam/drill-script-3-team-iam.md)
"If I am designing IAM for a company with three teams, I start with
accounts, not users. I put the company in AWS Organizations. Each team
gets its own account: Engineering, Data, and Operations. Then I add two
shared accounts nobody works in day to day: a Security account and a
Log Archive account. Separate accounts are the strongest isolation AWS
gives you. A mistake in the Data account cannot reach Production
resources in the Engineering account, because they are not in the same
account at all.

For people, nobody signs in to an account directly. Everyone signs in
once, through IAM Identity Center, with MFA enforced. From there they
assume a role into the account they need. Roles, not IAM users, and no
long-term access keys. If a key is never created, it can never leak.

Each team gets a role shaped to its job, and nothing more.

Engineering gets a deployment role. They can build and ship to their own
account: EC2, ECS, Lambda, and their own S3 buckets. They cannot touch
IAM, and they cannot reach into the Data account.

The Data team gets a role scoped to data services: S3, Glue, and Athena,
and only against the buckets and databases that belong to Data. They get
no compute in the Engineering account.

Operations is the broadest role, because they respond to incidents. They
can see across accounts and fix things. But even Operations does not get
standing full admin. Real admin sits behind a separate break-glass role
that requires MFA, sends an alert every time it is used, and is reviewed
after every incident.

Now the guardrails, because roles alone are not enough. Every role gets
a permission boundary: a ceiling on what that role can ever do, even if
someone later attaches a policy that grants too much. The boundary is
what stops a mistake from becoming a breach.

Above the accounts, I attach Service Control Policies to the whole
organization. Three denies, for everyone, including account admins.
Nobody can stop or delete CloudTrail, because that is our audit record.
Nobody can turn off encryption or schedule a KMS key for deletion.
And no account can leave the organization. An SCP grants nothing; it
only removes the actions nobody should ever take.

Finally, auditing. CloudTrail is an organization trail, and the logs go
to the Log Archive account, where none of the three teams can edit or
delete them. I turn on IAM Access Analyzer to flag anything shared
outside the organization, and I review access quarterly and remove what
is not being used, because unused permissions are just risk sitting
there.

So the design in one line: separate accounts for isolation, Identity
Center and roles for people, least privilege for each team, permission
boundaries as ceilings, SCPs as the floor nobody falls through, and all
logs landing somewhere the teams cannot touch."

Cold take notes (Q1): stumble / strong line / score vs reference:

## Question 2 (Day 2): "A private instance cannot reach S3. Walk me through your checks."

The five checks stay in this order: route table, endpoint, DNS,
security group egress, NACL.

### Reference (from week1/network/drill-script-private-instance-s3.md)
"If a private instance cannot reach S3, I do not guess. I walk the path
the traffic has to take, in order, and I stop at the first thing that
fails.

First, the route table. I check which route table the instance's subnet
is actually associated with, not the one I meant to associate. If that
association was never made, the subnet silently falls back to the main
route table, and that is the most common cause of this exact problem.
Then I read the routes. There has to be a path to S3: either the gateway
endpoint's prefix-list route, or a default route to a NAT gateway that
is actually available. No route, no traffic. Nothing else I check later
can fix a missing route.

Second, the endpoint. In my design the private subnets reach S3 through
a gateway VPC endpoint, so I check three things: the endpoint exists,
it is associated with this subnet's route table, and its endpoint policy
allows the bucket and the action the instance is trying to use. An
endpoint that exists but is not attached to this route table does
nothing, and a policy that names the wrong bucket looks exactly like a
network failure from the instance.

Third, DNS. I resolve the bucket name from the instance itself. S3 is a
name before it is a destination, so if DNS resolution is broken, or the
VPC's DNS settings are off, the connection fails before any packet is
routed. If the name does not resolve, I stop there and fix DNS.

Fourth, security group egress. I check the instance's security group
allows outbound traffic on port 443 toward S3. Security groups are
stateful, so the return traffic is allowed automatically; only the
outbound rule has to exist. A tightened egress rule is a quiet blocker,
because the instance was probably working until someone hardened it.

Fifth, and last, the network ACL on the subnet. NACLs are stateless,
so they have to allow the conversation in both directions: outbound on
443, and inbound return traffic on the ephemeral ports, 1024 to 65535.
This is the one people forget, because the request leaves fine and the
response dies at the subnet boundary.

So my order is route table, endpoint, DNS, security group egress, then
NACL, and I work it top to bottom without skipping, because each check
assumes the ones before it passed. In practice it is usually the first
one: a subnet associated with the wrong route table."

Cold take notes (Q2): stumble / strong line / score vs reference:
