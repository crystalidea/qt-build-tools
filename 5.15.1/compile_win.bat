SET PATH=%PATH%;%cd%\bin
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x86
SET _ROOT=%cd%
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
cd qtbase
if "%~1"=="step2" goto step2
IF EXIST openssl-1.1.1a\build GOTO OPENSSL_ALREAD_COMPILED
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1a.tar.gz
7z x openssl-1.1.1a.tar.gz
7z x openssl-1.1.1a.tar
rm openssl-1.1.1a.tar.gz
rm openssl-1.1.1a.tar
cd openssl-1.1.1a
perl Configure VC-WIN32 no-asm no-shared no-tests --prefix=%cd%\build --openssldir=%cd%\build
nmake
nmake install
rm test\*.exe
rm test\*.pdb
rm test\*.obj
:OPENSSL_ALREAD_COMPILED
cd ..
configure -opensource -developer-build -confirm-license -opengl desktop -mp -nomake tests -nomake examples -I "%cd%\openssl-1.1.1a\build\include" -openssl-linked OPENSSL_LIBS="%cd%\openssl-1.1.1a\build\lib\libssl.lib %cd%\openssl-1.1.1a\build\lib\libcrypto.lib -lcrypt32 -lws2_32 -lAdvapi32 -luser32"
goto :EOF
:step2
nmake
cd ..\qttools
..\qtbase\bin\qmake
nmake
cd ..\qtbase
cd ..
cd qtbase
cd openssl-1.1.1a
del /s /f /q out32
del /s /f /q out32.dbg
cd ..
cd ..
del *.obj /s /f
del *.ilk /s /f
del *.pch /s /f
del Makefile* /s /f
