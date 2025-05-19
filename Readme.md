# 🧪 Local Dev Stack with Cassandra, gRPC, and Protobuf

This repository provides development files and scripts to run a sample microservice application locally using Minikube and Kubernetes, demonstrating the infrastructure setup process. You can use it locally with docker+k8s/ansible/Makefile by your choise.
**The distributed parser is used only as an example application to demonstrate functionality.**

Run it locally with Docker + Kubernetes, Ansible, or Makefile — your pick! 
---

## ▶️ Automated Startup

To simplify the process, use the provided `start.sh` script.

### How to use:
```bash
chmod +x start.sh       # Make the script executable
./start.sh              # Run the automation script
```

It will perform all of the above steps automatically.

---

## 🔧 Manual Startup

If you prefer to run everything manually, follow these steps:

### 1. Build vcpkg base image (optional)
```bash
docker build -f Dockerfile.vcpkg -t base-vcpkg .
```

### 2. Generate gRPC code
```bash
docker run --rm \
  -v $(pwd)/proto_files:/app/proto_files \
  -v $(pwd)/generated:/app/generated \
  grpc-generator
```

### 3. Start Minikube
```bash
minikube start
```

### 4. Load Docker images into Minikube
```bash
minikube image load distributed_parser-coordinator:latest
minikube image load distributed_parser-worker:latest
```

### 5. Apply Kubernetes manifests
```bash
kubectl apply -f ./kubernetes/ --recursive
```



## 🛠 Requirements

- [Docker](https://www.docker.com/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- bash shell (or WSL on Windows)

> ✅ **Tip:** If you're on Windows, we recommend using WSL2 for better compatibility with Docker and Kubernetes.
