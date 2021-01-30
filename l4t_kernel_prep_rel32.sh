#!/bin/bash
set -e

# Build variables
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-"user"}
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-"custombuild"}
export ARCH=${ARCH:-"arm64"}
if [[ `uname -m` != aarch64 ]]; then
	export CROSS_COMPILE=${CROSS_COMPILE:-"aarch64-linux-gnu-"}
fi
export CPUS=${CPUS:-$(($(getconf _NPROCESSORS_ONLN) - 1))}

# Retrieve last argument as output directory
CWD="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
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
	curl https://storage.googleapis.com/git-repo-downloads/repo-1 > repo
	chmod a+x repo
	python3 repo init -u . -m default.xml -b master
	python3 repo sync --force-sync --jobs=${CPUS}
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
