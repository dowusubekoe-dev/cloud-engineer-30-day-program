# Drill script: "Design IAM for a 3-team company"
Read it out loud as written. About 3.5 minutes at a calm pace.
Pause where you see a line break. Do not rush the opening.

---

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

---

## After you record
- Save the recording next to this file and note the date.
- Listen once. Mark one sentence you stumbled on and one you liked.
- Re-record once if you want; two takes is the drill, not ten.
