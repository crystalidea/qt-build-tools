#!/bin/bash

if [ -z "$1" ]; then echo "Please specify the admin pass as first argument"; exit 1; fi

makej () { 
   make -j$(sysctl -n hw.ncpu) 
}
export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure $OPTIONS QMAKE_APPLE_DEVICE_ARCHS=arm64 -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport  -prefix /usr/local/Qt-5.15.8-arm

makej
echo $1 | sudo -S sudo make install

cd ../qttools
qmake
makej
echo $1 | sudo -S sudo make install

cd ../qtmacextras
qmake
makej
echo $1 | sudo -S sudo make install

cd /usr/local
zip -r ~/Desktop/qt5.15.8_mac_arm.zip Qt-5.15.8/*