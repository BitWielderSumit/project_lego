# Colima Setup

## Problem
Machine does not have Docker. Need container runtime with Kubernetes support.

## Solution
Install Colima (Docker Desktop alternative for macOS) with Kubernetes enabled.

---

## Commands to Execute

### 1. Install Prerequisites
```bash
# Install Colima
brew install colima

# Install Docker CLI
brew install docker

# Install kubectl (Kubernetes CLI)
brew install kubectl
```

### 2. Start Colima with Kubernetes
```bash
# Start Colima with Kubernetes enabled (4 CPU, 8GB RAM)
colima start --kubernetes --cpu 4 --memory 8

# Verify Docker
docker ps

# Verify Kubernetes
kubectl get nodes
```

### 3. Test Installation
```bash
# Run test container
docker run --rm hello-world

# Check Kubernetes cluster info
kubectl cluster-info
```

---

## Troubleshooting

### Error: "error starting vm: error at 'starting': exit status 1"
If Colima fails to start with an existing instance error, clean up and restart:

```bash
# Stop any running instance
colima stop

# Delete the existing instance
colima delete

# Start fresh with Kubernetes
colima start --kubernetes --cpu 4 --memory 8
```
