#!/bin/sh
# launcher script to be copied into the root of a Qt installation tree, e.g.
# /usr/local/qt/5/5.9.1 . Copy libqextstandardpaths.dylib to that location too.
#
# Then,
# /usr/local/qt/5/5.9.1/thisQt.sh /path/to/some/QtThingy.app/Contents/MacOS/QtThingy
#
# will run QtThingy with the Qt version from /usr/local/qt/5/5.9.1


HERE="`dirname $0`"

# insert libqextstandardpaths.dylib, must be built against the Qt from this library
if [ "${DYLD_INSERT_LIBRARIES}" != "" ] ;then
    export DYLD_INSERT_LIBRARIES="${DYLD_INSERT_LIBRARIES}:${HERE}/libqextstandardpaths.dylib"
else
    export DYLD_INSERT_LIBRARIES="${HERE}/libqextstandardpaths.dylib"
fi

export DYLD_FORCE_FLAT_NAMESPACE=1

export DYLD_FRAMEWORK_PATH="${HERE}/clang_64/lib:${DYLD_FRAMEWORK_PATH}"

if [ "${QT_PLUGIN_PATH}" != "" ] ;then
    export QT_PLUGIN_PATH="${HERE}/clang_64/plugins:${QT_PLUGIN_PATH}"
else
    export QT_PLUGIN_PATH="${HERE}/clang_64/plugins"
fi
if [ -d /opt/local/share/qt5/plugins ] ;then
    export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}:/opt/local/share/qt5/plugins"
fi

# used by QSP in libqextstandardpaths.dylib:
export XDG_DATA_DIRS=/opt/local/share
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_CONFIG_DIRS=/opt/local/etc/xdg
export XDG_RUNTIME_DIR=${TMPDIR}/runtime-${USER}

exec "$@"
