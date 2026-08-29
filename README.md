# plasma-plus

Plasma 6 based desktop.

<img width="3070" height="1918" alt="image" src="https://github.com/user-attachments/assets/271bdb58-7431-4141-9110-f579bf3e98e1" />

## Layout

```
windows-modern/     full theme (upstream + grafted applets/themes/icons)
graft/              extras: icontasks override, KWin scripts, configs, fonts, Fluent bits
scripts/refresh-from-live.sh
restore.sh
```

`windows-modern/` is installable with the upstream installer. `graft/` is rsynced onto `$HOME` after that.

## Restore

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

## Refresh

```bash
./scripts/refresh-from-live.sh
```

## Grafts

- Patched Icon Tasks (`org.kde.plasma.icontasks` QML + `.so`) — thumbnails, drag-reorder, raise-all
- KWin `raise-app-windows` and `flameshot-cover-panel`
- Instant logout (no 30s timer)
- Win11 calendar / Start hover / shapecorners 8px
- KWin rules: flameshot chrome-free, Chromium focus
- Dolphin Win11-slim menus, Open with Cursor
- Battery tray autohide
- Live look: **FluentDark** + **Fluent-round** Kvantum on Windows Modern Plasma theme
- Segoe UI, panel layout, `QT_PLUGIN_PATH` drop-in
