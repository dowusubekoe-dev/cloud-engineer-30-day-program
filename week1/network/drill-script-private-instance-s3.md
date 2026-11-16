# Drill script: "A private instance cannot reach S3. Walk me through your checks."
Read it out loud as written. About 3 minutes at a calm pace.
Pause where you see a line break. The five checks stay in this order:
route table, endpoint, DNS, security group egress, NACL.

---

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

---

## After you record
- Save the recording next to this file and note the date.
- Listen once. Mark one sentence you stumbled on and one you liked.
- Re-record once if you want; two takes is the drill, not ten.
