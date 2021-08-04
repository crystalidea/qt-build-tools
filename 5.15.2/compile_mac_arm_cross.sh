#!/bin/bash

alias makej="make -j $(sysctl hw.ncpu | awk '{print $2}')"
export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -device-option QMAKE_APPLE_DEVICE_ARCHS=arm64 -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport -prefix /usr/local/Qt-5.15.2-arm

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
zip -r ~/Desktop/qt5.15.2_mac_arm.zip Qt-5.15.2-arm/*