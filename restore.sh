#!/usr/bin/env bash
# Restore this Windows Modern Plasma snapshot onto a stock KDE Plasma 6 machine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$ROOT/snapshot"
HOME_DIR="${HOME:?}"

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

echo "==> KDE Windows Modern snapshot restore"
echo "    from: $ROOT"
echo "    to:   $HOME_DIR"

need rsync
need kwriteconfig6
need qdbus6

# --- optional packages (Arch / CachyOS) ---
if command -v pacman >/dev/null 2>&1; then
  echo "==> Ensuring Kvantum + Qt6 plugin deps (pacman)"
  pkgs=(kvantum kvantum-qt6)
  missing=()
  for p in "${pkgs[@]}"; do
    pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if ((${#missing[@]})); then
    echo "    installing: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  fi
else
  echo "==> Tip: install Kvantum (kvantum / qt6-style-kvantum) for the window style"
fi

# --- copy files ---
echo "==> Installing theme assets + configs"
mkdir -p "$HOME_DIR/.local" "$HOME_DIR/.config"
rsync -a "$SNAP/local/" "$HOME_DIR/.local/"
rsync -a "$SNAP/config/" "$HOME_DIR/.config/"

# Expand __HOME__ placeholders
echo "==> Rewriting paths for $HOME_DIR"
while IFS= read -r -d '' f; do
  if grep -q "__HOME__" "$f" 2>/dev/null; then
    sed -i "s|__HOME__|$HOME_DIR|g" "$f"
  fi
done < <(find "$HOME_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc" \
              "$HOME_DIR/.config/plasmashellrc" \
              "$HOME_DIR/.local/share/plasma" \
              -type f \( -name "*.rc" -o -name "*.config" -o -name "appletsrc" -o -name "*.qml" -o -name "*.desktop" \) -print0 2>/dev/null
         find "$HOME_DIR/.config" -maxdepth 2 -type f -print0 2>/dev/null)

# systemd drop-in with real path (Environment= does not expand %h reliably everywhere)
mkdir -p "$HOME_DIR/.config/systemd/user/plasma-plasmashell.service.d"
cat > "$HOME_DIR/.config/systemd/user/plasma-plasmashell.service.d/override.conf" <<EOF
[Service]
Environment=QT_PLUGIN_PATH=$HOME_DIR/.local/lib/qt6/plugins:/usr/lib/qt6/plugins
EOF
systemctl --user daemon-reload 2>/dev/null || true

# --- apply look (belt + suspenders beyond copied configs) ---
echo "==> Applying look-and-feel settings"
kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.windowsmodern.dark
kwriteconfig6 --file kdeglobals --group General --key ColorScheme WindowsModernDark
kwriteconfig6 --file kdeglobals --group Icons --key Theme windows-modern
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kwriteconfig6 --file kdeglobals --group General --key font "Segoe UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key menuFont "Segoe UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key toolBarFont "Segoe UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Segoe UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

kwriteconfig6 --file plasmarc --group Theme --key name Windows-modern-dark
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Windows11Light

kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__windows-modern-dark-aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize None
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ML
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX

if [ -f "$HOME_DIR/.config/Kvantum/kvantum.kvconfig" ]; then
  kwriteconfig6 --file "$HOME_DIR/.config/Kvantum/kvantum.kvconfig" --group General --key theme Windows-modernDark
fi

# Refresh font + icon caches
fc-cache -f "$HOME_DIR/.local/share/fonts/segoe-ui" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME_DIR/.local/share/icons/windows-modern" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME_DIR/.local/share/icons/Win11" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME_DIR/.local/share/icons/hicolor" 2>/dev/null || true

# --- optional: rebuild Icon Tasks plugin from sources (preferred on mismatched Plasma) ---
if [[ "${REBUILD_ICONTASKS:-0}" == "1" ]]; then
  echo "==> Rebuilding org.kde.plasma.icontasks from sources/"
  need cmake
  need ninja || need make
  SRC="$ROOT/sources/org.kde.windowsmodern.icontasks"
  BUILD="$SRC/build-restore"
  rm -rf "$BUILD"
  cmake -S "$SRC" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$BUILD" -j"$(nproc)"
  mkdir -p "$HOME_DIR/.local/lib/qt6/plugins/plasma/applets"
  # find built .so
  so="$(find "$BUILD" -name 'org.kde.plasma.icontasks.so' | head -1)"
  [[ -n "$so" ]] || die "build succeeded but .so not found"
  cp -a "$so" "$HOME_DIR/.local/lib/qt6/plugins/plasma/applets/"
fi

echo "==> Reloading KWin + plasmashell"
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service 2>/dev/null || true

echo
echo "Done. Log out/in once if decorations or fonts look stale."
echo "If taskbar icons look wrong (Plasma ABI mismatch), rerun:"
echo "  REBUILD_ICONTASKS=1 $0"
echo
echo "Snapshot notes: BorderSize=None (invisible resize grips), audio badges off,"
echo "custom Start menu + Icon Tasks plugin under ~/.local."
