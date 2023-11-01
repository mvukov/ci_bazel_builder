FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ARG BAZELISK_VER=1.18.0
ARG GCC_VER=11
ARG CLANG_VER=14

RUN apt update && apt-get install -y --no-install-recommends \
    clang-$CLANG_VER \
    curl \
    gcc-$GCC_VER \
    g++-$GCC_VER \
    libatomic1 \
    lld-$CLANG_VER \
    patch \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-$CLANG_VER 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCC_VER 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VER 100

RUN curl -L "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VER}/bazelisk-linux-amd64" -o /usr/local/bin/bazelisk \
    && chmod +x /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

# Based on https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user
ARG USERNAME=ci
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
