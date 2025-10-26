# Multi-stage Dockerfile for toaststunt (build + minimal runtime)
#
# Build stage: installs build deps, configures, compiles with CMake.
# Runtime stage: copies the built binary into the final image at
# /usr/src/toaststunt/build/moo so it matches your docker-compose command.
#
# Place this Dockerfile at the repository root (the build context must
# include CMakeLists.txt and the source tree).

FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies. Add other -dev packages here if CMake complains.
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
    ca-certificates \
    git \
    curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt

# Copy entire repo into the image (build context must contain project files)
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

# Install only runtime packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libstdc++6 \
    ca-certificates \
    libgmp10 \
    libssl3 \
    libreadline8 \
 && rm -rf /var/lib/apt/lists/*

# Keep the same working_dir expected by your docker-compose
WORKDIR /usr/src/toaststunt/build

# Copy the built executable(s) into the runtime image.
# The compose expects /usr/src/toaststunt/build/moo to exist and be runnable.
COPY --from=build /usr/src/toaststunt/build/moo ./moo

# If your program needs other files (configs, data, scripts), copy them here:
# COPY --from=build /usr/src/toaststunt/some/config /usr/src/toaststunt/config

# Expose the default port used in docker-compose (optional)
EXPOSE 7777

# Default command — matches how your compose calls the binary.
ENTRYPOINT ["/usr/src/toaststunt/build/moo"]