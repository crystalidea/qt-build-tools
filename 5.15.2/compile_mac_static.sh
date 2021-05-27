#!/bin/bash

export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -static -release -ltcg -optimize-size -no-pch -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport -prefix /usr/local/Qt-5.15.2-static

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
zip -r ~/Desktop/qt5.15.2_mac_static.zip Qt-5.15.2-static/*