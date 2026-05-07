cask "dnsswitcher" do
  version "1.2.2"
  sha256 "3f55eac3f3711f8c3987e7589145e96ab55e4ca6ce68d746dae0831ca7dadc79"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
