#!/bin/bash

# -------------------- Set variables --------------------
pd=23.1.0
toolchain_source=/opt/ampliphy-vendor-xwayland/BSP-Yocto-NXP-i.MX8MP-PD23.1.0/environment-setup-cortexa53-crypto-phytec-linux
toolchain_sysroot=/opt/ampliphy-vendor-xwayland/BSP-Yocto-NXP-i.MX8MP-PD23.1.0/sysroots/cortexa53-crypto-phytec-linux

yocto_dir=~/phyLinux
yocto_source=sources/poky/oe-init-build-env
yocto_kernel=${yocto_dir}/build/tmp/work/phyboard_pollux_imx8mp_3-phytec-linux/linux-imx/5.15.71-r0.0/build/arch/arm64/boot/Image

ddr_firmware=firmware-imx-8.18.1
device_tree=imx8mp-phyboard-pollux-rdk-falcon

# ----------------------------------------
# lsblk -e7  # list SD cards
# sdcard=/dev/mmcblk0  # PCO laptop internal SD card reader
# sdcard=/dev/sda      # PCO laptop external SD card reader
# sdcard=/dev/sdb      # jarsulk home PC

# ----------------------------------------
default="\e[0m"
red="\e[31m"
yellow="\e[33m"
kernel_yocto=$1
normal_falcon=$2
sdcard=$3

function help_and_exit
{
	echo "usage:"
	echo "./scripts/3-compile_and_write_to_sd_card.sh [kernel|yocto] [normal|falcon] sd_card_device"
	echo "  sd_card_device - /dev/mmcblk0 or /dev/sdx"
	echo "  type           - 'lsblk -e7' to list SD card devices"
	exit
}

if [ "$#" -ne 3 ]; then help_and_exit; fi
if [[ "${kernel_yocto}" != "kernel" && "${kernel_yocto}" != "yocto" ]]; then help_and_exit; fi
if [[ "${normal_falcon}" != "normal" && "${normal_falcon}" != "falcon" ]]; then help_and_exit; fi

if [ ! -f "${toolchain_source}" ]; then
	echo -e "${red}Error: BSP toolchain not exists:\n${toolchain_source}\nSet toolchain_source variable.${default}"
	exit 1
fi
if [ ! -d "${toolchain_sysroot}" ]; then
	echo -e "${red}Error: BSP toolchain folder not exists:\n${toolchain_sysroot}\nSet toolchain_sysroot variable.${default}"
	exit 1
fi

if [[ "${kernel_yocto}" == "yocto" && (! -d "${yocto_dir}") ]]; then
	echo -e "${red}Error: Folder '${yocto_dir}' not found.${default}"
	exit 1
fi
if [[ "${kernel_yocto}" == "yocto" && (! -f "${yocto_dir}/${yocto_source}") ]]; then
	echo -e "${red}Error: File '${yocto_dir}/${yocto_source}' not found.${default}"
	exit 1
fi

if [ ! -d "${firmware}/" ]; then
	echo -e "${red}Error: Folder '${firmware}/' not found.${default}"
	exit 1
fi
if [ ! -d "imx-atf/" ]; then
	echo -e "${red}Error: Folder 'imx-atf/' not found.${default}"
	exit 1
fi
if [ ! -d "imx-mkimage/" ]; then
	echo -e "${red}Error: Folder 'imx-mkimage/' not found.${default}"
	exit 1
fi
if [ ! -d "u-boot-imx/" ]; then
	echo -e "${red}Error: Folder 'u-boot-imx/' not found.${default}"
	exit 1
fi

if [[ "${kernel_yocto}" == "kernel" && ! -d "linux-imx/" ]]; then
	echo -e "${red}Error: Folder 'linux-imx/' not found.${default}"
	exit 1
fi
if [[ "${kernel_yocto}" == "yocto" && ! -f ${yocto_kernel} ]]; then
	echo -e "${red}Error: File '${yocto_kernel}' not exists.${default}"
	exit 1
fi

if [ -z "${USER}" ]; then
	echo -e "${red}Error: Variable 'USER' not defined in script.${default}"
	exit 1
fi

if grep "${sdcard}" /etc/mtab > /dev/null 2>&1; then
	echo -n ""
else
	lsblk -e7
	echo -e "\n${red}Error: SD card '${sdcard}' not found in devices.${default}"
	exit 1
fi

clear
echo -e "${yellow}USER = $USER"
echo -e "sdcard = $sdcard"
echo -e "pd = $pd"
echo -e "toolchain source = ${toolchain_source}"
echo -e "toolchain sysroot = ${toolchain_sysroot}"
echo -e "${default}"
lsblk -e7
echo

# Phytec SDK toolchain
source ${toolchain_source}
set sysroot ${toolchain_sysroot}

sleep 2

echo "-------------------- ATF --------------------"
cd imx-atf/

# rm -rf build/
# make distclean
make -j16 PLAT=imx8mp IMX_BOOT_UART_BASE=0x30890000 IMX_BOOT_UART_BASE=0x30860000 LDFLAGS= bl31
cp build/imx8mp/release/bl31.bin ../imx-mkimage/iMX8M/  # 1
cd ..

if [ ! -f imx-atf/build/imx8mp/release/bl31.bin ]; then
	echo -e "${red}Error: File imx-atf/build/imx8mp/release/bl31.bin not exists.${default}"
	exit 1
else
	echo -e "${yellow}"
	ls -al imx-atf/build/imx8mp/release/bl31.bin
	echo -e "${default}"
fi

echo "-------------------- U-boot --------------------"
cd u-boot-imx/
# Device Tree:
#   u-boot-imx/arch/arm/dts/imx8mp-phyboard-pollux-rdk.dts
#   u-boot-imx/arch/arm/dts/imx8mp-phycore-som.dtsi
#   u-boot-imx/arch/arm/dts/imx8mp.dtsi
# make distclean  # 4
make phycore-imx8mp_defconfig
cp ../$ddr_firmware/firmware/ddr/synopsys/lpddr4* .
make -j $(nproc --all)

if [ ! -f u-boot.bin ]; then
	echo -e "${red}Error: File u-boot-imx/u-boot.bin not exists.${default}"
	exit 1
fi
if [ ! -f u-boot-spl-ddr.bin ]; then
	echo -e "${red}Error: File u-boot-imx/u-boot-spl-ddr.bin not exists.${default}"
	exit 1
fi

cp u-boot*.bin ../imx-mkimage/iMX8M/  # 5
cp spl/u-boot-spl*.bin ../imx-mkimage/iMX8M/
cp arch/arm/dts/imx8mp-phyboard-pollux-rdk.dtb ../imx-mkimage/iMX8M/  # 6
cp tools/mkimage ../imx-mkimage/iMX8M/mkimage_uboot  # 7
cd ..

echo "-------------------- mkimage --------------------"
cd imx-mkimage/  # 8
cp ../$ddr_firmware/firmware/ddr/synopsys/lpddr4* ../imx-mkimage/iMX8M/  # 2
# cp ../$ddr_firmware/firmware/hdmi/cadence/signed_hdmi_imx8m.bin ../imx-mkimage/iMX8M/
make SOC=iMX8MP dtbs=imx8mp-phyboard-pollux-rdk.dtb flash_evk

if [ "${normal_falcon}" == "falcon" ]; then
	make SOC=iMX8MP dtbs=imx8mp-phyboard-pollux-rdk.dtb flash_evk_falcon
fi
cd ..

if [ ! -f imx-mkimage/iMX8M/flash.bin ]; then
	echo -e "${red}Error: File imx-mkimage/iMX8M/flash.bin not exists.${default}"
	exit 1
else
	echo -e "${yellow}"
	ls -al imx-mkimage/iMX8M/flash.bin
	echo -e "${default}"
fi

if [ "${kernel_yocto}" == "kernel" ]; then
	echo "-------------------- Linux Kernel standalone --------------------"
	cd linux-imx/
	if [ ! -f .config ]; then
		make imx_v8_defconfig imx8_phytec_distro.config imx8_phytec_platform.config
	fi

	make -j $(nproc --all) all

	if [ ! -f arch/arm64/boot/Image ]; then
		echo -e "${red}Error: File 'arch/arm64/boot/Image' not exists.${default}"
		exit 1
	fi

	cp arch/arm64/boot/Image ../imx-mkimage/iMX8M/
	cd ..
fi

if [ "${kernel_yocto}" == "yocto" ]; then
	echo "-------------------- Linux Kernel from Yocto --------------------"
	if [ ! -f ${yocto_kernel} ]; then
		echo -e "${red}Error: File '${yocto_kernel}' not exists.${default}"
		exit 1
	fi
	cp ${yocto_kernel} imx-mkimage/iMX8M/
fi

echo "-------------------- copy flash.bin to SD card --------------------"
sudo dd if=imx-mkimage/iMX8M/flash.bin of=${sdcard} bs=1k seek=32 conv=fsync; sync

sudo mkdir -p /media/$USER/root/home/root/.falcon/
if [ "${normal_falcon}" == "normal" ]; then
	cp imx-mkimage/iMX8M/flash.bin flash_normal.bin
	sudo cp imx-mkimage/iMX8M/flash.bin /media/$USER/root/home/root/.falcon/flash_normal.bin
fi
if [ "${normal_falcon}" == "falcon" ]; then
	cp imx-mkimage/iMX8M/flash.bin flash_falcon.bin
	sudo cp imx-mkimage/iMX8M/flash.bin /media/$USER/root/home/root/.falcon/flash_falcon.bin
fi

if [ "${normal_falcon}" == "falcon" ]; then
	echo -e "-------------------- Device Tree ${device_tree}.dtb to SD card --------------------"
	if [ "${kernel_yocto}" == "kernel" ]; then
		if [ ! -f linux-imx/arch/arm64/boot/dts/freescale/${device_tree}.dtb ]; then
			echo -e "${red}Error: File '${device_tree}.dtb' not exists.${default}"
			exit 1
		fi
		cp linux-imx/arch/arm64/boot/dts/freescale/${device_tree}.dtb /media/$USER/boot
	fi

	echo "-------------------- u-boot.itb to SD card --------------------"
	if [ ! -f imx-mkimage/iMX8M/u-boot.itb ]; then
		echo -e "${red}Error: File imx-mkimage/iMX8M/u-boot.itb not exists.${default}"
		exit 1
	fi
	cp imx-mkimage/iMX8M/u-boot.itb /media/$USER/boot

	echo "-------------------- FIT image contains the ATF and the kernel Image --------------------"
	cd imx-mkimage/iMX8M/

	if [ ! -f Image ]; then
		echo -e "${red}Error: File 'imx-mkimage/iMX8M/Image' not exists.${default}"
		exit 1
	fi

	chmod +x ../mkimage_fit_atf_kernel.sh
	ATF_LOAD_ADDR=0x00970000 KERNEL_LOAD_ADDR=0x40200000 ../mkimage_fit_atf_kernel.sh > Image.its

	echo "-------------------- FIT binary --------------------"
	./mkimage_uboot -E -p 0x3000 -f Image.its Image.itb
	cp Image.itb /media/$USER/boot

	echo "-------------------- Flattened Device Tree --------------------"
	mkimage -A arm -O linux -T kernel -C none -a 0x43FFFFC0 -e 0x44000000 -n "Linux kernel" -d Image uImage
	sudo mkdir -p /media/$USER/root/home/root/.falcon/
	sudo cp uImage /media/$USER/root/home/root/.falcon/
	cd ../..
fi

echo "-------------------- Unmount SD card --------------------"
# mkdir /media/$USER/{boot,root}; mount /dev/sdb1 /media/$USER/boot; mount /dev/sdb2 /media/$USER/root
sync; umount /media/$USER/boot; umount /media/$USER/root
ls /media/$USER/

echo "-------------------- Output files --------------------"
ls -al imx-mkimage/iMX8M/flash.bin
ls -al imx-atf/build/imx8mp/release/bl31.bin
ls -al imx-mkimage/iMX8M/u-boot.itb
if [ "${normal_falcon}" == "falcon" ]; then
	ls -al imx-mkimage/iMX8M/Image.its
	ls -al imx-mkimage/iMX8M/Image.itb
fi
ls -al u-boot-imx/spl/u-boot-spl*.bin
