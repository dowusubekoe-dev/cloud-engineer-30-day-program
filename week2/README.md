# Week 2 — Azure + IaC: SmartLead on Azure (Days 8–14)

My execution guide for Week 2, updated as I go, same as Week 1.
Master program document: `cloud-engineer-30-README.md` (goal files) and
the Week 1 README in `week1/`. This file is the Week 2 working copy;
the master copy lives in the goal files as `week2-README.md`.

**Week checkpoint (2026-11-14 Plan Update):** SmartLead running on Azure
Container Apps, deployed by Terraform (azurerm) from its own repo, with a
VNet, private endpoints, Key Vault secrets delivered by managed identity,
one Azure Policy, a PostgreSQL + Redis data layer, a GitHub Actions
deployment, and Scaling Write-Up v1. SmartLead's real data stays local;
Azure gets seed/test data only.

## Where Week 2 lives

- Course folder: `week2/` in the cloud-engineer-30 course repo (WSL).
- Working repo for the week: `week2/smartlead-on-azure/` (its own GitHub
  repo: https://github.com/dowusubekoe-dev/smartlead-on-azure).
- How the repos fit (decided 2026-11-27): this program repo is the
  showcase journal, the day-by-day record. The smartlead-on-azure
  repo holds the deployment itself (Terraform, pipeline, write-ups).
  The SmartLead application code stays in its own repo
  (crewsite-smartlead, private). The course repo's .gitignore
  excludes the nested smartlead-on-azure folder; the links here and
  in that repo's own README are how the pieces point at each other.
- `week2/day08-azure-foundations/` holds material from the superseded
  original Day 8 (Entra ID foundations). Left untouched as archive; the
  current Day 8 below supersedes it.
- `week2/notes/aws-to-azure.md`: my AWS-to-Azure translation notes.

## Standing rules for the week

- Billing alerts on before building (verified below, 2026-11-27).
- Check existing state first and verify every change live before
  building on it (standing rule, 2026-11-15).
- Tear down paid Azure resources the same day unless a step says
  otherwise. The tfstate storage account is state infrastructure and
  stays.
- Screenshots: landscape, viewport 1600 px wide or more, PNG, with the
  subscription ID masked in anything published.
- This README gets updated the same day a gap or error is found, in
  both copies (standing rule, 2026-11-15).

## Preflight record — checked live 2026-11-27 before Day 8

- Azure CLI in WSL: 2.92.0.
- **My default subscription is the wrong one.** `az account show`
  returns a different subscription, and calls against it fail with
  SubscriptionNotFound. The program subscription is the one whose ID
  starts `c6172d8a`. Day 8 Step 0 sets it. (This sign-in can also see
  other subscriptions, including a cohort demo subscription; none of
  them are mine to build in.)
- Budgets on the program subscription: **monthly-guard, $10/mo, Cost**
  is in place, and a second $10 budget named `azure_user` also exists.
  The Week 2 billing-guard rule is satisfied; no new budget needed.
- Resource groups on the subscription: none. `rg-smartlead` does not
  exist yet; Day 8 creates it.
- Resource providers on the subscription: Microsoft.Resources is
  Registered. **Microsoft.Storage is NotRegistered** (this is why the
  storage name check failed with SubscriptionNotFound), and
  Microsoft.App is also NotRegistered. Day 8 Step 0 registers both.
- Terraform in WSL: v1.7.0 (backend.tf requires >= 1.6). Good.
- **Terraform was being hijacked by leftover environment variables.**
  My .bashrc exported ARM_SUBSCRIPTION_ID and ARM_TENANT_ID pointing
  at a cohort-era subscription and tenant, plus a service principal's
  ARM_CLIENT_ID and ARM_CLIENT_SECRET. The azurerm provider reads
  those variables before it ever looks at the az CLI login, so my
  first `terraform init` targeted the wrong subscription and failed
  with SubscriptionNotFound, even though every az command was
  correct. Fix applied 2026-11-27: the whole ARM_* block in .bashrc
  is commented out (backup kept), so Terraform now authenticates
  through my az CLI login, like this guide assumes. A terminal that
  is already open keeps the variables until they are unset; Step 0
  covers that.
- `week2/smartlead-on-azure/` exists but is empty, and is not yet a
  git repo. Day 8 creates `terraform/` inside it; git init is part of
  the Day 8 close-out, and the GitHub remote gets created separately.
- Storage account name `stderektfstate`: availability not yet
  confirmed. Confirm in Day 8 Step 0 after the subscription is set and
  Microsoft.Storage is registered. If taken, pick a new name and use
  it in BOTH the create command and backend.tf.

---

## Day 8 — Azure refresh + Terraform on Azure

**Goal:** azurerm Terraform with remote state, planning cleanly against
my subscription: `terraform init` succeeds on the azurerm backend and
`terraform plan` returns an empty plan.

**Step 0 — fix the subscription and providers first (added 2026-11-27;
the original guide assumed the right subscription was already active):**

```bash
# Clear any inherited ARM_* variables first: in a terminal that has
# been open a while they can point Terraform at the wrong
# subscription (see the preflight record above).
unset ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_SUBSCRIPTION_ID ARM_TENANT_ID
SUB=$(az account list --query "[?starts_with(id, 'c6172d8a')].id | [0]" -o tsv)
az account set --subscription "$SUB"
az account show --query "{name:name, id:id}" -o table
# The id shown must start c6172d8a. If the query returned nothing,
# stop and sort the sign-in before creating anything.
az provider register -n Microsoft.Storage
az provider register -n Microsoft.App
az provider show -n Microsoft.Storage --query registrationState -o tsv
# Wait until it reads Registered (a few minutes). Microsoft.App is for
# Day 10's Container Apps; registering now means no wait then.
az storage account check-name --name stderektfstate
# nameAvailable must be true before Step 1.
```

**Step 1 — resource group and remote state storage:**

```bash
az group create -n rg-smartlead -l eastus2
az storage account create -n stderektfstate -g rg-smartlead -l eastus2 --sku Standard_LRS --min-tls-version TLS1_2
az storage container create -n tfstate --account-name stderektfstate
```

**Step 2 — backend.tf** (staged at
`week2/smartlead-on-azure/terraform/backend.tf` from the Day 8 prep
package):

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-smartlead"
    storage_account_name = "stderektfstate"
    container_name       = "tfstate"
    key                  = "smartlead.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

**Step 3 — init and plan:**

```bash
cd week2/smartlead-on-azure/terraform
terraform init && terraform plan   # empty plan is the day's bar
```

**Close-out:** screenshots per `screenshots.md` (staged in
`week2/smartlead-on-azure/`), fill in `notes.md`, record the drill
(`drill-script-day8.md`, staged alongside), git init and commit
backend.tf + notes in the smartlead-on-azure repo.

**Learn:** Microsoft Learn AZ-104 refresh (VNets, private endpoints)
and the Container Apps docs (environments, ingress, revisions, scale
rules).
**Drill:** "Walk me through VNet design for a three-tier app on Azure,"
from my bootcamp three-tier project.

**Status (2026-11-27):** Complete, except my drill recording.
Steps 0 and 1
done: the subscription is set, rg-smartlead and the tfstate storage
are created in eastus2. My first `terraform init` failed with
SubscriptionNotFound (the ARM_* variables in the preflight record
above); after unsetting them, init succeeded on the azurerm backend
and the state blob sits in the tfstate container. `terraform plan`
verified empty twice, my run and a fresh-shell re-run; the re-run
output is saved in the repo as terraform/plan-day8.log, and notes.md
is filled in. The GitHub repo `smartlead-on-azure` is created
(public) and pushed (e371d5b: backend.tf, lock file, notes,
screenshots list, drill script, .gitignore; 6fc0a3c: repo README).
The first push attempt was rejected because `git add .` swept in
`terraform/.terraform/` (the 222 MB provider binary is over GitHub's
100 MB file limit); fixed with a .gitignore and an amended commit.
Portal evidence is saved in the repo's screenshots/ folder (five
PNGs, subscription and tenant IDs blurred in the committed copies);
screenshots.md records what each one shows.

---

## Day 9 — Network first

**Goal:** the network in Terraform before any app lands on it.

**Target architecture:** the design and diagram are filed in the
smartlead-on-azure repo (`docs/architecture.mmd`; the design
document is `docs/architecture.md`). Reconcile before building:
the architecture puts the VNet at 10.0.0.0/16 with four /24
subnets (ingress, app, data, endpoints), while the sketch below
uses 10.30.0.0/16 with a /23 infra subnet and a /24 endpoints
subnet. Settle the CIDR and the Container Apps subnet size first.

`network.tf` (core resources; extend with NSG rules per tier):

```hcl
resource "azurerm_virtual_network" "main" {
  name                = "vnet-smartlead"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.30.0.0/16"]
}
resource "azurerm_subnet" "infra" {  # Container Apps environment subnet (delegated, /23 minimum)
  name                 = "snet-infra"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.30.0.0/23"]
  delegation {
    name = "aca"
    service_delegation { name = "Microsoft.App/environments" actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] }
  }
}
resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.30.4.0/24"]
}
```

Add: NSGs per subnet, a Private DNS zone for PostgreSQL
(`privatelink.postgres.database.azure.com`) linked to the VNet, and the
private endpoint on Day 12. Decide internal vs external Container Apps
environment and write the trade-off in the repo README.

**Prove it:** network diagram in the repo (extend the bootcamp
three-tier diagram).
**Drill:** "How do private endpoints change how an app talks to its
database?" (DNS resolves to a private IP; traffic never leaves the
VNet; public access can be disabled outright.)

**Status:** Not started.

---

## Day 10 — SmartLead onto Container Apps

**Goal:** my FastAPI app running on the platform the target roles name.

SmartLead already runs in Docker locally. Confirm the image builds,
then:

```bash
az acr create -n acrdereksmartlead -g rg-smartlead --sku Basic --admin-enabled false
az acr build --registry acrdereksmartlead --image smartlead:latest ./app-src   # or docker build + push
```

`app.tf` (essentials):

```hcl
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-smartlead"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  infrastructure_subnet_id   = azurerm_subnet.infra.id
}
resource "azurerm_container_app" "smartlead" {
  name                         = "ca-smartlead"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  identity { type = "SystemAssigned" }   # used on Day 11
  template {
    min_replicas = 1
    max_replicas = 3                       # revisited on Day 13 after load data
    container {
      name   = "smartlead"
      image  = "acrdereksmartlead.azurecr.io/smartlead:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }
  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight { percentage = 100 latest_revision = true }
  }
}
```

Grant the app's identity `AcrPull` on the registry, `terraform apply`,
and hit the app URL.

**Known items to settle on the day:** the ACR name `acrdereksmartlead`
is globally unique in Azure; check availability before the create.
Microsoft.App registration is handled on Day 8. A Log Analytics
workspace (Microsoft.OperationalInsights) may be needed by the
environment; register the provider if apply asks for it.

**Prove it:** running revision URL + `az containerapp show` output
saved in the repo.
**Drill:** "Container Apps, AKS, or ECS: how do you choose?" Answer
from this deployment.

**Status:** Not started.

---

## Day 11 — Identity and secrets, the Azure way

**Goal:** no secret in code, in the repo, or in plain environment
configuration. The app's managed identity reads Key Vault.

```hcl
resource "azurerm_key_vault" "main" {
  name                      = "kv-derek-smartlead"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = false   # lab only; say why in the note
}
# The container app's identity gets Secrets User (read only, nothing more)
resource "azurerm_role_assignment" "app_kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.smartlead.identity[0].principal_id
}
```

Steps: create the vault, move every SmartLead secret into it
(`az keyvault secret set`), rewire the app to read secrets via its
identity at startup, delete the secrets from local config, and grep
the repo to prove none remain
(`git grep -i "password\|secret" -- ':!*.md'`). Then assign one Azure
Policy to the resource group and show it evaluating:

```bash
az policy assignment create -n deny-public-ip --policy "<policy-definition-id>" \
  --scope /subscriptions/<sub>/resourceGroups/rg-smartlead --enforcement-mode Default
az policy state list --resource-group rg-smartlead --query "[?complianceState=='NonCompliant']" -o table
```

**Known gap to settle on the day:** `<policy-definition-id>` and
`<sub>` above are placeholders in the original guide. On Day 11, pick
a real built-in policy (for example the built-in "Deny the creation of
public IP addresses" or an allowed-locations policy), get its real
definition ID with `az policy definition list`, and patch this
section with the verified values the same day.

**Prove it:** a "Secrets handling" note in the repo: what moved, what
the identity can and cannot read, the grep evidence.
**Drill:** "How do you keep secrets out of code in Azure?" Now a
story, not a definition.

**Status:** Not started.

---

## Day 12 — A real data layer: PostgreSQL + Redis

**Goal:** SmartLead off SQLite and onto the data layer the job
descriptions name.

```bash
az postgres flexible-server create -n psql-smartlead -g rg-smartlead -l eastus2 \
  --admin-user smartleadadmin --admin-password "<from-your-password-manager>" \
  --sku-name Standard_B1ms --version 15 --vnet vnet-smartlead --subnet snet-data \
  --private-dns-zone <your-zone-id> --yes
az redis create -n redis-smartlead -g rg-smartlead -l eastus2 --sku Basic --vm-size C0
```

Steps: add a data subnet (`10.30.8.0/24`, delegated to
`Microsoft.DBforPostgreSQL/flexibleServers`) and the private
endpoint/DNS from Day 9's groundwork; run SmartLead's existing Alembic
migrations against PostgreSQL (`alembic upgrade head` with the new
`DATABASE_URL`); set the pool deliberately in the app config and write
down the numbers:

```python
# app/db.py — explicit pool settings, sized for the Day 14 load test
engine = create_async_engine(
    settings.database_url,
    pool_size=10,        # steady connections per replica
    max_overflow=5,      # burst headroom before requests queue
    pool_timeout=30,     # seconds a request waits for a connection before failing
    pool_recycle=1800,   # recycle connections every 30 min
)
```

Add Redis as a cache-aside layer on the app's hottest read path: check
Redis first, on a miss read PostgreSQL and populate with a short TTL.
Record one before/after latency reading for that endpoint.

**Week rule check:** PostgreSQL Flexible Server and Redis are paid;
per the standing rule they are torn down the same day unless the
checkpoint work needs them standing, and any keep-standing decision
gets recorded here with its reason.

**Prove it:** migration output + the before/after cache note in the
repo.
**Drill:** "What happens to a FastAPI service under load when the
database connection pool is too small?" (Requests queue on the pool,
latency climbs, then timeouts; I will see it on Day 14.)

**Status:** Not started.

---

## Day 13 — Pipeline and scale rules

**Goal:** the Veolia pipeline pattern, Azure target; scaling set by
evidence, not defaults.

`.github/workflows/deploy.yml`:

```yaml
name: deploy-smartlead
on:
  push: { branches: [main] }
permissions: { id-token: write, contents: read }
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - name: Build and push
        run: |
          az acr build --registry acrdereksmartlead --image smartlead:${{ github.sha }} ./app-src
      - name: Deploy new revision
        uses: azure/container-apps-deploy-action@v1
        with:
          containerAppName: ca-smartlead
          resourceGroup: rg-smartlead
          imageToDeploy: acrdereksmartlead.azurecr.io/smartlead:${{ github.sha }}
```

Federated (OIDC) login, no stored Azure password: that is the point
of the `azure/login` setup. Then add scale rules to the Terraform
template block:

```hcl
http_scale_rule {
  name                = "http-concurrency"
  concurrent_requests = 50        # new replica per 50 concurrent requests
}
```

Keep min replicas 1, max 3 until Day 14 gives real numbers.

**Prove it:** a green pipeline run + the scale rules in Terraform.
**Drill:** "Tell me about a time you scaled a system." I finish
building the honest project version of this answer on Day 14.

**Status:** Not started.

---

## Day 14 — Load test, break it, Week 2 checkpoint

**Goal:** evidence. What breaks first, what one change fixes, what the
numbers do.

`loadtest/locustfile.py`:

```python
from locust import HttpUser, task, between

class LeadUser(HttpUser):
    wait_time = between(0.5, 2)
    @task(3)
    def list_leads(self):
        self.client.get("/api/leads")
    @task(1)
    def create_lead(self):
        self.client.post("/api/leads", json={"name": "Load Test", "email": "load@example.com", "source": "locust"})
```

```bash
pip install locust
locust -f loadtest/locustfile.py --host https://<your-container-app-url> --headless -u 50 -r 5 -t 5m --csv loadtest/run1
# Watch in parallel: az containerapp replica list, Azure Monitor metrics, DB connections
```

Steps: ramp 10, 50, 100 users; record where it degrades (app CPU,
pool exhaustion, Redis hit rate, cold starts). Change exactly one
thing (pool size, scale threshold, or cache coverage), rerun, record
the difference.

**Prove it (Week 2 checkpoint):** the repo holds the Terraform module
with remote state, the network diagram, the secrets note, the
pipeline, and **Scaling Write-Up v1**: what broke, what I changed,
what the numbers did, in my own words.
**Drill:** deliver the scaling story out loud in two minutes. Record
it.

**Status:** Not started.
