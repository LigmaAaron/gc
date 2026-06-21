#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
CHECK="${GREEN}✔${NC}"; CROSS="${RED}✖${NC}"
INFO="${CYAN}➜${NC}"; WARN="${YELLOW}⚠${NC}"

DYLIB_URL="https://github.com/LigmaAaron/glacier-releases/releases/download/v20260621024229/libGlacierDylib.dylib"
UI_URL="https://github.com/LigmaAaron/glacier-releases/releases/download/v20260621024229/Glacier.app.zip"
ROBLOX_VERSION="version-5e5ddbfddbdf4c6c"

section() { echo; echo -e "${BOLD}${CYAN}==> $1${NC}"; }
run_step() {
    local msg="$1"; shift
    echo -ne "${CYAN}[...]${NC} $msg\r"
    if "$@"; then printf "\r\033[K${GREEN}${CHECK} %s${NC}\n" "$msg"
    else        printf "\r\033[K${RED}${CROSS} %s${NC}\n" "$msg"; exit 1; fi
}

clear
echo -e "${BOLD}"
cat <<'EOF'
   _____ _            _
  / ____| |          (_)
 | |  __| | __ _  ___ _  ___ _ __
 | | |_ | |/ _` |/ __| |/ _ \ '__|
 | |__| | | (_| | (__| |  __/ |
  \_____|_|\__,_|\___|_|\___|_|
EOF
echo -e "${NC}"
echo -e "${BLUE}=[ Glacier Installer ]=${NC}"
echo

if [ -w "/Applications" ]; then APP_DIR="/Applications"
else APP_DIR="$HOME/Applications"; mkdir -p "$APP_DIR"
     echo -e "${WARN} No root — installing to $APP_DIR"; fi

TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

run_step "Killing Roblox" bash -c "killall -9 RobloxPlayer Glacier 2>/dev/null || true"

section "Removing old installs"
for target in "$APP_DIR/Roblox.app" "$APP_DIR/Glacier.app"; do
    [ -e "$target" ] || continue
    name="$(basename "$target")"
    rm -rf "$target" 2>/dev/null || sudo rm -rf "$target" 2>/dev/null || true
    if [ -e "$target" ]; then
        echo -e "${RED}${CROSS} Could not remove $name — delete it manually and re-run.${NC}"; exit 1; fi
    echo -e "${GREEN}${CHECK} Removed $name${NC}"
done

section "Downloading Roblox ($ROBLOX_VERSION)"
run_step "Downloading Roblox" bash -c "
    curl -# -L 'https://setup.rbxcdn.com/mac/$ROBLOX_VERSION-RobloxPlayer.zip' -o '$TEMP/RobloxPlayer.zip' &&
    unzip -oq '$TEMP/RobloxPlayer.zip' -d '$TEMP' &&
    mv '$TEMP/RobloxPlayer.app' '$APP_DIR/Roblox.app' &&
    xattr -cr '$APP_DIR/Roblox.app' &&
    codesign --remove-signature '$APP_DIR/Roblox.app/Contents/MacOS/RobloxPlayer'
"

section "Installing Glacier"
run_step "Injecting libGlacierDylib.dylib" bash -c "
    curl -# -L '$DYLIB_URL' -o '$TEMP/libGlacierDylib.dylib' &&
    mv '$TEMP/libGlacierDylib.dylib' '$APP_DIR/Roblox.app/Contents/MacOS/libGlacierDylib.dylib' &&
    codesign --force --deep --sign - '$APP_DIR/Roblox.app'
"
run_step "Installing Glacier UI" bash -c "
    curl -# -L '$UI_URL' -o '$TEMP/Glacier.app.zip' &&
    unzip -oq '$TEMP/Glacier.app.zip' -d '$TEMP' &&
    mv '$TEMP/Glacier.app' '$APP_DIR/Glacier.app' &&
    codesign --force --deep --sign - '$APP_DIR/Glacier.app'
"
run_step "Creating workspace" bash -c "mkdir -p ~/Glacier/{workspace,autoexec,scripts}"

echo
echo -e "${GREEN}${BOLD}Installation complete.${NC}"
open "$APP_DIR/Glacier.app"
open "$APP_DIR/Roblox.app"
