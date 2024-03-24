cd Linux_for_Tegra/ 
sudo ./tools/l4t_create_default_user.sh -u nvidia -p nvidia
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1   -c tools/kernel_flash/flash_l4t_external.xml -p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml"   --showlogs --network usb0 jetson-orin-nx internal

