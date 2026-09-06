# Platform Ops Lab

A small Flask API containerised with Docker and deployed to Amazon EKS. The AWS infrastructure is created with Terraform and the application image is stored in Amazon ECR.

## What this project covers

- Flask API with `/` and `/health` endpoints
- Docker image built for `linux/amd64`
- Terraform-managed VPC, public subnets, EKS cluster and managed node group
- Amazon ECR for the application image
- Kubernetes Deployment, Service, ConfigMap, health probes and resource limits
- GitHub Actions checks for Python, Docker and Terraform
- Troubleshooting and rollback of an `ImagePullBackOff` failure

## Project structure

```text
app/                 Flask application and Dockerfile
k8s/                 Kubernetes manifests
terraform/           AWS and EKS infrastructure
docs/incidents/      Troubleshooting notes
.github/workflows/   CI workflow
```

## Build locally

```bash
docker build -t platform-ops-lab:0.1 ./app
docker run --rm -p 8080:8080 platform-ops-lab:0.1
```

Test it:

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Create the AWS infrastructure

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Connect `kubectl` to the cluster:

```bash
aws eks update-kubeconfig --region eu-west-2 --name platform-ops-eks
kubectl get nodes
```

## Push the image to ECR

From the repository root:

```bash
docker build --platform linux/amd64 -t platform-ops-lab:0.1 ./app
ECR_URL=$(terraform -chdir=terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ECR_URL
docker tag platform-ops-lab:0.1 $ECR_URL:0.1
docker push $ECR_URL:0.1
```

## Deploy to EKS

```bash
kubectl apply -f k8s/
kubectl rollout status deployment/platform-api
kubectl get pods -o wide
```

Test the application through the ClusterIP Service:

```bash
kubectl port-forward service/platform-api 8080:80
```

Then in another terminal:

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Troubleshooting example

The live Deployment was intentionally changed to use a missing ECR image tag. The new Pod entered `ErrImagePull` and then `ImagePullBackOff` while the existing healthy Pods stayed available.

The issue was diagnosed with `kubectl describe`, the bad image reference was confirmed, and the rollout was recovered with:

```bash
kubectl rollout undo deployment/platform-api
kubectl rollout status deployment/platform-api
```

See `docs/incidents/imagepullbackoff.md` for the full walkthrough.

## Destroy the AWS resources

When finished with the lab:

```bash
cd terraform
terraform destroy
```

The EKS cluster and worker nodes incur AWS charges while they exist, so the environment is designed to be created for testing and destroyed afterwards.
