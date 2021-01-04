FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install -y \
	wget \
	tar \
	make \
	git \
	patch \
	xz-utils \
	gcc \
	bc \
	xxd \
	build-essential \
	bison \
	flex \
	python3 \
	python3-distutils \
	python3-dev \
	swig \
	python \
	python-dev \
	kmod \
	curl
RUN /bin/bash -c 'set -ex && \
    ARCH=`uname -m` && \
    if [ "$ARCH" != "aarch64" ]; then \
	apt install -y gcc-aarch64-linux-gnu; \
    fi'

VOLUME /build
WORKDIR /build
COPY . /build

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
RUN git config --global color.ui false

CMD /build/l4t_kernel_prep_rel32.sh 
