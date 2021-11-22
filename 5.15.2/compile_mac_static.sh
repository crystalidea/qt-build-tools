#!/bin/bash

if [ -z "$1" ]; then echo "Please specify the admin pass as first argument"; exit 1; fi

makej () { 
   make -j$(sysctl -n hw.ncpu) 
}
export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -static -release -ltcg -optimize-size -no-pch -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport -prefix /usr/local/Qt-5.15.2-static

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
zip -r ~/Desktop/qt5.15.2_mac_static.zip Qt-5.15.2-static/*