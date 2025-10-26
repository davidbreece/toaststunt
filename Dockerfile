# Multi-stage Dockerfile for toaststunt (build + minimal runtime)
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies (include pcre dev)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    bison \
    flex \
    gperf \
    pkg-config \
    nettle-dev \
    libargon2-dev \
    libssl-dev \
    libgmp-dev \
    libreadline-dev \
    libpcre3-dev \
    ca-certificates \
    git \
    curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt

# Copy project into image (build context must contain CMakeLists.txt)
COPY . /usr/src/toaststunt

# Optional quick checks during build (can be removed later)
RUN bison --version && flex --version && gperf --version && pkg-config --modversion nettle || true

# Configure & build
RUN mkdir -p build \
 && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && make -j$(nproc)

# Runtime stage: minimal image containing only runtime deps + binary
FROM ubuntu:22.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime packages, include libpcre3 for PCRE runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libstdc++6 \
    ca-certificates \
    libgmp10 \
    libssl3 \
    libreadline8 \
    libpcre3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt/build

# Copy the built executable(s) into the runtime image.
COPY --from=build /usr/src/toaststunt/build/moo ./moo

EXPOSE 7777

ENTRYPOINT ["/usr/src/toaststunt/build/moo"]