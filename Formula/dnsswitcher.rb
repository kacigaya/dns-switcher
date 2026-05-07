cask "dnsswitcher" do
  version "1.2.1"
  sha256 "6f03b3f3c5948d64a1994fe3afcfe2cf0652b24f21ee76901b6e4b5e6ae939fc"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
