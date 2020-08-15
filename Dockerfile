FROM ubuntu:focal
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir /build
WORKDIR /build

RUN apt update -y && apt upgrade -y && apt install -y wget tar make git patch xz-utils gcc bc xxd gcc-aarch64-linux-gnu build-essential bison flex python3 python3-distutils python3-dev swig python python-dev kmod

RUN mkdir proprietary_vendor_nvidia/ && cd proprietary_vendor_nvidia/ 
RUN git init
RUN git remote add -f origin https://gitlab.incom.co/CM-Shield/proprietary_vendor_nvidia/
RUN git config core.sparseCheckout true
RUN echo "t210/firmware/" >> .git/info/sparse-checkout
RUN git pull origin lineage-17.0

RUN cp -r t210/firmware/gm20b /usr/lib/firmware
RUN cp -r t210/firmware/tegra21x /usr/lib/firmware/
RUN cp t210/firmware/xusb/* /usr/lib/firmware/

ADD l4t_kernel_prep_rel32.sh /
RUN chmod +x /l4t_kernel_prep_rel32.sh

ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64
ARG CPUS=2
ENV CPUS=${CPUS}

VOLUME [ "/build" ]
ENTRYPOINT [ "/l4t_kernel_prep_rel32.sh" ]
