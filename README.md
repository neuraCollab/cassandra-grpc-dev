# 🚀 Distributed Parser with Cassandra & gRPC

![CI/CD](https://github.com/neuraCollab/cassandra-grpc-dev/actions/workflows/publish-ghcr.yml/badge.svg)

**A distributed text-processing system** built on:
- **Apache Cassandra** (NoSQL database)
- **gRPC + Protocol Buffers** (microservice communication, C++17)
- **vcpkg** (manifest-mode dependency management — identical library versions across every service)
- **Streamlit Web UI** (`cassandra-web`, exposed on host port `3000`)

---

## 🔍 What's Inside?

- **Coordinator**: Orchestrates parsing jobs
- **Worker(s)**: Perform the actual text processing (3 replicas by default)
- **Cassandra**: Stores parsed results
- **Web UI**: Visualize and interact with data via Streamlit

Most C++ dependencies (`grpc`, `protobuf`, `abseil`, `curl`, `libxml2`) are declared once in [`vcpkg.json`](vcpkg.json) and built into a single shared base image, so coordinator and worker always link against the exact same versions. The one exception is the DataStax C/C++ driver for Cassandra: it has no official vcpkg port, so it's compiled from source exactly once in that same shared base image (`docker/Dockerfile.vcpkg`) instead of being duplicated per-service.

---

## 📦 Using Prebuilt Images (Recommended)

`docker-compose.yml` is set up by default to pull ready-to-run images from GitHub Container Registry instead of compiling anything locally. Every push to `main` and every release rebuilds and republishes them via [`.github/workflows/publish-ghcr.yml`](.github/workflows/publish-ghcr.yml).

```bash
docker compose up -d
```

That's it — no C++ compiler, no vcpkg, no waiting for `grpc`/`protobuf`/`abseil`/the Cassandra driver to build from source. Compose pulls `ghcr.io/neuracollab/coordinator:latest` and `ghcr.io/neuracollab/worker:latest` and starts the full stack (Cassandra, `cassandra-web`, coordinator, 3 worker replicas) in seconds.

Open the web interface at http://localhost:3000, and tear it down with `docker compose down` when you're done.

If you're changing C++ code and need to build locally instead, see **Quick Start (Local Development)** below — `coordinator`/`worker` in `docker-compose.yml` each carry a commented-out `build:` block you can uncomment to switch back.

---

## 🚀 Quick Start (Local Development)

Use this path when you're modifying the coordinator/worker C++ code and need to build the images yourself, rather than pulling the prebuilt ones above.

### 1. Prerequisites

- [Docker](https://www.docker.com/) with Compose v2 (`docker compose`)

### 2. Build the shared base image (first time, or whenever `vcpkg.json` changes)

```bash
docker build -f docker/Dockerfile.vcpkg -t base-vcpkg:latest .
```

This compiles the vcpkg manifest's dependencies once. It's the slow step (expect it to take a while the first time); Docker's layer cache makes every rebuild after that instant unless `vcpkg.json` changes.

### 3. Switch `docker-compose.yml` to local builds

In the `coordinator` and `worker` services, comment out the `image:` line and uncomment the `build:` block underneath it.

### 4. Bring the stack up

```bash
docker compose up --build
```

This builds `coordinator` and `worker` on top of `base-vcpkg` and starts Cassandra, `cassandra-web`, the coordinator, and 3 worker replicas.

### 5. Open the Web Interface

```
http://localhost:3000
```

### 6. Tear it down

```bash
docker compose down
```

---

## 🧑‍💻 VS Code Dev Container

A [`.devcontainer/`](.devcontainer/devcontainer.json) is included, wired to the same `docker-compose.yml`. Open the repo in VS Code and choose **Reopen in Container** to get C++ IntelliSense, CMake Tools, and Docker support pre-installed, with the container attached to the running Cassandra instance.

---

## 🧪 Verify It Works

```bash
docker compose ps
```

Expected: `cassandra` reports `healthy`, and `coordinator` / `worker` are `Up`.

```bash
docker compose logs coordinator worker
```

---

## 📦 Project Layout

```
vcpkg.json              # manifest: grpc, protobuf, abseil, curl, libxml2
docker/Dockerfile.vcpkg  # shared base image: toolchain + vcpkg deps + generated proto stubs
coordinator/Dockerfile   # multi-stage build -> minimal runtime image
worker/Dockerfile        # multi-stage build -> minimal runtime image
proto_files/             # .proto definitions
docker-compose.yml       # local dev stack
```

---

## 🖼️ Screenshots

### Cassandra Web UI (Streamlit)
![Cassandra Web UI](assets/database.png)

---

## Advanced / Production Deployment (Kubernetes / Minikube)

Running on Kubernetes (via Minikube for local cluster testing) is supported for production-like deployments, but it's **not** the recommended path for day-to-day development — Minikube's RAM footprint and slower startup add friction that `docker compose` avoids.

### Prerequisites

- [Docker](https://www.docker.com/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

> 💡 **Windows users**: Use **WSL2** for best experience.

### Automated

```bash
chmod +x start.sh
./start.sh
```

This builds the base + service images, generates gRPC code, starts Minikube, loads images into the cluster, creates the Cassandra init config, and deploys everything under `kubernetes/`.

### Manual

```bash
# 1. Build the shared base image and service images
docker build -f docker/Dockerfile.vcpkg -t base-vcpkg:latest .
docker build -f coordinator/Dockerfile -t distributed_parser-coordinator ./coordinator
docker build -f worker/Dockerfile -t distributed_parser-worker ./worker

# 2. Start Minikube
minikube start

# 3. Load images into Minikube
minikube image load distributed_parser-coordinator:latest
minikube image load distributed_parser-worker:latest

# 4. Create Cassandra init config
kubectl create configmap cassandra-setup --from-file=setup.cql=./cassandra/setup.cql

# 5. Deploy everything
kubectl apply -f ./kubernetes/ --recursive

# 6. Access the Web UI
kubectl port-forward deployment/cassandra-web 8083:8083
# → Open http://localhost:8083
```

### Screenshots

![Minikube Dashboard](assets/dashboard.png)
> 📌 **Tip**: Run `minikube dashboard` to monitor pods, services, and logs in real time.

### Verify

```bash
kubectl get pods
```

```
NAME                                      READY   STATUS    RESTARTS   AGE
cassandra-xxxxx                           1/1     Running   0          2m
cassandra-web-xxxxx                       1/1     Running   0          2m
coordinator-xxxxx                         1/1     Running   0          2m
worker-xxxxx                              1/1     Running   0          2m
```

---

## 📬 Troubleshooting

- If Cassandra runs out of memory, reduce limits (see `kubernetes/cassandra/cassandra-deployment.yaml` for the K8s path, or add resource limits under the `cassandra` service in `docker-compose.yml` for local dev).
- For gRPC/proto issues, verify `.proto` files are in `proto_files/` and rebuild `base-vcpkg` so the generated stubs pick up the change.
- If a service fails to build against `base-vcpkg:latest`, make sure you built it first — Compose does not build it automatically since it's referenced only via `FROM`, not as a compose service.
