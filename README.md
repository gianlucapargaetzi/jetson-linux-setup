# About this repository
This repository builds my go to starting point to modifying the Jetson Linux Kernel when used with custom hardware.

Using Jetson Linux and the scripts in this repo works best on a Linux Distribution. If you are using a Windows OS, I would recommend to [**set up a Ubuntu Distribution as Dual Boot**](https://www.xda-developers.com/dual-boot-windows-11-linux/).

# Customized Linux for Tegra (L4T) 35.4.1
The Nvidia Jetson platforms come with a custom operating system called [**Jetson Linux / Linux for Tegra (L4T)**](https://developer.nvidia.com/embedded/jetson-linux-archive) (in this case Version *35.4.1* based on *Linux Kernel 5.10*) which implements SoC specific functionality and is part of [**Jetpack SDK**](https://developer.nvidia.com/embedded/jetpack), which is Nvidia's environment for hardware-accelerated Edge-AI computing.

> In the future, the compatibility will be extended to *L4T 36.X.X*, which at the time of this documentation was relatively new and in some aspects incompletely documented.

Custom hardware requires custom firmware. The bash scripts in this repository will guide you through the necessary steps to prepare a Jetson Linux Environment ready for customization.

>

# Setting up L4T for your custom project
## Quick setup
The script `full_setup.sh` can be used to fully setup a directory for customizing the L4T operating system. Just run the script once with the desired workspace path. It will basically guide you through all steps described in the chapter [**Step-by-step setup**](#step-by-step-setup) (setting up environment, adapting and compiling sources and flashing if wanted). 

```
./full_setup.sh <path/to/workspace>
```

After that you can implement your own changes and recompile the sources and flash them as described in chapters [**L4T_Build: Compiling the kernel sources**](#l4t_build-compiling-the-kernel-sources) and [**Flashing the hardware**](#flashing-the-hardware).


If you want to know how to use the script and what it does, you can also type
```
./full_setup.sh --help
```

## Step-by-step setup
If you don't want to run the automatic Quick Setup script as described above, you can alternatively install the custom Jetson Linux following the instructions below.

### How to setup the Linux for Tegra sources
The script `l4t_setup.sh` is used to setup the Linux for Tegra environment using the compiled sources, rootfs and source code from NVIDIA.
Overall, the script runs through the [**Nvidia Quick Start Guide**](https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/text/IN/QuickStart.html#to-flash-the-jetson-developer-kit-operating-software), which can be a helpful documentation point in general when customizing a L4T-kernel.

1. Create your workspace directory (where you want your Jetson for Linux to be stored at) and copy the script `l4t_setup.sh` into that workspace
    ```
    mkdir -p <path/to/workspace>
    cp l4t_setup.sh <path/to/workspace>
    ```
2. Go to your workspace and run the script to download the sources from NVIDIA.
    ```
    cd <path/to/workspace>
    sudo ./l4t_setup.sh all
    ```
    This should setup all files necessary for kernel customization. 


    > Quickly check if the installation was completed by checking if a new folder *Linux_for_Tegra* exists in your workspace directory as well as *Linux_for_Tegra/sources* with all kernel sources files.

3. Go to the *Linux_for_Tegra* folder and apply all binarys and install the necessary prerequisites for flashing the hardware

    ```
    cd <path/to/workspace>/Linux_for_Tegra
    sudo ./apply_binaries.sh
    sudo ./tools/l4t_flash_prerequisites.sh
    ```

At this point, you should have a clean "base", with which you can start to customize your kernel as described in the following chapters.

### L4T_Toolchain: Setting up the cross-compiling toolchain
Once setup with the `l4t_setup.sh` script, you can proceed with the customization of the Linux kernel.

But first you have to install the **Bootlin Toolchain** for cross-compiling Jetson Images directly on your host PC. The Toolchain is used when compiling the customized Jetson Linux sources for your Jetson hardware.

1. Copy the script `l4t_toolchain.sh` to your home directory
    ```
    cp l4t_toolchain.sh ~/
    ```
2. Run it there to download the Toolchain binaries and extract them to the "standard path" *~/l4t_gcc* (as used in all my other L4T scripts)
     ```
    cd
    sudo ./l4t_toolchain.sh
    ``` 
    > Quickly check if the installation was completed by checking if a new folder *l4t_gcc* exists in your home directory containing the toolchain libraries.

### Setup your sources for your custom hardware
Once everything is setup (toolchain installed and sources downloaded) you can start customizing the Jetson Kernel for your needs.

```
sudo cp -r <this/github/repo/directory>/Linux_for_Tegra/. <path/to/workspace>/Linux_for_Tegra
```


### L4T_Build: Compiling the kernel sources
1. Copy the **l4t_build.sh** script to your workspace directory (where the *Linux_for_Tegra* folder is located at)
     ```
    cp l4t_build.sh <path/to/workspace>
    ```  
2. Build the menuconfig file by running `l4t_build.sh` with the argument *menuconfig*. The menuconfig GUI will pop up. On first run or if your newly added modules don't show up in the menuconfig GUI, you might have to run *menuconfig initial*
    ```
    ./l4t_build.sh menuconfig initial
    ```  
    
     ```
    ./l4t_build.sh menuconfig
    ```  
3. If you are intending to use custom kernel drivers (for example the LT6911 driver for the HDMI2CSI module), activate them in the menuconfig. Upon closing, the driver config *.config* should automatically be saved to the right location *<path/to/workspace>/Linux_for_Tegra/sources/kernel_out*.

    > In the Menuconfig GUI you can search for your drivers by typing "/" and then the name of the driver (or part of it). Activate them as module "m" or built-in "y".

4. Once setup, you can finally compile the sources by running *l4t_build.sh all*. By adding the argument *apply* you can also directly replace the old OS version by the newly compiled sources. If you only want to compile the image or device tree you can use *image* or *dtb* vice versa.
     ```
    sudo ./l4t_build.sh all
    ```  
     ```
    sudo ./l4t_build.sh all apply
    ```  

# Flashing the hardware

Once your custom Jetson Linux is setup, you can now flash it to your Jetson hardware using the Micro-USB flashing port on your Jetson carrier board.

1. Start up your device in recovery mode (Check the instructions for your hardware on how to do that...)
2. Connect the baseboard via the Micro-USB port to your host PC and check on your host PC with *lsusb* if the Jetson is detected and in recovery mode. You should see a device called **Nvidia Corp.** fitting the nomenclature according to the [**Quick Start Guide**](https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/text/IN/QuickStart.html#to-determine-whether-the-developer-kit-is-in-force-recovery-mode) (ID 7323 for Orin NX 16GB and 7423 for Orin NX 8GB).


    ```
    lsusb
    ```
    ```
    ...
    Bus <bbb> Device <ddd>: ID 0955:7323/7423 Nvidia Corp.
    ...
    ```
3. *Optional*: When flashing the hardware, it makes sense to simultaneously log the Debug UART serial output. In case of a flash failure, the serial kernel log often gives valuable information about flashing errors. 

3. Finally, flash your Orin NX by either running the `flash_hardware.sh` script or navigating into the *Linux_for_Tegra*-Folder and running the flash command:
    ```  
    ./flash_hardware.sh
    ```  


    ```  
    cd <path/to/workspace>/Linux_for_Tegra
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1   -c tools/kernel_flash/flash_l4t_external.xml -p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml"   --showlogs --network usb0 jetson-orin-nx internal
    ```  
# Some general notes on working with Jetsons and L4T

## Useful information about device tree adaptions
The device tree node names in the Jetson Linux source files are most often rather cryptic and difficult to understand. Even harder is sometimes the link between device tree node and actual physical hardware.

Heres an excerpt from a device tree I programmed:
```  
i2c@3180000 {
    status="okay";
    tca9554_pin_header: tca9539@21 {
        compatible = "ti,tca9554";
        gpio-controller;
        #gpio-cells = <2>;
        reg = <0x21>;
        interrupt-parent = <&tegra_main_gpio>;
        interrupts = <TEGRA234_MAIN_GPIO(N, 1) IRQ_TYPE_LEVEL_LOW>;
        #interrupt-cells = <2>;
        interrupt-controller;
        vcc-supply = <&cb_vdd_3v3_sys>;
    };
};
``` 


1. It is important to note that this **is NOT the full description** of the I2C bus. Most properties are defined in the SoC device tree definitions somewhere in the *sources/hardware/nvidia/soc/* folder:
    ```  
    cam_i2c: i2c@3180000 {
        #address-cells = <1>;
        #size-cells = <0>;
        iommus = <&smmu_niso0 TEGRA_SID_NISO0_GPCDMA_0>;
        ...
        sda-gpio = <&tegra_main_gpio TEGRA234_MAIN_GPIO(P, 3) 0>;
        status = "disabled";
        clock-frequency = <400000>;
        ...
        dma-names = "rx", "tx";
        nvidia,epl-reporter-id = <0x8052>;
    };
    ```  
    It is only enabled in my device tree. In general you can overwrite these properties in the your device tree when needed (for example for lowering the I2C speed).

2. The difficult thing is to make the connection between the physical I2C bus (in the hardware design / schematic) and the device tree node.
    
    First search for the address after the "@" (in this case *3180000*) in the [**Jetson Orin Series SoC Technical Reference Manual**](https://developer.nvidia.com/downloads/orin-series-soc-technical-reference-manual/) between page 51 and 81. This will give you a Software Interface Name, in this case "I2C3".

    The complicated part is that for example in the *i2cdetect* bus numbering starts with 0, so "I2C3" is actually "i2c-2"...
    
    Even more complicated is that "I2C3" **does not** correspond to the hardware I2C3. You have to check in the Pinmux file which hardware pins (Column *Jetson Orin NX and Nano Function*) are assigned to the I2C3 software functionalities (Column *Customer Usage*). In this Case I2C3 are the *CAM_I2C* hardware pins.



## Working with the Jetson after flashing

### Setup the Jetson

Once you have successfully flashed the NVIDIA Jetson there should already be a user configured:
```  
username: nvidia
password: nvidia
```  

If necessary, install Nvidia jetpack on your device:
```  
sudo apt update
sudo apt install nvidia-jetpack
```  
### Work with the Jetson

My goto workflow with a Nvidia Jetson hardware bring-up is remote development via SSH for now. Combined with the Visual Studio Code extensions "Remote Development", where you are able to see the file structure of the target, this is a feasible solution.

### Device-tree changes without reflash

Device-tree changes (if no new corresponding driver has to be built in the kernel or if it can be loaded as a module) **DO NOT** need a reflash:

1. Make your device-tree adaptions on your host as you would when reflashing the device and compile the device-tree by running `l4t_build.sh`
    ```  
    ./l4t_build dtb
    ```      
    This will compile the device-trees to the directory *<path/to/workspace>/Linux_for_Tegra/sources/kernel_out/arch/arm64/boot/dts/nvidia/*
2. Transfer the desired device-tree to your Jetson module, for example via secure copy and place it in the */boot/dtb* directory.
    
    *On host:*
    ```  
    scp <device-tree-file> nvidia@<ip-of-jetson>:/home/nvidia
    ``` 
    *On device:*
    ```  
    sudo cp <device-tree-file> /boot/dtb/ 
    ``` 

3. Open */boot/extlinux/extlinux.conf* and replace the mentioned device-tree with your new device-tree.
    ```  
    sudo nano /boot/extlinux/extlinux.conf
    ```  
4. Reboot the system.
    ```  
    sudo reboot now
    ```   
