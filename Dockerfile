FROM golang:latest AS golang-stage

WORKDIR /app

RUN wget https://raw.githubusercontent.com/buildbarn/bb-remote-execution/96c4fdce659fabfaba7ee2a60fd4e2ffab8352e2/cmd/fake_python/main.go

RUN go mod init fake_python \
    && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o fake_python

FROM curlimages/curl:latest AS curl-stage

WORKDIR /app

ARG BAZELISK_VER=1.18.0
RUN curl -L "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VER}/bazelisk-linux-amd64" -o bazelisk

FROM ghcr.io/troglobit/mg:latest AS mg-stage

FROM ubuntu:22.04 AS builder-stage

ARG DEBIAN_FRONTEND=noninteractive

ARG CLANG_VER=14
ARG GCC_VER=11
RUN apt update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang-$CLANG_VER \
    file \
    gcc-$GCC_VER \
    g++-$GCC_VER \
    libatomic1 \
    lld-$CLANG_VER \
    patch \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCC_VER 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VER 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-$GCC_VER 100

COPY --from=golang-stage /app/fake_python /usr/bin/fake_python
RUN ln -s /usr/bin/fake_python /usr/bin/python3

COPY --from=curl-stage --chown=root:root --chmod=755 /app/bazelisk /usr/bin/bazelisk
RUN ln -s /usr/bin/bazelisk /usr/bin/bazel

COPY --from=mg-stage /usr/bin/mg /usr/bin/mg
