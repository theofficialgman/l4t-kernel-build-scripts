FROM ubuntu:19.10
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir /build
WORKDIR /build

RUN apt update -y && apt upgrade -y && apt install -y wget tar make git patch xz-utils gcc bc xxd
RUN wget https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz -P /build
RUN tar xf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
RUN mv gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu /opt
ENV PATH=$PATH:/opt/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin

ADD tegra21x /lib/firmware/tegra21x
ADD tegra21x_xusb_firmware /lib/firmware/
ADD gm20b /lib/firmware/gm20b
ADD l4t_kernel_prep_rel32.sh /
RUN chmod +x /l4t_kernel_prep_rel32.sh

VOLUME [ "/build" ]
ENTRYPOINT [ "/l4t_kernel_prep_rel32.sh", "--compiler=aarch64-linux-gnu-", "--output=/build" ]
