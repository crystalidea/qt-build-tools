#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.13.2/bin

cd qtbase

./configure $OPTIONS QMAKE_APPLE_DEVICE_ARCHS=arm64 -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

make -j 8
echo maki | sudo -S sudo make install

cd ../qttools
qmake
make -j 8
echo maki | sudo -S sudo make install

cd ../qtmacextras
qmake
make -j 8
echo maki | sudo -S sudo make install

cd /usr/local
zip -r ~/Desktop/qt5.13.2_mac_arm.zip Qt-5.13.2/*