cask "dnsswitcher" do
  version "1.3.1"
  sha256 "07ee70a2ffae3632bc1719c28da4fb9e4eec41b0170ccc6973572b50a75b5683"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
