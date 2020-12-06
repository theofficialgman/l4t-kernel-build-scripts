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

Download/Pull the docker image :
```sh
docker pull alizkan/l4t-kernel:latest
```

Create a directory to store the build files and downloaded files :
```sh
mkdir -p $(pwd)/out/
```

Run the container to trigger the actuall build of the kernel :

```sh
docker run --rm -it -e CPUS=4 -v $(pwd)/out:/out registry.gitlab.com/switchroot/kernel/l4t-kernel-build-scripts:latest
```

THe build files will be stored in the directory you gave as a volume to the docker container (`$(pwd)/out/` here).
Here's the files you should get after a successfull build :
```txt
Image
tegra210-icosa.dtb
modules.tar.gz
update.tar.gz
```

The rest of the files and directory are kept for later builds.

### Docker tips
*You can override the workdir used in the docker, to use your own changes, without rebuilding the image by adding this repository directory as a volume to the docker command above.*

```sh
-v $(pwd):build/
```
