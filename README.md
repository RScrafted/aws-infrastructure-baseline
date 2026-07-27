# AWS High-Availability Web Infrastructure Baseline

A production-grade, multi-AZ AWS infrastructure provisioned with Terraform, focusing on isolated private networking, automated load balancing, and high-availability Auto Scaling web fleets.

```text
                                    Internet
                                       |
                           [ Internet Gateway (IGW) ]
                                       |
    =======================================================================
    |                              AWS VPC                                |
    |                           10.20.0.0/16                              |
    |   +-------------------------------------------------------------+   |
    |   |                       PUBLIC SUBNETS                        |   |
    |   |     Subnet A: 10.20.1.0/24  |  Subnet B: 10.20.2.0/24       |   |
    |   |           (eu-west-2a)      |        (eu-west-2b)           |   |
    |   |                             |                               |   |
    |   |               +-----------------------------+               |   |
    |   |               |  Application Load Balancer  |               |   |
    |   |               |           Port 80           |               |   |
    |   |               +-----------------------------+               |   |
    |   |                              |                              |   |
    |   |                              | (Outbound Traffic Only)      |   |
    |   |                        +-----------+                        |   |
    |   |                        | NAT Gate  |                        |   |
    |   |                        +-----------+                        |   |
    |   +------------------------------|------------------------------+   |
    |                                  |                                  |
    |                                  v                                  |
    |   +-------------------------------------------------------------+   |
    |   |                       PRIVATE SUBNETS                       |   |
    |   |     Subnet A: 10.20.10.0/24 | Subnet B: 10.20.20.0/24       |   |
    |   |           (eu-west-2a)      |        (eu-west-2b)           |   |
    |   |                             |                               |   |
    |   |                      Target Group                           |   |
    |   |                (Health Checks Every 30s)                    |   |
    |   |                             |                               |   |
    |   |             +---------------+---------------+               |   |
    |   |             |                               |               |   |
    |   |     +---------------+               +---------------+       |   |
    |   |     | EC2 Instance  |               | EC2 Instance  |       |   |
    |   |     |  (AZ-A)       |               |  (AZ-B)       |       |   |
    |   |     +---------------+               +---------------+       |   |
    |   |             ^                               ^               |   |
    |   |             |                               |               |   |
    |   |             +---------------++--------------+               |   |
    |   |                             ||                              |   |
    |   |                    Auto Scaling Group                       |   |
    |   |                  (Min: 2, Desired: 2, Max: 4)               |   |
    |   |                             |                               |   |
    |   |                      Launch Template                        |   |
    |   |                   (Amazon Linux + Apache)                   |   |
    |   +-------------------------------------------------------------+   |
    =======================================================================
```

## Architectural Features

* **Network Isolation:** Compute nodes strictly run inside private subnets without public IPs. Ingress traffic from the internet is forced through the Application Load Balancer.
* **Decoupled Security Rules:** Utilizes standalone `aws_vpc_security_group_ingress_rule` and `egress_rule` resources instead of inline rules for precise lifecycle tracking and clean rule management.
* **Security Group References:** Restricts EC2 instances to accept HTTP traffic solely originating from the ALB Security Group (`referenced_security_group_id`).
* **Dynamic AMI Selection:** Evaluates Amazon Linux 2023 (AL2023) AMI data sources dynamically to avoid manual image maintenance.
* **Outbound Egress:** Private instances access external updates safely via a NAT Gateway deployed in the public subnet tier.

> [!NOTE]
> The current setup utilizes a single NAT Gateway tailored for `dev` environments. Production deployments should provision dedicated NAT Gateways per Availability Zone to eliminate single-point-of-failure risks.

## Project Structure

```plaintext
.
├── provider.tf            # Provider configuration & AWS profile mapping
├── variables.tf           # Default variables, CIDRs, tags, and environment settings
├── main.tf                # Core VPC, Security Groups, ALB, and ASG resources
├── outputs.tf             # Infrastructure deployment outputs & endpoint URLs
├── docs/
│   └── architecture.md    # Detailed architecture reference & notes
└── images/
    ├── 01-terraform-outputs.png
    ├── 02-terraform-state-list.png
    ├── 03-asg-ec2-instance-1.png
    └── 04-asg-ec2-instance-2.png

```

## Prerequisites

* **Terraform CLI** (v1.5.0+)
* **AWS CLI** configured locally with valid named profile credentials
* **IAM Permissions** for VPC, EC2, ALB, and Auto Scaling resource provisioning
* **aws configure profile** named `dev`

Verify local AWS CLI setup using non-sensitive caller identity checks:

```bash
aws sts get-caller-identity --profile dev
```

> [!CAUTION]
> Never display or commit sensitive AWS credentials (`~/.aws/credentials`) to source control or logs.

## Deployment Workflow

> [!WARNING]
> The deployed resources incur charges and will reflect on your AWS monthly bills. Tags are implemented to identify.

### 1. Configure Local Profile

Define your named AWS profile matching `var.env` (defaults to `dev`):

```bash
aws configure --profile dev
```

### 2. Provision Infrastructure

Initialize dependencies, validate HCL syntax, and apply the infrastructure plan:

```bash
# 1. Format code standards
terraform fmt

# 2. Initialize AWS provider & backend
terraform init

# 3. Validate configuration syntax
terraform validate

# 4. Generate execution plan
terraform plan -out=tfplan

# 5. Apply changes
terraform apply "tfplan"
```

![Terraform Outputs](/images/01-terraform-outputs.png)

## Deployment Verification

Verify state list and exported deployment outputs post-provisioning:

```bash
# List all active state-managed resources
terraform state list
```

![Terraform State List](/images/02-terraform-state-list.png)

### Traffic Distribution & Load Balancing Test

- Access the web service using the exported `alb_dns_name` URL at your terminal:
- Refreshing requests validates round-robin instance routing across the Auto Scaling fleet:

| ASG Target Instance 1 | ASG Target Instance 2 |
| --- | --- |
| ![ASG EC2 Instance 1](/images/03-asg-ec2-instance-1.png) | ![ASG EC2 Instance 2](/images/04-asg-ec2-instance-2.png) |

## Cleanup

Destroy all provisioned AWS resources and state dependencies:

```bash
terraform destroy
```