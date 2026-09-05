# DevOps Infratify Final Project 2026

This is the final project as requirement after completing Infratify DevOps Bootcamp 2026.

## Introduction

- End-to-end infrastructure and deployment pipeline built as a final project for a DevOps bootcamp.
- Provisions AWS infrastructure with **Terraform**
- Configures servers with **Ansible**, and deploys a containerized web app pulled from a private **Amazon ECR** repository — with monitoring via **Prometheus + Grafana**.

## Table of Contents

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Variables](#variables)
- [Getting Started](#getting-started)
  - [1. Provision Infrastructure](#1-provision-infrastructure)
  - [2. Connect via SSM](#2-connect-via-ssm)
  - [3. Build and Push the App Image](#3-build-and-push-the-app-image)
  - [4. Deploy with Ansible](#4-deploy-with-ansible)
  - [5. Verify](#5-verify)
- [Monitoring](#monitoring)
- [CI/CD Pipeline](#cicd-pipeline)
- [List of URLs](#list-of-urls)

## Architecture

```
                     devops-vpc (10.0.0.0/24)
                             │
          ┌──────────────────┴──────────────────┐
          │                                      │
  Public Subnet                          Private Subnet
  10.0.0.0/25                            10.0.0.128/25
          │                                      │
 ┌────────┴────────┐                ┌────────────┼────────────┐
 │   web server     │                │  ansible    │ monitoring │
 │   10.0.0.5       │                │  controller │ server     │
 │   + Elastic IP   │                │  10.0.0.135 │ 10.0.0.136 │
 │   port 80        │                └─────────────┴────────────┘
 └──────────────────┘
          │                                      │
    Internet Gateway                      NAT Gateway
    (devops-igw)                          (devops-ngw)
```

| Component | Subnet | Private IP | Purpose |
|---|---|---|---|
| Web server | Public | `10.0.0.5` | Runs the app container (pulled from ECR), exposed via Elastic IP on port 80 |
| Ansible controller | Private | `10.0.0.135` | Runs Ansible playbooks against the other two servers |
| Monitoring server | Private | `10.0.0.136` | Runs Prometheus + Grafana; scrapes `node_exporter` metrics from all servers |

**Security groups**
- `devops-public-sg` — port 80 from anywhere, port 9100 (node_exporter) from the monitoring server only, port 22 from within the VPC
- `devops-private-sg` — port 22 from within the VPC only

All servers are managed through **AWS Systems Manager (SSM) Session Manager** — no SSH keys and no inbound SSH exposed to the internet.

## Repository Structure

```
├── terraform/                  # Infrastructure as Code
│   ├── providers.tf               # Terraform + AWS provider configuration, backend
│   ├── variables.tf               # Input variable declarations (e.g. az, region)
│   ├── network.tf                 # VPC, subnets, IGW, NAT Gateway, route tables
│   ├── security.tf                # Security groups and rules
│   ├── ec2.tf                     # EC2 instances (web server, controller, monitoring)
│   └── output.tf                  # Outputs (IPs, IDs, ARNs)
│
├── ansible/                       # Configuration management (run from the controller)
│   ├── ansible.cfg
│   ├── inventory.ini                # Rendered inventory (generated from the template)
│   ├── playbook-web.yaml            # Deploys the app container to the web server
│   ├── playbook-exporter.yaml       # Installs node_exporter on all servers
│   ├── playbook-prometheus.yaml     # Installs Prometheus on the monitoring server
│   ├── playbook-stack.yaml          # Deploys Prometheus + Grafana via Docker Compose
│   ├── compose.yaml
│   └── prometheus.yaml
│
├── app/ship/                    # Application source
│   ├── Dockerfile                  # Multi-stage build: Vite build → Nginx static serve
│   ├── src/
│   ├── public/
│   └── package.json
│
└── .github/workflows/           # CI/CD pipeline
    └── build-and-deploy.yml        # Build image → push to ECR → deploy via Ansible over SSM
```

## Prerequisites

- AWS account with an `EC2-SSM-Role` IAM instance profile already created
- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.15`
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws sts get-caller-identity` to verify)
- [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed locally
- [Docker](https://docs.docker.com/get-docker/) installed locally
- An existing Amazon ECR repository (e.g. `devops-bootcamp/final-project-faris`)

## Variables

Terraform inputs are declared in `terraform/variables.tf`. Set these before running `terraform apply`, either via a `terraform.tfvars` file, `-var` flags, or environment variables (`TF_VAR_<name>`).

| Variable | Type | Required | Description |
|---|---|---|---|
| `az` | `string` | Yes | AWS Availability Zone used for both the public and private subnets (e.g. `ap-southeast-1a`) |

> **Note:** the table above reflects the variables confirmed in use across `network.tf` (`var.az`). If `variables.tf` declares additional inputs (e.g. a project/name prefix, instance type, or CIDR overrides), update this table to match — check `terraform/variables.tf` directly for the full, authoritative list.

Example `terraform.tfvars`:

```hcl
az = "ap-southeast-1a"
```

## Getting Started

### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Review the created resources:

```bash
terraform output
```

### 2. Connect via SSM

No SSH keys required:

```bash
aws ssm start-session --target <instance-id> --region ap-southeast-1
```

### 3. Build and Push the App Image

```bash
cd app/ship
docker build -t ship-app .

ECR="<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com"
FULL="$ECR/devops-bootcamp/final-project-faris:v1"

aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin "$ECR"

docker tag ship-app:latest "$FULL"
docker push "$FULL"
```

### 4. Deploy with Ansible

From the Ansible controller (`10.0.0.135`, via SSM):

```bash
cd ansible

# First-time setup only
ansible-galaxy collection install prometheus.prometheus
ansible-galaxy role install geerlingguy.docker

ansible-playbook playbook-exporter.yaml    # node_exporter on all servers
ansible-playbook playbook-web.yaml         # deploy app to the web server
ansible-playbook playbook-stack.yaml       # Prometheus + Grafana on the monitoring server
```

### 5. Verify

| Service | URL |
|---|---|
| App | `http://<web server Elastic IP>` |
| Prometheus | `http://<monitoring server IP>:9090` (via port forwarding, see below) |
| Grafana | `http://<monitoring server IP>:3000` (via port forwarding, see below) |

## Monitoring

The monitoring server sits in a private subnet with no public access. To reach Prometheus/Grafana from your local machine, use SSM port forwarding:

```bash
aws ssm start-session \
  --target <monitoring-server-instance-id> \
  --region ap-southeast-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3000"],"localPortNumber":["8888"]}'
```

Then open `http://localhost:8888` for Grafana (swap `3000` → `9090` for Prometheus).

## CI/CD Pipeline

This project uses **GitHub Actions** to automate the build-and-deploy flow, replacing the manual steps in [Build and Push the App Image](#3-build-and-push-the-app-image) and [Deploy with Ansible](#4-deploy-with-ansible) above.

**Workflow file:** `.github/workflows/deploy.yml`

**Trigger:** every push to the `main` branch

```
push to main
     │
     ▼
┌─────────────────────┐
│ 1. Checkout code     │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│ 2. Authenticate to   │  aws-actions/configure-aws-credentials
│    AWS + login ECR   │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│ 3. Build & push       │  docker build (app/ship/) → tag with commit SHA
│    Docker image       │  → push to ECR
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│ 4. Trigger deploy     │  aws ssm send-command → Ansible controller
│    via SSM             │  runs `git pull` + `ansible-playbook playbook-web.yaml`
└─────────────────────┘
```

### Required GitHub Secrets

Configure these under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key with ECR push + SSM send-command permissions |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |
| `ANSIBLE_CONTROLLER_ID` | Instance ID of the Ansible controller (`10.0.0.135`) |

### What it does

1. Builds the Docker image from `app/ship/` and pushes it to ECR, tagged with the Git commit SHA.
2. Sends an SSM command to the Ansible controller instructing it to pull the latest playbooks from this repo and run `playbook-web.yaml`, which redeploys the container on the web server.




## List of URLs

| Service | URL |
|---|---|
| Public Web Server | https://web.faris-mohamed.com |
| Monitoring Server | https://monitoring.faris-mohamed.com |