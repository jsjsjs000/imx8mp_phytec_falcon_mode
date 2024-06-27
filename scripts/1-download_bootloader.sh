#!/bin/bash

# sudo apt install flex bison libssl-dev gcc-aarch64-linux-gnu u-boot-tools libncurses5-dev libncursesw5-dev uuid-dev gnutls-dev swig

default="\e[0m"
red="\e[31m"
yellow="\e[33m"

git clone --depth 1 -b lf-5.15.71_2.2.0 https://github.com/nxp-imx/imx-mkimage
git clone --depth 1 -b lf-5.15.71_2.2.1 https://github.com/nxp-imx/imx-atf
git clone --depth 1 -b v2022.04_2.2.2-phy5 git://git.phytec.de/u-boot-imx  # newest -phy6

wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.18.1.bin
chmod +x firmware-imx-8.18.1.bin
./firmware-imx-8.18.1.bin
#> q, q, y, Enter
rm firmware-imx-8.18.1.bin

if [ ! -d "u-boot-imx/" ]; then
	echo -e "${red}Error: Folder 'u-boot-imx/' not found.${default}"
	exit 1
fi

if [ ! -d "imx-atf/" ]; then
	echo -e "${red}Error: Folder 'imx-atf/' not found.${default}"
	exit 1
fi

cd u-boot-imx/
echo -e "\n# PCO\n*.map\nitb.fit.*\nkeep-syms-lto.c\n*.mkimage\ntools/boot/\n" >> .gitignore
git add .
git checkout -b v2022.04_2.2.2-phy5-PCO-v1.0
git commit -m "PCO falcon mode v1.0"
git status
cd ..

cd imx-atf/
git add .
git checkout -b lf-5.15.71_2.2.1-PCO-v1.0
git commit -m "PCO falcon mode v1.0"
git status
cd ..
