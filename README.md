# Initial Build Scripts

## Dependencies

On Ubuntu Focal :

```sh
sudo apt-get install wget tar make git patch xz-utils gcc bc xxd gcc-aarch64-linux-gnu build-essential bison flex python3 python3-distutils python3-dev swig python python-dev kmod
```

## Usage

```txt
Usage: l4t_kernel_prep_rel32.sh <dir>
```

## Building without Docker

```sh
mkdir -p $(pwd)/out/
export ARCH=arm64
export CPUS=4
export CROSS_COMPILE=aarch64-linux-gnu-
./l4t_kernel_prep_rel32.sh out/
```

## Building using Docker

```sh
mkdir -p $(pwd)/out/
docker run --rm -it -e CPUS=4 -v $(pwd)/out:/build alizkan/l4t-kernel:latest
```
