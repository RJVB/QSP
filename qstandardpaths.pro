TEMPLATE = lib
CONFIG += plugin
QT += core core-private

TARGET = qextstandardpaths

QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9

SOURCES += \
    qstandardpaths.cpp
OBJECTIVE_SOURCES += \
    qstandardpaths_mac.mm \
    missing_OS_functions.mm

HEADERS += \
    qstandardpaths.h \
    qextstandardpaths.h

LIBS_PRIVATE += -framework AppKit -framework CoreServices
