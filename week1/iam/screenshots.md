# Day 1 Screenshots: IAM

Save PNGs in `week1/iam/screenshots/` with the filenames below. Every shot must show the resource name or ID and its status; that is what makes it proof rather than decoration.

Standing pattern for every day (applies Days 1-30): (1) the resource exists, list or detail page with name/ID/status; (2) the day's key configuration close-up; (3) the security setting proof; (4) the test result; (5) the cost or budget view when the day creates billable resources.

1. `01-policies-list.png` — IAM → Policies, filter "Customer managed": the `app-data-access` policy in the list.
2. `02-app-policy-json.png` — IAM → Policies → app-data-access → JSON tab: the policy document itself.
3. `03-policy-simulator.png` — IAM → Policy Simulator: run the app policy against a few EC2/S3 actions and capture the allowed/denied results. (Regenerate live; the simulator keeps no history.)
4. `04-organizations-accounts.png` — AWS Organizations → AWS accounts: the organization structure with its accounts. This is the org the SCP template in this folder is written for.
5. `05-budget-monthly-guard.png` — AWS Budgets → monthly-guard: $10 budget, current/forecast amounts, and the 80% alert.
6. `06-cloudtrail-trails.png` — CloudTrail → Trails: the trail list with logging status.
7. `07-iam-dashboard.png` — IAM → Dashboard: the security status panel (root user MFA and recommendations).

Note: the permission boundary and SCP from Day 1 are JSON templates in this folder, not live console objects; the JSON files themselves are their proof. Do not stage console shots for resources that do not exist.
