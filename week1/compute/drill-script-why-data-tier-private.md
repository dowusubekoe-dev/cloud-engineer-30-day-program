# Drill script: "Why is the data tier in private subnets if the app needs updates?"
Read it out loud as written. About 2.5 minutes at a calm pace.
Pause where you see a line break. Do not rush the opening.

---

"Private does not mean cut off. It means one direction is missing: the
inbound one.

The data tier sits in private subnets because nothing on the internet
should ever be able to open a connection to my database. There is no
public IP on those instances and no route from the internet gateway to
those subnets, so an attacker scanning the internet cannot even address
the database, let alone attack it. The only thing allowed to talk to it
is the app tier, through a security group that accepts the database
ports from the app security group and nothing else.

But the app still needs to reach out: operating system updates, package
repositories, calls to AWS APIs. That is what the NAT gateway is for.
NAT is outbound only. A connection that starts inside the private
subnet goes out through the NAT, and the reply comes back, because NAT
tracks the connection it opened. A connection that starts on the
internet has no entry in that table, so it dies. Same pipe, one
direction.

And a lot of what the app needs is not on the internet at all. S3 is
reached through a gateway endpoint inside the VPC, so that traffic never
leaves the AWS network and never touches the NAT. Systems Manager works
the same way for patching and access, which is why I can manage these
instances with no SSH port open anywhere.

So the design in one line: private subnets remove the inbound path,
NAT and endpoints provide the outbound path, and updates were never a
reason to expose a database to the internet."

---

## After you record
- Save the recording next to this file and note the date.
- Listen once. Mark one sentence you stumbled on and one you liked.
- Re-record once if you want; two takes is the drill, not ten.
