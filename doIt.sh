mkdir -p $HOME/rpi-kernel/rt-kernel/boot

export RPI_IP=192.168.1.2
export ARCH=arm
export CROSS_COMPILE=$HOME/rpi-kernel/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-
export INSTALL_MOD_PATH=$HOME/rpi-kernel/rt-kernel
export INSTALL_DTBS_PATH=$HOME/rpi-kernel/rt-kernel
export KERNEL=kernel7

cd $HOME/rpi-kernel/

sudo apt-get install -y git

#Download Xenomai
wget https://xenomai.org/downloads/ipipe/v4.x/arm/ipipe-core-4.14.36-arm-1.patch
wget http://xenomai.org/downloads/xenomai/stable/xenomai-3.0.7.tar.bz2
tar xjf xenomai-3.0.7.tar.bz2

#Download rpi-kernel Linux 4.14.36 commit d6949f48093c2d862d9bc39a7a89f2825c55edc4
git clone https://github.com/raspberrypi/linux.git --depth 3
git clone https://github.com/raspberrypi/tools.git --depth 3
cd linux
git reset --hard 719df11c
git merge d6949f48093c2d862d9bc39a7a89f2825c55edc4
wget https://raw.githubusercontent.com/lemariva/RT-Tools-RPi/master/xenomai/v3.0.7/irq-bcm2836.c -P drivers/irqchip/
wget https://raw.githubusercontent.com/lemariva/RT-Tools-RPi/master/xenomai/v3.0.7/irq-bcm2835.c -P drivers/irqchip/

#Patching the kernel
cd $HOME/rpi-kernel/
xenomai-3.0.7/scripts/prepare-kernel.sh --linux=linux/ --arch=arm --ipipe=ipipe-core-4.14.36-arm-1.patch --verbose

#Building the kernel configuration
cd $HOME/rpi-kernel/linux
make bcm2709_defconfig
#make menuconfig //TODO with sed

#Compiling the kernel
make -j $(cat /proc/cpuinfo | grep -c ^processor) zImage
make -j $(cat /proc/cpuinfo | grep -c ^processor) modules
make -j $(cat /proc/cpuinfo | grep -c ^processor) dtbs
make -j $(cat /proc/cpuinfo | grep -c ^processor) modules_install | grep DEPMOD
make -j $(cat /proc/cpuinfo | grep -c ^processor) dtbs_install
./scripts/mkknlimg ./arch/arm/boot/zImage $INSTALL_MOD_PATH/boot/$KERNEL.img

#Transfer the Kernel
cd $INSTALL_MOD_PATH
tar czf ../xenomai-kernel.tgz *
cd ..
scp xenomai-kernel.tgz pi@$RPI_IP:/tmp

