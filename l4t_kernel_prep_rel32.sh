 #!/bin/bash

CROSS_COMPILER_STRING=$1
if [[ "$1x" == "x" ]]; then
	echo "Cross Compiler not defined, exiting."
	exit
fi

if [[ "$2x" == "x" ]]; then
	echo "Number of cores to build with not set Generally this should be Number of CPU cores + 1"
	exit
fi
#Download Nvidia Bits

echo "Downloading All Required Files, This may take a while..... Please Wait"
wget -O "linux-nvgpu-r32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_kernel_nvgpu/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_kernel_nvgpu-lineage-16.0.tar.gz" > /dev/null
wget -O "soc-tegra-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_tegra-lineage-16.0.tar.gz" > /dev/null
wget -O "soc-tegra-t210-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_soc_t210-lineage-16.0.tar.gz" > /dev/null
wget -O "platform-tegra-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_tegra_common-lineage-16.0.tar.gz" > /dev/null
wget -O "platform-tegra-t210-common-rel32.2.2.tar.gz" "https://gitlab.incom.co/CM-Shield/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common/-/archive/lineage-16.0/android_kernel_nvidia_linux-4.9_hardware_nvidia_platform_t210_common-lineage-16.0.tar.gz" > /dev/null


#Clone Switchroot Bits

git clone -b linux-rel32 "https://gitlab.com/switchroot/l4t-kernel-4.9.git" > /dev/null
git clone -b linux-rel32 "https://gitlab.com/switchroot/l4t-kernel-nvidia.git" > /dev/null
git clone -b linux-rel32 "https://gitlab.com/switchroot/l4t-platform-t210-switch.git" > /dev/null

KERNEL_DIR=$(pwd)"/kernel_r32/kernel-4.9"
CURPWD=$(pwd)

#Handle Standard Kernel Bits
echo "Extracting and Patching L4T-Switch 4.9"
mkdir -p kernel_r32
mv ./l4t-kernel-4.9 $KERNEL_DIR
cd $KERNEL_DIR
#put patch files for kernel repo after this line
cd $CURPWD
echo "Done"

#Handle Nvidia Kernel bits
echo "Extracting Nvidia Kernel Stuff"
mkdir -p ./kernel_r32/nvidia
mv ./l4t-kernel-nvidia*/* ./kernel_r32/nvidia
rm -r ./l4t-kernel-nvidia*
echo "Done"

#Handle Switchroot DTS files
echo "Extracting DTS stuff"
mkdir -p ./kernel_r32/hardware/nvidia/platform/t210/icosa
cd l4t-platform-t210-switch
cd $CURPWD
mv ./l4t-platform-t210-switch*/* ./kernel_r32/hardware/nvidia/platform/t210/icosa/
rm -r ./l4t-platform-t210-switch*
echo "Done"

#Extract and place nvidia bits
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

echo "Preparing Source and Creating Defconfig"
cd $KERNEL_DIR
cp arch/arm64/configs/tegra_linux_defconfig .config
#Patch Defconfig

#Prepare Linux sources
ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILER_STRING make olddefconfig
ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILER_STRING make prepare
ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILER_STRING make modules_prepare

#Actually build kernel
ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILER_STRING make -j$2 tegra-dtstree="../hardware/nvidia"
echo "Done"

echo "Finished"
