# iOSIntegrity

## Installation in IOS 

### Step 1: Create New Swift Class
Add a `.swift` file to your project, and name it `IntegrityCheck.swift`.

In `IntegrityCheck.swift`:

```swift
import Foundation
import iOSIntegrity

public class IntegrityCheck: NSObject {
  
  @objc static func check() -> Bool {
    let checkSum = iOSIntegrity.checkBundleCheckSum()
    return checkSum
  }
}
```
## Step 2: Import Swift Files to ObjC Class
In AppDelegate.m:

```objectivec
#import "<#YourProjectName#>-Swift.h"
```

The file:`<#YourProjectName#>-Swift.h` should already be created automatically in your project, even if you can not see it.

## Step 3: Add following code to application method in AppDelegate.m

```objectivec
//integrity
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog(@"integrity start");
    bool ic = [IntegrityCheck check];
    
    if(ic == false) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow* topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            topWindow.rootViewController = [UIViewController new];
            topWindow.windowLevel = UIWindowLevelAlert + 1;
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"INTEGRITY" message:@"Something went wrong" preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"confirm") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // continue your work
            exit(1);
            }]];
            
            [topWindow makeKeyAndVisible];
            [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
});
```

# Install Build Phase

## Step 1: Add custom Run Script in Build Phases  

Select xcodeproj file of you project -> Select Target -> Select Build Phases -> Click on plus button (upper left corner) -> Select New Run Script Phase.

![a red dot](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==)

A description of this package.

sudo arch -x86_64 gem install ffi
add this code at the end of the pod file which is inside ios folder:

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings["ONLY_ACTIVE_ARCH"] = "NO"
        end
    end
end
```
Add following code to application method in AppDelegate.m



cd ios/ && arch -x86_64 pod install.

Select your project in Xcode, and go to "Build Settings". Scroll down until you see "Search Paths", and finally, "Library Search Paths". Replace "$(TOOLCHAIN_DIR)/usr/lib/swift-5.0/$(PLATFORM_NAME)" with "$(SDKROOT)/usr/lib/swift".