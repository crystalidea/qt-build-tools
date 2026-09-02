#!/bin/bash

if [ -z "$1" ]; then echo "Please specify the admin pass as first argument"; exit 1; fi

makej () {
   make -j$(sysctl -n hw.ncpu)
}
export PATH=$PATH:$(pwd)/qtbase/bin

# Source root, needed after the build to scrub it out of the installed .prl files.
SRC_ROOT="$(pwd)"

cd qtbase

./configure QMAKE_APPLE_DEVICE_ARCHS="x86_64 arm64" -opensource -confirm-license -nomake examples -nomake tests -no-openssl -securetransport

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

# ---------------------------------------------------------------------------
# Scrub the build tree out of the installed .prl files.
#
# Each Qt module ships a .prl telling qmake projects what to link against it.
# qtbase's own modules record the portable $$[QT_INSTALL_LIBS], but the modules
# built separately above (qttools -> QtHelp, QtDesigner, QtDesignerComponents,
# QtUiTools; qtmacextras -> QtMacExtras) record the literal path of the qtbase
# build instead:
#     QMAKE_PRL_LIBS = -F<source root>/qtbase/lib -framework QtGui ...
# The source tree is normally deleted after the build, and from then on every
# project linking those modules gets, on every link:
#     ld: warning: directory not found for option '-F<source root>/qtbase/lib'
#
# Replace those tokens with $$[QT_INSTALL_LIBS] - the same thing the correctly
# recorded modules use, resolved by qmake to wherever Qt actually lives. Only
# QMAKE_PRL_LIBS lines are touched (QMAKE_PRL_LIBS_FOR_CMAKE included, it shares
# the prefix); QMAKE_PRL_BUILD_DIR is informational and never reaches a link
# command, so it is left alone.
#
# .prl files sit both directly in lib/ and inside the framework bundles
# (lib/QtMacExtras.framework/Versions/5/Resources/QtMacExtras.prl), hence -r.
QT_PREFIX="$(qmake -query QT_INSTALL_PREFIX)"
echo "Scrubbing build-tree paths from .prl files in $QT_PREFIX ..."

grep -rl "^QMAKE_PRL_LIBS.*-[LF]$SRC_ROOT" "$QT_PREFIX/lib" --include='*.prl' 2>/dev/null |
while IFS= read -r prl; do
    echo "  $prl"
    echo $1 | sudo -S sed -i.bak \
        -e '/^QMAKE_PRL_LIBS/ s|-F'"$SRC_ROOT"'[^ ;]*|-F$$[QT_INSTALL_LIBS]|g' \
        -e '/^QMAKE_PRL_LIBS/ s|-L'"$SRC_ROOT"'[^ ;]*|-L$$[QT_INSTALL_LIBS]|g' \
        "$prl"
done

# Nothing should be left; say so loudly if something slipped through.
remaining=$(grep -rl "^QMAKE_PRL_LIBS.*-[LF]$SRC_ROOT" "$QT_PREFIX/lib" --include='*.prl' 2>/dev/null | wc -l | tr -d ' ')
if [ "$remaining" != "0" ]; then
    echo "WARNING: $remaining .prl file(s) still reference the build tree"
fi

cd /usr/local
zip -r ~/Desktop/qt5.15.17_mac.zip Qt-5.15.17/* -x '*.prl.bak'