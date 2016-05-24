#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.6.1/bin

cd qtbase
./configure -opensource -no-openssl -no-securetransport -nomake examples -nomake tests -platform macx-clang-32
make
make docs
sudo make install

cd ../qtdeclarative
qmake
make
make docs
sudo make install

cd ../qttools
qmake
make
make docs
sudo make install

cd ../qtmacextras
qmake
make
make docs
sudo make install

sudo cp -f -r ../qtbase/doc /usr/local/Qt-5.6.1/

cd /usr/local
zip -r ~/Desktop/qt5.6.1_mac.zip Qt-5.6.1/*