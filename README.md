# plasma-plus

Plasma 6 based desktop.

<img width="3070" height="1918" alt="image" src="https://github.com/user-attachments/assets/271bdb58-7431-4141-9110-f579bf3e98e1" />

## Layout

```
windows-modern/     git submodule → github.com/lofcz/KDE-Windows-Modern (fork of Jeysef/KDE-Windows-Modern
                    with the patched applets/themes/icons committed in-tree)
graft/              extras: icontasks override, KWin scripts, configs, fonts, Fluent bits
scripts/refresh-from-live.sh
restore.sh
```

`windows-modern/` is installable with the upstream installer. `graft/` is rsynced onto `$HOME` after that.

## Restore

```bash
git clone --recurse-submodules git@github.com:lofcz/plasma-plus.git
cd plasma-plus
./restore.sh
```

(`restore.sh` runs `git submodule update --init` itself if the submodule is missing.)

That runs `windows-modern/install.sh all --dark`, then applies `graft/`.

Rebuild the taskbar plugin on a different Plasma/Qt ABI:

```bash
REBUILD_ICONTASKS=1 ./restore.sh
```

## Refresh

```bash
./scripts/refresh-from-live.sh      # rsync live edits into windows-modern/ and graft/
git -C windows-modern commit -a && git -C windows-modern push
git add windows-modern graft && git commit && git push
```

Theme/applet source changes are committed in the submodule (the fork); this repo only
tracks the submodule pointer plus `graft/`. Icon Tasks is edited in
`windows-modern/plasma/applets/org.kde.windowsmodern.icontasks` and built with CMake.

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
