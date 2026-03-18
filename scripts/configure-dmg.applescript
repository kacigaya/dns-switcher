on run argv
	set volName to item 1 of argv
	set appName to item 2 of argv

	tell application "Finder"
		tell disk volName
			open
			set current view of container window to icon view
			set toolbar visible of container window to false
			set statusbar visible of container window to false
			set bounds of container window to {200, 200, 860, 600}
			set theViewOptions to icon view options of container window
			set arrangement of theViewOptions to not arranged
			set icon size of theViewOptions to 80
			set background picture of theViewOptions to file ".background:background.png"
			set position of item (appName & ".app") of container window to {150, 200}
			set position of item "Applications" of container window to {510, 200}
			close
			open
			update without registering applications
			delay 2
			close
		end tell
	end tell
end run
