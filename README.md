# iOSIntegrity

A description of this package.

sudo arch -x86_64 gem install ffi
add this code at the end of the pod file which is inside ios folder:

```Swift
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings["ONLY_ACTIVE_ARCH"] = "NO"
        end
    end
end
```

cd ios/ && arch -x86_64 pod install.

Select your project in Xcode, and go to "Build Settings". Scroll down until you see "Search Paths", and finally, "Library Search Paths". Replace "$(TOOLCHAIN_DIR)/usr/lib/swift-5.0/$(PLATFORM_NAME)" with "$(SDKROOT)/usr/lib/swift".