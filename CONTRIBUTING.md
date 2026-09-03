# Contributing

Thanks for taking a look at this project. It's a Docker/vcpkg template for C++ gRPC + Cassandra microservices, with a small example pipeline — contributions to either the infrastructure or the example are welcome.

## Setting up a dev environment

You don't need a local C++ toolchain, CMake, or vcpkg — everything compiles inside Docker.

1. Fork and clone the repo.
2. Build the shared base image (first time, or whenever `vcpkg.json` changes):
   ```bash
   docker build -f docker/Dockerfile.vcpkg -t base-vcpkg:latest .
   ```
3. In `docker-compose.yml`, switch `coordinator`/`worker` from the prebuilt `image:` to their `build:` blocks (comment/uncomment — see the file).
4. Bring the stack up against your local build:
   ```bash
   docker compose up --build
   ```
5. Verify: `docker compose ps` should show `cassandra` as `healthy` and `coordinator`/`worker` as `Up`. `docker compose logs coordinator worker` should show tasks being processed.

See [README.md](README.md#quick-start-local-development) for more detail on this flow, and the [Customizing for Your Project](README.md#customizing-for-your-project) section if you're changing `.proto` definitions or `vcpkg.json` dependencies.

## Code style

There's no enforced formatter or linter configured in this repo yet. Match the style of the surrounding code (the existing `coordinator/`/`worker/` source uses fairly standard C++17 formatting) rather than introducing a new one in a drive-by change. If you want to add `clang-format`/`clang-tidy` config, that's a welcome contribution on its own — please do it as a separate PR from a functional change so the formatting diff doesn't bury the actual change.

## Submitting a PR

1. Create a feature branch: `git checkout -b feature/your-change`
2. Make your change and verify it locally (see above)
3. Push and open a PR against `main`
4. `.github/workflows/ci.yml` will automatically build `coordinator`/`worker` from your branch and bring the full stack up via `docker compose` — a broken build or a service that fails to start will show up as a failed check before review
5. Describe *what* changed and *why* in the PR description; if it's a behavior change to the example pipeline vs. the infrastructure/CI, say which

## Reporting issues

If you're filing a bug, include: the command you ran, what you expected, what actually happened, and `docker compose logs` output if a service is misbehaving. For infrastructure issues (Docker build, CI, vcpkg), mention your Docker version and OS.
