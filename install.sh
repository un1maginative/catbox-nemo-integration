#!/usr/bin/env bash
# Installer for catbox-nemo-integration.
# Usage: ./install.sh [-y] [--no-deps] [--bin-dir DIR] [--uninstall]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ACTION_DIR="$HOME/.local/share/nemo/actions"
ASSUME_YES=0
INSTALL_DEPS=1
UNINSTALL=0

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes) ASSUME_YES=1 ;;
        --no-deps) INSTALL_DEPS=0 ;;
        --bin-dir) BIN_DIR="$2"; shift ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

restart_nemo() {
    if pgrep -x nemo >/dev/null; then
        say "Restarting Nemo"
        nemo -q >/dev/null 2>&1 || true
    fi
}

if [ "$UNINSTALL" -eq 1 ]; then
    rm -fv "$BIN_DIR/catbox-upload" "$ACTION_DIR/catbox-upload.nemo_action"
    restart_nemo
    say "Uninstalled. (Config in ~/.config/catbox left untouched.)"
    exit 0
fi

if ! command -v nemo >/dev/null; then
    warn "Nemo not found in PATH. Installing anyway."
fi

# --- dependencies ---------------------------------------------------------
missing=()
command -v curl >/dev/null || missing+=(curl)
command -v notify-send >/dev/null || missing+=(libnotify)
if ! command -v xclip >/dev/null && ! command -v wl-copy >/dev/null && ! command -v xsel >/dev/null; then
    missing+=(clipboard)
fi

if [ ${#missing[@]} -gt 0 ] && [ "$INSTALL_DEPS" -eq 1 ]; then
    if command -v pacman >/dev/null; then
        mgr="sudo pacman -S --needed"; map=([curl]=curl [libnotify]=libnotify [clipboard]=xclip)
    elif command -v apt-get >/dev/null; then
        mgr="sudo apt-get install -y"; map=([curl]=curl [libnotify]=libnotify-bin [clipboard]=xclip)
    elif command -v dnf >/dev/null; then
        mgr="sudo dnf install -y"; map=([curl]=curl [libnotify]=libnotify [clipboard]=xclip)
    else
        mgr=""
    fi
    if [ -n "$mgr" ]; then
        pkgs=()
        for m in "${missing[@]}"; do pkgs+=("${map[$m]}"); done
        say "Missing dependencies: ${pkgs[*]}"
        reply=y
        [ "$ASSUME_YES" -eq 1 ] || read -rp "Install with '$mgr'? [Y/n] " reply
        if [[ "${reply:-y}" =~ ^[Yy]$ ]]; then
            $mgr "${pkgs[@]}"
        else
            warn "Skipping dependency install."
        fi
    else
        warn "Unknown package manager; install manually: ${missing[*]}"
    fi
fi

# --- install files --------------------------------------------------------
say "Installing script to $BIN_DIR"
mkdir -p "$BIN_DIR" "$ACTION_DIR"
install -m 755 "$HERE/src/catbox-upload" "$BIN_DIR/catbox-upload"

say "Installing Nemo action to $ACTION_DIR"
sed "s|@BIN@|$BIN_DIR/catbox-upload|g" "$HERE/src/catbox-upload.nemo_action.in" \
    > "$ACTION_DIR/catbox-upload.nemo_action"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not in your PATH (the Nemo action uses the full path, so it still works)." ;;
esac

restart_nemo
say "Done. Right-click a file in Nemo -> 'Upload to Catbox'."
say "Optional: save your catbox userhash to ~/.config/catbox/userhash to tie uploads to your account."
