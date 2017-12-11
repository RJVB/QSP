/****************************************************************************
**
** Copyleft (C) 2017 René J.V. Bertin
**
****************************************************************************/

#include <qglobal.h>

#import <CoreFoundation/CoreFoundation.h>
#import <AppKit/AppKit.h>

#if QT_MAC_DEPLOYMENT_TARGET_BELOW(__MAC_10_10, __IPHONE_NA)
#warning "providing LSCopyDefaultApplicationURLForURL"
Q_CORE_EXPORT CFURLRef LSCopyDefaultApplicationURLForURL(CFURLRef inURL, LSRolesMask inRoleMask, CFErrorRef *outError)
{
    CFURLRef outAppURL = NULL;
    OSStatus ret = LSGetApplicationForURL(inURL, inRoleMask, NULL, &outAppURL);
    if (ret == noErr) {
        return outAppURL;
    } else if (outError) {
        CFErrorRef err = CFErrorCreate(NULL, CFSTR("OSStatus"), ret, NULL);
        *outError = err;
    }
    return NULL;
}
#endif
