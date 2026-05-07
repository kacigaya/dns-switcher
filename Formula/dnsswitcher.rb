cask "dnsswitcher" do
  version "1.2.2"
  sha256 "6e0295650fa05d03e1b5c4d3c0c9e555de2f2e6afb840113a3ba2034579a283d"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
