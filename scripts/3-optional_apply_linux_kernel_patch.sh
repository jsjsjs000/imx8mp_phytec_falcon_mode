#!/bin/bash

default="\e[0m"
red="\e[31m"
yellow="\e[33m"

if [ ! -d "linux-imx/" ]; then
	echo -e "${red}Folder 'linux-imx/' not found.${default}"
	exit 1
fi

cp patches/0001-falcon-mode-phytec-imx8mp-linux-imx.patch linux-imx/

cd linux-imx/
git apply 0001-falcon-mode-phytec-imx8mp-linux-imx.patch
cd ..
