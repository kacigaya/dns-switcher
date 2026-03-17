cask "dnsswitcher" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/gayakaci/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/gayakaci/dns-switcher"

  app "DNS Switcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
