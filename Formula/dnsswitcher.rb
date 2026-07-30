cask "dnsswitcher" do
  version "1.3.3"
  sha256 "e9187c28941a30ba552b5f1db33d9a27736e66f82ecfd9bdd7fca51b9528b7cd"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
