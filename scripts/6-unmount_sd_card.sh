#!/bin/bash

echo "-------------------- Unmount SD card --------------------"
# mkdir /media/$USER/{boot,root}; mount /dev/sdb1 /media/$USER/boot; mount /dev/sdb2 /media/$USER/root
sync; umount /media/$USER/boot; umount /media/$USER/root

echo "-------------------- Mounted devices list (e.g. SD cards) --------------------"
ls /media/$USER/
echo "-------------------- end of list --------------------"
