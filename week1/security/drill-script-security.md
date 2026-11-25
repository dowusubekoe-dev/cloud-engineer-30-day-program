# Day 5 drill script - Security and compliance

Word-for-word read-aloud script, in the Day 1 and Day 2 format. Read it
exactly as written for the recording; the bracketed lines are stage
directions, not spoken.

## Read-aloud instructions

- Record on your phone, one take per question, in week1/security/.
- Speak the answer as if an interviewer just asked it. No reading the
  notes.md file; this script is the practice, not the exam.
- If you stall, stop the take and restart that question only.
- The Veolia story in Question 1 must state only what your resume
  supports. No invented percentages.

## Question 1: "Tell me about a time you caught a security issue early."

"Situation: at Veolia I supported a customer-data platform, the
metering and revenue applications, where a misconfiguration could
expose customer data before anyone noticed. Task: my job was to catch
misconfigurations and suspicious activity early, not after an
incident. Action: I worked the detection loop: GuardDuty for
threat intelligence and behaviour signals, AWS Config for
configuration drift against rules, Inspector for known
vulnerabilities, and log review across the applications for root
cause. When something flagged, I triaged it, fixed what was in my
scope with least-privilege changes, and escalated the rest through
ServiceNow to the infrastructure team with a clear business
communication. Result: issues were caught as findings and fixed as
routine work instead of becoming incidents, and I can walk through
the same loop today because I just rebuilt it in my own lab: I
created a security group open to the world on purpose, watched
Config flag it, traced the change in CloudTrail, deleted it, and
verified the rule went back to compliant."

## Question 2: "GuardDuty vs Config vs Inspector: a finding arrives, which tool made it?"

"I sort by signal. GuardDuty is behaviour and threat intelligence:
malicious or unusual activity, like an instance talking to a known
bad address or credentials being used from somewhere impossible.
Config is configuration state: what a resource looks like right now
and whether it matches a rule, like a bucket allowing public read or
a security group opening a restricted port. Inspector is known
vulnerabilities: CVE scanning of instances and images, telling you
which patch you are missing. Same incident can light up all three,
but the first question is always which signal fired, because that
tells you whether you are hunting an actor, fixing a setting, or
patching a host. Security Hub is not a fourth detector; it is the
aggregator that collects all three into one queue and one score."

## Question 3: "An S3 bucket with customer data is found public. Your first hour?"

"First, contain: turn on account-level and bucket-level Block Public
Access and remove the public policy, because every minute public is
more exposure. Second, preserve evidence before I change anything
else: CloudTrail history for who made it public and when, access
logs and version history to see what was read or changed. Third,
assess exposure: how long it was public and whether the logs show
access from outside. Fourth, notify per policy: the security and
business owners get the facts I have verified, not speculation.
Fifth, remediate fully and verify: re-run the Config rule
s3-bucket-public-read-prohibited and confirm compliant. Then
prevention, so it cannot quietly recur: Block Public Access at the
account level, the Config rule evaluating continuously, and an alert
on high-severity findings. Contain first, evidence second, and I do
not delete logs or the bucket in a panic, because that destroys the
record of what actually happened."

## After you record

- [ ] All three takes saved in week1/security/
- [ ] notes.md Prove-it checklist ticked from the actual run
- [ ] finding-note.md filled with measured times, not expectations
- [ ] Security Hub starting score recorded for the Day 7 comparison
