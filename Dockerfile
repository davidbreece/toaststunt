# Build stage
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and nettle dev package
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    bison \
    flex \
    gperf \
    pkg-config \
    libnettle-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt

# Copy project into image (context must include CMakeLists.txt)
COPY . /usr/src/toaststunt

# Optional debug: confirm nettle is present
RUN pkg-config --modversion nettle && pkg-config --cflags nettle

# Build
RUN mkdir -p build \
 && cd build \
 && cmake .. \
 && make -j$(nproc)

# Runtime stage
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libstdc++6 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Replace <your_executable> below with the real binary produced by your build
COPY --from=build /usr/src/toaststunt/build/<your_executable> /app/<your_executable>

ENTRYPOINT ["/app/<your_executable>"]