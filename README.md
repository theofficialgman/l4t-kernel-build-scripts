# Inital Build Scripts

## Usage

```txt
Usage: l4t_kernel_prep_rel32.sh [options]
Options:
  --compiler               Set Cross Compiler string
  -c, --cpus               CPU core number used for build
  -h, --help               Show this help text
  -k, --keep               Keep older build files
  -o, --output             Specify output dir
```

## Building using Docker

```sh
mkdir -p $(pwd)/out/
docker run --rm -it -v $(pwd)/out:/build alizkan/l4t_kernel_prep:latest
```

## Building without Docker

```sh
mkdir -p $(pwd)/out/
./l4t_kernel_prep_rel32.sh --compiler="aarch64-linux-gnu-" -o out
```
