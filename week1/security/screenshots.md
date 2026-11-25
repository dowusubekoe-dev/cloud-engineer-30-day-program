# Day 5 - Screenshots to capture (AWS Console)

Save each PNG in this folder's `screenshots/` subfolder with the filename
shown. Pattern: the service is on, the key configuration, the security
evidence, the before/after test result, and the budget view.

1. `day5-01-guardduty-detector.png` - GuardDuty console showing the
   detector enabled for the account.
2. `day5-02-config-rules.png` - AWS Config, Rules list showing the five
   managed rules created by day5-security.sh (including
   restricted-common-ports).
3. `day5-03-security-hub.png` - Security Hub summary page showing the
   hub enabled and standards/scores visible.
4. `day5-04-inspector-coverage.png` - Inspector console showing EC2
   scanning coverage active.
5. `day5-05-bad-sg-inbound.png` - EC2, Security Groups, w1-bad-sg inbound
   rule close-up: port 22 open to 0.0.0.0/0 (the deliberate violation).
6. `day5-06-config-noncompliant-before.png` - AWS Config evaluation for
   w1-bad-sg showing NON-COMPLIANT (capture BEFORE remediating).
7. `day5-07-cloudtrail-event-history.png` - CloudTrail, Event history,
   the CreateSecurityGroup event for w1-bad-sg with time and principal.
8. `day5-08-config-compliant-after.png` - The same Config evaluation
   after remediation showing COMPLIANT.
9. `day5-09-budget.png` - AWS Budgets, monthly-guard, current vs
   budgeted after Day 5's services are enabled.
