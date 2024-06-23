# Compile Phytec bootloader PD23.1.0 (Kernel 5.15.71) with falcon mode (fast boot without U-boot)
# Use Ubuntu 22.04

sudo apt install -y flex bison pkg-config libncurses-dev libyaml-dev libssl-dev

mkdir ~/pd23.1.0_bootloader
cd ~/pd23.1.0_bootloader
git clone https://github.com/jsjsjs000/imx8mp_phytec_falcon_mode.git
cp -r imx8mp_phytec_falcon_mode/scripts .
chmod +x scripts/*.sh

./scripts/1-download_bootloader.sh
# Accept license - press: q, q, y, Enter

# Optional download Linux Kernel. Or use Linux BSD in Yocto - Phytec PD23.1.0
./scripts/2-optional_download_linux_kernel.sh
./scripts/3-optional_apply_linux_kernel_patch.sh

# Compile normal U-boot with SPL command and write to SD card
./scripts/4-compile_and_write_to_sd_card.sh kernel normal /dev/mmcblk0  # or /dev/sd[x]

# Apply falcon patches, compile bootloader and write to SD card
./scripts/5-apply_falcon_patches.sh
./scripts/4-compile_and_write_to_sd_card.sh kernel falcon /dev/mmcblk0  # or /dev/sdx




# Yocto
~/phyLinux/yocto_source=sources/poky/oe-init-build-env
devtool modify -x linux-imx linux-imx
devtool modify -x u-boot-imx u-boot-imx
devtool modify -x imx-atf imx-atf
devtool modify -x imx-boot-phytec imx-boot-phytec
#? firmware-imx_8.18.1.bb

./scripts/4-compile_and_write_to_sd_card.sh yocto normal /dev/mmcblk0  # or /dev/sd[x]
