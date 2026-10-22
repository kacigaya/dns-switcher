cask "dnsswitcher" do
  version "1.4.1"
  sha256 "112b61b95bc41693fa33bd9c6a8286edefa09d56b6f9427243f9a5bf70066c12"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
