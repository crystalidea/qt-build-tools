#!/bin/bash

export PATH=$PATH:/usr/local/Qt-5.6.3/bin

cd qtbase

if [[ $1 == openssl ]]; then
    
	# download openssl
	curl -O https://www.openssl.org/source/old/1.0.2/openssl-1.0.2l.tar.gz
	tar -xvzf openssl-1.0.2l.tar.gz

	# compile openssl
	cd openssl-1.0.2l
	./Configure darwin64-x86_64-cc --prefix=$PWD/dist
	make
	# print arch info (optional)
	lipo -info libssl.a 
	lipo -info libcrypto.a
	make install
	cd ..

	# continue

	OPENSSL_LIBS='-L$PWD/openssl-1.0.2l/dist/lib -lssl -lcrypto' ./configure -opensource -confirm-license -no-securetransport -nomake examples -nomake tests -openssl-linked -I $PWD/openssl-1.0.2l/dist/include -L $PWD/openssl-1.0.2l/dist/lib

elif [[ $1 == securetransport ]]; then

	./configure -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

else

	echo "Error: please specify which SSL layer to use (openssl or securetransport)"
    exit 1

fi

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

echo 12345 | sudo -S cp -f -r ../qtbase/doc /usr/local/Qt-5.6.3/

cd /usr/local
zip -r ~/Desktop/qt5.6.3_mac.zip Qt-5.6.3/*