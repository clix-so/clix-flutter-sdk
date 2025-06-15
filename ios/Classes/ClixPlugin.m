#import "ClixPlugin.h"
#if __has_include(<clix_flutter_sdk/clix_flutter_sdk-Swift.h>)
#import <clix_flutter_sdk/clix_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "clix_flutter_sdk-Swift.h"
#endif

@implementation ClixPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [ClixPlugin register:registrar];
}
@end