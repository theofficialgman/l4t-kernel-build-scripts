# Initial Build Scripts

## Dependencies

```sh
sudo apt-get install bc wget git make
```

## Toolchain setup

Download and extract the [toolchain](https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz) ( In `/opt` for the example)

Then :

```sh
export  PATH=$PATH:/opt/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin
```

## Usage

```txt
Usage: l4t_kernel_prep_rel32.sh [options] <dir>
Options:
  --compiler               Set Cross Compiler string
  -c, --cpus               CPU core number used for build
  -h, --help               Show this help text
  -k, --keep               Keep older build files
```

## Building using Docker

```sh
mkdir -p $(pwd)/out/
docker run --rm -it -v $(pwd)/out:/build alizkan/l4t_kernel_prep:latest --cpus 4
```

## Building without Docker

```sh
mkdir -p $(pwd)/out/
./l4t_kernel_prep_rel32.sh --compiler "aarch64-linux-gnu-" --cpus 4 out/
```
