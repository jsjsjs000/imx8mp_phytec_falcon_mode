# Compile Phytec bootloader PD23.1.0 (Kernel 5.15.71) with falcon mode (fast boot without U-boot)
# Use Ubuntu 22.04

# 1. Install packages in Ubuntu
sudo apt install -y flex bison pkg-config libncurses-dev libyaml-dev libssl-dev

# 2. Download scripts and patches
mkdir ~/pd23.1.0_bootloader
cd ~/pd23.1.0_bootloader

git clone https://github.com/jsjsjs000/imx8mp_phytec_falcon_mode.git
cp -r imx8mp_phytec_falcon_mode/scripts .
cp -r imx8mp_phytec_falcon_mode/patches .
chmod +x scripts/*.sh

# 3. Download i.MX 8M plus bootloader packages
./scripts/1-download_bootloader.sh
# Accept license - press: q, q, y, Enter

# 4.a. Kernel standalone
# Download Linux Kernel. Or use Linux BSD in Yocto - Phytec PD23.1.0
./scripts/2-optional_download_linux_kernel.sh
./scripts/3-optional_apply_linux_kernel_patch.sh

# Compile normal U-boot with SPL command and write to SD card
# Set variables: toolchain_source, toolchain_sysroot in script '/scripts/4-compile_and_write_to_sd_card.sh'
./scripts/4-compile_and_write_to_sd_card.sh kernel normal /dev/mmcblk0  # or /dev/sd[x]

# Apply falcon patches, compile bootloader and write to SD card
./scripts/5-apply_falcon_patches.sh
./scripts/4-compile_and_write_to_sd_card.sh kernel falcon /dev/mmcblk0  # or /dev/sdx

# remove SD card and run i.MX devboard

# 4.b. Kernel from Yocto
# Set Yocto environment
dir=`pwd`
cd ~/phyLinux
source sources/poky/oe-init-build-env

# Build Kernel in Yocto
bitbake phytec-qt6demo-image
cd $dir  # return to original folder

# Apply falcon patches, compile bootloader and write to SD card
./scripts/5-apply_falcon_patches.sh

# Set variables: toolchain_source, toolchain_sysroot, yocto_dir, yocto_source, yocto_kernel
# in script '/scripts/4-compile_and_write_to_sd_card.sh'
./scripts/4-compile_and_write_to_sd_card.sh yocto falcon /dev/mmcblk0  # or /dev/sd[x]

# remove SD card and run i.MX devboard

# 5. Read system boot time
systemd-analyze time
#>   Normal:
#> Startup finished in 1.939s (kernel) + 3.867s (userspace) = 5.806s 
#> graphical.target reached after 3.860s in userspace
#>   Falcon:
#> Startup finished in 3.918s (kernel) + 5.766s (userspace) = 9.684s 
#> graphical.target reached after 5.751s in userspace
