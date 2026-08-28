# Platform Ops Lab

This repo follows a small Flask API as I containerise it and later deploy it to Kubernetes.

The app has two endpoints:

- `/` shows the service name, environment and version
- `/health` returns the health status

## Run with Docker

```
docker build -t platform-ops-lab:0.1 app/
docker run --rm -p 8080:8080 platform-ops-lab:0.1
```

Test it:

```
curl http://localhost:8080/
curl http://localhost:8080/health
```
