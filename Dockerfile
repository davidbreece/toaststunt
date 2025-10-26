# Build stage
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Install required build tools (use nettle-dev on jammy)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    bison \
    flex \
    gperf \
    pkg-config \
    nettle-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt

# Copy project into image (build context must include CMakeLists.txt)
COPY . /usr/src/toaststunt

# Optional: verify build tools are present (remove once debugged)
RUN bison --version && flex --version && gperf --version && pkg-config --modversion nettle

# Build
RUN mkdir -p build \
 && cd build \
 && cmake .. \
 && make -j$(nproc)

# Runtime stage
FROM ubuntu:22.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends libstdc++6 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Replace <your_executable> with the actual binary name produced by your build
COPY --from=build /usr/src/toaststunt/build/<your_executable> /app/<your_executable>

ENTRYPOINT ["/app/<your_executable>"]