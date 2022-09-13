# iOSIntegrity

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

```objectivec

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"integrity start");
        IntegrityCheck * myOb = [IntegrityCheck new];
    
        [myOb testWithCompletionHandler:^(NSString* string){
            NSLog(@"Callback start");
        
            dispatch_async(dispatch_get_main_queue(), ^{
                UIWindow* topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                topWindow.rootViewController = [UIViewController new];
                topWindow.windowLevel = UIWindowLevelAlert + 1;
        
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"INTEGRITY" message:@"Something went wrong" preferredStyle:UIAlertControllerStyleAlert];
        
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"confirm") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) 
                exit(1);
            }]];
    
            [topWindow makeKeyAndVisible];
            [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
            });
        }];
    });

```

cd ios/ && arch -x86_64 pod install.

Select your project in Xcode, and go to "Build Settings". Scroll down until you see "Search Paths", and finally, "Library Search Paths". Replace "$(TOOLCHAIN_DIR)/usr/lib/swift-5.0/$(PLATFORM_NAME)" with "$(SDKROOT)/usr/lib/swift".