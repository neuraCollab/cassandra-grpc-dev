# syntax: build context is ./worker (see docker-compose.yml)
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
COPY --from=builder /app/build/worker ./worker
# libcassandra is a shared library with no vcpkg/apt package; ship the one
# built in the base image alongside the binary.
COPY --from=builder /usr/local/lib/libcassandra.so* /usr/local/lib/
RUN ldconfig

EXPOSE 50051
CMD ["./worker"]
