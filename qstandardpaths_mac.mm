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

#undef QT_USE_EXTSTANDARDPATHS
#include "qstandardpaths.h"

#ifndef QT_NO_STANDARDPATHS

#include <qdir.h>
#include <qurl.h>
#include <private/qcore_mac_p.h>
#include <private/qfilesystemengine_p.h>

#ifndef QT_BOOTSTRAPPED
#include <qcoreapplication.h>
#include <qlibraryinfo.h>
#endif

#import <Foundation/Foundation.h>

#include <pwd.h>

QT_BEGIN_NAMESPACE

static QString pathForDirectory(NSSearchPathDirectory directory,
                                NSSearchPathDomainMask mask)
{
    return QString::fromNSString(
        [NSSearchPathForDirectoriesInDomains(directory, mask, YES) lastObject]);
}

static NSSearchPathDirectory searchPathDirectory(QStandardPaths::StandardLocation type)
{
    switch (type) {
    case QStandardPaths::DesktopLocation:
        return NSDesktopDirectory;
    case QStandardPaths::DocumentsLocation:
        return NSDocumentDirectory;
    case QStandardPaths::ApplicationsLocation:
        return NSApplicationDirectory;
    case QStandardPaths::MusicLocation:
        return NSMusicDirectory;
    case QStandardPaths::MoviesLocation:
        return NSMoviesDirectory;
    case QStandardPaths::PicturesLocation:
        return NSPicturesDirectory;
    case QStandardPaths::GenericDataLocation:
    case QStandardPaths::RuntimeLocation:
    case QStandardPaths::AppDataLocation:
    case QStandardPaths::AppLocalDataLocation:
        return NSApplicationSupportDirectory;
    case QStandardPaths::GenericCacheLocation:
    case QStandardPaths::CacheLocation:
        return NSCachesDirectory;
    case QStandardPaths::DownloadLocation:
        return NSDownloadsDirectory;
    default:
        return (NSSearchPathDirectory)0;
    }
}

static void appendOrganizationAndApp(QString &path)
{
#ifndef QT_BOOTSTRAPPED
    const QString org = QCoreApplication::organizationName();
    if (!org.isEmpty())
        path += QLatin1Char('/') + org;
    const QString appName = QCoreApplication::applicationName();
    if (!appName.isEmpty())
        path += QLatin1Char('/') + appName;
#else
    Q_UNUSED(path);
#endif
}

static QString baseWritableLocation(QStandardPaths::StandardLocation type,
                                    NSSearchPathDomainMask mask = NSUserDomainMask,
                                    bool appendOrgAndApp = false)
{
    QString path;
    const NSSearchPathDirectory dir = searchPathDirectory(type);
    switch (type) {
    case QStandardPaths::HomeLocation:
        path = QDir::homePath();
        break;
    case QStandardPaths::TempLocation:
        path = QDir::tempPath();
        break;
#if defined(QT_PLATFORM_UIKIT)
    // These locations point to non-existing write-protected paths. Use sensible fallbacks.
    case QStandardPaths::MusicLocation:
        path = pathForDirectory(NSDocumentDirectory, mask) + QLatin1String("/Music");
        break;
    case QStandardPaths::MoviesLocation:
        path = pathForDirectory(NSDocumentDirectory, mask) + QLatin1String("/Movies");
        break;
    case QStandardPaths::PicturesLocation:
        path = pathForDirectory(NSDocumentDirectory, mask) + QLatin1String("/Pictures");
        break;
    case QStandardPaths::DownloadLocation:
        path = pathForDirectory(NSDocumentDirectory, mask) + QLatin1String("/Downloads");
        break;
    case QStandardPaths::DesktopLocation:
        path = pathForDirectory(NSDocumentDirectory, mask) + QLatin1String("/Desktop");
        break;
    case QStandardPaths::ApplicationsLocation:
        break;
#endif
    case QStandardPaths::FontsLocation:
        path = pathForDirectory(NSLibraryDirectory, mask) + QLatin1String("/Fonts");
        break;
    case QStandardPaths::ConfigLocation:
    case QStandardPaths::GenericConfigLocation:
    case QStandardPaths::AppConfigLocation:
        path = pathForDirectory(NSLibraryDirectory, mask) + QLatin1String("/Preferences");
        break;
    default:
        path = pathForDirectory(dir, mask);
        break;
    }

    if (appendOrgAndApp) {
        switch (type) {
        case QStandardPaths::AppDataLocation:
        case QStandardPaths::AppLocalDataLocation:
        case QStandardPaths::AppConfigLocation:
        case QStandardPaths::CacheLocation:
            appendOrganizationAndApp(path);
            break;
        default:
            break;
        }
    }

    return path;
}

static void normaliseDirs(QStringList &dirs)
{
    // Normalise paths, skip relative paths
    QMutableListIterator<QString> it(dirs);
    while (it.hasNext()) {
        const QString dir = it.next();
        if (!dir.startsWith(QLatin1Char('/')))
            it.remove();
        else
            it.setValue(QDir::cleanPath(dir));
    }

    // Remove duplicates from the list, there's no use for duplicated
    // paths in XDG_CONFIG_DIRS - if it's not found in the given
    // directory the first time, it won't be there the second time.
    // Plus duplicate paths causes problems for example for mimetypes,
    // where duplicate paths here lead to duplicated mime types returned
    // for a file, eg "text/plain,text/plain" instead of "text/plain"
    dirs.removeDuplicates();
}

static QStringList xdgCacheDirs()
{
    QStringList dirs;
    // http://standards.freedesktop.org/basedir-spec/latest/
    QString xdgConfigDirsEnv = QFile::decodeName(qgetenv("XDG_CACHE_HOME"));
    if (xdgConfigDirsEnv.isEmpty()) {
#ifndef QT_BOOTSTRAPPED
        dirs.append(QDir::homePath() + QString::fromLatin1("/.cache"));
#endif
    } else {
        dirs = xdgConfigDirsEnv.split(QLatin1Char(':'), QString::SkipEmptyParts);

        normaliseDirs(dirs);
    }
    return dirs;
}

static QStringList xdgConfigDirs()
{
    QStringList dirs;
    // http://standards.freedesktop.org/basedir-spec/latest/
    QString xdgConfigDirsEnv = QFile::decodeName(qgetenv("XDG_CONFIG_DIRS"));
    if (xdgConfigDirsEnv.isEmpty()) {
#ifndef QT_BOOTSTRAPPED
        dirs.append(QLibraryInfo::location(QLibraryInfo::PrefixPath) + QString::fromLatin1("/etc/xdg"));
#endif
    } else {
        dirs = xdgConfigDirsEnv.split(QLatin1Char(':'), QString::SkipEmptyParts);

        normaliseDirs(dirs);
    }
    return dirs;
}

static QStringList xdgDataDirs()
{
    QStringList dirs;
    // http://standards.freedesktop.org/basedir-spec/latest/
    QString xdgDataDirsEnv = QFile::decodeName(qgetenv("XDG_DATA_DIRS"));
    if (xdgDataDirsEnv.isEmpty()) {
#ifndef QT_BOOTSTRAPPED
        dirs.append(QLibraryInfo::location(QLibraryInfo::PrefixPath) + QString::fromLatin1("/share"));
#endif
    } else {
        dirs = xdgDataDirsEnv.split(QLatin1Char(':'), QString::SkipEmptyParts);

        normaliseDirs(dirs);
    }
    return dirs;
}

static QString xdgRuntimeDir()
{
    const uid_t myUid = geteuid();
    // http://standards.freedesktop.org/basedir-spec/latest/
    QString xdgRTDir = QFile::decodeName(qgetenv("XDG_RUNTIME_DIR"));
    if (xdgRTDir.isEmpty()) {
        struct passwd *pw = 0;
        pw = getpwuid(myUid);
        const QString userName = pw? QFile::decodeName(QByteArray(pw->pw_name)) : QString();
        // NSTemporaryDirectory() returns the default $TMPDIR value, regardless of its current setting,
        // which is more in line with XDG_RUNTIME_DIR requirements.
        xdgRTDir = QString::fromNSString(NSTemporaryDirectory()) + QLatin1String("runtime-") + userName;
        QDir dir(xdgRTDir);
        if (!dir.exists()) {
            if (!QDir().mkdir(xdgRTDir)) {
                qWarning("QStandardPaths: error creating runtime directory %s: %s",
                         qPrintable(xdgRTDir), qPrintable(qt_error_string(errno)));
                return QString();
            }
        }
    } else {
        qDebug("QStandardPaths: XDG_RUNTIME_DIR is set, using '%s'", qPrintable(xdgRTDir));
    }
    // "The directory MUST be owned by the user"
    QFileInfo fileInfo(xdgRTDir);
    if (fileInfo.ownerId() != myUid) {
        qWarning("QStandardPaths: wrong ownership on runtime directory %s, %d instead of %d", qPrintable(xdgRTDir),
                 fileInfo.ownerId(), myUid);
        return QString();
    }
    // "and he MUST be the only one having read and write access to it. Its Unix access mode MUST be 0700."
    // since the current user is the owner, set both xxxUser and xxxOwner
    QFile file(xdgRTDir);
    const QFile::Permissions wantedPerms = QFile::ReadUser | QFile::WriteUser | QFile::ExeUser
                                           | QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner;
    if (file.permissions() != wantedPerms && !file.setPermissions(wantedPerms)) {
        qWarning("QStandardPaths: could not set correct permissions on runtime directory %s: %s",
                 qPrintable(xdgRTDir), qPrintable(file.errorString()));
        return QString();
    }
    return xdgRTDir;
}

QString QStandardPaths::writableLocation(StandardLocation type, bool altMode)
{
    if (altMode) {
        const QString prefix = (isTestModeEnabled())? QDir::homePath() + QLatin1String("/.qttest") : QDir::homePath();
        QString path;
        switch (type) {
        case GenericDataLocation:
        case AppDataLocation:
        case AppLocalDataLocation:
            path = prefix + QLatin1String("/.local/share");
            if (type != GenericDataLocation)
                appendOrganizationAndApp(path);
            return path;
        case GenericCacheLocation:
        case CacheLocation:
            path = prefix + QLatin1String("/.cache");
            if (type == CacheLocation)
                appendOrganizationAndApp(path);
            return path;
        case GenericConfigLocation:
        case ConfigLocation:
            return prefix + QLatin1String("/.config");
        case ApplicationsLocation:
            path = writableLocation(GenericDataLocation, altMode) + QLatin1String("/applications");
            return path;
        case RuntimeLocation:
            return xdgRuntimeDir();
        default:
            break;
        }
    }

    if (isTestModeEnabled()) {
        const QString qttestDir = QDir::homePath() + QLatin1String("/.qttest");
        QString path;
        switch (type) {
        case GenericDataLocation:
        case AppDataLocation:
        case AppLocalDataLocation:
            path = qttestDir + QLatin1String("/Application Support");
            if (type != GenericDataLocation)
                appendOrganizationAndApp(path);
            return path;
        case GenericCacheLocation:
        case CacheLocation:
            path = qttestDir + QLatin1String("/Cache");
            if (type == CacheLocation)
                appendOrganizationAndApp(path);
            return path;
        case GenericConfigLocation:
        case ConfigLocation:
        case AppConfigLocation:
            path = qttestDir + QLatin1String("/Preferences");
            if (type == AppConfigLocation)
                appendOrganizationAndApp(path);
            return path;
        case ApplicationsLocation:
            path = qttestDir + QLatin1String("/Applications");
            return path;
        default:
            break;
        }
    }

    return baseWritableLocation(type, NSUserDomainMask, true);
}

QString QStandardPaths::writableLocation(StandardLocation type)
{
    return QStandardPaths::writableLocation(type, isALTLocationsEnabled());
}

QStringList QStandardPaths::standardLocations(StandardLocation type)
{
    QStringList dirs;

    // always support the alternative mode for the readable locations.

    switch (type) {
    case GenericDataLocation:
        dirs.append(xdgDataDirs());
        break;
    case GenericConfigLocation:
    case ConfigLocation:
        dirs.append(xdgConfigDirs());
        break;
    case GenericCacheLocation:
    case CacheLocation:
        dirs.append(xdgCacheDirs());
        break;
    case ApplicationsLocation:
        QStringList xdgDirs = xdgDataDirs();
        for (int i = 0; i < xdgDirs.count(); ++i)
            xdgDirs[i].append(QLatin1String("/applications"));
        dirs.append(xdgDirs);
        break;
    }

#if defined(QT_PLATFORM_UIKIT)
    if (type == PicturesLocation)
        dirs << writableLocation(PicturesLocation) << QLatin1String("assets-library://");
#endif

    if (type == GenericDataLocation || type == FontsLocation || type == ApplicationsLocation
            || type == AppDataLocation || type == AppLocalDataLocation
            || type == GenericCacheLocation || type == CacheLocation) {
        QList<NSSearchPathDomainMask> masks;
        masks << NSLocalDomainMask;
        if (type == FontsLocation || type == GenericCacheLocation)
            masks << NSSystemDomainMask;

        for (QList<NSSearchPathDomainMask>::const_iterator it = masks.begin();
             it != masks.end(); ++it) {
            const QString path = baseWritableLocation(type, *it, true);
            if (!path.isEmpty() && !dirs.contains(path))
                dirs.append(path);
        }
    }

    if (type == AppDataLocation || type == AppLocalDataLocation) {
        // additional locations for alternative mode:
        QStringList xdgDirs = xdgDataDirs();
        for (int i = 0; i < xdgDirs.count(); ++i) {
            appendOrganizationAndApp(xdgDirs[i]);
        }
        dirs.append(xdgDirs);

        CFBundleRef mainBundle = CFBundleGetMainBundle();
        if (mainBundle) {
            CFURLRef bundleUrl = CFBundleCopyBundleURL(mainBundle);
            CFStringRef cfBundlePath = CFURLCopyPath(bundleUrl);
            QString bundlePath = QString::fromCFString(cfBundlePath);
            CFRelease(cfBundlePath);
            CFRelease(bundleUrl);

            CFURLRef resourcesUrl = CFBundleCopyResourcesDirectoryURL(mainBundle);
            CFStringRef cfResourcesPath = CFURLCopyPath(resourcesUrl);
            QString resourcesPath = QString::fromCFString(cfResourcesPath);
            CFRelease(cfResourcesPath);
            CFRelease(resourcesUrl);

            // Handle bundled vs unbundled executables. CFBundleGetMainBundle() returns
            // a valid bundle in both cases. CFBundleCopyResourcesDirectoryURL() returns
            // an absolute path for unbundled executables.
            if (resourcesPath.startsWith(QLatin1Char('/')))
                dirs.append(resourcesPath);
            else
                dirs.append(bundlePath + resourcesPath);
        }
    }
    const QString localDir = writableLocation(type, false);
    const QString localAltDir = writableLocation(type, true);
    // FIXME: do we need to handle FontsLocation here too as in Qt <=5.6?
    if (!localDir.isEmpty()) {
        dirs.prepend(localDir);
        if (localAltDir != localDir) {
            dirs.prepend(localAltDir);
        }
    }
    return dirs;
}

#ifndef QT_BOOTSTRAPPED
QString QStandardPaths::displayName(StandardLocation type)
{
    // Use "Home" instead of the user's Unix username
    if (QStandardPaths::HomeLocation == type)
        return QCoreApplication::translate("QStandardPaths", "Home");

    // The temporary directory returned by the old Carbon APIs is ~/Library/Caches/TemporaryItems,
    // the display name of which ("TemporaryItems") isn't translated by the system. The standard
    // temporary directory has no reasonable display name either, so use something more sensible.
    if (QStandardPaths::TempLocation == type)
        return QCoreApplication::translate("QStandardPaths", "Temporary Items");

    // standardLocations() may return an empty list on some platforms
    if (QStandardPaths::ApplicationsLocation == type)
        return QCoreApplication::translate("QStandardPaths", "Applications");

    if (QCFType<CFURLRef> url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
            standardLocations(type).constFirst().toCFString(),
            kCFURLPOSIXPathStyle, true)) {
        QCFString name;
        CFURLCopyResourcePropertyForKey(url, kCFURLLocalizedNameKey, &name, NULL);
        if (name && CFStringGetLength(name))
            return QString::fromCFString(name);
    }

    return QFileInfo(baseWritableLocation(type)).fileName();
}
#endif

QT_END_NAMESPACE

#endif // QT_NO_STANDARDPATHS
