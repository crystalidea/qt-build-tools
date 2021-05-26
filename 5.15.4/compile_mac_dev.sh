#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.15.4/bin

cd qtbase

./configure -developer-build -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

make -j 12

cd ../qttools
qmake
make -j 12

cd ../qtmacextras
qmake
make -j 12