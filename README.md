# EKS Online Boutique - Production-Ready Kubernetes Infrastructure

A complete, production-grade AWS EKS infrastructure with GitOps, service mesh, secrets management, and policy enforcement for the Google Cloud microservices demo application.

## Architecture Overview

This project demonstrates enterprise-grade Kubernetes infrastructure with:

- **Infrastructure as Code**: Terraform for reproducible infrastructure
- **Container Orchestration**: AWS EKS (Kubernetes 1.29)
- **Service Mesh**: Istio 1.21 for traffic management and observability
- **GitOps**: ArgoCD for continuous deployment
- **Secrets Management**: External Secrets Operator with AWS Secrets Manager
- **Policy Enforcement**: OPA Gatekeeper for admission control
- **Auto-scaling**: Cluster Autoscaler and Horizontal Pod Autoscaling
- **Load Balancing**: AWS Network Load Balancer with health checks

## GitOps Application Repository

This infrastructure is designed to work with the GitOps application repository:

**Repository**: [online-boutique-app](https://github.com/bosingva/online-boutique-app)

The application repository contains:
- Kubernetes manifests for the microservices application
- Istio configuration (Gateway, VirtualService, AuthorizationPolicies)
- External Secrets configuration for AWS Secrets Manager integration
- OPA Gatekeeper policies for security enforcement
- Kustomize overlays for environment-specific configuration

### How They Work Together

```
eks-online-boutique (Infrastructure)          online-boutique-app (Application)
├── VPC and Networking              ←─────   Deployed into this infrastructure
├── EKS Cluster                     ←─────   
├── Istio (base, istiod, gateway)   ←─────   Uses Gateway and routing rules
├── ArgoCD                          ─────→   Watches this Git repository
├── External Secrets Operator       ←─────   Syncs secrets defined here
└── OPA Gatekeeper                  ←─────   Enforces policies defined here
```

### Deployment Flow

1. **Infrastructure deployment** (this repo): Creates EKS cluster, Istio, ArgoCD
2. **ArgoCD Application creation**: Points to `online-boutique-app` repository
3. **GitOps sync**: ArgoCD automatically deploys application from Git
4. **Continuous deployment**: Changes to `online-boutique-app` auto-sync to cluster

## Infrastructure Components

### Networking
- **VPC**: Custom VPC with public and private subnets across 3 availability zones
- **NAT Gateway**: Single NAT gateway for cost optimization (can be scaled to 3 for HA)
- **Security Groups**: Least-privilege security groups for cluster and load balancer

### EKS Cluster
- **Control Plane**: Managed by AWS with public API endpoint
- **Node Groups**:
  - `initial`: t3.small instances (2-10 nodes, desired: 4)
  - `istio`: t3.medium instances (2-10 nodes, desired: 4)
- **Authentication**: IAM-based with cluster creator admin permissions
- **Addons**: EBS CSI driver, CoreDNS, VPC CNI, kube-proxy

### Service Mesh (Istio)
- **Components**:
  - `istio-base`: Custom Resource Definitions
  - `istiod`: Control plane for configuration and certificate management
  - `istio-ingress`: Gateway for external traffic with NLB integration
- **Features**:
  - Automatic sidecar injection
  - mTLS between services
  - Traffic management and observability

### GitOps (ArgoCD)
- Automated deployment from Git repository
- Self-healing and pruning enabled
- Sidecar injection enabled for Istio integration

### Security & Compliance
- **External Secrets**: Syncs secrets from AWS Secrets Manager to Kubernetes
- **OPA Gatekeeper**: Policy enforcement for security and compliance
- **IAM Roles for Service Accounts (IRSA)**: Fine-grained AWS permissions

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl
- Helm 3.x (optional, for manual operations)
- Valid GitHub Personal Access Token with `repo` scope

## Project Structure

```
infra/
├── main.tf                          # EKS cluster and VPC
├── providers.tf                     # Terraform and provider configuration
├── variables.tf                     # Input variables
├── output.tf                        # Output values
├── iam.tf                           # IAM roles and policies
├── istio.tf                         # Istio installation
├── istio-ingress-values.yaml.tftpl  # Istio gateway configuration
├── argocd.tf                        # ArgoCD installation
├── argocd-values.yaml               # ArgoCD configuration
├── external-secrets.tf              # External Secrets Operator
├── gatekeeper.tf                    # OPA Gatekeeper
├── kube-resources.tf                # Kubernetes resources (namespaces, RBAC)
├── online-boutique-argo-app.yaml    # ArgoCD application for main app
└── platform-argo-app.yaml           # ArgoCD application for platform resources
```

## Deployment Guide

### Step 1: Configure Variables

Create a `terraform.tfvars` file (do NOT commit this):

```hcl
aws_region             = "us-east-1"
eks_cluster_name       = "online-boutique-eks"
vpc_name               = "online-boutique-vpc"
k8s_version            = "1.29"
user_for_admin_role    = "arn:aws:iam::YOUR-ACCOUNT-ID:user/YOUR-USERNAME"
user_name_git          = "your-github-username"
```

Set your GitHub token as an environment variable:

```bash
export TF_VAR_gitops_password="ghp_your_github_token_here"
```

### Step 2: Initialize Terraform

```bash
cd infra
terraform init
```

### Step 3: Review and Apply

```bash
# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

Expected deployment time: 15-20 minutes

### Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --name online-boutique-eks --region us-east-1
```

### Step 5: Verify Installation

```bash
# Check cluster status
kubectl get nodes

# Check Istio installation
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress

# Check ArgoCD installation
kubectl get pods -n argocd

# Get ArgoCD admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode; echo
```

### Step 6: Access ArgoCD UI

```bash
# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: (from step 5)
```

### Step 7: Deploy Applications via ArgoCD

```bash
# Apply ArgoCD applications
kubectl apply -f online-boutique-argo-app.yaml
kubectl apply -f platform-argo-app.yaml

# Watch deployment progress
kubectl get applications -n argocd -w
```


**Note**: The application manifests are managed in the [online-boutique-app](https://github.com/bosingva/online-boutique-app) repository. Any application changes should be made there, not in this infrastructure repository.

## Key Features Explained

### Istio Gateway Configuration

The Istio ingress gateway is configured with:
- **Auto-scaling**: 2-5 replicas based on CPU utilization
- **Health Checks**: TCP health checks on traffic ports
- **Cross-zone Load Balancing**: Enabled for high availability
- **Security Groups**: Dedicated security group for ingress traffic

### Security Group Rules

**Node Security Group** (EKS worker nodes):
- Ports 30000-32767: NodePort range from Load Balancer
- Port 15017: Istio webhook (cluster to nodes)
- Port 15012: Istio XDS configuration (cluster to nodes)
- Port 15090: Prometheus metrics collection

**Load Balancer Security Group**:
- Port 80: HTTP traffic from internet
- Port 443: HTTPS traffic from internet
- Egress: All traffic allowed

### GitOps Workflow

1. Developer pushes changes to the Git repository
2. ArgoCD detects changes automatically
3. ArgoCD syncs the desired state to the cluster
4. Istio handles traffic routing with zero-downtime
5. Metrics and logs are collected for observability

### External Secrets Integration

Secrets are stored in AWS Secrets Manager and synchronized to Kubernetes:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-secret
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: k8s-secret-name
  data:
  - secretKey: password
    remoteRef:
      key: /path/to/secret
```

## Cleanup

To destroy all infrastructure:

```bash
# Delete ArgoCD applications first
kubectl delete -f online-boutique-argo-app.yaml
kubectl delete -f platform-argo-app.yaml

# Wait for applications to be deleted
kubectl get applications -n argocd

# Destroy infrastructure
cd infra
terraform destroy

# Confirm with 'yes'
```

**Note**: The destroy process takes 10-15 minutes.

## Security Best Practices

- Store sensitive values in AWS Secrets Manager or Parameter Store
- Never commit credentials to Git (use `.gitignore`)
- Use IAM roles instead of long-lived credentials
- Regularly update Kubernetes and Istio versions
- Implement network policies for pod-to-pod communication
- Use OPA Gatekeeper policies for compliance


## References

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [External Secrets Operator](https://external-secrets.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

## Related Repositories

- **Application Manifests**: [online-boutique-app](https://github.com/bosingva/online-boutique-app) - Kubernetes manifests and GitOps configuration
- **Original Application**: [Google Cloud Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo) - Source application code


## Contact

For questions or collaboration opportunities, please reach out via [GitHub](https://github.com/bosingva) or [LinkedIn](your-linkedin-profile).

---
