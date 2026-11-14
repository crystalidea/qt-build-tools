# A window with the controls QMacStyle draws its own way under Liquid Glass (patches/qtbase-macstyle-*.patch), next
# to the same AppKit controls. How to build and check it is in README.md

TEMPLATE = app
TARGET = StyleCheck

QT += widgets
CONFIG += c++20

QMAKE_MACOSX_DEPLOYMENT_TARGET = 12

HEADERS += StyleCheckDialog.h
SOURCES += main.cpp
OBJECTIVE_SOURCES += StyleCheckDialog.mm

LIBS += -framework AppKit
