#!/usr/bin/env bash
# Rebuild windows-modern/ from upstream + graft live customizations on top.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="${KDE_WINDOWS_MODERN_SRC:-$HOME/.local/src/KDE-Windows-Modern}"
WM="$ROOT/windows-modern"
GRAFT="$ROOT/graft"

die() { echo "error: $*" >&2; exit 1; }
[ -d "$UPSTREAM" ] || die "missing upstream at $UPSTREAM"

copy() {
  local src="$1" dest="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    rsync -a --delete --exclude 'icon-theme.cache' --exclude '*.qmlc' --exclude 'build/' --exclude 'build-restore/' "$src" "$dest"
    echo "  OK  $2"
  else
    echo "  MISS $src"
  fi
}

echo "==> windows-modern from $UPSTREAM"
rm -rf "$WM"
mkdir -p "$WM"
rsync -a \
  --exclude '.git/' \
  --exclude 'build/' \
  --exclude 'build-restore/' \
  --exclude '**/*.qmlc' \
  --exclude '**/icon-theme.cache' \
  "$UPSTREAM/" "$WM/"
# Drop nested git leftovers
rm -rf "$WM/.git" "$WM/.gitmodules"
echo "  OK  windows-modern/ ($(du -sh "$WM" | cut -f1))"

echo "==> graft live Windows Modern installs onto source tree"
# Installed (edited) files overwrite the matching upstream paths.
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
copy "$HOME/.local/share/aurorae/themes/windows-modern-dark-aurorae/" \
     "$WM/aurorae/themes/windows-modern-dark-aurorae/"
copy "$HOME/.local/share/aurorae/themes/windows-modern-light-aurorae/" \
     "$WM/aurorae/themes/windows-modern-light-aurorae/"
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

# Patched Icon Tasks QML lives as a plasmashell override (org.kde.plasma.icontasks).
# Also keep the C++ applet source in sync (skip build trees).
if [ -d "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks" ]; then
  copy "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks/" \
       "$WM/plasma/applets/org.kde.windowsmodern.icontasks/"
fi
# Disk plasmoid QML is often stale: plasmashell loads the compiled .so.
# Re-apply applet source last so StreamBroker / tooltip fixes win.
if [ -d "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks" ]; then
  copy "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks/" \
       "$WM/plasma/applets/org.kde.windowsmodern.icontasks/"
fi

echo "==> extras that are not part of upstream (graft/)"
rm -rf "$GRAFT"
mkdir -p "$GRAFT"

copy "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.icontasks/" \
     "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/"
if [ -d "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks/contents" ]; then
  rsync -a "$HOME/.local/src/KDE-Windows-Modern/plasma/applets/org.kde.windowsmodern.icontasks/contents/" \
           "$GRAFT/local/share/plasma/plasmoids/org.kde.plasma.icontasks/contents/"
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

echo "==> sanitize /home/lofcz → __HOME__ in text configs"
python3 - <<'PY'
from pathlib import Path
root = Path("/run/media/lofcz/ssd_external/GitHub/plasma-plus/graft")
home = "/home/lofcz"
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

echo "==> drop old snapshot/ (replaced by windows-modern + graft)"
rm -rf "$ROOT/snapshot" "$ROOT/sources"

echo "done"
du -sh "$WM" "$GRAFT" "$ROOT"
