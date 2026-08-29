# plasma-plus

Versioned **Windows Modern** Plasma 6 desktop plus every local graft (taskbar, Start, calendar, KWin scripts, configs).

Formerly `kde-windows-modern-snapshot`. Lives on the external SSD:

`/run/media/lofcz/ssd_external/GitHub/plasma-plus`

Upstream base: [Jeysef/KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern). This repo is that tree with our live files copied on top, plus extras that are not in upstream.

## Layout

```
windows-modern/     full theme (upstream + grafted applets/themes/icons)
graft/              extras: icontasks override, KWin scripts, configs, fonts, Fluent bits
scripts/refresh-from-live.sh
restore.sh
```

`windows-modern/` is installable with the upstream installer. `graft/` is rsynced onto `$HOME` after that.

## Restore (new machine)

```bash
git clone git@github.com:lofcz/plasma-plus.git
cd plasma-plus
./restore.sh
```

That runs `windows-modern/install.sh all --dark`, then applies `graft/`.

Rebuild the taskbar plugin on a different Plasma/Qt ABI:

```bash
REBUILD_ICONTASKS=1 ./restore.sh
```

## Refresh from this machine

```bash
./scripts/refresh-from-live.sh
```

## Grafts (not in stock Windows Modern)

- Patched Icon Tasks (`org.kde.plasma.icontasks` QML + `.so`) — thumbnails, drag-reorder, raise-all
- KWin `raise-app-windows` and `flameshot-cover-panel`
- Instant logout (no 30s timer)
- Win11 calendar / Start hover / shapecorners 8px
- KWin rules: flameshot chrome-free, Chromium focus
- Dolphin Win11-slim menus, Open with Cursor
- Battery tray autohide
- Live look: **FluentDark** + **Fluent-round** Kvantum on Windows Modern Plasma theme
- Segoe UI, panel layout, `QT_PLUGIN_PATH` drop-in

## Privacy

Private by default. Configs use `__HOME__` instead of a raw home path.
