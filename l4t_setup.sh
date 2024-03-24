#!/bin/bash

jetson_linux="jetson_linux"
rootfs="rootfs"
sources="sources"
all="all"

get_jetson_linux() {
    echo 'Download Jetson Linux.'
    wget https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v4.1/release/jetson_linux_r35.4.1_aarch64.tbz2/ -O jetson_linux.tbz2
    echo 'Extracting Jetson Linux...'
    tar xf jetson_linux.tbz2
    sudo rm jetson_linux.tbz2
}

get_rootfs() {
    echo 'Download Root FS.'
    wget https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v4.1/release/tegra_linux_sample-root-filesystem_r35.4.1_aarch64.tbz2/ -O sample_root_file_system.tbz2
    echo 'Extracting Root FS...'
    sudo tar xpf sample_root_file_system.tbz2 -C Linux_for_Tegra/rootfs
    sudo rm sample_root_file_system.tbz2
}

get_sources(){
    echo 'Download Sources.'
    wget https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v4.1/sources/public_sources.tbz2/ -O public_sources.tbz2
    sudo rm -rf Linux_for_Tegra/sources
    mkdir tmp
    mkdir Linux_for_Tegra/sources
    echo 'Extracting Sources...'
    tar xpf public_sources.tbz2 -C tmp/
    tar xpf tmp/Linux_for_Tegra/source/public/kernel_src.tbz2 -C Linux_for_Tegra/sources  
    rm -rf tmp

    mkdir -p Linux_for_Tegra/sources/kernel_out
    mkdir -p Linux_for_Tegra/sources/kernel_out/modules_out

    sudo rm public_sources.tbz2
}

if test "$1" = "$jetson_linux" 
then
    get_jetson_linux

elif test "$1" = "$rootfs"
then
    get_rootfs

elif test "$1" = "$sources"
then
    get_sources

elif test "$1" = "$all"
then
    get_jetson_linux
    get_rootfs
    get_sources

else
    echo "Nothing to be done!"
fi

echo 'Finished setup!'






