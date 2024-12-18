
BLUE='\033[0;34m'
WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'

# Helper functions

# $1=file name, $2=file sha256, $3=file url, $4=POST arguments (optional)
download_archive() {
    if [[ $(sha256sum $1) = "$2  $1" ]]; then
        echo "$1 already downloaded."
    else
        echo "File not valid or inexistant. Downloading..."
        if ! [ -z "$4" ]; then
            wget -O $1 --post-data=$4 $3 --no-check-certificate
        else
            wget -O $1 $3 --no-check-certificate
        fi
        if ! [[ $(sha256sum $1) = "$2  $1" ]]; then
            echo -e "${RED}$1 download failure${WHITE}"
            exit
        fi
    fi
}

# Prerequisites
echo -e "${BLUE}Installing prerequisites${WHITE}"

sudo apt update
sudo apt install wget -y
sudo apt install make -y
sudo apt install gcc -y

ENVDIR=/home/$(whoami)/mbed-dev-env
mkdir -p $ENVDIR
cd $ENVDIR

mkdir -p $ENVDIR/.tmp

# VSCode
echo -e "${BLUE}Installing VSCode${WHITE}"
cd $ENVDIR/.tmp

download_archive "vscode_linux_x64_stable.tar.gz" "66b4c2fc830d8114ec76318d9a604ab3c8e8165c95a6d0d1453b55a97cf9dab7" "https://vscode.download.prss.microsoft.com/dbazure/download/stable/65edc4939843c90c34d61f4ce11704f09d3e5cb6/code-stable-x64-1730354220.tar.gz"

echo "Installing VSCode to environment"
tar -xvzf vscode_linux_x64_stable.tar.gz
cd vscode_linux_x64_stable
cp -r *VSCode* $ENVDIR/vscode
cd $ENVDIR/vscode
mkdir data
cd bin
./code --install-extension ms-vscode.cpptools
./code --install-extension ms-vscode.cpptools-extension-pack
./code --install-extension ms-vscode.cpptools-themes
./code --install-extension nemesv.copy-file-name
./code --install-extension marus25.cortex-debug
./code --install-extension SanaAjani.taskrunnercode
./code --install-extension tomoki1207.pdf

## Compiler
echo -e "${BLUE}Installing ARM GCC toolchain${WHITE}"
cd $ENVDIR/.tmp

#download_archive "gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2" "5adc2ee03904571c2de79d5cfc0f7fe2a5c5f54f44da5b645c17ee57b217f11f" "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2"
download_archive "arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz" "12a2815644318ebcceaf84beabb665d0924b6e79e21048452c5331a56332b309" "https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz"

tar -xvf arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz
cp -r arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi $ENVDIR/gcc-arm-none-eabi
touch $ENVDIR/gcc-arm-none-eabi/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi


## Python
echo -e "${BLUE}Installing Python3${WHITE}"
cd $ENVDIR/.tmp

sudo apt install -y libffi-dev libgdbm-dev libsqlite3-dev libssl-dev zlib1g-dev

download_archive "openssl-1.1.1g.tar.gz" "ddb04774f1e32f0c49751e21b67216ac87852ceb056b75209af2443400636d46" "https://www.openssl.org/source/openssl-1.1.1g.tar.gz"

if ! test -d "$ENVDIR/openssl"; then
    tar -zxvf openssl-1.1.1g.tar.gz
    cd openssl-1.1.1g

    ./config --prefix=$ENVDIR/openssl --openssldir=$ENVDIR/openssl/ssl no-ssl2
    make
    #make test
    make install_sw
fi

export LD_LIBRARY_PATH=$ENVDIR/openssl/lib:$LD_LIBRARY_PATH

cd $ENVDIR/.tmp
download_archive "Python-3.7.17.tgz" "fd50161bc2a04f4c22a0971ff0f3856d98b4bf294f89740a9f06b520aae63b49" "https://www.python.org/ftp/python/3.7.17/Python-3.7.17.tgz"

tar -xvzf Python-3.7.17.tgz
cd Python-3.7.17

#LDFLAGS="-L$ENVDIR/openssl/lib"

./configure \
    --prefix=$ENVDIR/python-install/python-3.7.17/ \
    --enable-shared \
    --enable-ipv6 \
    --with-openssl=$ENVDIR/openssl \
    LDFLAGS=-Wl,-rpath=$ENVDIR/python-install/python-3.7.17/lib,--disable-new-dtags,-L$ENVDIR/openssl/lib

make -j8

OLDPATH=$PATH
PATH=$PATH:$ENVDIR/python-install/python-3.7.17/bin/
make install

# Copy the openssl libraries to the python lib folder
cp -r $ENVDIR/openssl/lib/* $ENVDIR/python-install/python-3.7.17/lib/

cd $ENVDIR/python-install/python-3.7.17/bin/

wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py --no-check-certificate
sudo ./python3 get-pip.py

./python3 -m pip install wheel
./python3 -m pip install python-dateutil
./python3 -m pip install pyparsing

# Install mbed cli requirements
wget -O mbed-requirements.txt https://raw.githubusercontent.com/ARMmbed/mbed-os/master/requirements.txt --no-check-certificate
./python3 -m pip install -r mbed-requirements.txt
rm -f mbed-requirements.txt
sudo apt install mercurial
./python3 -m pip install mbed-cli --target $ENVDIR/mbed-cli
./python3 -m pip install mbed-cli

PATH=$OLDPATH

# DIRENV
echo -e "${BLUE}Installing direnv${WHITE}"
sudo apt-get install direnv -y
if ! cat ~/.bashrc | grep -a 'eval "$(direnv hook bash)"'; then
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
fi

# Openocd
echo -e "${BLUE}Installing openocd${WHITE}"
#sudo apt install openocd=0.11.0-1
cd $ENVDIR/.tmp
git clone https://github.com/openocd-org/openocd openocd
cd openocd
git checkout 9ea7f3d
sudo apt install libtool -y
sudo apt install pkg-config -y
sudo apt install libusb-1.0-0-dev -y
sudo apt install autoconf -y
sudo apt install automake -y
sudo apt install texinfo -y
./bootstrap
./configure --prefix=$ENVDIR/openocd --exec-prefix=$ENVDIR/openocd/bin --enable-jlink --enable-stlink
make
mkdir -p $ENVDIR/openocd
make install

# Jlink
echo -e "${BLUE}Installing JLink${WHITE}"
cd $ENVDIR/.tmp
download_archive "JLink_Linux_V788h_x86_64.tgz" "cde202c17376b4b77a99d66794c819dcf312695be783a951aaf99cd69e449612" "https://www.segger.com/downloads/jlink/JLink_Linux_V788h_x86_64.tgz" "accept_license_agreement=accepted"
tar -xvzf JLink_Linux_V788h_x86_64.tgz
cd JLink_Linux_V788h_x86_64
mkdir -p $ENVDIR/jlink
cp -r . $ENVDIR/jlink

# Fixup
## USB permission fixup
sudo usermod -a -G dialout $USER
sudo usermod -a -G plugdev $USER
sudo wget -O /etc/udev/rules.d/49-stlinkv3.rules https://raw.githubusercontent.com/stlink-org/stlink/master/config/udev/rules.d/49-stlinkv3.rules --no-check-certificate
sudo wget -O /etc/udev/rules.d/49-stlinkv2.rules https://raw.githubusercontent.com/stlink-org/stlink/master/config/udev/rules.d/49-stlinkv2.rules --no-check-certificate
sudo wget -O /etc/udev/rules.d/49-stlinkv1.rules https://raw.githubusercontent.com/stlink-org/stlink/master/config/udev/rules.d/49-stlinkv1.rules --no-check-certificate
sudo wget -O /etc/udev/rules.d/49-stlinkv2-1.rules https://raw.githubusercontent.com/stlink-org/stlink/master/config/udev/rules.d/49-stlinkv2-1.rules --no-check-certificate
sudo udevadm control --reload

sudo touch /etc/udev/rules.d/99-jlink.rules
sudo echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1366", ATTR{idProduct}=="0101", MODE="0666"' > /etc/udev/rules.d/99-jlink.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Cleanup
echo "Cleaning temp folder"
rm -rf $ENVDIR/.tmp

# Creating utilities
echo -e "${BLUE}Creating utilities${WHITE}"

mkdir -p $ENVDIR/utilities

touch $ENVDIR/utilities/envrc.content
echo "MBEDENVDIR=/home/$(whoami)/mbed-dev-env" > $ENVDIR/utilities/envrc.content
#echo "PATH_add \$MBEDENVDIR/python-install/python-3.7.17/bin/" >> $ENVDIR/utilities/envrc.content
echo "PATH_add \$MBEDENVDIR/mbed-cli/bin/" >> $ENVDIR/utilities/envrc.content
echo "PATH_add \$MBEDENVDIR/vscode/bin/" >> $ENVDIR/utilities/envrc.content
echo "PATH_add \$MBEDENVDIR/gcc-arm-none-eabi/bin/" >> $ENVDIR/utilities/envrc.content
echo "PATH_add \$MBEDENVDIR/openocd/bin/bin" >> $ENVDIR/utilities/envrc.content
echo "PATH_add \$MBEDENVDIR/jlink" >> $ENVDIR/utilities/envrc.content
echo "export PYTHONHOME=\$MBEDENVDIR/python-install/python-3.7.17" >> $ENVDIR/utilities/envrc.content
echo "export PYTHONPATH=\$MBEDENVDIR/python-install/python-3.7.17/lib/python3.7:\$MBEDENVDIR/python-install/python-3.7.17/lib/python3.7/encodings" >> $ENVDIR/utilities/envrc.content
echo "echo 'Mbed environment with VSCode has been setup and is ready to be used.'"  >> $ENVDIR/utilities/envrc.content

touch $ENVDIR/utilities/mbedify.sh
chmod +x $ENVDIR/utilities/mbedify.sh
echo "cp -f /home/$(whoami)/mbed-dev-env/utilities/envrc.content ./.envrc" > $ENVDIR/utilities/mbedify.sh
echo "direnv allow" >> $ENVDIR/utilities/mbedify.sh

if ! grep -q "export PATH=\$PATH:$ENVDIR/utilities/" "/home/$(whoami)/.bashrc"; then
  echo "export PATH=\$PATH:$ENVDIR/utilities/" >> /home/$(whoami)/.bashrc
fi


echo -e "${GREEN}Successfully installed Mbed OS development environment${WHITE}"
echo "Installation folder: /home/$(whoami)/mbed-dev-env"
echo -e "Summary of the installed components:"
echo -e "  - VScode with extensions (command(s): ${BLUE}code${WHITE})"
echo -e "  - Mbed CLI 1 (command(s): ${BLUE}mbed${WHITE})"
echo -e "  - ARM-GCC toolchain 12 (command(s): ${BLUE}arm-none-eabi-xxx${WHITE})"
echo -e "  - OpenOCD 0.12.0 (command(s): ${BLUE}openocd${WHITE})"
echo -e "  - JLink commander 7.88h (command(s): ${BLUE}JLinkExe${WHITE})"
echo "==============================="
echo -e "${BLUE}Usage instruction${WHITE}"
echo "To use this environment automatically, create a '.envrc' file at the root of directory in which you want to have access to the environment"
echo "Content of '.envrc' file:"
echo "==============================="
echo "MBEDENVDIR=/home/$(whoami)/mbed-dev-env"
echo "PATH_add \$MBEDENVDIR/mbed-cli/bin/"
echo "PATH_add \$MBEDENVDIR/vscode/bin/"
echo "PATH_add \$MBEDENVDIR/gcc-arm-none-eabi/bin/"
echo "PATH_add \$MBEDENVDIR/openocd/bin/bin"
echo "PATH_add \$MBEDENVDIR/jlink"
echo "export PYTHONHOME=\$MBEDENVDIR/python-install/python-3.7.17"
echo "export PYTHONPATH=\$MBEDENVDIR/python-install/python-3.7.17/lib/python3.7:\$MBEDENVDIR/python-install/python-3.7.17/lib/python3.7/encodings"
echo "==============================="
echo "Finally, run 'direnv allow' within the folder to enable the automatic environment setup when you enter the folder."
echo ""
echo ""
echo -e "IMPORTANT: You can also use '${BLUE}mbedify${WHITE}' command in the folder you want to automatically deploy the above content."
echo ""
echo ""
echo "Installation done"
