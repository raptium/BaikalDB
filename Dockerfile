FROM ubuntu:20.04 as builder

# install dependencies
RUN apt-get update 
RUN apt-get install -y wget \
    build-essential autoconf automake libtool flex bison \
    libssl-dev libz-dev

# install bazelisk
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.7.4/bazelisk-linux-amd64 \
    -O /usr/local/bin/bazelisk \
    && chmod +x /usr/local/bin/bazelisk

# copy sources
RUN mkdir -p /app/src
WORKDIR /app/src
COPY . .

# build all
RUN bazelisk build //:all

# create executing image
FROM ubuntu:20.04

# install runtime dependencies
RUN apt-get update
RUN apt-get install -y \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

# copy artifacts 
COPY --from=builder /app/src/bazel-bin/baikaldb /app/bin/baikaldb
COPY --from=builder /app/src/bazel-bin/baikalMeta /app/bin/baikalMeta
COPY --from=builder /app/src/bazel-bin/baikalStore /app/bin/baikalStore
COPY ./conf /app/conf
COPY ./src/tools/script /app/script
COPY ./entrypoint.sh /app/entrypoint.sh

# set entrypoint
ENV PATH /app/bin:$PATH
WORKDIR /app/
RUN mkdir -p /app/log/
ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "db" ]