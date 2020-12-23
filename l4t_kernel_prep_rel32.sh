#!/bin/bash
set -e

# Kernel repo: https://gitlab.com/switchroot/l4t-kernel-4.9
KERNEL_VER=${KERNEL_VER:-"linux-rel32-rebase"}

# Kernel_nvidia repository: https://gitlab.com/switchroot/l4t-kernel-nvidia
NVIDIA_VER=${NVIDIA_VER:-"linux-rel32-rebase"}

# DTS repository: https://gitlab.com/switchroot/l4t-platform-t210-switch
DTS_VER=${DTS_VER:-"linux-rel32"}

# CM_Shield repository: https://gitlab.incom.co/CM-Shield/
LINEAGE_VER=${LINEAGE_VER:-"lineage-17.1"}

# Build variables
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-"user"}
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-"custombuild"}
export ARCH=${ARCH:-"arm64"}
export CROSS_COMPILE=${CROSS_COMPILE:-"aarch64-linux-gnu-"}
export CPUS=${CPUS:-$(($(getconf _NPROCESSORS_ONLN) - 1))}

# Retrieve last argument as output directory
BUILD_DIR="$(realpath "${@:$#}")"
KERNEL_DIR="${BUILD_DIR}/kernel_r32"
FW_DIR="${KERNEL_DIR}/firmware"
CWD="$(dirname "${BASH_SOURCE[0]}")"
PATCH_DIR="${CWD}/patch/"

create_update_modules()
{
	find "$1" -type d -exec chmod 755 {} \;
	find "$1" -type f -exec chmod 644 {} \;
	find "$1" -name "*.sh" -type f -exec chmod 755 {} \;
	fakeroot chown -R root:root "$1"
	tar -C "$1" -czvpf "$2" .
}

Prepare() {
	# Download Nvidia Bits
	echo "Downloading All Required Files, This may take a while..... Please Wait"
	wget -O "linux-nvgpu-r32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_kernel_nvgpu/-/archive/${LINEAGE_VER}/android_kernel_nvidia_linux-4.9_kernel_nvgpu-${LINEAGE_VER}.tar.gz" >/dev/null
	wget -O "soc-tegra-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra/-/archive/${LINEAGE_VER}/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra-${LINEAGE_VER}.tar.gz" >/dev/null
	wget -O "soc-tegra-t210-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210/-/archive/${LINEAGE_VER}/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210-${LINEAGE_VER}.tar.gz" >/dev/null
	wget -O "platform-tegra-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common/-/archive/${LINEAGE_VER}/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common-${LINEAGE_VER}.tar.gz" >/dev/null
	wget -O "platform-tegra-t210-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common/-/archive/${LINEAGE_VER}/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common-${LINEAGE_VER}.tar.gz" >/dev/null

	# Clone Switchroot Bits
	git clone -b "${KERNEL_VER}" "https://gitlab.com/switchroot/l4t-kernel-4.9.git" >/dev/null
	git clone -b "${NVIDIA_VER}" "https://gitlab.com/switchroot/l4t-kernel-nvidia.git" >/dev/null
	git clone -b "${DTS_VER}" "https://gitlab.com/switchroot/l4t-platform-t210-switch.git" >/dev/null

	# Handle Standard Kernel Bits
	echo "Extracting and Patching L4T-Switch 4.9"
	mkdir -p "${KERNEL_DIR}/hardware/nvidia/platform/t210/"
	mv l4t-kernel-4.9 "${KERNEL_DIR}/kernel-4.9"
	echo "Done"

	# Handle Nvidia Kernel bits
	echo "Extracting Nvidia Kernel Stuff"
	mv l4t-kernel-nvidia "${KERNEL_DIR}/nvidia"
	echo "Done"

	#Handle Switchroot DTS files
	echo "Extracting DTS stuff"
	mv l4t-platform-t210-switch/ "${KERNEL_DIR}/hardware/nvidia/platform/t210/icosa/"
	echo "Done"

	echo "Extracting Nvidia GPU Kernel Bits"
	mkdir -p "${KERNEL_DIR}"/nvgpu
	mkdir linux-nvgpu
	tar -xf "./linux-nvgpu-r32.2.2.tar.gz" -C linux-nvgpu --strip 1
	rm "./linux-nvgpu-r32.2.2.tar.gz"
	mv ./linux-nvgpu/* "${KERNEL_DIR}"/nvgpu
	rm -r linux-nvgpu
	echo "Done"

	echo "Extracting Tegra SOC Data"
	mkdir -p "${KERNEL_DIR}"/hardware/nvidia/soc/tegra/
	mkdir soc-tegra
	tar -xf "./soc-tegra-rel32.2.2.tar.gz" -C soc-tegra --strip 1
	rm "./soc-tegra-rel32.2.2.tar.gz"
	mv ./soc-tegra/* "${KERNEL_DIR}"/hardware/nvidia/soc/tegra/
	rm -r soc-tegra
	echo "Done"

	echo "Extracting T210 SOC Data"
	mkdir -p "${KERNEL_DIR}"/hardware/nvidia/soc/t210/
	mkdir soc-tegra-t210
	tar -xf "soc-tegra-t210-rel32.2.2.tar.gz" -C soc-tegra-t210 --strip 1
	rm "soc-tegra-t210-rel32.2.2.tar.gz"
	mv ./soc-tegra-t210/* "${KERNEL_DIR}"/hardware/nvidia/soc/t210/
	rm -r soc-tegra-t210
	echo "Done"

	echo "Extracting Tegra Common Platform Data"
	mkdir -p "${KERNEL_DIR}"/hardware/nvidia/platform/tegra/common/
	mkdir platform-tegra-common
	tar -xf "platform-tegra-common-rel32.2.2.tar.gz" -C platform-tegra-common --strip 1
	rm "platform-tegra-common-rel32.2.2.tar.gz"
	mv ./platform-tegra-common/* "${KERNEL_DIR}"/hardware/nvidia/platform/tegra/common/
	rm -r platform-tegra-common
	echo "Done"

	echo "Extracting T210 Common Platform Data"
	mkdir -p "${KERNEL_DIR}"/hardware/nvidia/platform/t210/common/
	mkdir common-t210
	tar -xf "platform-tegra-t210-common-rel32.2.2.tar.gz" -C common-t210 --strip 1
	rm "platform-tegra-t210-common-rel32.2.2.tar.gz"
	mv ./common-t210/* "${KERNEL_DIR}"/hardware/nvidia/platform/t210/common/
	rm -r common-t210
	echo "Done"

	echo "Download and extract tegra firmware"
	mkdir -p "${FW_DIR}" ${BUILD_DIR}/update ${BUILD_DIR}/modules
	wget -q -nc --show-progress https://developer.nvidia.com/embedded/L4T/r32_Release_v4.3/t210ref_release_aarch64/Tegra210_Linux_R32.4.3_aarch64.tbz2
	tar xf Tegra210_Linux_R32.4.3_aarch64.tbz2 Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	tar xf Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	mv "${BUILD_DIR}"/lib/firmware/* "${FW_DIR}"
	rm -rf Linux_for_Tegra usr/ lib/ etc/ var/ Tegra210_Linux_R32.4.3_aarch64.tbz2
	echo "Done"
}

Patch() {
	if [[ ${PATCH} == "true" ]]; then
		cd "${KERNEL_DIR}"
		echo "Applying patches"
		for patch in `ls ${PATCH_DIR}`; do
			patch -p1 < "${PATCH_DIR}/${patch}" || echo -e "\nPatch $patch failed"
		done
	fi
}

Build() {
	echo "Preparing Source and Creating Defconfig"

	mkdir -p "${BUILD_DIR}"
	
	cd "${KERNEL_DIR}/nvidia"
	git checkout ${NVIDIA_VER}

	cd "${KERNEL_DIR}/kernel-4.9"
	git checkout ${KERNEL_VER}

	cd "${KERNEL_DIR}"
	cp arch/arm64/configs/tegra_linux_defconfig .config

	# Prepare Linux sources
	make olddefconfig
	make prepare
	make modules_prepare

	# Actually build kernel
	make -j${CPUS} tegra-dtstree="../hardware/nvidia"

	make modules_install INSTALL_MOD_PATH=${MOD:-"${BUILD_DIR}/modules/"}
	make headers_install INSTALL_HDR_PATH=${HDR:-"${BUILD_DIR}/update/usr/"}
	echo "Done"
}

PostConfig() {
	find "${BUILD_DIR}/update/usr/include" -name *.install* -exec rm {} \;
	find "${BUILD_DIR}/update/usr/include" -exec chmod 777 {} \;
	
	create_update_modules "${BUILD_DIR}/modules/lib/" "${BUILD_DIR}/modules.tar.gz"
	create_update_modules "${BUILD_DIR}/update/" "${BUILD_DIR}/update.tar.gz"
	
	cp arch/arm64/boot/Image \
		arch/arm64/boot/dts/tegra210-icosa.dtb \
		${BOOT_DIR:-"${BUILD_DIR}"}

	rm -rf "${BUILD_DIR}/modules" \
		"${BUILD_DIR}/update/usr/include" \
		"${BUILD_DIR}/modules/lib/modules/4.9.140+/source" \
		"${BUILD_DIR}/modules/lib/modules/4.9.140+/build"

	cd "${CWD}"
}

if [[ -z ${ARCH} ]]; then
	echo "Target build ARCH not set! Exiting.." && exit 1
fi

if [[ -z "${CROSS_COMPILE}" ]] ; then
	echo "CROSS_COMPILE not set! Exiting.." && exit 1
fi

if [[ ! -d "${BUILD_DIR}" ]]; then
	echo "Not a valid directory! Exiting.." && exit 1
fi

cd "${BUILD_DIR}" || exit

if [[ ! -e ${KERNEL_DIR} ]]; then
	Prepare
fi

Patch
Build
PostConfig
