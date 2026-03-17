APP_NAME = DNSSwitcher
BUNDLE_ID = com.gayakaci.dns-switcher
BUILD_DIR = .build/apple/Products/Release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
DMG_NAME = DNSSwitcher.dmg

.PHONY: build app dmg clean

build:
	swift build -c release --arch arm64 --arch x86_64

app: build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp $(BUILD_DIR)/DNSSwitcher "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp $(APP_NAME).icns "$(APP_BUNDLE)/Contents/Resources/$(APP_NAME).icns"
	/usr/libexec/PlistBuddy -c "Add :CFBundleName string '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Set :CFBundleName '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string '$(BUNDLE_ID)'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier '$(BUNDLE_ID)'" "$(APP_BUNDLE)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string 'APPL'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string '1.0.0'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string '1.0.0'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile '$(APP_NAME)'" "$(APP_BUNDLE)/Contents/Info.plist"

dmg: app
	rm -f $(DMG_NAME)
	hdiutil create -volname "$(APP_NAME)" -srcfolder "$(APP_BUNDLE)" -ov -format UDZO $(DMG_NAME)

clean:
	swift package clean
	rm -rf .build
	rm -f $(DMG_NAME)
	rm -rf $(APP_NAME).iconset
