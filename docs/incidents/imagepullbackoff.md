# ImagePullBackOff troubleshooting

## What happened

A deployment update pointed the application at an ECR image tag that did not exist:

```text
platform-ops-lab:does-not-exist
```

Kubernetes created a new Pod for the rollout, but the container could not start and moved into `ErrImagePull` / `ImagePullBackOff`.

The two existing healthy Pods remained running while the new rollout failed.

## How it was diagnosed

Checked the Pod status:

```bash
kubectl get pods
```

Inspected the failing Pod and its Events:

```bash
kubectl describe pod <pod-name>
```

The Events showed that the image reference could not be found in ECR.

Confirmed the image configured on the Deployment:

```bash
kubectl get deployment platform-api \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

## Fix

Rolled the Deployment back to the previous working revision:

```bash
kubectl rollout undo deployment/platform-api
```

Verified that the rollout completed successfully:

```bash
kubectl rollout status deployment/platform-api
```

Confirmed that the Deployment was using the valid `0.1` image tag again.

## Root cause

The configured ECR image tag did not exist. This was an image reference problem, not an authentication or ECR permissions issue.
