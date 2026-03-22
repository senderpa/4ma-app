# ── 4MA Desktop Installer for Windows ──
# Usage: irm https://raw.githubusercontent.com/senderpa/4ma-app/main/install-windows.ps1 | iex

Write-Host ""
Write-Host "  ┌─────────────────────┐" -ForegroundColor Cyan
Write-Host "  │   4MA Desktop App   │" -ForegroundColor Cyan
Write-Host "  │   Installing...     │" -ForegroundColor Cyan
Write-Host "  └─────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# Check Rust
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rust..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri https://win.rustup.rs/x86_64 -OutFile rustup-init.exe
    Start-Process -Wait -FilePath .\rustup-init.exe -ArgumentList '-y'
    Remove-Item rustup-init.exe
    $env:PATH += ";$env:USERPROFILE\.cargo\bin"
}

# Check Node
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..." -ForegroundColor Cyan
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
}

# Clone & build
$installDir = "$env:LOCALAPPDATA\4MA"
Write-Host "Downloading 4MA..." -ForegroundColor Cyan
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
git clone --depth 1 https://github.com/senderpa/4ma-app.git $installDir
Set-Location $installDir

Write-Host "Installing dependencies..." -ForegroundColor Cyan
npm install --silent 2>$null

Write-Host "Building native app (this takes 3-5 minutes)..." -ForegroundColor Cyan
npx tauri build 2>&1 | Select-Object -Last 5

# Find installer
$msi = Get-ChildItem -Recurse -Filter "*.msi" -Path "src-tauri\target\release\bundle" -ErrorAction SilentlyContinue | Select-Object -First 1
$exe = Get-ChildItem -Recurse -Filter "*.exe" -Path "src-tauri\target\release\bundle" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($msi) {
    Write-Host "Running installer..." -ForegroundColor Cyan
    Start-Process -FilePath $msi.FullName
} elseif ($exe) {
    Write-Host "Running installer..." -ForegroundColor Cyan
    Start-Process -FilePath $exe.FullName
}

Write-Host ""
Write-Host "4MA installed successfully!" -ForegroundColor Green
Write-Host "Find it in your Start Menu." -ForegroundColor Gray
Write-Host ""
