option(host_build)
CONFIG += force_bootstrap

SOURCES += main.cpp ../shared/shared.cpp
QT = core
LIBS += -framework CoreFoundation

load(qt_tool)