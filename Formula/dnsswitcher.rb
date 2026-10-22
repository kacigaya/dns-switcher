cask "dnsswitcher" do
  version "1.5.0"
  sha256 "53cc0950c0a3b30b4d1302cc81c60709d5e1a9bcc9020e6672a43f534ff9a48a"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
