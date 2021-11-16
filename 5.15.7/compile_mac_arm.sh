#!/bin/bash

makej () { 
   make -j$(sysctl -n hw.ncpu) 
}
export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure $OPTIONS QMAKE_APPLE_DEVICE_ARCHS=arm64 -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

makej
echo maki | sudo -S sudo make install

cd ../qttools
qmake
makej
echo maki | sudo -S sudo make install

cd ../qtmacextras
qmake
makej
echo maki | sudo -S sudo make install

cd /usr/local
zip -r ~/Desktop/qt5.15.7_mac_arm.zip Qt-5.15.7/*