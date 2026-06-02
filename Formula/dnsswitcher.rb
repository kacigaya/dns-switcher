cask "dnsswitcher" do
  version "1.3.0"
  sha256 "1e2c0e4e63578f692dfcb15aeb35b243c91c101f732ec8ae36bd61802c2c986e"

  url "https://github.com/kacigaya/dns-switcher/releases/download/v#{version}/DNSSwitcher.dmg"
  name "DNS Switcher"
  desc "macOS menu bar app for instant DNS profile switching"
  homepage "https://github.com/kacigaya/dns-switcher"

  app "DNSSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gayakaci.dns-switcher.plist",
  ]
end
