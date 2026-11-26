# Day 7 screenshots

Landscape, PNG, viewport 1600px wide or more (per the AWS console
screenshots skill). Save into this folder's screenshots/ subfolder.
Note: the browser tooling cannot save PNG files to the computer (Day 5
finding), so I capture these in the console myself while the stack
is up, or leave them unchecked honestly.

1. [x] ASG app-asg before the test: 2 instances, one per AZ, InService + Healthy
2. [x] ALB target group w1-app-tg: both targets healthy (before)
3. [x] The terminated instance / ASG activity history showing the kill
4. [x] ASG during healing: replacement instance launching in the surviving AZ
5. [x] ALB target group after healing: targets healthy again
6. [x] Security Hub summary: Foundational + CIS scores (compare Day 5: 8% / 6%)
7. [x] Cost Explorer: top services by cost for the lab account (November)
8. [x] Budgets page: monthly-guard status

## Capture record, 2026-11-26

All eight items captured 2026-11-26 in landscape (1069 x 769, account ID masked) during a one-session rebuild. The HA test was re-run for items 3, 4, and 5: us-east-1a removed from app-asg at 04:48:55 EST, replacement InService in us-east-1b, two healthy targets again at 04:52:35 (3m40s), then us-east-1a restored and the group rebalanced (log: ha-test-recapture.log in this folder). Item 6 shows Foundational 83 percent and overall 78 percent with the stack up; the Day 7 record (80 and 76) stands in the notes. The stack was destroyed after the captures and verified at state 0, snapshot app-db-manual-1 kept. This supersedes the note above about the browser tooling being unable to save PNG files: the captures were recovered from the browser session files and filed manually.
