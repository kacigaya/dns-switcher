cask "dnsswitcher" do
  version "1.4.0"
  sha256 "07892448bde69f845ce3ddba64ff97c40f8fdd355b6d24c2504e4ec5dd9c4214"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
