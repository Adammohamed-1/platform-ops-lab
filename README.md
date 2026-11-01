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

## Automated CI checks and container smoke test

The [GitHub Actions workflow](.github/workflows/ci.yml) runs for pushes to `main`
and pull requests targeting `main`. It checks Python syntax, builds the Docker
image, validates Terraform formatting/configuration, and **starts the built
container** to check that the Flask application actually responds.

The smoke test:
1. Runs the image with `APP_ENV=ci` and binds its port only to localhost on the CI runner.
2. Waits for `GET /health` to return HTTP 200 and JSON `{"status":"ok"}`.
3. Requests `GET /` and verifies the application identifies itself as
   `platform-ops-lab` running in the `ci` environment.
4. Prints the container logs on failure and removes the test container even if
   a check fails.

To try the same idea locally from the repository root:

```bash
docker build --platform linux/amd64 -t platform-ops-lab:ci ./app
docker run -d --name platform-api-smoke -p 127.0.0.1:8080:8080 -e APP_ENV=ci platform-ops-lab:ci
curl -i http://127.0.0.1:8080/health
curl -i http://127.0.0.1:8080/
docker rm -f platform-api-smoke
```

This is an automated **smoke test**, not a complete test suite or deployment
pipeline: it does not deploy to EKS, test Kubernetes networking, or prove all
business behaviour is correct.

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
