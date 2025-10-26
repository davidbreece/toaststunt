# build stage
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential cmake git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/toaststunt

# copy project into the image; build context must contain the project files (including CMakeLists.txt)
COPY . /usr/src/toaststunt

RUN mkdir -p build \
 && cd build \
 && cmake .. \
 && make -j$(nproc)

# runtime stage
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libstdc++6 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# adjust the path below to match the executable produced by your build
COPY --from=build /usr/src/toaststunt/build/my_executable /app/my_executable

ENTRYPOINT ["/app/my_executable"]
