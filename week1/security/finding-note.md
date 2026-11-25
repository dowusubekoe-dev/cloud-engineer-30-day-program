# Day 5 finding note (the Prove-it artifact)

Half a page, incident format, from the Week 1 guide. I filled it
from the actual run on 2026-11-23. The Week 1 checkpoint names this
note, alongside the architecture diagram, as what I show in
interviews.

**What was found**
Security group w1-bad-sg (sg-02873315ed049e15b) in VPC
vpc-0318b57b8c085ac94 allowed inbound SSH (port 22) from 0.0.0.0/0,
i.e. the entire internet. I created it deliberately on Day 5 as a
controlled test of the detection loop, and it was attached to no
network interfaces, so nothing in the lab was actually reachable
through it. I created a throwaway bucket alongside it,
derek-lab-bad-public-428101261622.

**How it was detected**
AWS Config rule restricted-common-ports evaluated the group as
NON_COMPLIANT, and the same evaluation is reflected in Security
Hub, where the account's starting overall score was 8 percent.
CloudTrail Event History traced the group's creation to a
CreateSecurityGroup event on 2026-11-19 at 05:25:33 ET, principal
derek-admin, source IP 65.34.64.90 (event ID
3fd67e91-0359-4b19-9362-747305b0375a), confirming the change was
the deliberate lab action and not an unknown actor.

**Risk**
Unrestricted SSH on a public-reachable instance is a brute-force
and credential-stuffing entry point; in a production account this
is a high-severity misconfiguration even with key-only auth. In
this lab the group was attached to nothing, so the realized
exposure was zero; the exercise tests the pattern, not a live
host.

**Remediation**
I deleted the security group in the console on 2026-11-23 (it was
attached to nothing; had it been attached, I would have replaced
the rule in place, not deleted the group). I deleted the throwaway
bucket in the same session. The bucket's Block Public Access had
held throughout: Config showed it COMPLIANT, so it never allowed a
public read.

**How the fix was verified**
I verified by CLI after deletion: describe-security-groups returns
NotFound for sg-02873315ed049e15b and HeadBucket returns 404 for
the bucket (verified about 14:35 ET). I re-evaluated the Config
rule on demand. Config's entry for the deleted group lagged for several
hours (deletion-processing lag), but at the final re-check before
lab-off on 2026-11-23 the group no longer appeared in the rule's
NON_COMPLIANT results; only the two out-of-lab groups remained.

**Prevention**
What I built: the Config rule restricted-common-ports evaluates
continuously, so a recurrence is flagged without anyone watching
the console, and an EventBridge rule
(day5-config-noncompliant-alert) now writes an event to a
CloudWatch Logs group whenever any of the five lab rules reports
NON_COMPLIANT. Design-only, not built: an SCP denying
ec2:AuthorizeSecurityGroupIngress with 0.0.0.0/0 on sensitive
ports, and Security Hub high-severity findings routed to email
via EventBridge and SNS. Follow-ups from the same evaluation: the
rule also flagged ad-groceries-backend-sg (a real port-22 exposure
in a separate project, to be fixed outside Day 5) and ctf_sg
(open by design for CTF work, no action).
