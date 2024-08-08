rem: https://wiki.qt.io/QtPDF_Build_Instructions

rem requirements:
rem 1. Python and html5lib package (pip3 install html5lib)
rem 2. node.js
rem 3. gperf.exe on PATH

SET PATH=%PATH%;%cd%\_tools;%cd%\_tools\cmake\bin
CALL "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
SET _ROOT=%cd%
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
mkdir qtwebengine-pdf-build
cd qtwebengine-pdf-build
C:\qt6_x64\bin\qt-configure-module.bat ../qtwebengine -- -DFEATURE_qtwebengine_build=OFF && cmake --build . --parallel && cmake --install . --config Release && cmake --install . --config Debug && pause