# Compile Phytec bootloader PD23.1.0 (Kernel 5.15.71) with falcon mode (fast boot without U-boot)
# Use Ubuntu 22.04

# 1. Install packages in Ubuntu
sudo apt install -y flex bison pkg-config libncurses-dev libyaml-dev libssl-dev

# 2. Download scripts and patches
mkdir ~/pd23.1.0_bootloader
cd ~/pd23.1.0_bootloader

git clone https://github.com/jsjsjs000/imx8mp_phytec_falcon_mode.git
cp -r imx8mp_phytec_falcon_mode/{scripts,patches} .
chmod +x scripts/*.sh

# 3. Download i.MX 8M plus bootloader packages
./scripts/1-download_bootloader.sh
# Accept license - press: q, q, y, Enter

# list available SD cards
lsblk -e7
#> /dev/mmcblk0 or /dev/sda or /dev/sdb or ...
sd_card=/dev/mmcblk0
# sd_card=/dev/sda
# sd_card=/dev/sdb

# 4. Kernel standalone (a) of Kernel from Yocto (b)
# (Kernel standalone don't have modules)

# 4.a. Kernel standalone
# Download Linux Kernel. Or use Linux BSD in Yocto - Phytec PD23.1.0
./scripts/2-optional_download_linux_kernel.sh
./scripts/3-optional_apply_linux_kernel_patch.sh

# Compile normal U-boot with SPL command and write to SD card
# Set variables: toolchain_source, toolchain_sysroot in script '/scripts/4-compile_and_write_to_sd_card.sh'
./scripts/4-compile_and_write_to_sd_card.sh kernel normal ${sd_card}

./scripts/6-unmount_sd_card.sh
# remove SD card and run i.MX devboard

# Apply falcon patches, compile bootloader and write to SD card
./scripts/5-apply_falcon_patches.sh
./scripts/4-compile_and_write_to_sd_card.sh kernel falcon ${sd_card}

./scripts/6-unmount_sd_card.sh
# remove SD card and run i.MX devboard

# 4.b. Kernel from Yocto - 4.b.1. in original build folder or 4.b.2. unpack Kernel
# Set Yocto environment
yocto_dir=~/phyLinux
dir=`pwd`
cd ${yocto_dir}
source sources/poky/oe-init-build-env

# Build Kernel in Yocto
bitbake phytec-qt6demo-image
cd $dir  # return to original folder

# Apply falcon patches, compile bootloader and write to SD card
cp patches/0001-falcon-mode-phytec-imx8mp-yocto.patch ${yocto_dir}/sources/meta-phytec/
cd ${yocto_dir}/sources/meta-phytec/
git apply 0001-falcon-mode-phytec-imx8mp-yocto.patch
cd $dir  # return to original folder

# 4.b.1 Kernel in Yocto build folder - $$$$ not tested - test it in PCO
cp patches/0001-falcon-mode-phytec-imx8mp-linux-imx.patch ${yocto_dir}/build/tmp/work/phyboard_pollux_imx8mp_3-phytec-linux/linux-imx/5.15.71-r0.0/git/
cd ${yocto_dir}/build/tmp/work/phyboard_pollux_imx8mp_3-phytec-linux/linux-imx/5.15.71-r0.0/git/
git apply 0001-falcon-mode-phytec-imx8mp-linux-imx.patch

cd ${yocto_dir}
source sources/poky/oe-init-build-env
bitbake -c compile -f linux-imx
ls ${yocto_dir}/build/tmp/work/phyboard_pollux_imx8mp_3-phytec-linux/linux-imx/5.15.71-r0.0/build/arch/arm64/boot/dts/freescale/imx8mp-phyboard-pollux-rdk*
cd $dir

# 4.b.2 unpack Kernel
devtool modify -x linux-imx linux-imx
cp patches/0001-falcon-mode-phytec-imx8mp-linux-imx.patch ${yocto_dir}/build/linux-imx/
cd ${yocto_dir}/build/linux-imx/
git apply 0001-falcon-mode-phytec-imx8mp-linux-imx.patch

cd ${yocto_dir}
source sources/poky/oe-init-build-env
bitbake -c compile -f linux-imx
ls ${yocto_dir}/build/tmp/work/phyboard_pollux_imx8mp_3-phytec-linux/linux-imx/5.15.71-r0.0/linux-imx-5.15.71/arch/arm64/boot/dts/freescale/imx8mp-phyboard-pollux-rdk*
cd $dir

# 4.b. continue
# Compile normal U-boot with SPL command and write to SD card
# Set variables: toolchain_source, toolchain_sysroot, yocto_dir, yocto_source, yocto_kernel_dir
# in script '/scripts/4-compile_and_write_to_sd_card.sh'
./scripts/4-compile_and_write_to_sd_card.sh yocto normal ${sd_card}

./scripts/6-unmount_sd_card.sh
# remove SD card and run i.MX devboard

# Apply falcon patches, compile bootloader and write to SD card
./scripts/5-apply_falcon_patches.sh
./scripts/4-compile_and_write_to_sd_card.sh yocto falcon ${sd_card}

./scripts/6-unmount_sd_card.sh
# remove SD card and run i.MX devboard

# 5. Read system boot time
# on i.MX Linux:
systemd-analyze time
#>   Normal:
#> Startup finished in 1.939s (kernel) + 3.867s (userspace) = 5.806s 
#> graphical.target reached after 3.860s in userspace
#>   Falcon:
#> Startup finished in 3.918s (kernel) + 5.766s (userspace) = 9.684s 
#> graphical.target reached after 5.751s in userspace

# 6. Resize rootfs on SD card
# on i.MX Linux - boot from SD card:
parted /dev/mmcblk1 print  # SD card
parted /dev/mmcblk1 resizepart 2 100%
parted /dev/mmcblk1 print  # check again
resize2fs /dev/mmcblk1p2
reboot
df -h

# 7. Copy SD card image from Yocto to SD card
# on PC:
sudo cp ~/phyLinux/build/deploy/images/phyboard-pollux-imx8mp-3/phytec-qt6demo-image-phyboard-pollux-imx8mp-3.wic /media/$USER/root/root/
# 2.8GB
./scripts/6-unmount_sd_card.sh
# remove SD card and run i.MX devboard

# 8. Copy SD card image to eMMC
# on i.MX Linux - boot from SD card:
fdisk -l
dd if=/root/phytec-qt6demo-image-phyboard-pollux-imx8mp-3.wic of=/dev/mmcblk2

dd if=/home/root/.falcon/flash_falcon.bin of=/dev/mmcblk2 bs=1k seek=32 conv=fsync

mkdir -p /mnt/sd_boot
mount /dev/mmcblk2p1 /mnt/sd_boot/
cp /boot/* /mnt/sd_boot/
cp /home/root/.falcon/imx8mp-phyboard-pollux-rdk-falcon-emmc.dtb /mnt/sd_boot/imx8mp-phyboard-pollux-rdk-falcon.dtb
umount /mnt/sd_boot/

# eMMC boot mode DIP switch on Phytec PhyBoard (1234): 0000
poweroff
# remove SD card from i.MX, power on i.MX

# 9. Resize rootfs on eMMC
# on i.MX Linux - boot from eMMC:
parted /dev/mmcblk2 print  # eMMC
parted /dev/mmcblk2 resizepart 2 100%
parted /dev/mmcblk2 print  # check again
resize2fs /dev/mmcblk2p2
reboot
df -h
