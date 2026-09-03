#!/usr/bin/env bash
# Graft live customizations into the windows-modern submodule and graft/.
#
# windows-modern/ is a git submodule (github.com/lofcz/KDE-Windows-Modern).
# Installed copies under ~/.local/share are rsynced onto the matching
# source paths; review and commit inside windows-modern/ afterwards.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WM="$ROOT/windows-modern"
GRAFT="$ROOT/graft"

die() { echo "error: $*" >&2; exit 1; }
[ -f "$WM/install.sh" ] || die "submodule not initialised: git submodule update --init"

EXCLUDES=(--exclude 'icon-theme.cache' --exclude '*.qmlc' --exclude '*.bak*'
          --exclude 'build/' --exclude 'build-restore/')

copy() {
  local src="$1" dest="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    rsync -a --delete "${EXCLUDES[@]}" "$src" "$dest"
    echo "  OK  ${dest#"$ROOT"/}"
  else
    echo "  MISS $src"
  fi
}

echo "==> graft live Windows Modern installs onto windows-modern/ (submodule)"
copy "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.startmenu/" \
     "$WM/plasma/applets/org.kde.windowsmodern.startmenu/"
copy "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.digitalclock/" \
     "$WM/plasma/applets/org.kde.windowsmodern.digitalclock/"
copy "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.showdesktop/" \
     "$WM/plasma/applets/org.kde.windowsmodern.showdesktop/"
copy "$HOME/.local/share/plasma/desktoptheme/Windows-modern-dark/" \
     "$WM/plasma/desktoptheme/Windows-modern-dark/"
copy "$HOME/.local/share/plasma/desktoptheme/Windows-modern-light/" \
     "$WM/plasma/desktoptheme/Windows-modern-light/"
copy "$HOME/.local/share/plasma/look-and-feel/org.kde.windowsmodern.dark/" \
     "$WM/plasma/look-and-feel/org.kde.windowsmodern.dark/"
copy "$HOME/.local/share/plasma/look-and-feel/org.kde.windowsmodern.light/" \
     "$WM/plasma/look-and-feel/org.kde.windowsmodern.light/"
copy "$HOME/.local/share/plasma/layout-templates/org.kde.windowsmodern.panel/" \
     "$WM/plasma/layout-templates/org.kde.windowsmodern.panel/"
# Upstream layout is aurorae/<theme>, installed as ~/.local/share/aurorae/themes/<theme>.
copy "$HOME/.local/share/aurorae/themes/windows-modern-dark-aurorae/" \
     "$WM/aurorae/windows-modern-dark-aurorae/"
copy "$HOME/.local/share/aurorae/themes/windows-modern-light-aurorae/" \
     "$WM/aurorae/windows-modern-light-aurorae/"
copy "$HOME/.local/share/icons/windows-modern/" \
     "$WM/icons/windows-modern/"
copy "$HOME/.local/share/color-schemes/WindowsModernDark.colors" \
     "$WM/color-schemes/WindowsModernDark.colors"
copy "$HOME/.local/share/color-schemes/WindowsModernLight.colors" \
     "$WM/color-schemes/WindowsModernLight.colors"
copy "$HOME/.config/Kvantum/Windows-modern/" \
     "$WM/Kvantum/Windows-modern/"
copy "$HOME/.local/share/wallpapers/Windows-modern/" \
     "$WM/wallpaper/Windows-modern/"
# Icon Tasks (org.kde.plasma.icontasks) is edited directly in the submodule
# source tree and compiled into the .so; nothing to graft for it here.

echo "==> extras that are not part of upstream (graft/)"
rm -rf "$GRAFT"
mkdir -p "$GRAFT"

# QML mirror of the applet source (plasmashell loads the compiled .so; the
# on-disk plasmoid is kept for tooling/inspection).
copy "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.icontasks/" \
     "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/"
if [ -d "$WM/plasma/applets/org.kde.windowsmodern.icontasks/contents" ]; then
  mkdir -p "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/contents"
  rsync -a "$WM/plasma/applets/org.kde.windowsmodern.icontasks/contents/" \
           "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/contents/"
  cp -a "$WM/plasma/applets/org.kde.windowsmodern.icontasks/metadata.json" \
        "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/metadata.json"
  echo "  OK  icontasks graft QML from applet source"
fi
copy "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so" \
     "$GRAFT/local/lib/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so"
copy "$HOME/.local/share/kwin/scripts/raise-app-windows/" \
     "$GRAFT/local/share/kwin/scripts/raise-app-windows/"
copy "$HOME/.local/share/kwin/scripts/flameshot-cover-panel/" \
     "$GRAFT/local/share/kwin/scripts/flameshot-cover-panel/"
copy "$HOME/.local/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/" \
     "$GRAFT/local/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/"
copy "$HOME/.local/share/fonts/segoe-ui/" \
     "$GRAFT/local/share/fonts/segoe-ui/"
copy "$HOME/.local/share/color-schemes/FluentDark.colors" \
     "$GRAFT/local/share/color-schemes/FluentDark.colors"
copy "$HOME/.config/Kvantum/Fluent-round/" \
     "$GRAFT/config/Kvantum/Fluent-round/"
copy "$HOME/.config/Kvantum/kvantum.kvconfig" \
     "$GRAFT/config/Kvantum/kvantum.kvconfig"
copy "$HOME/.local/share/kio/servicemenus/open-with-cursor.desktop" \
     "$GRAFT/local/share/kio/servicemenus/open-with-cursor.desktop"
copy "$HOME/.local/share/dolphin/view_properties/global/.directory" \
     "$GRAFT/local/share/dolphin/view_properties/global/.directory"
copy "$HOME/.local/bin/battery-tray-autohide.py" \
     "$GRAFT/local/bin/battery-tray-autohide.py"
copy "$HOME/.config/systemd/user/battery-tray-autohide.service" \
     "$GRAFT/config/systemd/user/battery-tray-autohide.service"
copy "$HOME/.config/environment.d/98-plasma-plugins.conf" \
     "$GRAFT/config/environment.d/98-plasma-plugins.conf"

for f in kwinrc kwinrulesrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc \
         kdeglobals plasmarc klaunchrc kservicemenurc dolphinrc ksplashrc \
         kscreenlockerrc kcminputrc kactivitymanagerd-statsrc; do
  copy "$HOME/.config/$f" "$GRAFT/config/$f"
done
copy "$HOME/.config/kdedefaults/" "$GRAFT/config/kdedefaults/"
copy "$HOME/.config/systemd/user/plasma-plasmashell.service.d/override.conf" \
     "$GRAFT/config/systemd/user/plasma-plasmashell.service.d/override.conf"

echo "==> sanitize $HOME → __HOME__ in text configs"
GRAFT_DIR="$GRAFT" HOME_DIR="$HOME" python3 - <<'PY'
import os
from pathlib import Path
root = Path(os.environ["GRAFT_DIR"])
home = os.environ["HOME_DIR"]
skip = {".png", ".jpg", ".jpeg", ".svg", ".so", ".ttf", ".otf", ".ico", ".cache"}
for p in root.rglob("*"):
    if not p.is_file() or p.suffix.lower() in skip:
        continue
    try:
        data = p.read_bytes()
    except OSError:
        continue
    if home.encode() not in data:
        continue
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        continue
    p.write_text(text.replace(home, "__HOME__"), encoding="utf-8")
    print(f"  sanitized {p.relative_to(root)}")
PY

echo
echo "==> windows-modern/ (submodule) changes to review and commit:"
git -C "$WM" status --short || true
echo
echo "done. Commit inside windows-modern/ and push, then commit the submodule"
echo "pointer + graft/ here:  git add windows-modern graft && git commit"
