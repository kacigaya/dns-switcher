cask "dnsswitcher" do
  version "1.3.2"
  sha256 "1269b61d40e7d3d9a0f6acc2ff458c76f49c39b57d374c15f62c76363f13acb2"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
