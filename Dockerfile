# TODO: Figure out github caching

ARG LLVM_VERSION=15
ARG QEMU_VERSION=7.2.0
ARG SLIRP_VERSION=4.7.0

FROM debian:bullseye

ARG LLVM_VERSION
ARG QEMU_VERSION
ARG SLIRP_VERSION

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        git \
        gnupg \
        libglib2.0-dev \
        libpixman-1-dev \
        libzstd-dev \
        meson \
        ninja-build \
        software-properties-common \
        wget && \
    wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh ${LLVM_VERSION} && \
    rm llvm.sh && \
    ln -sf /usr/lib/llvm-${LLVM_VERSION}/bin/* /usr/bin && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://gitlab.freedesktop.org/slirp/libslirp.git -b v${SLIRP_VERSION}

RUN wget https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz && \
    tar -xf qemu-${QEMU_VERSION}.tar.xz

ENV CC=clang \
    CXX=clang++

RUN cd libslirp && \
    meson setup -Ddefault_library=both build && \
    ninja -C build install

RUN mkdir -p /out && \
    cd qemu-${QEMU_VERSION} && \
    ./configure \
        --prefix=/out \
        --target-list=x86_64-softmmu \
        --static \
        --enable-strip \
        --enable-lto \
        --enable-safe-stack \
        --without-default-features \
        --without-default-devices \
        --disable-curses \
        --enable-kvm \
        --enable-slirp \
        --enable-tcg \
        --enable-zstd && \
    ninja -C build install
