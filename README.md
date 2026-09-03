# 🚀 C++ gRPC + Cassandra Dev Stack

![CI/CD](https://github.com/neuraCollab/cassandra-grpc-dev/actions/workflows/publish-ghcr.yml/badge.svg)
![Image Size](https://img.shields.io/docker/image-size/neuracollab/coordinator?label=coordinator&color=blue)
![Image Size](https://img.shields.io/docker/image-size/neuracollab/worker?label=worker&color=blue)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**Production-ready Docker template for building distributed C++ microservices with gRPC, Protocol Buffers, and Apache Cassandra.**

This is a *template*, not a finished application: it gives you a working coordinator/worker architecture, vcpkg-based dependency management, multi-stage Docker builds, and a CI/CD pipeline that publishes to GHCR — all wired together and verified working — with an example parsing pipeline standing in for whatever business logic you're actually building.

---

## 📋 Table of Contents

- [Features](#features)
- [What's Inside?](#whats-inside)
- [Using Prebuilt Images (Recommended)](#using-prebuilt-images-recommended)
- [Quick Start (Local Development)](#quick-start-local-development)
- [VS Code Dev Container](#vs-code-dev-container)
- [Verify It Works](#verify-it-works)
- [Use Cases](#use-cases)
- [Configuration](#configuration)
- [Customizing for Your Project](#customizing-for-your-project)
- [Project Layout](#project-layout)
- [Screenshots](#screenshots)
- [Advanced / Production Deployment (Kubernetes / Minikube)](#advanced--production-deployment-kubernetes--minikube)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Additional Resources](#additional-resources)

---

## ✨ Features

| | |
|---|---|
| 📦 **Pre-built images on GHCR** | No local compilation needed — `docker compose up -d` pulls ready-to-run images |
| 🐳 **Multi-stage Docker builds** | ~170–190MB final images, down from multi-GB dev images |
| 🔧 **vcpkg manifest mode** | Identical library versions across every service, built once in a shared base image |
| ⚡ **gRPC + Protocol Buffers** | C++17, generated stubs baked into the base image |
| 🗄️ **Apache Cassandra integration** | Pre-configured schema and driver, wired up in `docker-compose.yml` |
| 🖥️ **Web UI for data inspection** | `cassandra-web` on port 3000 |
| 🧑‍💻 **VS Code Dev Containers** | Full C++ toolchain + `gdb`, attached to the running stack |
| 🔄 **Automated CI/CD** | GitHub Actions builds, validates, and publishes on every push/release |
| ❤️ **Health checks** | Cassandra readiness gates coordinator/worker startup in Compose |
| 🧩 **Example implementation included** | A distributed parsing pipeline with Cassandra storage, ready to run or replace |

---

## 🔍 What's Inside?

This is a **template with a working example**, not a ready-made product:

- **Coordinator**: an example gRPC server that distributes tasks to workers — replace with your own orchestration logic
- **Worker(s)**: example gRPC clients that fetch and parse data (via curl + libxml2) and write results to Cassandra (3 replicas by default) — replace with your own business logic
- **Cassandra**: a pre-configured NoSQL store for results
- **Web UI**: `cassandra-web`, for visualizing stored data
- **Infrastructure**: a production-ready Docker/CI setup around all of the above

### Architecture

```
                     ┌────────────────────┐
                     │      Browser       │
                     │  localhost:3000    │
                     └─────────┬──────────┘
                               │ HTTP
                               ▼
┌─────────────────┐   gRPC   ┌──────────────┐   gRPC   ┌──────────────┐
│  cassandra-web   │◄──CQL───┤  coordinator │◄────────►│    worker    │
│   (Streamlit)    │         │  :50051      │  (x3)    │  (x3 pods)   │
└────────┬─────────┘         └──────────────┘          └──────┬───────┘
         │ CQL                                                │ CQL
         ▼                                                    ▼
                     ┌─────────────────────┐
                     │      Cassandra      │
                     │  keyspace: parser   │
                     └─────────────────────┘
```

The coordinator hands out tasks over gRPC; workers pull a task, execute it (fetch + parse in the example implementation), write the result straight to Cassandra, and report completion back to the coordinator. Swap out what happens inside "execute it" and the rest of the architecture — service discovery, health checks, image builds, CI — keeps working unchanged.

### Tech Stack & Versions

Pinned/observed from an actual build of this repo's `docker/Dockerfile.vcpkg` — check `vcpkg.json` and the workflow logs for the current resolved versions, since vcpkg's baseline moves forward over time:

| Component | Version | Source |
|---|---|---|
| Base OS | `ubuntu:22.04` | `docker/Dockerfile.vcpkg` |
| gRPC | 1.81.1 | vcpkg port `grpc` |
| Protobuf | 6.33.4 (protoc 33.4.0) | vcpkg port `protobuf` |
| Cassandra C/C++ driver | 2.17.1 | built from source, pinned in `docker/Dockerfile.vcpkg` (no official vcpkg port) |
| C++ standard | C++17 | `coordinator/CMakeLists.txt`, `worker/CMakeLists.txt` |
| Package manager | vcpkg (manifest mode, `x64-linux` triplet) | `vcpkg.json` |

### Why use this?

- Skip weeks of Docker/vcpkg/gRPC configuration
- Start from a working multi-service architecture (includes a runnable example pipeline)
- Prebuilt images mean no local C++ toolchain is required to try it
- Learn multi-stage builds, vcpkg manifest mode, and GHCR publishing by example
- Replace the example parsing logic with your own business logic when you're ready

### What this template does *not* include

Being upfront about scope: this is infrastructure and an example pipeline, not a hardened product. It doesn't currently include authentication/authorization on the gRPC services, TLS between services (channels are created with `InsecureChannelCredentials`), automated tests, or Cassandra data modeling beyond the one example table. Add these as your project needs them — the point of the template is to get the plumbing (builds, images, CI, service wiring) out of your way, not to make those decisions for you.

---

## 📦 Using Prebuilt Images (Recommended)

`docker-compose.yml` is set up by default to pull ready-to-run images from GitHub Container Registry instead of compiling anything locally. Every push to `main` and every release rebuilds and republishes them via [`.github/workflows/publish-ghcr.yml`](.github/workflows/publish-ghcr.yml).

```bash
docker compose up -d
```

That's it — no C++ compiler, no vcpkg, no waiting for `grpc`/`protobuf`/`abseil`/the Cassandra driver to build from source. Compose pulls `ghcr.io/neuracollab/coordinator:latest` and `ghcr.io/neuracollab/worker:latest` and starts the full stack (Cassandra, `cassandra-web`, coordinator, 3 worker replicas) in seconds.

Open the web interface at http://localhost:3000, and tear it down with:

```bash
docker compose down
```

If you're changing the C++ code and need to build the images yourself, see [Quick Start (Local Development)](#quick-start-local-development) below.

---

## 🚀 Quick Start (Local Development)

Use this path when you're modifying the coordinator/worker C++ code and need to build the images yourself, rather than pulling the prebuilt ones above.

### 1. Prerequisites

- [Docker](https://www.docker.com/) with Compose v2 (`docker compose`)
- No local C++ toolchain, CMake, or vcpkg installation required — everything compiles inside the `base-vcpkg` build in the next step

### 2. Build the shared base image

First time, or whenever `vcpkg.json` changes:

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

A [`.devcontainer/`](.devcontainer/devcontainer.json) is included, wired to the same `docker-compose.yml`. Open the repo in VS Code and choose **Reopen in Container**.

Included out of the box:
- C++ IntelliSense (`ms-vscode.cpptools`)
- CMake Tools (`ms-vscode.cmake-tools`)
- Docker support (`ms-azuretools.vscode-docker`)
- A container attached to the `builder` stage (full toolchain + `gdb`), connected to the running Cassandra instance

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

## 🎯 Use Cases

- **Learning**: understand how C++ gRPC microservices talk to each other and to Cassandra, without first having to figure out how to wire vcpkg, multi-stage Docker, and CI together yourself
- **Prototyping**: quickly test a distributed system idea — coordinator/worker fan-out, a shared Cassandra store, a web UI — without setting up infrastructure by hand
- **Production base**: extend it with your own C++ business logic and ship it through the same CI/CD pipeline that already builds, validates, and publishes images on every push
- **Teaching**: demonstrate modern C++ containerization (vcpkg manifest mode, multi-stage builds, GHCR publishing) end to end, with a runnable example instead of slides

**Example applications you can build on top of this template:**
- Data parsing and ETL pipelines (the example included in this repo)
- Real-time data processing pipelines
- Distributed task queues
- Microservices with shared state in Cassandra
- High-performance backend services
- Web scraping and content aggregation systems

### Development Workflow

A typical loop for extending this template looks like:

1. Edit C++ source under `coordinator/` or `worker/` (or both).
2. Rebuild and run locally via the [Quick Start (Local Development)](#quick-start-local-development) path.
3. Verify with `docker compose ps` / `docker compose logs`, same as in [Verify It Works](#verify-it-works).
4. Push to a branch and open a PR — `.github/workflows/ci.yml` builds the images and brings the full stack up in CI to catch regressions.
5. Merge to `main` — `.github/workflows/publish-ghcr.yml` rebuilds and republishes `coordinator` and `worker` to GHCR automatically, so `docker compose up -d` on the prebuilt-images path picks up the change for anyone who pulls again.

---

## ⚙️ Configuration

Everything below is currently **hardcoded** in source or in `docker-compose.yml` — there's no environment-variable layer wired in yet. This table exists so you know exactly what to change and where, rather than pretending it's already configurable:

| Setting | Current value | Where it's defined |
|---|---|---|
| Cassandra contact point | `cassandra` | hardcoded in [`worker/worker.cpp`](worker/worker.cpp) (`cass_cluster_set_contact_points`) |
| Cassandra native port | `9042` (driver default) | not overridden anywhere in code |
| Coordinator gRPC listen address | `0.0.0.0:50051` | hardcoded in [`coordinator/main.cpp`](coordinator/main.cpp) |
| Worker → Coordinator address | `coordinator:50051` | hardcoded in [`worker/main.cpp`](worker/main.cpp) |
| Worker replica count | `3` | `docker-compose.yml` (`deploy.replicas`) |
| Web UI host port | `3000` | `docker-compose.yml` (`cassandra-web` port mapping) |

> `.env.example` at the repo root sketches out env vars for a future config-driven setup (`COORDINATOR_PORT`, `WORKER_PORT`, `CASSANDRA_SEEDS`, etc.), but none of them are actually read by the running services yet. Wiring these up via `getenv`/`argv` is a good first customization — see below.

---

## 🛠️ Customizing for Your Project

1. **Replace the example parsing logic**: edit [`coordinator/main.cpp`](coordinator/main.cpp) / [`coordinator/coordinator.cpp`](coordinator/coordinator.cpp) and [`worker/main.cpp`](worker/main.cpp) / [`worker/worker.cpp`](worker/worker.cpp) to implement your own business logic instead of the example fetch-parse-store pipeline.
2. **Update proto definitions**: modify [`proto_files/task.proto`](proto_files/task.proto), then rebuild the base image so the generated stubs pick up the change: `docker build -f docker/Dockerfile.vcpkg -t base-vcpkg:latest .`
3. **Add vcpkg dependencies**: edit [`vcpkg.json`](vcpkg.json), then rebuild the base image the same way.
4. **Change the Cassandra schema**: edit [`cassandra/setup.cql`](cassandra/setup.cql) to match your data model.
5. **Remove the example parsing code**: if your project doesn't need HTTP fetching or HTML parsing, drop the `curl`/`libxml2` usage in `worker/page_fetcher.*` and `worker/html_parser.*`, and the corresponding entries in `vcpkg.json`.

---

## 📦 Project Layout

```
vcpkg.json               # manifest: grpc, protobuf, abseil, curl, libxml2
docker/Dockerfile.vcpkg   # shared base image: toolchain + vcpkg deps + generated proto stubs
coordinator/Dockerfile    # multi-stage build -> minimal runtime image
worker/Dockerfile         # multi-stage build -> minimal runtime image
proto_files/              # .proto definitions (example: task distribution)
coordinator/              # example gRPC server (task distribution logic)
worker/                   # example gRPC client (parsing + Cassandra write)
cassandra/                # Cassandra init scripts (setup.cql)
docker-compose.yml        # local dev stack
.github/workflows/        # CI/CD: docker-compose validation + auto-publish to GHCR
.devcontainer/             # VS Code development environment
kubernetes/                # K8s manifests for production deployment
```

---

## 🖼️ Screenshots

### Docker Compose Stack
![Docker Compose Status](./assets/docker-compose-ps.png)

### Cassandra Web UI
![Cassandra Web UI](./assets/cassandra-web-ui.png)

### 📸 How to Update Screenshots

1. Run `docker compose up -d` and wait for `docker compose ps` to report `healthy`.
2. Take a screenshot of the terminal output of `docker compose ps` → save as `assets/docker-compose-ps.png`.
3. Open http://localhost:3000 → screenshot the Web UI → save as `assets/cassandra-web-ui.png`.
4. Commit: `git add assets/ && git commit -m "docs: add screenshots"`.
5. Recommended resolution: 1200×675 (16:9).

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

![Minikube Dashboard](./assets/minikube-dashboard.png)
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

- **Cassandra runs out of memory** → reduce limits (see `kubernetes/cassandra/cassandra-deployment.yaml` for the K8s path, or add resource limits under the `cassandra` service in `docker-compose.yml` for local dev).
- **gRPC/proto issues** → verify `.proto` files are in `proto_files/` and rebuild `base-vcpkg` so the generated stubs pick up the change.
- **A service fails to build against `base-vcpkg:latest`** → make sure you built it first — Compose does not build it automatically since it's referenced only via `FROM`, not as a compose service.
- **Port 3000 is busy** → change the host-side port mapping for `cassandra-web` in `docker-compose.yml`.
- **BuildKit cache issues / stale layers** → `docker builder prune`.
- **The example parsing worker fails** → check that `curl`/`libxml2` are present in the base image (they're part of the `vcpkg.json` manifest); a rebuild of `base-vcpkg` after any `vcpkg.json` edit usually fixes it.

**Resource requirements:**
- Minimum: 4GB RAM, 2 CPU cores
- Recommended: 8GB RAM, 4 CPU cores (for 3 worker replicas plus Cassandra)

---

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Opening a PR against `main` automatically runs `.github/workflows/ci.yml`, which builds `coordinator`/`worker` from your branch and brings the full stack up with `docker compose` — so a broken build or a service that fails to start shows up before review, not after merge.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 📚 Additional Resources

- [`proto_files/task.proto`](proto_files/task.proto) — the example service/message definitions
- [`vcpkg.json`](vcpkg.json) — the dependency manifest
- [`.github/workflows/publish-ghcr.yml`](.github/workflows/publish-ghcr.yml) — the GHCR publish pipeline
- [`cassandra/setup.cql`](cassandra/setup.cql) — the example Cassandra schema
