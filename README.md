Inital Build Scripts

Basic use:

1: ./l4t_kernel_prep_rel32.sh aarch64-linux-gnu- <num cpu cores +1>

2: cd kernel_r32/kernel-4.9

3: ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make modules_install INSTALL_MOD_PATH=< Path to mounted linux root>

4: cp arch/arm64/boot/Image </path/to/hos_partion/l4t-ubuntu/>

5: cp arch/arm64/boot/dts/tegra210-icosa.dtb </path/to/hos_partion/l4t-ubuntu/>

If using Cypress Wifi version:

1: follow above directions, excepting use ./l4t_kernel_prep_rel32_cypress_wifi.sh 

2: from step 5 above. cp ../wifi-driver/modules_out/* <Path to mounted linux root>/lib/modules/4.9.140+/

3: extract firmware tgz from here: https://community.cypress.com/servlet/JiveServlet/download/15330-5-37716/cypress-fmac-v4.14.34-2018_0716.zip

4: place all firmware files from firmware.tgz in <Path to mounted linux root>/usr/lib/firmware

5: Download https://raw.githubusercontent.com/lakka-switch/Lakka-LibreELEC/master/projects/Switch/firmwares/files/brcm/brcmfmac4356-pcie.txt and also place in <Path to mounted linux root>/usr/lib/firmware
4. Boot console, and run sudo depmod -a in terminal and reboot, and wifi should be working.
