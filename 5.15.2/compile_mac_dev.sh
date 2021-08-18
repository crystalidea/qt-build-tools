#!/bin/bash

makej () { 
   make -j$(sysctl -n hw.ncpu) 
}

export PATH=$PATH:$(pwd)/qtbase/bin

cd qtbase

./configure -developer-build -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

makej

cd ../qttools
qmake
makej

cd ../qtmacextras
qmake
makej