APP_NAME = DNSSwitcher
BUNDLE_ID = com.gayakaci.dns-switcher
BUILD_DIR = .build/apple/Products/Release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
DMG_NAME = DNSSwitcher.dmg
DMG_VOL = $(APP_NAME)_Install

.PHONY: build icns app dmg clean

build:
	swift build -c release --arch arm64 --arch x86_64

icns:
	mkdir -p $(APP_NAME).iconset
	sips -z 16 16     icon.png --out $(APP_NAME).iconset/icon_16x16.png
	sips -z 32 32     icon.png --out $(APP_NAME).iconset/icon_16x16@2x.png
	sips -z 32 32     icon.png --out $(APP_NAME).iconset/icon_32x32.png
	sips -z 64 64     icon.png --out $(APP_NAME).iconset/icon_32x32@2x.png
	sips -z 128 128   icon.png --out $(APP_NAME).iconset/icon_128x128.png
	sips -z 256 256   icon.png --out $(APP_NAME).iconset/icon_128x128@2x.png
	sips -z 256 256   icon.png --out $(APP_NAME).iconset/icon_256x256.png
	sips -z 512 512   icon.png --out $(APP_NAME).iconset/icon_256x256@2x.png
	sips -z 512 512   icon.png --out $(APP_NAME).iconset/icon_512x512.png
	sips -z 1024 1024 icon.png --out $(APP_NAME).iconset/icon_512x512@2x.png
	iconutil -c icns $(APP_NAME).iconset

app: build icns
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
	codesign --force --sign - "$(APP_BUNDLE)"

dmg: app
	rm -f $(DMG_NAME)
	# Generate background image
	mkdir -p .build/dmg-resources
	swift scripts/create-dmg-background.swift .build/dmg-resources/background.png
	# Create staging folder with app and Applications symlink
	rm -rf .build/dmg-staging
	mkdir -p .build/dmg-staging
	cp -R "$(APP_BUNDLE)" .build/dmg-staging/
	ln -s /Applications .build/dmg-staging/Applications
	# Create writable DMG
	hdiutil create -volname "$(DMG_VOL)" -srcfolder .build/dmg-staging \
		-ov -format UDRW -fs HFS+ .build/$(APP_NAME)-rw.dmg
	# Mount and configure layout
	hdiutil attach .build/$(APP_NAME)-rw.dmg
	mkdir -p "/Volumes/$(DMG_VOL)/.background"
	cp .build/dmg-resources/background.png "/Volumes/$(DMG_VOL)/.background/background.png"
	osascript scripts/configure-dmg.applescript "$(DMG_VOL)" "$(APP_NAME)"
	sync
	sleep 3
	hdiutil detach "/Volumes/$(DMG_VOL)"
	# Convert to compressed read-only DMG
	hdiutil convert .build/$(APP_NAME)-rw.dmg -format UDZO -o $(DMG_NAME)
	rm -f .build/$(APP_NAME)-rw.dmg
	rm -rf .build/dmg-staging

clean:
	swift package clean
	rm -rf .build
	rm -f $(DMG_NAME)
	rm -rf $(APP_NAME).iconset
	rm -rf .build/dmg-staging .build/dmg-resources
