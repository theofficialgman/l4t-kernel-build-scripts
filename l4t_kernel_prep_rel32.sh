#!/bin/bash
set -e

create_update_modules()
{
    chown -R root:root "$1"
    find "$1" -type d -exec chmod 755 {} \;
    find "$1" -type f -exec chmod 644 {} \;
    find "$1" -name "*.sh" -type f -exec chmod 755 {} \;
    tar -C "$1" -czvpf "$2" .
}

Prepare_firmware()
{
	# Download and extract firmware
	mkdir -p "${firmware_dir}"
	wget -q -nc --show-progress https://developer.nvidia.com/embedded/L4T/r32_Release_v4.3/t210ref_release_aarch64/Tegra210_Linux_R32.4.3_aarch64.tbz2
	tar xf Tegra210_Linux_R32.4.3_aarch64.tbz2 Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	tar xf Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	mv "${BUILD_DIR}"/lib/firmware/* "${firmware_dir}"
}

Prepare()
{
	# Download Nvidia Bits
	echo "Downloading All Required Files, This may take a while..... Please Wait"
	wget -O "linux-nvgpu-r32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_kernel_nvgpu/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_kernel_nvgpu-lineage-16.0.tar.gz" >/dev/null
	wget -O "soc-tegra-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra-lineage-16.0.tar.gz" >/dev/null
	wget -O "soc-tegra-t210-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210-lineage-16.0.tar.gz" >/dev/null
	wget -O "platform-tegra-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common-lineage-16.0.tar.gz" >/dev/null
	wget -O "platform-tegra-t210-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common-lineage-16.0.tar.gz" >/dev/null

	# Clone Switchroot Bits
	git clone -b "${KERNEL_VER}" "https://gitlab.com/switchroot/l4t-kernel-4.9.git" >/dev/null
	git clone -b "${NVIDIA_VER}" "https://gitlab.com/switchroot/l4t-kernel-nvidia.git" >/dev/null
	git clone -b "${DTS_VER}" "https://gitlab.com/switchroot/l4t-platform-t210-switch.git" >/dev/null

	# Handle Standard Kernel Bits
	echo "Extracting and Patching L4T-Switch 4.9"
	mkdir -p "${KERNEL_DIR}"
	mv ./l4t-kernel-4.9 "${KERNEL_DIR}/kernel-4.9"
	echo "Done"

	# Handle Nvidia Kernel bits
	echo "Extracting Nvidia Kernel Stuff"
	mkdir -p "${KERNEL_DIR}"/nvidia
	mv ./l4t-kernel-nvidia*/* "${KERNEL_DIR}"/nvidia
	rm -rf ./l4t-kernel-nvidia*
	echo "Done"

	#Handle Switchroot DTS files
	echo "Extracting DTS stuff"
	mkdir -p "${KERNEL_DIR}"/hardware/nvidia/platform/t210/icosa
	mv ./l4t-platform-t210-switch*/* "${KERNEL_DIR}"/hardware/nvidia/platform/t210/icosa/
	rm -rf ./l4t-platform-t210-switch*
	echo "Done"

	# Extract and place nvidia bits
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
}

Build() {
	echo "Preparing Source and Creating Defconfig"
	cd "${KERNEL_DIR}/kernel-4.9" || exit
	mkdir -p "${BUILD_DIR}/Final/"
	cp arch/arm64/configs/tegra_linux_defconfig .config
	sed -i 's/CONFIG_EXTRA_FIRMWARE_DIR=.*/CONFIG_EXTRA_FIRMWARE_DIR="..\/firmware\/"/g' .config

	export KBUILD_BUILD_USER=user
	export KBUILD_BUILD_HOST=custombuild

	# Prepare Linux sources
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j"${CPUS}" olddefconfig
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j"${CPUS}" prepare
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j"${CPUS}" modules_prepare

	# Actually build kernel
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j"${CPUS}" tegra-dtstree="../hardware/nvidia"

	# Install kernel modules
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j"${CPUS}" modules_install INSTALL_MOD_PATH="${BUILD_DIR}/Final/"

	find "${BUILD_DIR}/Final/" -exec chmod 777 {} \;
	create_update_modules "${BUILD_DIR}"/Final/lib "${BUILD_DIR}"/Final/modules.tar.gz
	cp arch/arm64/boot/Image "${BUILD_DIR}"/Final/
	cp arch/arm64/boot/dts/tegra210-icosa.dtb "${BUILD_DIR}"/Final/
	rm -rf "${BUILD_DIR}"/Final/lib
	echo "Done"
}

# Retrieve last argument as output directory
BUILD_DIR="$(realpath "${@:$#}")"
KERNEL_DIR="${BUILD_DIR}/kernel_r32"
firmware_dir="${KERNEL_DIR}/firmware"

# Retrieve KERNEL_BRANCH variables corresponding to the build file branch to checkout
set -a && . "./KERNEL_VERSIONS" && set +a

[[ -z "${CROSS_COMPILE}" ]] && \
	echo "CROSS_COMPILE not set! Exiting.." && exit 1

[[ ! -d "${BUILD_DIR}" ]] && \
	echo "Not a valid directory! Exiting.." && exit 1

[[ ! "${CPUS}" =~ ^[0-9]{,2}$ || "${CPUS}" > $(nproc)  ]] && \
	echo "${CPUS} cores out of range or invalid, CPUS cores avalaible: $(nproc) ! Exiting..." && exit 1

cd "${BUILD_DIR}" || exit

# Download and prepare bits
if [[ ! -e "${firmware_dir}" && -z "$(ls "${firmware_dir}")" ]]; then Prepare_firmware;
	else echo "${firmware_dir} exists! Skipping firmware setup/download..."; fi

if [[ ! -e "${KERNEL_DIR}" ]]; then Prepare;
	else echo "${KERNEL_DIR} exists! Skipping kernel files setup/download..."; fi

Build
