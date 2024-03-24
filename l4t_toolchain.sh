#!/bin/bash
wget https://developer.nvidia.com/embedded/jetson-linux/bootlin-toolchain-gcc-93 -O bootlin_toolchain.tar.gz
mkdir l4t_gcc
tar xpf bootlin_toolchain.tar.gz -C l4t_gcc
sudo apt-get update
sudo apt install ncurses-dev
sudo apt install flex
sudo apt install bison
sudo apt-get install python3-sphinx
sudo apt-get install --reinstall build-essential
sudo apt install qemu-user-static


