<p align="center">
  <img src="logo.svg" alt="Logo" width="200">
</p>

<h1 align="center">DNSSwitcher</h1>

<p align="center">
   <strong>A lightweight macOS menu bar app for instant DNS profile switching</strong><br>
   <em>No Dock icon — lives entirely in your menu bar.</em>
</p>

## Features

- Switch DNS profiles with two clicks from the menu bar
- Ships with Cloudflare, Quad9, and AdGuard profiles
- Create custom profiles with any DNS servers
- "Off (DHCP)" resets to automatic DNS
- Apply to all network interfaces or just the primary one
- Launch at login support
- IPv4 and IPv6 server validation

## Installation

### Homebrew (coming soon)

```bash
brew install --cask dnsswitcher
```

### Manual

1. Download the latest DMG from [Releases](https://github.com/gayakaci/dns-switcher/releases)
2. Drag **DNS Switcher** to Applications
3. Launch the app — a network icon appears in the menu bar

### Build from source

```bash
git clone https://github.com/kacigaya/dns-switcher.git
cd dns-switcher
make app
open ".build/release/DNSSwitcher.app"
```

## Usage

Click the network icon in the menu bar to see your DNS profiles. Select one to apply it. Choose **Off (DHCP)** to reset to automatic DNS. Open **Preferences** to manage profiles and settings.

## Why does it ask for my admin password?

macOS requires administrator privileges to change DNS settings via `networksetup`. The app uses AppleScript's `with administrator privileges` to prompt for your password when needed. No credentials are stored.

## Requirements

- macOS 13.0 (Ventura) or later
