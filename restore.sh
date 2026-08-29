#!/usr/bin/env bash
# Install full Windows Modern, then graft plasma-plus customizations on top.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WM="$ROOT/windows-modern"
GRAFT="$ROOT/graft"
HOME_DIR="${HOME:?}"

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

echo "==> plasma-plus restore"
echo "    from: $ROOT"
echo "    to:   $HOME_DIR"

need rsync
need kwriteconfig6
[ -x "$WM/install.sh" ] || die "missing $WM/install.sh"
[ -d "$GRAFT" ] || die "missing $GRAFT"

if command -v pacman >/dev/null 2>&1; then
  pkgs=(kvantum kvantum-qt6)
  missing=()
  for p in "${pkgs[@]}"; do
    pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if ((${#missing[@]})); then
    echo "==> installing: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  fi
fi

echo "==> 1/3 Windows Modern (upstream + grafted theme/applets)"
"$WM/install.sh" all --dark

echo "==> 2/3 graft extras (taskbar override, KWin scripts, configs)"
mkdir -p "$HOME_DIR/.local" "$HOME_DIR/.config"
rsync -a "$GRAFT/local/" "$HOME_DIR/.local/"
rsync -a "$GRAFT/config/" "$HOME_DIR/.config/"

echo "==> rewriting __HOME__ → $HOME_DIR"
while IFS= read -r -d '' f; do
  grep -q "__HOME__" "$f" 2>/dev/null || continue
  sed -i "s|__HOME__|$HOME_DIR|g" "$f"
done < <(find "$HOME_DIR/.config" "$HOME_DIR/.local/share" "$HOME_DIR/.local/bin" \
         -type f \( -name '*.rc' -o -name '*.conf' -o -name '*.desktop' \
                    -o -name 'appletsrc' -o -name '*.service' -o -name 'override.conf' \) \
         -print0 2>/dev/null)

mkdir -p "$HOME_DIR/.config/systemd/user/plasma-plasmashell.service.d"
cat > "$HOME_DIR/.config/systemd/user/plasma-plasmashell.service.d/override.conf" <<EOF
[Service]
Environment=QT_PLUGIN_PATH=$HOME_DIR/.local/lib/qt6/plugins:/usr/lib/qt6/plugins
EOF
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now battery-tray-autohide.service 2>/dev/null || true

fc-cache -f "$HOME_DIR/.local/share/fonts/segoe-ui" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME_DIR/.local/share/icons/windows-modern" 2>/dev/null || true

if [[ "${REBUILD_ICONTASKS:-0}" == "1" ]]; then
  echo "==> rebuilding org.kde.plasma.icontasks"
  need cmake
  SRC="$WM/plasma/applets/org.kde.windowsmodern.icontasks"
  BUILD="$SRC/build-restore"
  rm -rf "$BUILD"
  cmake -S "$SRC" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$BUILD" -j"$(nproc)"
  mkdir -p "$HOME_DIR/.local/lib/qt6/plugins/plasma/applets"
  so="$(find "$BUILD" -name 'org.kde.plasma.icontasks.so' | head -1)"
  [[ -n "$so" ]] || die "build succeeded but .so not found"
  cp -a "$so" "$HOME_DIR/.local/lib/qt6/plugins/plasma/applets/"
fi

echo "==> 3/3 reload KWin + plasmashell"
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service 2>/dev/null || true

echo
echo "Done. Log out/in once if decorations or fonts look stale."
echo "Taskbar ABI mismatch: REBUILD_ICONTASKS=1 $0"
