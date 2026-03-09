# k3s-platform-demo

![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-k3s-blue)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black)

A **DevOps / Platform Engineering portfolio project** demonstrating how
to deploy and operate a **production‑style Kubernetes platform on AWS**
using **Terraform**, **GitHub Actions**, and **k3s**.

This project demonstrates modern DevOps practices:

-   Infrastructure as Code with **Terraform**
-   **Modular infrastructure design**
-   **Multi‑environment deployments** (dev / prod)
-   Secure AWS authentication with **GitHub OIDC**
-   **Infrastructure CI/CD**
-   **Cost visibility (FinOps)** using Infracost
-   **Static analysis** using TFLint
-   **Drift detection**
-   Secure Kubernetes networking architecture

The repository demonstrates how a single engineer can build a
**production‑like Kubernetes platform using DevOps practices**.

------------------------------------------------------------------------

# Architecture Overview

The platform deploys a **high‑availability k3s Kubernetes cluster on
AWS**.

Infrastructure components:

-   VPC
-   Public subnet
-   Private subnets across two availability zones
-   Bastion host acting as:
    -   SSH entry point
    -   NAT instance for private subnets
    -   HAProxy load balancer for Kubernetes API
-   2 Kubernetes control‑plane nodes
-   4 worker nodes

------------------------------------------------------------------------

# AWS Infrastructure Architecture

``` mermaid
flowchart TD

Internet --> Bastion

subgraph AWS VPC
    Bastion --> HAProxy

    subgraph Private AZ1
        Master1
        Worker1
        Worker2
    end

    subgraph Private AZ2
        Master2
        Worker3
        Worker4
    end

    HAProxy --> Master1
    HAProxy --> Master2

    Worker1 --> HAProxy
    Worker2 --> HAProxy
    Worker3 --> HAProxy
    Worker4 --> HAProxy
end
```

Key characteristics:

-   Only the **bastion host has a public IP**
-   Kubernetes nodes are deployed in **private subnets**
-   Bastion provides **NAT for outbound traffic**
-   HAProxy provides **API load balancing across masters**

------------------------------------------------------------------------

# Kubernetes Cluster Architecture

``` mermaid
flowchart TD

kubectl --> SSH_Tunnel
SSH_Tunnel --> Bastion

Bastion --> HAProxy

HAProxy --> Master1
HAProxy --> Master2

Master1 --> Worker1
Master1 --> Worker2

Master2 --> Worker3
Master2 --> Worker4
```

Cluster characteristics:

-   k3s Kubernetes distribution
-   containerd runtime
-   Ubuntu 24.04 nodes
-   2 control‑plane nodes
-   4 workers distributed across AZs

Workers communicate with the API server via **HAProxy running on the
bastion host**.

------------------------------------------------------------------------

# Technology Stack

  Category                 Technology
  ------------------------ ----------------
  Infrastructure as Code   Terraform
  Cloud                    AWS
  Kubernetes               k3s
  Container Runtime        containerd
  CI/CD                    GitHub Actions
  Security                 AWS OIDC
  Cost estimation          Infracost
  Static analysis          TFLint
  Load balancing           HAProxy
  OS                       Ubuntu 24.04

------------------------------------------------------------------------

# Terraform Architecture

Terraform modules are composed into a **platform module** orchestrating
the infrastructure.

``` mermaid
flowchart TD

Platform --> Network
Platform --> Bastion
Platform --> Masters
Platform --> Workers
```

Modules:

    modules/
     ├ network
     ├ bastion
     ├ k3s-masters
     ├ k3s-workers
     └ platform

Each module has a single responsibility.

------------------------------------------------------------------------

# Repository Structure

    .
    ├ bootstrap
    │   ├ Terraform backend
    │   └ IAM configuration
    │
    ├ environments
    │   ├ dev
    │   └ prod
    │
    ├ modules
    │   ├ network
    │   ├ bastion
    │   ├ k3s-masters
    │   ├ k3s-workers
    │   └ platform
    │
    └ .github
        ├ actions
        └ workflows

------------------------------------------------------------------------

# CI/CD Pipeline

Infrastructure is deployed using **GitHub Actions**.

Pipeline features:

-   Terraform formatting validation
-   Terraform configuration validation
-   TFLint static analysis
-   Terraform plan on Pull Requests
-   Infracost cost estimation
-   Manual apply via workflow dispatch
-   Environment protection rules
-   Drift detection workflow
-   Controlled destroy workflow

------------------------------------------------------------------------

# CI/CD Pipeline Flow

``` mermaid
flowchart TD

PR --> TerraformFmt
TerraformFmt --> Validate
Validate --> TFLint
TFLint --> Plan
Plan --> Infracost
Infracost --> PRComment

ManualRun --> TerraformApply
```

Deployment strategy:

  Environment   Apply
  ------------- -----------------
  dev           automatic
  prod          manual approval

------------------------------------------------------------------------

# Terraform Bootstrap

The `bootstrap` configuration provisions Terraform backend resources:

-   S3 bucket for Terraform state
-   State versioning
-   Encryption
-   IAM role for Terraform execution
-   GitHub OIDC provider

This allows CI/CD pipelines to authenticate **without storing AWS
credentials**.

------------------------------------------------------------------------

# Security Design

Security controls implemented:

-   OIDC authentication for GitHub Actions
-   No long‑lived AWS credentials
-   Kubernetes nodes in private subnets
-   Bastion host as the only public entry point
-   Security group isolation
-   Encrypted Terraform state
-   S3 public access blocked

------------------------------------------------------------------------

# Design Decision: NAT Instance vs NAT Gateway

This project intentionally uses a **NAT instance** instead of an AWS
**NAT Gateway**.

### NAT Gateway (production best practice)

Advantages:

-   fully managed by AWS
-   high availability
-   automatic scaling
-   minimal maintenance

Disadvantages:

-   relatively expensive
-   hourly cost + traffic cost

Typical monthly cost per AZ:

    ~ $32 / month + data transfer

For multi‑AZ environments the cost increases further.

------------------------------------------------------------------------

### NAT Instance (used in this project)

Advantages:

-   significantly cheaper
-   simple architecture
-   good for development environments
-   easier to understand networking concepts

Trade‑offs:

-   not managed by AWS
-   requires manual configuration
-   single point of failure

------------------------------------------------------------------------

### Why NAT Instance was chosen

This project prioritizes:

-   **cost efficiency**
-   **educational value**
-   **architecture transparency**

The NAT instance runs on the **bastion host**, reducing infrastructure
cost while still demonstrating:

-   private subnets
-   outbound internet access
-   routing configuration

In production environments, the NAT instance would typically be replaced
with **managed NAT Gateways**.

------------------------------------------------------------------------

# Accessing the Kubernetes Cluster

Retrieve kubeconfig from the bastion host:

    ssh -J ubuntu@<bastion-ip> ubuntu@<master-ip> "sudo cat /etc/rancher/k3s/k3s.yaml"

Then establish the API tunnel:

    ssh -N -L 6443:127.0.0.1:6443 -J ubuntu@<bastion-ip> ubuntu@<master-ip>

Use kubectl locally:

    kubectl get nodes

------------------------------------------------------------------------

# FinOps: Cost Awareness

The CI pipeline integrates **Infracost**.

Pull Requests display:

-   estimated monthly cost
-   cost differences introduced by changes

This supports **cost‑aware infrastructure decisions**.

------------------------------------------------------------------------

# Drift Detection

A scheduled GitHub workflow runs:

    terraform plan

to detect configuration drift.

If drift occurs, the workflow reports it automatically.

------------------------------------------------------------------------

# Destroy Workflow

A dedicated workflow allows safe destruction of the dev environment.

The workflow requires explicit confirmation:

    DESTROY

------------------------------------------------------------------------

# Future Improvements

Possible extensions:

-   Prometheus monitoring
-   Grafana dashboards
-   GitOps with ArgoCD
-   Vault for secrets management
-   Example microservice deployment
-   Cluster autoscaling

------------------------------------------------------------------------

# Purpose of the Project

This repository demonstrates how to build a **modern Kubernetes platform
using DevOps practices**.

It highlights:

-   Infrastructure automation
-   Secure cloud authentication
-   CI/CD pipelines for infrastructure
-   Cost‑aware infrastructure design
-   Kubernetes platform architecture

The project is intended as a **DevOps / Platform Engineering portfolio
example**.
