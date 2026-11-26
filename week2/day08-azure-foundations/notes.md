# Day 8 - Azure foundations + Entra ID

Goal: explain Azure's management hierarchy and identity model in AWS terms, with a working tenant, RBAC, and no shared owner account.

## Build checklist
- [ ] 1. Sign in (personal tenant). Resource group rg-w2-lab in East US. Cost Management budget: $20/month, alerts at 50%, 80%, 100%. MFA on own account.
- [ ] 2. Hierarchy map: tenant, management group, subscription, resource group, resource. One sentence each: what policy and billing attach to at that level, and the AWS equivalent.
- [ ] 3. Entra ID: users cloud operator + read-only analyst (test accounts). Groups w2-operators, w2-readers. One user in each. No shared accounts, no guests.
- [ ] 4. RBAC at resource-group scope only: w2-readers = Reader on rg-w2-lab. w2-operators = Contributor on rg-w2-lab. Never subscription scope.
- [ ] 5. Break the scope on purpose: as the reader, try to create a storage account in rg-w2-lab (record the exact error below), then read the resource group (must succeed).
- [ ] 6. Conditional Access: review built-in report-only policies. Write what you would enable first in production and why. Do NOT enforce anything that could lock out the only admin.
- [ ] 7. Translation table started: ../notes/aws-to-azure.md (identity rows today, in your own words).

## Hierarchy notes
(tenant / management group / subscription / resource group / resource: policy + billing level, AWS equivalent)

## Authorization error (step 5, exact text)

## Conditional Access: what I would enable first, and why

## Prove it (commit to GitHub)
Hierarchy diagram, RBAC scope screenshots, authorization-error note, translation table started.
