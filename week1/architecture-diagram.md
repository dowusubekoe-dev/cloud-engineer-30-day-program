# Week 1 architecture — the checkpoint stack

One page. The three-tier design I built by hand on Days 1-4, secured
on Day 5, rebuilt with Terraform on Day 6, and failure-tested on
Day 7.
Account: AWS lab (us-east-1). VPC w1-vpc, 10.20.0.0/16.

```mermaid
flowchart TB
    U[Internet user] -->|HTTP 80| ALB
    subgraph VPC["VPC 10.20.0.0/16 (us-east-1a + us-east-1b)"]
        subgraph PUB["Public subnets 10.20.1.0/24, 10.20.2.0/24"]
            ALB["ALB w1-alb<br/>w1-public-sg: 80/443 from 0.0.0.0/0"]
            NAT["NAT gateway (in 1a)<br/>+ Elastic IP"]
        end
        subgraph APP["App subnets 10.20.11.0/24, 10.20.12.0/24 (private)"]
            ASG["ASG app-asg, min 2 / max 4<br/>launch template app-lt, t3.micro"]
            I1["instance (httpd)<br/>w1-app-sg: 80/443 from public SG only"]
            I2["instance (httpd)"]
            ASG --> I1
            ASG --> I2
        end
        subgraph DATA["Data subnets 10.20.21.0/24, 10.20.22.0/24 (private)"]
            RDS[("RDS app-db<br/>PostgreSQL 15.19, db.t3.micro<br/>w1-data-sg: 5432/3306 from app SG only")]
        end
        ALB -->|target group w1-app-tg :80| I1
        ALB --> I2
        I1 -->|5432| RDS
        I2 -->|5432| RDS
        I1 -.->|egress via NAT| NAT
        I2 -.->|egress via NAT| NAT
        EP["S3 gateway VPC endpoint<br/>on app + data route tables"]
        I1 -.-> EP
    end
    NAT -->|0.0.0.0/0| IGW[Internet gateway]
    subgraph SEC["Security layer (Day 5, account-wide)"]
        GD[GuardDuty]
        SH[Security Hub: Foundational + CIS]
        INSP[Inspector - EC2]
        CFG[AWS Config: 5 lab rules + recorder]
        CT[CloudTrail event history]
        EB[EventBridge rule day5-config-noncompliant-alert<br/>to CloudWatch Logs]
        CFG --> EB
    end
    subgraph STATE["Terraform state (Day 6)"]
        S3B[("S3 derek-lab-tfstate<br/>versioned, encrypted, public access blocked")]
        DDB[DynamoDB derek-lab-tflock]
    end
```

## How to read it
- Traffic enters only through the ALB. App instances sit in private
  subnets, take traffic only from the public security group, and reach
  the internet outbound through one NAT gateway (needed for package
  installs; proven on Day 7 when the replacement instance's user data
  installed httpd with no inbound path).
- The data tier takes connections only from the app security group and
  is never public. RDS was restored from the Day 4 manual snapshot
  (app-db-manual-1) on both Terraform builds.
- S3 traffic from the private tiers stays off the internet through the
  gateway endpoint.
- The Day 5 security layer watches the whole account, not just this
  stack: GuardDuty, Security Hub, Inspector, Config rules, and an
  EventBridge alert on any Config noncompliance.
- Day 7 proved the shape: with us-east-1a removed, the ASG replaced the
  lost instance inside us-east-1b in 37 seconds, full healthy capacity
  in 3m31s, and the ALB never stopped answering.
