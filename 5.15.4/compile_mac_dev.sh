#!/bin/bash

alias makej="make -j $(sysctl hw.ncpu | awk '{print $2}')"
export PATH=$PATH:/usr/local/Qt-5.15.4/bin

cd qtbase

./configure -developer-build -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

makej

cd ../qttools
qmake
makej

cd ../qtmacextras
qmake
makej