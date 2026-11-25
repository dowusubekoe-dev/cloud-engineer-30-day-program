# Day 6 drill script - Terraform rebuild

Word-for-word read-aloud script, in the Day 1 and Day 2 format. Read
it exactly as written for the recording; the bracketed lines are
stage directions, not spoken.

## Read-aloud instructions

- Record on your phone, one take per question, in week1/terraform/.
- Speak the answer as if an interviewer just asked it. No reading
  the notes.md file; this script is the practice, not the exam.
- If you stall, stop the take and restart that question only.
- State only what the run actually did: if you took the import
  path, Question 1 is your story; if greenfield, say so plainly
  and use the teardown version in brackets.

## Question 1: "Have you ever brought existing infrastructure under Terraform?"

"Situation: my Week 1 lab stack, a VPC, load balancer, auto scaling
group, and database tier, was built by hand and by script first,
the way a lot of real environments start. Task: get it under
Terraform management without downtime theatre and without lying
about what the state file held. Action: I bootstrapped remote
state first, an S3 bucket with versioning and encryption and a
DynamoDB lock table, created outside Terraform because the backend
cannot create itself. Then I wrote three modules, network, compute,
and data, matching the tiers I had built. [Import path:] I imported
each live resource by its real ID, then ran plan again and again,
fixing the configuration until the plan showed only the changes I
actually intended, including recreating a NAT gateway I had
deleted earlier to cut cost. [Greenfield path:] I recorded every
resource ID, tore the manual stack down in dependency order, and
let Terraform create the replacement stack from a clean state.
Result: the same architecture, now reproducible from code, with a
plan I can read before anything changes and a destroy that I have
actually rehearsed, not just assumed."

## Question 2: "Why remote state, and why locking?"

"Local state makes Terraform a one-laptop tool: lose the file and
you have lost the map between your code and reality. Remote state
in S3 means the state survives the machine, versioning gives me
history when a run goes wrong, and encryption is on because state
files contain resource details in plain text. Locking matters the
moment two runs can overlap: without the DynamoDB lock, two applies
can read the same state, make different plans, and corrupt each
other's work. The lock makes the second run wait and fail loudly
instead of silently overwriting. Bootstrap order matters too: the
bucket and table exist before init, created by a small checked
script, never by the configuration that will store state in them."

## Question 3: "A terraform plan wants to destroy something you did not expect. What do you do?"

"I stop. I do not apply and hope. First I read the exact resource
and attribute forcing replacement, because some changes, like a new
launch template version or a subnet change, force recreation by
design, and the plan says so if you read it. Second, I check
whether it is drift: did someone change the resource outside
Terraform, did I import it with a configuration that does not match
reality, or is my code simply wrong. Third, I fix the cause in
code, or use targeted state commands if the state, not the
resource, is the problem, and I plan again until the destroy list
is either empty or every line on it is one I can explain out loud.
An unexplained destroy in a plan is the tool doing its job; the
failure would be applying anyway."

## After you record

- [ ] All three takes saved in week1/terraform/
- [ ] notes.md Prove-it checklist ticked from the actual run
- [ ] Path A or B decision and the data-module choice recorded in
      notes.md in my own words
- [ ] Cost decision for the recreated NAT gateway recorded the
      same day (destroy rehearsed, or lab-off with reason)
