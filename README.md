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

You can also change the variables set in the file KERNEL_BRANCH to checkout different version of the kernel (default: latest kernel for L4T-Ubuntu).

## Building without Docker

```sh
mkdir -p $(pwd)/out/
ARCH=arm64 CPUS=4 CROSS_COMPILE=aarch64-linux-gnu- ./l4t_kernel_prep_rel32.sh out/
```

## Building using Docker

```sh
mkdir -p $(pwd)/out/
docker run --rm -it -e CPUS=4 -v $(pwd)/out:/out alizkan/l4t-kernel:latest
```

*You can override the workdir used in the docker, to use your own changes, without rebuilding the image by adding this repository directory as a volume to the docker command above.*

```sh
-v $(pwd):build/
```
