/****************************************************************************
**
** Copyleft (C) 2017 René J.V. Bertin
**
****************************************************************************/

// #include <exception>
// #include <objc/objc-exception.h>

#include <qglobal.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
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

#warning "providing NSURLQuarantinePropertiesKey"
FOUNDATION_EXPORT NSString * const NSURLQuarantinePropertiesKey = (NSString*) kLSItemQuarantineProperties;

#endif

#if QT_MAC_DEPLOYMENT_TARGET_BELOW(__MAC_10_11, __IPHONE_NA)

#warning "providing [NSFont systemFontOfSize:weight:]"

typedef CGFloat NSFontWeight;

@interface NSFont (missing)
+ (NSFont*) systemFontOfSize:(CGFloat)fontSize weight:(NSFontWeight)weight;
@end

@implementation NSFont (missing)

+ (NSFont*) systemFontOfSize:(CGFloat)fontSize weight:(NSFontWeight)weight
{
    NSFont *fnt = [NSFont systemFontOfSize:fontSize];
    NSLog(@"[NSFont systemFontOfSize:%g weight:%g] ignoring unsupported weight param; returning font %@", fontSize, weight, fnt);
    return fnt;
}

@end
#endif

#if QT_MAC_DEPLOYMENT_TARGET_BELOW(__MAC_10_10, __IPHONE_NA)

#warning "providing [NSWindow setTitlebarAppearsTransparent:]"

@interface NSWindow (missing)
+ (void) setTitlebarAppearsTransparent:(BOOL)enabled;
+ (BOOL) titlebarAppearsTransparent;
@end

@implementation NSWindow (missing)

+ (void) setTitlebarAppearsTransparent:(BOOL)enabled
{
    return;
}

+ (BOOL) titlebarAppearsTransparent
{
    return false;
}

@end

@interface NSPanel (missing)
+ (void) setTitlebarAppearsTransparent:(BOOL)enabled;
+ (BOOL) titlebarAppearsTransparent;
@end

@implementation NSPanel (missing)

+ (void) setTitlebarAppearsTransparent:(BOOL)enabled
{
    return;
}

+ (BOOL) titlebarAppearsTransparent
{
    return false;
}

@end
#endif

// static void uncaughtExceptionHandler(NSException *e)
// {
//     NSArray *stack = [e callStackReturnAddresses];
//     NSLog(@"Uncaught exception: %@", e);
//     NSLog(@"Stack trace: %@", stack);
// }
// 
// static void cpp_terminate()
// {
//     NSLog(@"Aborting on uncaught exception");
//     abort();
// }
// 
// __attribute__((constructor)) void missing_OS_functions_init()
// {
//     [NSApplication sharedApplication];
//     objc_setUncaughtExceptionHandler(uncaughtExceptionHandler);
//     NSSetUncaughtExceptionHandler(uncaughtExceptionHandler);
//     NSLog(@"Uncaught objc exception handler: %p (%p)", NSGetUncaughtExceptionHandler(), uncaughtExceptionHandler);
//     std::set_terminate(cpp_terminate);
//     std::set_unexpected(cpp_terminate);
// }
