cask "dnsswitcher" do
  version "1.3.2"
  sha256 "312916fd9d940687537e542d0b5f3a90dd5f100881cbde03cc0dc5c5e35ad1e0"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
