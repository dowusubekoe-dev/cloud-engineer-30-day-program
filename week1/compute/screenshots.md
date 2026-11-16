# Day 3 Screenshots: Compute and Storage

Save PNGs in `week1/compute/screenshots/` with the filenames below. Every shot must show the resource name or ID and its status; that is what makes it proof rather than decoration.

Standing pattern for every day (applies Days 1-30): (1) the resource exists, list or detail page with name/ID/status; (2) the day's key configuration close-up; (3) the security setting proof; (4) the test result; (5) the cost or budget view when the day creates billable resources.

1. `01-launch-template.png` — EC2 → Launch templates → app-lt: the versions list (v1 and v2), default version marked.
2. `02-asg-details.png` — EC2 → Auto Scaling groups → app-asg: desired 2, min 2, max 4, and the launch template name.
3. `03-asg-instances.png` — app-asg → Instance management: both instances InService and healthy, one per AZ (i-04a26119b8a97a577 in us-east-1a, i-0aae6ee914c41a815 in us-east-1b).
4. `04-alb-details.png` — EC2 → Load balancers → w1-alb: state Active, the DNS name, both public subnets/AZs, and the listener on port 80.
5. `05-target-health.png` — EC2 → Target groups → w1-app-tg → Targets: both targets **healthy**. This is the day's test result.
6. `06-instance-role.png` — EC2 → Instances → either app instance → Security tab: IAM role **ec2-app-role** attached (via the ec2-app-profile instance profile) and **no key pair name**. This is the "no keys on the box" proof.
7. `07-alb-page.png` — Browser at the ALB DNS name (w1-alb-1654882201.us-east-1.elb.amazonaws.com): the "hello from" page with the instance hostname. Refresh a few times to catch both hostnames if you can.
8. `08-s3-properties.png` — S3 → derek-lab-app-data → Properties: versioning Enabled, default encryption on, and Block Public Access all on (the Permissions tab shows the block settings too).
9. `09-session-manager.png` — Systems Manager → Session Manager: the instance listed as connectable, or a started session. Proves administration works with no SSH port open.
