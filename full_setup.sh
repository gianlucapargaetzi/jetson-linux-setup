

print_help_screen()
{
    echo -e "${Yellow}How to use this script:${Color_Off}"
    echo "Pass the path to your workspace directory as argument when running this script."
    echo ""
    echo -e "${Yellow}What it does:${Color_Off}"
    echo "The script will then guide you through the installation of Jetson Linux with numerous context dialogs"
    echo "1. The script searches at ~/l4t_gcc for the bootlin cross compiling toolchain. If not found, it will install it."
    echo "2. After that, it will setup all files in your specified workspace. If your path already exists, you can decide to abort the installation or if not you can decide if you want to continue with the existing files or reinstall the Jetson Linux in the named directory"
    echo "3. After setting up the files, you can compile the sources or stop at this point"
    echo "4. When compiling the sources, you can decide if you want to reinitialize the module configuration (=resetting menuconfig) or if you want to modify the existing configuration (=modifying menuconfig)"
    echo "5. After compiling, you can flash the hardware or stop. If you want to flash the hardware, it has to be connected in recovery mode. Otherwise, the script will abort."
}

WORKSPACE_DIR_VAR="$1"
SRC_DIR=$PWD

WORKSPACE_DIR_ABS=""

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White


setup_l4t() {
    if test "$WORKSPACE_DIR_ABS" = ""
    then
        echo "Error: Absolute path of workspace not found"
        exit
    fi
    L4TDIR=${WORKSPACE_DIR_ABS}/Linux_for_Tegra

    echo -e "${Yellow}Copying scripts to ${WORKSPACE_DIR_ABS}${Color_Off}"
    cd ${SRC_DIR}
    cp l4t_setup.sh l4t_build.sh export.sh flash_hardware.sh ${WORKSPACE_DIR_ABS}/

    echo -e "${Yellow}Downloading L4T R35.4.1 BSP, Root FS and Sources from Nvidia.${Color_Off}"
    cd ${WORKSPACE_DIR_ABS}
    ./l4t_setup.sh all

    cd ${WORKSPACE_DIR_ABS}/Linux_for_Tegra
    

    echo -e "${Yellow}Installing prerequisites for flashing your hardware.${Color_Off}"
    sudo ./tools/l4t_flash_prerequisites.sh
    echo -e "${Yellow}First time applying binaries.${Color_Off}"
    sudo ./apply_binaries.sh

    echo -e "${Yellow}Copying custom files from Git repo '$SRC_DIR/Linux_for_Tegra' to your workspace '$L4TDIR'${Color_Off}" 
    
    if test -d ${SRC_DIR}/Linux_for_Tegra
    then
        sudo cp -r -a ${SRC_DIR}/Linux_for_Tegra/. ${L4TDIR}/
    fi

    echo -e "${Green}Finished setting up L4T in directory '${WORKSPACE_DIR_ABS}'.${Color_Off}"

}

if test "$WORKSPACE_DIR_VAR" = "--help"
then
    print_help_screen
    exit
fi 

if test ! -d ~/l4t_gcc
then
    echo -e "${Yellow}Bootlin Toolchain not found in directory '~/l4t_gcc'! Installing ...${Color_Off}"
    cp l4t_toolchain.sh ~/
    cd
    sudo ./l4t_toolchain.sh
    rm l4t_toolchain.sh
    cd ${SRC_DIR}
    echo -e "${Green}Bootlin Toolchain successfully installed!${Color_Off}"
else
    echo -e "${Green}Bootlin Toolchain already installed in '~/l4t_tcc'. Skipping toolchain installation ...${Color_Off}"
fi


if test ! -d ${WORKSPACE_DIR_VAR}
then
    mkdir -p ${WORKSPACE_DIR_VAR} && cd ${WORKSPACE_DIR_VAR}
    WORKSPACE_DIR_ABS=${PWD}
    echo "Created workspace directory '${WORKSPACE_DIR_ABS}'"


    setup_l4t
else
    echo -e "${Yellow}The specified directory '${WORKSPACE_DIR_VAR}' already exists. Do you want to overwrite it? (y / n)${Color_Off}"
    read INPUT
    if test "$INPUT" = "y"
    then
        sudo rm -rf ${WORKSPACE_DIR_VAR}
        mkdir -p ${WORKSPACE_DIR_VAR} && cd ${WORKSPACE_DIR_VAR}
        WORKSPACE_DIR_ABS=${PWD}
        echo -e "${Green}Workspace diryectory '${WORKSPACE_DIR_ABS}' wiped. Continuing with installation.${Color_Off}"


        setup_l4t
    else 
        echo -e "${Yellow}Do you want to continue building your kernel with the existing workspace directory '${WORKSPACE_DIR_VAR}' (y / n)${Color_Off}"
        read INPUT
        if test "$INPUT" = "y"
        then
            echo -e "${Green}Workspace directory '${WORKSPACE_DIR_ABS}' untouched. Continuing with installation.${Color_Off}"
            cd ${WORKSPACE_DIR_VAR}
            WORKSPACE_DIR_ABS=${PWD}

        else 
            echo -e "${Red}Aborting installation! Exiting setup guide ...${Color_Off}"
            exit
        fi    
    fi
fi

cd ${SRC_DIR}


echo -e "${Yellow}Would you like to compile and apply the sources? (y / n)${Color_Off}"
cd ${WORKSPACE_DIR_ABS}
read INPUT
if test "$INPUT" = "y"
then
    echo -e "${Yellow}Would you like to reinitialize or modify your compilation configuration (r / m / n)${Color_Off}"
    read INPUT
    if test "$INPUT" = "r"
    then
        echo "Resetting menuconfig"
        ./l4t_build.sh menuconfig initial
    elif test "$INPUT" = "m"
    then 
        echo "Modify menuconfig"
        ./l4t_build.sh menuconfig
    else
        echo "No changes in menuconfig. Continue building kernel"
    fi


    echo -e "${Yellow}Building all sources in workspace '${WORKSPACE_DIR_ABS}'${Color_Off}"
    ./l4t_build.sh all apply
    echo -e "${Green}Kernel built!${Color_Off}"
else
    echo -e "${Green}Sources not build. Exiting setup guide ...${Color_Off}"
    exit
fi

echo -e "${Yellow}Would you like to flash your device? (y / n)${Color_Off}"
read INPUT
if test "$INPUT" = "y"
then
    if lsusb | grep -q -i 'NVIDIA Corp.'; then
        echo -e "${Green}Device found, starting with flash procedure.${Color_Off}"
        cd ${WORKSPACE_DIR_ABS}
        sudo ./flash_hardware.sh
    else
        echo -e "${Red}No Nvidia device in recovery mode found. Exiting setup guide ...${Color_Off}"
        exit
    fi
fi
echo -e "${Green}Finished Full Setup.${Color_Off}"




