#!/bin/bash

default="\e[0m"
red="\e[31m"
yellow="\e[33m"

if [ ! -d "imx-atf/" ]; then
	echo -e "${red}Folder 'imx-atf/' not found.${default}"
	exit 1
fi
if [ ! -d "imx-mkimage/" ]; then
	echo -e "${red}Folder 'imx-mkimage/' not found.${default}"
	exit 1
fi
if [ ! -d "u-boot-imx/" ]; then
	echo -e "${red}Folder 'u-boot-imx/' not found.${default}"
	exit 1
fi
if [ ! -d "patches/" ]; then
	echo -e "${red}Folder 'patches/' not found.${default}"
	exit 1
fi

cp patches/0001-falcon-mode-phytec-imx8mp-u-boot.patch u-boot-imx/
cp patches/0001-falcon-mode-phytec-imx8mp-atf.patch imx-atf/
cp patches/0001-falcon-mode-phytec-imx8mp-mkimage.patch imx-mkimage/

cd u-boot-imx/
git apply 0001-falcon-mode-phytec-imx8mp-u-boot.patch
cd ..

cd imx-atf/
git apply 0001-falcon-mode-phytec-imx8mp-atf.patch
cd ..

cd imx-mkimage/
git apply 0001-falcon-mode-phytec-imx8mp-mkimage.patch
cd ..
