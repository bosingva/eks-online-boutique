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

### Step 8: Access the Application

```bash
# Get the load balancer URL
kubectl get svc -n istio-ingress

# Access the application via the NLB DNS name
```

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

## Cost Optimization

**Current estimated monthly cost**: ~$300-400

- EKS Control Plane: ~$73/month
- 8 EC2 instances (t3.small/medium): ~$200-250/month
- NAT Gateway: ~$32/month
- Network Load Balancer: ~$16/month
- Data transfer: Variable

**Cost reduction strategies**:
1. Use Spot instances for non-critical workloads
2. Reduce node count during off-hours
3. Use single NAT gateway (already implemented)
4. Enable cluster autoscaler (already enabled)

## Troubleshooting

### Issue: Pods stuck in ImagePullBackOff

```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Common cause: Image specification issue
# Solution: Verify image repository and tag in values files
```

### Issue: ArgoCD can't authenticate to Git

```bash
# Check repository secret
kubectl get secret gitops-k8s-repo -n argocd -o yaml

# Verify token has 'repo' scope
# Regenerate token if needed and update secret
```

### Issue: NLB targets unhealthy

```bash
# Check Istio gateway pods
kubectl get pods -n istio-ingress -o wide

# Ensure pods are running on multiple nodes
# Check security group rules allow NodePort range
```

### Issue: Cluster autoscaler not working

```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-cluster-autoscaler

# Verify IAM permissions for autoscaler service account
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
- Enable AWS GuardDuty and Security Hub
- Regularly update Kubernetes and Istio versions
- Implement network policies for pod-to-pod communication
- Use OPA Gatekeeper policies for compliance

## Monitoring and Observability

**Recommended additions**:
- Prometheus + Grafana for metrics
- EFK/ELK stack for logging
- Jaeger for distributed tracing
- Kiali for Istio visualization

## Future Enhancements

- [ ] Add Prometheus and Grafana
- [ ] Implement network policies
- [ ] Add cert-manager for TLS certificates
- [ ] Implement backup solution with Velero
- [ ] Add multiple NAT gateways for HA
- [ ] Implement pod security standards
- [ ] Add Falco for runtime security
- [ ] Implement disaster recovery procedures

## Technical Skills Demonstrated

- **Cloud Infrastructure**: AWS VPC, EKS, IAM, Secrets Manager
- **Infrastructure as Code**: Terraform with modules and best practices
- **Container Orchestration**: Kubernetes deployment and operations
- **Service Mesh**: Istio installation and configuration
- **GitOps**: ArgoCD continuous deployment
- **Security**: IRSA, OPA policies, secrets management
- **Networking**: Load balancers, security groups, service mesh
- **Automation**: Cluster autoscaling, self-healing deployments

## References

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [External Secrets Operator](https://external-secrets.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

## License

MIT License - Feel free to use this as a reference for your own projects

## Contact

For questions or collaboration opportunities, please reach out via [LinkedIn](https://www.linkedin.com/in/dimitri-korgalidze-73030b169/).

---

**Note**: This is a demonstration project. For production use, implement additional security measures, monitoring, and disaster recovery procedures.