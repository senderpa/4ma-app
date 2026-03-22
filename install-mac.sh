#!/usr/bin/env bash
# ── 4MA Desktop Installer for Mac ──
# Usage: curl -fsSL https://raw.githubusercontent.com/senderpa/4ma-app/main/install-mac.sh | bash
set -euo pipefail

G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
echo -e "${C}${B}"
echo "  ┌─────────────────────┐"
echo "  │   4MA Desktop App   │"
echo "  │   Installing...     │"
echo "  └─────────────────────┘"
echo -e "${N}"

# Homebrew
if ! command -v brew &>/dev/null; then
  echo -e "${C}Installing Homebrew...${N}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Rust
if ! command -v cargo &>/dev/null; then
  echo -e "${C}Installing Rust...${N}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# Node
if ! command -v node &>/dev/null; then
  echo -e "${C}Installing Node.js...${N}"
  brew install node
fi

# Clone & build
INSTALL_DIR="$HOME/Applications/4MA"
echo -e "${C}Downloading 4MA...${N}"
rm -rf "$INSTALL_DIR"
git clone --depth 1 https://github.com/senderpa/4ma-app.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${C}Installing dependencies...${N}"
npm install --silent 2>/dev/null

echo -e "${C}Building native app (this takes 2-3 minutes)...${N}"
npx tauri build 2>&1 | tail -5

# Find and install the .dmg or .app
DMG=$(find src-tauri/target/release/bundle -name "*.dmg" 2>/dev/null | head -1)
APP=$(find src-tauri/target/release/bundle -name "*.app" -type d 2>/dev/null | head -1)

if [ -n "$DMG" ]; then
  echo -e "${C}Opening installer...${N}"
  open "$DMG"
elif [ -n "$APP" ]; then
  echo -e "${C}Installing to /Applications...${N}"
  cp -R "$APP" /Applications/
  echo -e "${G}${B}Installed! Open '4MA' from Applications.${N}"
  open /Applications/4MA.app 2>/dev/null || true
else
  echo -e "${G}${B}Built! Run with: cd $INSTALL_DIR && npm run tauri dev${N}"
fi

echo ""
echo -e "${G}${B}✓ 4MA installed successfully${N}"
echo -e "  Open it from your Applications folder."
echo ""
