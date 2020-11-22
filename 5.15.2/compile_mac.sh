#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.15.2/bin

cd qtbase

./configure -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

make -j 12
echo maki | sudo -S sudo make install

cd ../qttools
qmake
make -j 12
echo maki | sudo -S sudo make install

cd ../qtmacextras
qmake
make -j 12
echo maki | sudo -S sudo make install

cd /usr/local
zip -r ~/Desktop/qt5.15.2_mac.zip Qt-5.15.2/*