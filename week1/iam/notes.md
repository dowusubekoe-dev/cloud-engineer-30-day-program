# Day 1, Task 3: Permission boundary and SCP-style deny (notes)

## What these two files are
- `permission-boundary-template.json` — a ceiling for ONE user or role. It grants
  nothing by itself. A person's real permissions are the overlap of their
  policies AND this boundary, so they can never exceed it, even if a policy is
  attached by mistake.
- `scp-deny-template.json` — a ceiling for EVERY account in the organization.
  It grants nothing either. It only removes actions, for everyone, including
  each member account's own administrators. (SCPs do not apply to the
  management account itself.)

## Decisions I still need to make (fill in, then delete the prompts)
### Permission boundary
1. Which services does the role under this boundary actually need?
   Template starts with EC2, S3, Lambda, CloudWatch, Logs. Add or remove.
2. Is `iam:PassRole` a full deny for this role, or should it be allowed only
   to specific services (for example Lambda and EC2)? A scoped PassRole is
   the more senior answer; write the condition if you choose it.
3. Why this boundary exists, in my words (2-3 sentences):

### SCP deny list
1. CloudTrail tampering is denied because: (my words — think evidence)
2. Disabling detection (Config, GuardDuty, Security Hub) is denied because:
3. Disabling encryption (EBS default encryption off, KMS key disable or
   deletion) is denied because:
4. Leaving the organization is denied because:
5. Scope: this SCP would attach to the whole organization
   (o-h31ljtdj6n) or to specific OUs/accounts first? Which, and why?

## Remember for the interview version
- Boundary = per-principal ceiling. SCP = per-organization ceiling.
- Neither grants access. Allow comes from identity policies; these only cap.
- An explicit Deny in either one beats any Allow anywhere else.
