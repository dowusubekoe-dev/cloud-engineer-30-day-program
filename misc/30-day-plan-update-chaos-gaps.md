# 30-Day Cloud Engineer Plan — Update: Closing the Platform-Engineering Gaps

**For Derek Owusu Bekoe · Added 2026-11-14 · Amends the 30-Day Cloud Engineer Program and the Weeks 2–4 Detailed Guide**

This update retargets parts of Weeks 2, 3, and 4 and the capstone. It came out of a real job description: Senior Cloud Infrastructure Engineer (Azure / Terraform) at CHAOS Industries, reviewed on 2026-11-14. That posting is representative of senior platform roles, and it exposed five specific gaps in an otherwise strong profile:

1. **Azure Container Apps** named as the container platform (your production containers are EKS and ECS).
2. **Terraform on Azure** as the primary IaC path (your production Terraform is AWS-first; your Azure depth is bootcamp projects and ARM).
3. **Owning production FastAPI services and their data layer** (PostgreSQL, Redis, caching, connection pooling, behavior under load). Your resume shows Python as scripting; your FastAPI work lives in SmartLead and is not yet production-shaped.
4. **Datadog** as the observability platform (yours is CloudWatch, Azure Monitor, and Splunk).
5. **A scaling story**: the posting asks for someone who "scaled a production system well beyond its original design and fixed what broke." Your Auto Scaling experience is bootcamp-level.

Everything below uses resources you already have: SmartLead, your Azure and AWS accounts, your GitHub, and the plan's existing Learn / Build / Prove it / Interview drill rhythm. Nothing here adds days to the program. It changes what some Build blocks produce.

**Cost and safety rules (unchanged from the plan, repeated because Azure is involved):** billing alerts on before Day 8, tear down Azure resources the same day unless a step says otherwise, and never put a real secret in code or in the repo. SmartLead's real data stays local; the Azure deployment uses seed or test data only.

---

## Week 2 (Days 8–14) — Azure + IaC: the checkpoint changes

**Old checkpoint:** the Week 1 design rebuilt in Azure terms, plus a reusable Terraform module with remote state.

**New checkpoint:** SmartLead running on Azure Container Apps, deployed by Terraform (azurerm) from a GitHub repo, with a VNet, private endpoints, Key Vault secrets delivered by managed identity, and a scaling write-up started. The reusable Terraform module and remote state requirements stay; they now describe this deployment.

### Day 8 — Azure fluency refresh, aimed at the deployment
- **Learn:** Microsoft Learn AZ-104 refresh on VNets, private endpoints, and Azure Container Apps concepts. Skim the Container Apps documentation: environments, ingress, revisions, scale rules.
- **Build:** Create the project repo `smartlead-on-azure`. Set up Terraform with the azurerm provider and remote state in an Azure Storage account (state locking on). Confirm billing alerts are active on the subscription.
- **Prove it:** Repo with a working `terraform plan` against an empty resource group.
- **Drill:** "Walk me through VNet design for a three-tier app on Azure," using your bootcamp three-tier project as the base.

### Day 9 — Network first
- **Learn:** Container Apps VNet integration and Azure Private DNS zones.
- **Build:** Terraform the network: VNet, subnets (infrastructure, private endpoints, app), NSGs, Private DNS. Deploy the Container Apps environment into the VNet in internal mode if your test setup allows, or external with restricted ingress, and note the trade-off in the repo.
- **Prove it:** Network diagram added to the repo (extend your bootcamp three-tier diagram).
- **Drill:** "How do private endpoints change how an app talks to its database?"

### Day 10 — SmartLead onto Container Apps
- **Learn:** Container Apps revisions, ingress, and environment variables versus secrets.
- **Build:** Containerize SmartLead's FastAPI app (it already runs in Docker locally). Push the image to Azure Container Registry and deploy it to Container Apps with Terraform. The app still uses its SQLite data layer today; that changes on Day 12.
- **Prove it:** A running revision URL and a screenshot or CLI output in the repo.
- **Drill:** "Container Apps, AKS, or ECS: how do you choose?" Answer from this deployment, not from reading.

### Day 11 — Identity and secrets, the Azure way
- **Learn:** Managed identities, Key Vault access models (RBAC versus access policies), Azure Policy basics.
- **Build:** Give the Container App a system-assigned managed identity. Move every app secret into Key Vault and have the app read them through the identity. Remove secrets from environment configuration in the repo. Assign one Azure Policy (for example, deny public IP creation or require tags) to the resource group and show it evaluating.
- **Prove it:** A short repo note: "Secrets handling" — what moved, what the identity can and cannot read.
- **Drill:** "How do you keep secrets out of code in Azure?" This is now a story, not a definition.

### Day 12 — A real data layer
- **Learn:** Azure Database for PostgreSQL Flexible Server basics, connection pooling (PgBouncer concepts), Redis cache patterns (cache-aside).
- **Build:** Migrate SmartLead from SQLite to Azure Database for PostgreSQL using its existing Alembic migrations. Add Azure Cache for Redis (or a containerized Redis if cost is a concern, and note the substitution) as a cache for the app's hottest read path. Configure the connection pool deliberately and write down the numbers you chose and why.
- **Prove it:** Migration output plus a before/after note on the endpoint you cached.
- **Drill:** "What happens to a FastAPI service under load when the database connection pool is too small?"

### Day 13 — Pipeline and scale rules
- **Learn:** Container Apps scaling: HTTP scaling, CPU/memory rules, and KEDA concepts. Review your Week 1 Day 3 Auto Scaling Group notes for the AWS parallel.
- **Build:** GitHub Actions pipeline that builds the image, pushes to ACR, and updates the Container App revision on merge (the same pattern as your Veolia pipelines, Azure target). Add scale rules: min replicas 0 or 1, max replicas set by your load test on Day 14, HTTP concurrency threshold explicit.
- **Prove it:** A pipeline run link and the scale rule configuration in Terraform.
- **Drill:** "Tell me about a time you scaled a system." You are building the honest project version of this answer today and tomorrow.

### Day 14 — Load test, break it, checkpoint
- **Build:** Load-test the deployment (locust or k6) at increasing concurrency. Record where it degrades: app CPU, database connections, Redis hit rate, cold starts. Change one thing (pool size, scale rule, cache coverage), retest, and record the difference.
- **Prove it (Week 2 checkpoint):** The repo now holds the Terraform module with remote state, the network diagram, the secrets note, the pipeline, and **Scaling Write-Up v1**: what broke under load, what you changed, what the numbers did. This write-up is an interview artifact, written in your own words.
- **Drill:** Deliver the scaling story out loud in two minutes. Record it on your phone.

---

## Week 3 (Days 15–21) — Kubernetes, containers, CI/CD: two additions

The week's existing work stands (your 3-node lab, EKS/AKS, GitOps step). Add:

1. **FastAPI production patterns (one Build block, Day 17 or 18).** Make SmartLead's API async where it does I/O, confirm connection pooling under the Day 14 load profile, and add graceful degradation: when Redis is down, the app falls back to the database and stays up. Write three sentences in the scaling write-up on consistency, caching, and back-pressure in this app. These are the distributed-systems words the posting lists; use them only where the app actually demonstrates them.
2. **The comparison note (Prove it, once this week).** One page: Container Apps versus AKS versus ECS for a small production API — cost shape, operational burden, scaling model, when each wins. Written from having now run all three styles (ECS and EKS at Veolia, Container Apps and AKS here).

## Week 4 (Days 22–28) — Observability: Datadog joins the stack

The week's incident and design work stands. Add Datadog against the SmartLead-on-Azure deployment:

- **Day 22 or 23 Build:** Start a Datadog trial and instrument the Container Apps deployment (logs and metrics first; APM if the trial and time allow). Build one dashboard: request rate, latency percentiles, error rate, replica count, database connections.
- **Alerts:** Create two alerts that would wake you up for a real reason (error rate and p95 latency), with a short note on why those thresholds.
- **Incident exercise:** Run the week's incident drill against this stack. Break something on purpose (kill the Redis cache, or set the pool to 1) and run your incident process with Datadog as the tool. The post-incident review the week already requires is written from this exercise.
- **Drill:** "Your dashboard shows p95 latency doubling while error rate stays flat. What do you check first?" You have now lived a version of this on Day 14.

## Days 29–30 — Capstone: use the project you already built

**Old capstone:** a new public GitHub project proving the whole stack.

**New capstone:** SmartLead-on-Azure **is** the capstone. Days 29–30 become finish-and-present work:

- README with the architecture diagram, the design decisions, and the trade-offs.
- Scaling Write-Up final version (from Day 14, updated with Week 3 and 4 findings).
- The comparison note (Container Apps / AKS / ECS) included.
- Two mock interviews, as planned, with at least three answers drawn from this project: the scaling story, the secrets story, and the incident story.

## What this does not change

- Week 1 (AWS reactivation) is untouched. It is your home ground and the AWS SAA renewal path after Day 30 still stands, then AZ-104, then Security+ in January 2027.
- The posting's nice-to-haves stay out of scope for these 30 days: TimescaleDB, streaming systems (WebSockets, pub/sub), and federal frameworks (FedRAMP, CMMC, NIST). They are not worth your hours yet.
- In your Focus System, the Wednesday One Block follows the plan week by week, so these projects are what Wednesdays build. If a Wednesday is missed, the Friday shutdown review moves the Build block, not the Learn block.

## The gap map, after this update

- Azure Container Apps: closed by doing (Day 10), with Terraform and a pipeline around it.
- Terraform on Azure: closed by doing (Days 8–14, azurerm, remote state, module).
- FastAPI ownership and data layer: substantially closed (PostgreSQL, Redis, pooling, async, load evidence), honestly labelled as project scale, not Veolia production scale.
- Datadog: working familiarity (Week 4), enough for screening questions and a first month on a team that uses it.
- Scaling story: a real project story with numbers (Day 14), plus Week 1 AWS Auto Scaling and Week 3 Kubernetes autoscaling around it.
