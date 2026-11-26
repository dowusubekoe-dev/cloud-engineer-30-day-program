# 30-Day Cloud Engineer Plan — Update: Days 31–32, Serverless + Event-Driven Extension

**For Derek Owusu Bekoe · Added 2026-11-25 · Amends the 30-Day Cloud Engineer Program and the master execution guide**

This update extends the program by two days. It came out of a portfolio guide Derek added to the parked-projects folder on 2026-11-25: "5 AWS Projects To Get You Hired" by Lefteris Karageorgiou. Reviewed against the program day by day, three of the five projects needed nothing:

- **Three-Tier Web Application** is Week 1 (Days 2–4 built it, Day 6 rebuilt it in Terraform, Day 7 tests its HA and cost).
- **Containerized Microservices** is covered by PetClinic on EKS (bootcamp) and again by Week 3 (Days 15–21).
- **Static Website Hosting** (S3 + CloudFront + ACM + WAF) was considered and left out: its pieces already appear on Day 3 (S3 hardening) and Day 25 (secure file-upload design), and a half-day build can still ride along on Day 25 later if Derek wants the CloudFront talking point. It does not earn two program days.

The remaining two projects are a genuine gap. Nothing in Days 1–30 touches AWS Lambda, API Gateway, DynamoDB, Cognito, SNS, or SQS, and those services are standard Cloud Engineer interview ground. This update closes that gap the way Derek closed the DevOps project list: not as two separate tutorial projects, but as **one combined build in two days** — a serverless, event-driven version of the SmartLead lead intake he already runs locally.

1. **Day 31 — Serverless Application** (the guide's Project 3): API Gateway + Lambda + DynamoDB + Cognito, deployed with Terraform.
2. **Day 32 — Event-Driven Application** (the guide's Project 4): SNS fanout, SQS with a dead-letter queue, an idempotent consumer, each proven with a deliberate failure or duplicate.

Everything below uses resources Derek already has: the AWS lab account (428101261622), the Day 6 Terraform backend (S3 bucket `derek-lab-tfstate`, lock table `derek-lab-tflock`, profile `terraform`), the program repo, and SmartLead's existing lead contract. It follows the plan's Learn / Build / Prove it / Interview drill rhythm and the standing per-day package: prove-it artifacts, a word-for-word drill script, and a screenshots.md list in the day's folder.

**Cost and safety rules (unchanged from the plan, repeated because they decide the design):** billing alerts stay on; every service here is pay-per-use, so the two days should cost pennies, and the keep-or-destroy decision is recorded in the day's notes.md the same day, as on Day 6. SmartLead's real data stays local; this build uses marked test leads only. No real secret in code or in the repo; the Cognito test user is created for the drill and deleted at teardown or in the keep note.

---

## Placement and sequencing

- Days 31–32 run **after Day 30** (capstone published, mocks done) and **before** the post-program certification study begins. Days 1–30 are untouched.
- In the Focus System they take the next two program One Blocks after Day 30, on the normal Mon/Tue/Thu/Fri pattern. The Wednesday Security+ MCQ block is not touched.
- Program completion, for the Focus System phase gate and the job-fleet flip rule, now means **Day 32 complete**. The flip rule itself is unchanged: the fleet returns to Cloud-primary only when the program is complete AND the Security+ exam has been taken. Derek accepted the two-day extension when he approved this update on 2026-11-25.
- The certification sequence after the program is unchanged: AWS SAA first, then AZ-104, then Security+ in January 2027.
- The master execution guide (cloud-engineer-30-README.md) is not edited by this update. The fold-in happens when Days 31–32 are staged, in the same way the CHAOS-gaps update was folded into the Days 29–30 section.

---

## Day 31 — Serverless lead API

**Learn:** Lambda execution model and cold starts; API Gateway HTTP APIs versus REST APIs (cost, features, when each wins); DynamoDB single-table basics: partition keys, sort keys, GSIs, and why access patterns come before table design; Cognito user pools as a JWT issuer.

**Build (Terraform, new module set in the program repo at `week5/serverless/`, reusing the Day 6 backend):**

- **Data:** DynamoDB table `leads`, on-demand billing, partition key `lead_id` (String), and a GSI `email-index` on `email` so "find leads by email" is a query, not a scan.
- **Compute:** One Python 3.12 Lambda, `lead-api`, with routes for create and read. It speaks SmartLead's existing contract exactly: POST body `{name, email}` required (email validated), `{phone, source, service_interest}` optional; create returns 201 with the lead `id`. Validation failures return 400 with the error, mirroring the FastAPI behaviour.
- **API:** API Gateway HTTP API with `POST /leads` (public: it is a website form endpoint, protected by payload validation and an API-level throttle) and `GET /leads/{id}` plus `GET /leads` (protected by a Cognito JWT authorizer; the list read uses the GSI or a bounded scan, and the notes record which and why).
- **Identity:** Cognito user pool `lead-api-users` and one test user for the drill.
- **Permissions:** the Lambda execution role gets only `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query` on this table and its GSI, `sns:Publish` on the Day 32 topic (created today, wired tomorrow), and CloudWatch Logs write. No wildcard actions.
- **Publish on create:** after the DynamoDB write succeeds, the create handler publishes a `lead.created` event to the SNS topic `lead-events`. If the publish fails, the lead is still saved and the failure is logged; capture never blocks on notification (the same rule as the live n8n workflow).

**Prove it (in `week5/serverless/notes.md`):**

- curl transcript: POST a marked test lead, 201 with an id; the item visible in DynamoDB.
- Auth proof: GET without a token returns 401; GET with the test user's Cognito token returns the lead.
- Validation proof: POST with a bad email returns 400.
- Terraform outputs recorded: API URL, table name, user pool id.
- screenshots.md for the day, five-part pattern: DynamoDB item, Lambda configuration with its least-privilege role policy, API Gateway routes showing the authorizer on the GET routes only, Cognito pool, and the cost view (Cost Explorer filtered to the day's services, expected near zero).

**Drill:** "Lambda or containers for this API: when does serverless lose?" and "Walk me through your DynamoDB key design from the access patterns." Both answered from today's build, not from reading.

## Day 32 — Event-driven follow-up layer

**Learn:** SNS fanout versus point-to-point queues; SQS visibility timeout and redrive policy; at-least-once delivery and what it forces (idempotent consumers); standard versus FIFO queues and when ordering is worth paying for; DLQ triage as an operations skill.

**Build (Terraform, same `week5/serverless/` module set):**

- **Fanout:** SNS topic `lead-events` (from Day 31) gains two subscriptions: the SQS queue below, and an email subscription to dowusubekoe@gmail.com as the owner alert (Derek confirms the subscription once; this is the AWS-native twin of the n8n alert email already live).
- **Queue:** SQS standard queue `lead-followup` with a redrive policy to dead-letter queue `lead-followup-dlq`, `maxReceiveCount` 3.
- **Consumer:** Lambda `lead-followup-worker` triggered by the queue. For each `lead.created` event it writes one row to a second DynamoDB table, `lead-followups`, keyed on `lead_id`, with status `queued` and the event timestamp. That row is the follow-up task a human or a later automation works from; sending real email to leads is out of scope for the lab and is named as the production step (SES) in the notes.
- **Idempotency:** the write is conditional, `attribute_not_exists(lead_id)`. A duplicate delivery finds the row, logs `duplicate-suppressed` with the lead id, and succeeds without writing.
- **Deliberate failure:** the worker treats the marked poison address `test+poison@example.com` as a hard failure (raises before any write), so the DLQ proof below is deterministic.

**Prove it (three proofs, all in the day's notes.md):**

1. **Flow proof:** POST a marked test lead (Day 31 endpoint) and trace it end to end: SNS published, queue received, followup row present in `lead-followups`, alert email arrived.
2. **Idempotency proof:** publish the same `lead.created` event a second time by hand; the followups table still holds exactly one row for that lead, and the worker log shows `duplicate-suppressed`.
3. **DLQ proof:** POST a lead with the poison address; after three receives the message sits in `lead-followup-dlq`. Record the queue depths and the worker error from CloudWatch Logs.
- screenshots.md for the day: SNS topic with both subscriptions confirmed, SQS queues showing the DLQ depth at 1 after the proof, worker Lambda configuration, the `lead-followups` item, and the cost view.
- **Extension checkpoint (Prove it, once):** a short write-up in the repo, "Serverless SmartLead: what the AWS-native version changes" — cost shape at rest and under load, cold starts, the public-intake / authenticated-read split, and where the FastAPI on Container Apps version from Week 2 still wins. Plus the architecture diagram for the two days, in the style of the Week 1 diagram.

**Drill:** "Your DLQ is filling up at 2 AM. Walk me through it." and "SNS, SQS, or EventBridge: how do you choose?" The first is answered from today's proof, step by step.

---

## What this does not change

- Days 1–30 stand exactly as written, including the CHAOS-gaps update (Week 2 SmartLead on Azure, Week 3 FastAPI patterns, Week 4 Datadog, capstone on Days 29–30).
- The parked post-CKA queue is untouched: the Production DevOps Project still goes deeper than the guide's container project, and nothing in this update pulls any parked item forward.
- No schedule outside the program moves. Security+ MCQ Wednesdays, the January exam target, and the 600-question MCQ goal all stand.
- SmartLead itself is not modified. This build borrows its API contract only; the local app, its database, and the live n8n intake workflow stay as they are.

## The gap map, after this update

- Serverless (Lambda, API Gateway, DynamoDB, Cognito): closed by doing (Day 31), with least-privilege IAM and an auth split that has a stated reason.
- Event-driven design (SNS, SQS, DLQ, idempotency): closed by doing (Day 32), with the three proofs interviewers actually probe: fanout, duplicate handling, and poison-message triage.
- Remaining known gap from the guide's list: none of the five projects. Static hosting stays a deliberate half-day option on Day 25, Derek's call, not a gap in the plan.
