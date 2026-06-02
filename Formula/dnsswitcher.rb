cask "dnsswitcher" do
  version "1.3.1"
  sha256 "233cfe3d36a7a53b6fadb6f13e88298c3cb82ec96f28fd2ebcce3afe833d5b8c"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
