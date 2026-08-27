# KDE Windows Modern — restorable desktop snapshot

Backup of a customized **Windows 11–style KDE Plasma 6** desktop (themes, plasmoids, panel layout, Kvantum, cursors, fonts, patched Icon Tasks). Intended to restore onto a **stock Plasma 6** machine.

Upstream theme base: [Jeysef/KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern) — this repo is a **machine snapshot** of the installed + customized result, not a full re-publish of that project.

## What’s included

| Area | Contents |
|------|----------|
| Plasmoids | Start menu, Show Desktop, Digital Clock (Windows Modern) + patched Icon Tasks QML |
| Look & feel | `org.kde.windowsmodern.dark` / `.light` |
| Plasma theme | `Windows-modern-dark` / `-light` (taskbar SVGs, etc.) |
| Window decoration | Aurorae `windows-modern-*-aurorae` |
| Style | Kvantum `Windows-modern` (+ opaque menus tweaks) |
| Icons | `windows-modern`, `Win11`, cropped Cursor / System Monitor overlays |
| Cursors | `Windows11Light` / `Windows11Dark`, `Win10OS-cursors` |
| Fonts | Segoe UI family under `~/.local/share/fonts/segoe-ui` |
| Wallpaper | `Windows-modern` |
| Config | Panel/applets layout, plasmashell, kwin borders/decoration, kdedefaults |
| Plugin | Prebuilt `org.kde.plasma.icontasks.so` + **source** under `sources/` |

Paths inside configs use `__HOME__` and are rewritten by `restore.sh`.

## Restore (new machine)

```bash
git clone git@github.com:lofcz/kde-windows-modern-snapshot.git
cd kde-windows-modern-snapshot
chmod +x restore.sh
./restore.sh
```

Requirements: KDE Plasma **6**, `kwriteconfig6`, `rsync`. On Arch/CachyOS the script installs `kvantum` / `kvantum-qt6` if missing.

If the taskbar plugin misbehaves (different Plasma/Qt ABI than the snapshot host):

```bash
REBUILD_ICONTASKS=1 ./restore.sh
```

Then log out and back in once if fonts or decorations look stale.

## Notable customizations in this snapshot

- Taskbar audio stream badges off (`indicateAudioStreams=false`)
- Window `BorderSize=None` (invisible resize grips; thin Tiny borders were hard to grab @ 1.25 scale)
- Start menu open/close animation + Win11-style power flyout
- Opaque Kvantum menus
- Custom Start button image (`windows-modern` `start-here.svg`)
- Icon Tasks sizing/hover behavior via patched plugin + `QT_PLUGIN_PATH`

## Layout

```
restore.sh          # install + apply
snapshot/           # mirrors ~/.local and ~/.config pieces
sources/            # Icon Tasks applet source for rebuild
MANIFEST.txt        # inventory + host metadata at snapshot time
```

## Privacy

Private backup by default. Do not commit secrets (VPN tokens, etc.) — this snapshot was sanitized for absolute home paths and machine tiling rules only.
