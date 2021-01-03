#!/bin/bash
set -e

# Kernel repo: https://gitlab.com/switchroot/l4t-kernel-4.9
KERNEL_VER=${KERNEL_VER:-"linux-rel32-rebase"}
# Kernel_nvidia repository: https://gitlab.com/switchroot/l4t-kernel-nvidia
NVIDIA_VER=${NVIDIA_VER:-"linux-rel32-rebase"}
# DTS repository: https://gitlab.com/switchroot/l4t-platform-t210-switch
DTS_VER=${DTS_VER:-"linux-rel32"}

# Build variables
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-"user"}
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-"custombuild"}
export ARCH=${ARCH:-"arm64"}
export CROSS_COMPILE=${CROSS_COMPILE:-"aarch64-linux-gnu-"}
export CPUS=${CPUS:-$(($(getconf _NPROCESSORS_ONLN) - 1))}

# Retrieve last argument as output directory
CWD="$(dirname "${BASH_SOURCE[0]}")"
KERNEL_DIR="${CWD}/kernel"
FW_DIR="${KERNEL_DIR}/firmware"
PATCH_DIR="${CWD}/patch/"

create_update_modules() {
	find "$1" -type d -exec chmod 755 {} \;
	find "$1" -type f -exec chmod 644 {} \;
	find "$1" -name "*.sh" -type f -exec chmod 755 {} \;
	fakeroot chown -R root:root "$1"
	tar -C "$1" -czvpf "$2" .
}

Prepare() {
	mkdir -p "${FW_DIR}" "${KERNEL_DIR}/update" "${KERNEL_DIR}/modules"

	repo init -b master -u https://gitlab.com/switchroot/kernel/l4t-kernel-build-scripts/
	repo sync --force-sync --jobs ${CPUS}

	git -C "${KERNEL_DIR}/kernel-4.9" checkout -b "${KERNEL_VER}" 
	git -C "${KERNEL_DIR}/nvidia" checkout -b "${NVIDIA_VER}" 
	git -C "${KERNEL_DIR}/hardware/nvidia/platform/t210/icosa/" checkout -b "${DTS_VER}" 

	echo "Download and extract tegra firmware"
	wget -q -nc --show-progress https://developer.nvidia.com/embedded/L4T/r32_Release_v4.3/t210ref_release_aarch64/Tegra210_Linux_R32.4.3_aarch64.tbz2
	tar xf Tegra210_Linux_R32.4.3_aarch64.tbz2 Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	tar xf Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2
	mv "${CWD}"/lib/firmware/* "${FW_DIR}"
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

	cd "${KERNEL_DIR}/kernel-4.9"
	cp arch/arm64/configs/tegra_linux_defconfig .config

	# Prepare Linux sources
	make olddefconfig
	make prepare
	make modules_prepare
	
	# Build kernel
	make -j${CPUS} tegra-dtstree="../hardware/nvidia"
	make modules_install INSTALL_MOD_PATH="${KERNEL_DIR}/modules/"
	make headers_install INSTALL_HDR_PATH="${KERNEL_DIR}/update/usr/"
}

PostConfig() {
	find "${KERNEL_DIR}/update/usr/include" -name *.install* -exec rm {} \;
	find "${KERNEL_DIR}/update/usr/include" -exec chmod 777 {} \;
	create_update_modules "${KERNEL_DIR}/modules/lib/" "${KERNEL_DIR}/modules.tar.gz"
	create_update_modules "${KERNEL_DIR}/update/" "${KERNEL_DIR}/update.tar.gz"

	cp arch/arm64/boot/Image arch/arm64/boot/dts/tegra210-icosa.dtb "${KERNEL_DIR}"

	rm -rf "${KERNEL_DIR}/modules" "${KERNEL_DIR}/update/usr/include" \
		"${KERNEL_DIR}/modules/lib/modules/4.9.140+/source" \
		"${KERNEL_DIR}/modules/lib/modules/4.9.140+/build"
	echo "Done"
}

Prepare
Patch
Build
PostConfig
