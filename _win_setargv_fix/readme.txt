пришлось скомпилировать и скопировать файл сюда
C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.16.27023\lib\x64\setargv.obj
C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.16.27023\lib\x86\setargv.obj

использовал вот это
https://perldoc.pl/perlwin32

В итоге:

cd C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.16.27023\crt\src\linkopts\
cl.exe /c /I. /D_CRTBLD setargv.cpp