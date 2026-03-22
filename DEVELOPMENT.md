# 4MA Desktop — Development Guide

Build and run 4MA Desktop from source on macOS, Windows, or Linux.

---

## Prerequisites

### macOS

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Rust**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source "$HOME/.cargo/env"
   ```

3. **Node.js 18+**
   ```bash
   # via Homebrew
   brew install node

   # or via nvm
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   nvm install 20
   ```

That's it. macOS ships with WebKit (used by Tauri), so no extra system libraries are needed.

### Windows

1. **Visual Studio Build Tools**

   Download and install [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/).
   During installation, select the **"Desktop development with C++"** workload.
   This provides the MSVC compiler and Windows SDK that Tauri needs.

2. **WebView2**

   Windows 10 (1803+) and Windows 11 ship with WebView2 pre-installed.
   If you're on an older build, install [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section).

3. **Rust**
   ```powershell
   # Download and run rustup-init from https://rustup.rs
   winget install Rustlang.Rustup
   ```

4. **Node.js 18+**
   ```powershell
   winget install OpenJS.NodeJS.LTS
   ```

### Linux (Debian/Ubuntu)

1. **System libraries**
   ```bash
   sudo apt update
   sudo apt install -y \
     build-essential \
     curl \
     wget \
     file \
     libgtk-3-dev \
     libwebkit2gtk-4.1-dev \
     libayatana-appindicator3-dev \
     librsvg2-dev \
     libssl-dev \
     libjavascriptcoregtk-4.1-dev \
     libsoup-3.0-dev
   ```

2. **Rust**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source "$HOME/.cargo/env"
   ```

3. **Node.js 18+**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

### Linux (Fedora)

```bash
sudo dnf install -y \
  webkit2gtk4.1-devel \
  gtk3-devel \
  libappindicator-gtk3-devel \
  librsvg2-devel \
  openssl-devel \
  javascriptcoregtk4.1-devel \
  libsoup3-devel
```

### Linux (Arch)

```bash
sudo pacman -S --needed \
  webkit2gtk-4.1 \
  gtk3 \
  libappindicator-gtk3 \
  librsvg \
  openssl
```

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/senderpa/4ma-app.git
cd 4ma-app

# 2. Install JS dependencies
npm install

# 3. Run in development mode (hot-reload frontend + native shell)
npm run tauri:dev

# 4. Build a production installer
npm run tauri:build
```

### Available npm scripts

| Script | What it does |
|--------|-------------|
| `npm run dev` | Start the Vite dev server only (no Tauri shell) |
| `npm run build` | Build the frontend to `dist/` |
| `npm run tauri:dev` | Full dev mode: Vite + Tauri native window |
| `npm run tauri:build` | Production build: compiles Rust + bundles installer |
| `npm run tauri:icon` | Regenerate app icons from `src-tauri/icons/icon.png` |

---

## Building Installers

After running `npm run tauri:build`, the output is in `src-tauri/target/release/bundle/`:

### macOS — DMG

```
src-tauri/target/release/bundle/dmg/4MA_1.0.0_aarch64.dmg   (Apple Silicon)
src-tauri/target/release/bundle/dmg/4MA_1.0.0_x64.dmg        (Intel)
```

To build for a specific architecture:

```bash
# Apple Silicon (default on M1-M4)
npm run tauri:build -- --target aarch64-apple-darwin

# Intel Mac
rustup target add x86_64-apple-darwin
npm run tauri:build -- --target x86_64-apple-darwin

# Universal binary (both architectures)
rustup target add x86_64-apple-darwin
npm run tauri:build -- --target universal-apple-darwin
```

### Windows — MSI / NSIS

```
src-tauri/target/release/bundle/msi/4MA_1.0.0_x64_en-US.msi
src-tauri/target/release/bundle/nsis/4MA_1.0.0_x64-setup.exe
```

### Linux — AppImage / DEB / RPM

```
src-tauri/target/release/bundle/appimage/4ma_1.0.0_amd64.AppImage
src-tauri/target/release/bundle/deb/4ma_1.0.0_amd64.deb
```

---

## How the Trial System Works

4MA ships with a **14-day free trial**. No account or credit card needed.

### Lifecycle

1. **First launch**: the app writes the current Unix timestamp to a platform-specific data directory:
   - macOS: `~/Library/Application Support/4MA/trial.json`
   - Windows: `%APPDATA%/4MA/trial.json`
   - Linux: `~/.local/share/4MA/trial.json`

2. **Each launch**: the Rust backend (`src-tauri/src/trial.rs`) reads the start timestamp, calculates days elapsed, and returns a `TrialStatus` to the frontend via the Tauri `check_trial` command.

3. **Trial active (days 1-14)**: a subtle bar at the top shows remaining days. It turns orange when 3 or fewer days remain.

4. **Trial expired (day 15+)**: the app shows a full-screen purchase/activation overlay. The iframe is hidden.

5. **Licensed**: if a valid license key file exists at `<data_dir>/4MA/license.key`, the trial is bypassed entirely.

### Data stored

| File | Contents |
|------|----------|
| `trial.json` | Unix timestamp (seconds) of first launch |
| `license.key` | The raw license key string |

### Resetting the trial (development only)

Delete the data directory:

```bash
# macOS
rm -rf ~/Library/Application\ Support/4MA/

# Linux
rm -rf ~/.local/share/4MA/

# Windows (PowerShell)
Remove-Item -Recurse -Force "$env:APPDATA\4MA"
```

---

## How to Generate License Keys

License keys follow the format `4MA-XXXX-XXXX-XXXX` where each `X` is an alphanumeric character (a-z, A-Z, 0-9). The key must be exactly 19 characters long.

### Quick generator (bash)

```bash
generate_key() {
  local seg1=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)
  local seg2=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)
  local seg3=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)
  echo "4MA-${seg1}-${seg2}-${seg3}"
}

# Generate a single key
generate_key

# Generate 10 keys
for i in $(seq 1 10); do generate_key; done
```

### Quick generator (Python)

```python
import random, string

def generate_key():
    chars = string.ascii_letters + string.digits
    segments = [''.join(random.choices(chars, k=4)) for _ in range(3)]
    return f"4MA-{'-'.join(segments)}"

# Generate 10 keys
for _ in range(10):
    print(generate_key())
```

### Quick generator (PowerShell)

```powershell
function Generate-4MAKey {
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $seg = { -join (1..4 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] }) }
    "4MA-$(& $seg)-$(& $seg)-$(& $seg)"
}

# Generate 10 keys
1..10 | ForEach-Object { Generate-4MAKey }
```

### Production notes

The current validation (`trial.rs` > `validate_key`) is a simple format check. For a real product, consider:

- **HMAC-signed keys**: include a checksum segment so keys can be validated offline without being trivially guessable.
- **Server validation**: POST the key to an API on activation, checking it against a database of purchased keys and marking it as redeemed.
- **Hardware binding**: hash the machine ID into the key to prevent sharing.

---

## Project Structure

```
4ma-app/
  index.html            — Frontend: loads 4MA backend in an iframe
  vite.config.js        — Vite config (dev server, build targets)
  package.json          — JS dependencies and scripts
  .env.example          — Example environment variables
  src-tauri/
    tauri.conf.json     — Tauri app config (window, bundle, CSP)
    Cargo.toml          — Rust dependencies
    build.rs            — Tauri build hook
    capabilities/
      default.json      — Permission declarations (shell, process)
    icons/              — App icons (png, ico, icns)
    src/
      main.rs           — Rust entry point (calls lib::run)
      lib.rs            — Tauri builder setup, commands
      trial.rs          — Trial/license logic
```

---

## Architecture

4MA Desktop is a thin native wrapper. It does two things:

1. Opens a native window with an embedded WebView.
2. Loads the **4MA backend** (a separate FastAPI server at `localhost:5090`) inside an iframe.

The Tauri shell provides:
- Native window chrome (title bar, minimize, maximize, close)
- Trial enforcement (the iframe is blocked after trial expiry)
- License key activation
- System tray (planned)
- Auto-updates (planned)

The actual AI logic, face rendering, voice, and agent orchestration all live in the 4MA backend — this app is purely the delivery vehicle.

---

## Troubleshooting

### `npm run tauri:dev` fails with "port 5173 already in use"

Kill the process using port 5173, or change the port in both `vite.config.js` and `src-tauri/tauri.conf.json`.

### Rust compilation errors on first build

The first build downloads and compiles all Rust crates. This is normal and takes 3-5 minutes. If it fails:

```bash
# Update Rust
rustup update

# Clean and rebuild
cd src-tauri && cargo clean && cd ..
npm run tauri:build
```

### macOS: "4MA.app is damaged and can't be opened"

This happens with unsigned builds. Fix it:

```bash
xattr -cr /Applications/4MA.app
```

Or in System Preferences > Privacy & Security, click "Open Anyway".

### Linux: missing `libwebkit2gtk-4.1`

Tauri 2 requires WebKit2GTK **4.1** (not 4.0). Make sure you install `libwebkit2gtk-4.1-dev`, not the older `libwebkit2gtk-4.0-dev`.

### Windows: "MSVC not found"

Install the Visual Studio Build Tools with the "Desktop development with C++" workload. A full Visual Studio installation works too.
