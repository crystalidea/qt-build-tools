#!/bin/bash

alias makej="make -j $(sysctl hw.ncpu | awk '{print $2}')"
export PATH=$PATH:/usr/local/Qt-5.6.3/bin

cd qtbase

./configure -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

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
zip -r ~/Desktop/qt5.6.3_mac.zip Qt-5.6.3/*