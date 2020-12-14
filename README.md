# Initial Build Scripts

## Dependencies

On Ubuntu Focal :

```sh
sudo apt-get install wget tar make git patch xz-utils gcc bc xxd gcc-aarch64-linux-gnu build-essential bison flex python3 python3-distutils python3-dev swig python python-dev kmod
```

## Usage

```txt
Usage: l4t_kernel_prep_rel32.sh <dir>
Opions:
	KERNEL_VER=<l4t-kernel-branch> (default: linux-rel32-rebase)
	NVIDIA_VER=<l4tt-nvidia-branch> (default: linux-rel32-rebase)
	DTS_VER=<l4t-dts-branch> (default: linux-rel32)
	LINEAGE_VER=<lineage_version> (default: 17.1)
	MOD=<modules_directory>
	HDR=<headers_directory>
	BOOT_DIR=<boot_directory>
	ARCH=<cpu_architecture>	(default: arm64)
	CROSS_COMPILE=<cross_compiler> (default: aarch64-gnu-linux-)
	CPU=<number_of_threads> (Set the number of threads to use durinmg compilation)
	PATCH=true (applies patch from patch directoy)
```

## Building without Docker

```sh
mkdir -p $(pwd)/out/
./l4t_kernel_prep_rel32.sh out/
```

## Building using Docker

Run the container to trigger the actual build of the kernel, it will create the `out` dir if it doesn't exist and pull the docker image  if it cannot be found :

```sh
docker run --rm -it -v $(pwd)/out:/out registry.gitlab.com/switchroot/kernel/l4t-kernel-build-scripts:latest
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
