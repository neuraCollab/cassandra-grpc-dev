# syntax: build context is ./coordinator (see docker-compose.yml)
#
# Requires the shared base image to be built first:
#   docker build -f ../docker/Dockerfile.vcpkg -t base-vcpkg:latest ..

FROM base-vcpkg:latest AS builder

ENV CMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake

WORKDIR /app
COPY . .

RUN mkdir -p build && \
    cd build && \
    VCPKG_TRIPLET=$(cat /vcpkg/triplet.txt) && \
    cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
          -DVCPKG_TARGET_TRIPLET=${VCPKG_TRIPLET} \
          -DVCPKG_INSTALLED_DIR=/app/vcpkg_installed \
          -DVCPKG_MANIFEST_MODE=OFF \
          -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc)

# --- Minimal runtime image ---
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libuv1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/build/coordinator ./coordinator

EXPOSE 50051
CMD ["./coordinator"]
