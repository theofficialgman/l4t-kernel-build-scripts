# Initial Build Scripts

## Dependencies

On Ubuntu Focal :

```sh
sudo apt-get install wget tar make git patch xz-utils gcc bc xxd build-essential bison flex python3 python3-distutils python3-dev swig python python-dev kmod
```

## Usage

```txt
Usage: l4t_kernel_prep_rel32.sh <dir>
Opions:
	ARCH=<cpu_architecture>	(default: arm64)
	CROSS_COMPILE=<cross_compiler> (default: aarch64-gnu-linux-)
	CPU=<number_of_threads> (Set the number of threads to use during compilation)
	PATCH=true (apply patches from patch directoy)
```

## Building without Docker

```sh
./l4t_kernel_prep_rel32.sh
```

## Building using Docker

```sh
docker run --rm -it -v $(pwd):/build registry.gitlab.com/switchroot/kernel/l4t-kernel-build-scripts:latest
```

The build files will be stored in the `kernel` directory.
Here's the files you should get after a successfull build :
```txt
Image
tegra210-icosa.dtb
modules.tar.gz
update.tar.gz
```

The rest of the files and directory are kept for later builds.
