#!/bin/bash

export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -device-option QMAKE_APPLE_DEVICE_ARCHS=arm64 -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport -prefix /usr/local/Qt-5.15.2-arm

make -j 16
echo maki | sudo -S sudo make install

cd ../qttools
qmake
make -j 16
echo maki | sudo -S sudo make install

cd ../qtmacextras
qmake
make -j 16
echo maki | sudo -S sudo make install

cd /usr/local
zip -r ~/Desktop/qt5.15.2_mac_arm.zip Qt-5.15.2-arm/*