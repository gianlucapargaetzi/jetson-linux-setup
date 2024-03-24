#!/bin/bash

export CUR_DIR=$PWD
export JETSON_LINUX_SOURCES=${CUR_DIR}/Linux_for_Tegra/sources
export KERNEL_SRC=${JETSON_LINUX_SOURCES}/kernel/kernel-5.10
export KERNEL_OUT=${JETSON_LINUX_SOURCES}/kernel_out
source export.sh

menuconfig="menuconfig"
all="all"
image="image"
dtb="dtb"
clean="clean"
apply="apply"
initial="initial"




apply_changes() {
    echo "Applying L4T changes"
    sudo cp ${KERNEL_OUT}/drivers/gpu/nvgpu/nvgpu.ko ${CUR_DIR}/Linux_for_Tegra/rootfs/usr/lib/modules/5.10.120-tegra/kernel/drivers/gpu/nvgpu 
    echo "Copying device tree files..."
    sudo cp -r ${KERNEL_OUT}/arch/arm64/boot/dts/nvidia/* ${CUR_DIR}/Linux_for_Tegra/kernel/dtb/
    echo "Copying image..."
    sudo cp ${KERNEL_OUT}/arch/arm64/boot/Image ${CUR_DIR}/Linux_for_Tegra/kernel/

    cd ${KERNEL_OUT}/modules_out
    echo "Packing driver modules..."
    tar --owner root --group root -cjf ${CUR_DIR}/Linux_for_Tegra/kernel/kernel_supplements.tbz2 lib/modules

    cd ${CUR_DIR}/Linux_for_Tegra
    sudo ./apply_binaries.sh
    cd ${CUR_DIR}
}


build_image() {
    cd ${KERNEL_SRC}
    make ARCH=arm64 LOCALVERSION=-tegra CROSS_COMPILE=$CROSS_COMPILE_AARCH64 O=${KERNEL_OUT} -j16 --output-sync=target Image    
    cd ${CUR_DIR}
}

build_dtb() {
    cd ${KERNEL_SRC}
    make ARCH=arm64 LOCALVERSION=-tegra CROSS_COMPILE=$CROSS_COMPILE_AARCH64 O=${KERNEL_OUT} -j16 --output-sync=target dtbs
    cd ${CUR_DIR}
}

build_modules() {
    cd ${KERNEL_SRC}
    make ARCH=arm64 LOCALVERSION=-tegra CROSS_COMPILE=$CROSS_COMPILE_AARCH64 O=${KERNEL_OUT} -j16 --output-sync=target modules
    make ARCH=arm64 LOCALVERSION=-tegra CROSS_COMPILE=$CROSS_COMPILE_AARCH64 O=${KERNEL_OUT}  INSTALL_MOD_PATH=${KERNEL_OUT}/modules_out/ --output-sync=target modules_install
    cd ${CUR_DIR}
}

if test ! -d ${KERNEL_OUT}
then
    mkdir ${KERNEL_OUT}
    mkdir ${KERNEL_OUT}/modules
fi

if test "$1" = "$clean"
then
    echo 'Cleaning build.'
    cd ${KERNEL_SRC}
    make mrproper
    cd ${JETSON_LINUX_SOURCES}
    sudo rm -rf kernel_out
    mkdir kernel_out
    cd kernel_out && mkdir modules_out  
    cd ${KERNEL_SRC}
    
elif test "$1" = "$menuconfig"
then
    echo 'Building menuconfig.'
    cd ${KERNEL_SRC}
    if test "$2" = "$initial"
    then
        make ARCH=arm64 O=${KERNEL_OUT} tegra_defconfig
    fi
    make ARCH=arm64 O=${KERNEL_OUT} menuconfig
    cd ${CUR_DIR}

elif test "$1" = "$all"
then
    echo 'Building all sources.'
    build_image    
    build_dtb
    build_modules
    if test "$2" = "$apply"
    then
        echo "Kernel built, applying changes to Jetson Linux!"
        apply_changes

    else
        echo "Kernel built, but changes not applied!"
    fi
elif test "$1" = "$image"
then
    echo 'Building image'
    build_image
elif test "$1" = "$dtb"
then
    echo 'Building Device Tree'
    build_dtb 
    
    if test "$2" = "$apply"
    then
        sudo cp -r ${KERNEL_OUT}/arch/arm64/boot/dts/nvidia/* ${CUR_DIR}/Linux_for_Tegra/kernel/dtb/
    fi
    
elif test "$1" = "$apply"
then
    echo "Kernel not built!! Applying last kernel build to Jetson Linux."
    apply_changes
else
    echo "No valid argument... Abort!"
fi

echo "Finished!!!"
