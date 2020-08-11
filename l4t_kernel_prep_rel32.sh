#!/bin/bash

Prepare() {
	cd ${BUILD_DIR}

	# Download Nvidia Bits
	echo "Downloading All Required Files, This may take a while..... Please Wait"
	wget -O "linux-nvgpu-r32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_kernel_nvgpu/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_kernel_nvgpu-lineage-16.0.tar.gz" > /dev/null
	wget -O "soc-tegra-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra-lineage-16.0.tar.gz" > /dev/null
	wget -O "soc-tegra-t210-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210-lineage-16.0.tar.gz" > /dev/null
	wget -O "platform-tegra-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common-lineage-16.0.tar.gz" > /dev/null
	wget -O "platform-tegra-t210-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common-lineage-16.0.tar.gz" > /dev/null

	# Clone Switchroot Bits
	git clone -b linux-3.0.2 "https://gitlab.com/switchroot/l4t-kernel-4.9.git" > /dev/null
	git clone -b linux-3.0.1 "https://gitlab.com/switchroot/l4t-kernel-nvidia.git" > /dev/null
	git clone -b linux-rel32 "https://gitlab.com/switchroot/l4t-platform-t210-switch.git" > /dev/null

	# Handle Standard Kernel Bits
	echo "Extracting and Patching L4T-Switch 4.9"
	mkdir -p ${KERNEL_DIR}
	mv ./l4t-kernel-4.9 "${KERNEL_DIR}/kernel-4.9"
	echo "Done"

	# Handle Nvidia Kernel bits
	echo "Extracting Nvidia Kernel Stuff"
	mkdir -p ./kernel_r32/nvidia
	mv ./l4t-kernel-nvidia*/* ./kernel_r32/nvidia
	rm -rf ./l4t-kernel-nvidia*
	echo "Done"

	#Handle Switchroot DTS files
	echo "Extracting DTS stuff"
	mkdir -p ./kernel_r32/hardware/nvidia/platform/t210/icosa
	cd l4t-platform-t210-switch
	cd ${BUILD_DIR}
	mv ./l4t-platform-t210-switch*/* ./kernel_r32/hardware/nvidia/platform/t210/icosa/
	rm -rf ./l4t-platform-t210-switch*
	echo "Done"

	# Extract and place nvidia bits
	echo "Extracting Nvidia GPU Kernel Bits"
	mkdir -p ./kernel_r32/nvgpu
	mkdir linux-nvgpu
	tar -xf "./linux-nvgpu-r32.2.2.tar.gz" -C linux-nvgpu --strip 1
	rm "./linux-nvgpu-r32.2.2.tar.gz"
	mv ./linux-nvgpu/* ./kernel_r32/nvgpu
	rm -r linux-nvgpu
	echo "Done"

	echo "Extracting Tegra SOC Data"
	mkdir -p ./kernel_r32/hardware/nvidia/soc/tegra/
	mkdir soc-tegra
	tar -xf "./soc-tegra-rel32.2.2.tar.gz" -C soc-tegra --strip 1
	rm "./soc-tegra-rel32.2.2.tar.gz"
	mv ./soc-tegra/* ./kernel_r32/hardware/nvidia/soc/tegra/
	rm -r soc-tegra
	echo "Done"

	echo "Extracting T210 SOC Data"
	mkdir -p ./kernel_r32/hardware/nvidia/soc/t210/
	mkdir soc-tegra-t210
	tar -xf "soc-tegra-t210-rel32.2.2.tar.gz" -C soc-tegra-t210 --strip 1
	rm "soc-tegra-t210-rel32.2.2.tar.gz"
	mv ./soc-tegra-t210/* ./kernel_r32/hardware/nvidia/soc/t210/
	rm -r soc-tegra-t210
	echo "Done"

	echo "Extracting Tegra Common Platform Data"
	mkdir -p ./kernel_r32/hardware/nvidia/platform/tegra/common/
	mkdir platform-tegra-common
	tar -xf "platform-tegra-common-rel32.2.2.tar.gz" -C platform-tegra-common --strip 1
	rm "platform-tegra-common-rel32.2.2.tar.gz"
	mv ./platform-tegra-common/* ./kernel_r32/hardware/nvidia/platform/tegra/common/
	rm -r platform-tegra-common
	echo "Done"

	echo "Extracting T210 Common Platform Data"
	mkdir -p ./kernel_r32/hardware/nvidia/platform/t210/common/
	mkdir common-t210
	tar -xf "platform-tegra-t210-common-rel32.2.2.tar.gz" -C common-t210 --strip 1
	rm "platform-tegra-t210-common-rel32.2.2.tar.gz"
	mv ./common-t210/* ./kernel_r32/hardware/nvidia/platform/t210/common/
	rm -r common-t210
	echo "Done"
}

Build() {
	echo "Preparing Source and Creating Defconfig"
	cd "${BUILD_DIR}/${KERNEL_DIR}/kernel-4.9"
	cp arch/arm64/configs/tegra_linux_defconfig .config

	#Prepare Linux sources
	ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILER_STRING}  make olddefconfig
	ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILER_STRING}  make prepare
	ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILER_STRING}  make modules_prepare

	#Actually build kernel
	ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILER_STRING} make -j${cpus} tegra-dtstree="../hardware/nvidia"

	mkdir ${BUILD_DIR}/Final/
	ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILER_STRING} make modules_install INSTALL_MOD_PATH=${BUILD_DIR}/Final/

	cp arch/arm64/boot/Image ${BUILD_DIR}/Final/
	cp arch/arm64/boot/dts/tegra210-icosa.dtb ${BUILD_DIR}/Final/
	echo "Done"
}

usage() {
    echo "Usage: $0 [options] <dir>"
    echo "Options:"
        echo " --compiler               Set Cross Compiler string"
        echo " -c, --cpus               CPU core number used for build"
        echo " -h, --help               Show this help text"
        echo " -k, --keep               Keep older build files"
}

# Parse arguments
options=$(getopt -n $0 -o c:o:hk -a --long compiler:,cpus:,output:,help,keep -- "$@")

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# Evaluate arguments
eval set -- "${options}"
while true; do
    case "$1" in
        --compiler) CROSS_COMPILER_STRING=$2; shift ; shift ;;
        -c | --cpus) cpus=$2; shift ; shift ;;
        -k | --keep) keep=true; shift ;;
        ?  | -h | --help) usage; exit 0 ;;
        -- ) shift; break ;;
    esac
done

# Store last arg as output dir
out=$(realpath ${@:$#})

if [[ -z ${CROSS_COMPILER_STRING} ]] || [[ ! -d ${out} ]]; then
	usage; exit 0
fi

# Set buld dir
BUILD_DIR=$(realpath ${out})

# Set kernel dirname
KERNEL_DIR="kernel_r32"

# Donwload and prepare bits
[[ ${keep} != true ]] && rm -rf ${BUILD_DIR}/* && Prepare

# Check if cpus have been set correctly and build
[[ ${cpus} =~ ^[0-9]{,2}$ && ! ${cpus} > $(nproc) ]] && Build
