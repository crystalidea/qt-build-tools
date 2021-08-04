#!/bin/bash

alias makej="make -j $(sysctl hw.ncpu | awk '{print $2}')"
export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -static -release -ltcg -optimize-size -no-pch -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport -prefix /usr/local/Qt-5.15.4-static

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
zip -r ~/Desktop/qt5.15.4_mac_static.zip Qt-5.15.4-static/*