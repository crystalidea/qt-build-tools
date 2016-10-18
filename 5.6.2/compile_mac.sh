#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.6.2/bin

cd qtbase
./configure -opensource -no-openssl -no-securetransport -nomake examples -nomake tests
make
echo 12345 | sudo -S sudo make install

cd ../qtdeclarative
qmake
make
echo 12345 | sudo -S sudo make install

cd ../qttools
qmake
make
echo 12345 | sudo -S sudo make install

cd ../qtmacextras
qmake
make
echo 12345 | sudo -S sudo make install

# make docs

cd ../qtbase
make docs
cd ../qttools
make docs
cd ../qtmacextras
make docs

echo 12345 | sudo -S cp -f -r ../qtbase/doc /usr/local/Qt-5.6.2/

cd /usr/local
zip -r ~/Desktop/qt5.6.2_mac.zip Qt-5.6.2/*