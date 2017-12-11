/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtCore module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QSTANDARDPATHS_H
#define QSTANDARDPATHS_H

#include <QtCore/qstringlist.h>
#include <QtCore/qobjectdefs.h>

QT_BEGIN_NAMESPACE


#ifndef QT_NO_STANDARDPATHS

#if defined(Q_OS_MACOS) /* || defined(???) */
// QStandardPaths provides an alternative mode on these platforms
#define QSTANDARDPATHS_HAS_ALTERNATIVE_MODE
#endif

class Q_CORE_EXPORT QStandardPaths
{
    Q_GADGET

public:
    // Do not re-order, must match QDesktopServices
    enum StandardLocation {
        DesktopLocation,
        DocumentsLocation,
        FontsLocation,
        ApplicationsLocation,
        MusicLocation,
        MoviesLocation,
        PicturesLocation,
        TempLocation,
        HomeLocation,
        DataLocation,
        CacheLocation,
        GenericDataLocation,
        RuntimeLocation,
        ConfigLocation,
        DownloadLocation,
        GenericCacheLocation,
        GenericConfigLocation,
        AppDataLocation,
        AppConfigLocation,
        AppLocalDataLocation = DataLocation
    };
    Q_ENUM(StandardLocation)

    static void setALTLocationsEnabled(bool altMode);
    static bool isALTLocationsEnabled();
// #if defined(Q_OS_MACOS)
//     // obsolete versions:
//     static Q_DECL_DEPRECATED void setXDGLocationsEnabled(bool altMode);
//     static Q_DECL_DEPRECATED bool isXDGLocationsEnabled();
// #endif // Q_OS_MACOS

    static QString writableLocation(StandardLocation type);
    static QStringList standardLocations(StandardLocation type);

    enum LocateOption {
        LocateFile = 0x0,
        LocateDirectory = 0x1
    };
    Q_DECLARE_FLAGS(LocateOptions, LocateOption)
    Q_FLAG(LocateOptions)

    static QString locate(StandardLocation type, const QString &fileName, LocateOptions options = LocateFile);
    static QStringList locateAll(StandardLocation type, const QString &fileName, LocateOptions options = LocateFile);
#ifndef QT_BOOTSTRAPPED
    static QString displayName(StandardLocation type);
#endif

    static QString findExecutable(const QString &executableName, const QStringList &paths = QStringList());

#if QT_DEPRECATED_SINCE(5, 2)
    static QT_DEPRECATED void enableTestMode(bool testMode);
#endif
    static void setTestModeEnabled(bool testMode);
    static bool isTestModeEnabled();

protected:
    static QString writableLocation(StandardLocation type, bool altMode);
    static Q_DECL_DEPRECATED QStringList standardLocations(StandardLocation type, bool altMode);

    static Q_DECL_DEPRECATED QString locate(StandardLocation type, bool altMode, const QString &fileName, LocateOptions options = LocateFile);
    static Q_DECL_DEPRECATED QStringList locateAll(StandardLocation type, bool altMode, const QString &fileName, LocateOptions options = LocateFile);

private:
    // prevent construction
    QStandardPaths();
    ~QStandardPaths();
    static bool usingALTLocations, isSetALTLocations;

    friend class QExtStandardPaths;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(QStandardPaths::LocateOptions)

/* **** Extended QStandardPaths **** */

#ifdef QT_EXTSTANDARDPATHS_ALT_DEFAULT
#if QT_EXTSTANDARDPATHS_ALT_DEFAULT == runtime
#define QSPDEFAULTALTMODE  QStandardPaths::isALTLocationsEnabled()
#else
#define QSPDEFAULTALTMODE  QT_EXTSTANDARDPATHS_ALT_DEFAULT
#endif // "runtime"
#else
#define QSPDEFAULTALTMODE  false
#endif

// obsolete version:
#ifdef QT_EXTSTANDARDPATHS_XDG_DEFAULT
#if QT_EXTSTANDARDPATHS_XDG_DEFAULT == runtime
#undef QSPDEFAULTALTMODE
#define QSPDEFAULTALTMODE  QStandardPaths::isALTLocationsEnabled()
#else
#undef QSPDEFAULTALTMODE
#define QSPDEFAULTALTMODE  QT_EXTSTANDARDPATHS_XDG_DEFAULT
#endif // "runtime"
#endif

// #ifndef QSTANDARDPATHS_CPP

/*!
    \class QExtStandardPaths
    \inmodule QtCore
    \brief The QExtStandardPaths class provides configurable methods for accessing standard paths.

    This class inherits and elaborates on \class QStandardPaths, providing access to the support for
    native vs. alternative (e.g. XDG-compliant) standard locations that QStandardPaths has on certain
    platforms (currently Mac OS X, Cygwin and MSYS2).
    When the QT_USE_EXTSTANDARDPATHS macro is defined, this class will replace QStandardPaths, and
    in that case the QT_EXTSTANDARDPATHS_ALT_DEFAULT macro will define the behaviour of code that does
    not use QExtStandardPaths explicitly itself. When undefined or QT_EXTSTANDARDPATHS_ALT_DEFAULT=false,
    QExtStandardPaths will use native locations, even if QStandardPaths::isALTLocationsEnabled() returns true.
    When QT_EXTSTANDARDPATHS_ALT_DEFAULT=runtime, behaviour is controlled at runtime through
    QStandardPaths::setALTLocationsEnabled() and QStandardPaths::isALTLocationsEnabled().
    In all other cases QStandardPaths will use alternative locations.
*/
class Q_CORE_EXPORT QExtStandardPaths : public QStandardPaths
{
public:
    /*!
        returns the default ALT mode as determined when the code was being compiled.
    */
    static bool getDefaultALTMode()
    {
        return QSPDEFAULTALTMODE;
    }
    static QString writableLocation(StandardLocation type, bool altMode=QSPDEFAULTALTMODE)
    {
        return QStandardPaths::writableLocation(type, altMode);
    }

private:
    // prevent construction
    QExtStandardPaths();
    ~QExtStandardPaths();
};

// #endif // QSTANDARDPATHS_CPP

#endif // QT_NO_STANDARDPATHS

QT_END_NAMESPACE

#ifdef QT_USE_EXTSTANDARDPATHS
#define QStandardPaths  QExtStandardPaths
#endif // QT_USE_EXTSTANDARDPATHS


#endif // QSTANDARDPATHS_H
