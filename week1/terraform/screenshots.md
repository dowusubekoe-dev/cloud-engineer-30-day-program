# Day 6 - Screenshots to capture (AWS Console)

Save each PNG in this folder's `screenshots/` subfolder with the
filename shown. Pattern: the resource exists, the key configuration,
the security setting, the test result, and the budget view.

1. `day6-01-tfstate-bucket.png` - S3 console, derek-lab-tfstate
   bucket properties showing versioning enabled.
2. `day6-02-tflock-table.png` - DynamoDB console, derek-lab-tflock
   table overview with the LockID key schema.
3. `day6-03-nat-gateway-recreated.png` - VPC console, NAT gateways
   list showing the Terraform-created gateway, status available
   (the resource deleted on Nov 19, back as code).
4. `day6-04-asg-under-terraform.png` - EC2, Auto Scaling groups,
   app-asg details showing desired 2 / min 2 after apply, or the
   recorded lab-off state if the cost decision kept it at 0.
5. `day6-05-bucket-public-access-block.png` - derek-lab-tfstate
   Permissions tab showing Block Public Access fully on (the
   security setting proof for the state bucket).
6. `day6-06-plan-summary.png` - Terminal capture of terraform plan:
   the add / change / destroy counts (the test result; pair it with
   the apply-complete terminal capture in the same folder).
7. `day6-07-budget.png` - AWS Budgets, monthly-guard, current vs
   budgeted after Day 6, with the NAT gateway billing again.
