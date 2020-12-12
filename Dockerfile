FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive

RUN chmod 1777 /tmp

RUN apt update -y && apt install -y wget tar make git patch xz-utils gcc bc xxd build-essential bison flex python3 python3-distutils python3-dev swig python python-dev kmod ash
RUN /bin/ash -c 'set -ex && \
    ARCH=`uname -m` && \
    if [ "$ARCH" != "aarch64" ]; then \
	echo "x86_64" && \
	apt install -y gcc-aarch64-linux-gnu; \
    fi'

ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64
ARG CPUS=2
ENV CPUS=${CPUS}

VOLUME /out
WORKDIR /build

COPY . /build/
RUN chmod +x /build/l4t_kernel_prep_rel32.sh
ENTRYPOINT /build/l4t_kernel_prep_rel32.sh /out/
