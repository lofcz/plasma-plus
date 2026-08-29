#!/usr/bin/env python3
"""Hide the Plasma battery tray icon at 100%, show it otherwise."""

from __future__ import annotations

import subprocess
import sys

from gi.repository import Gio, GLib

PLUGIN = "org.kde.plasma.battery"
UP_NAME = "org.freedesktop.UPower"
UP_PATH = "/org/freedesktop/UPower/devices/DisplayDevice"
UP_IFACE = "org.freedesktop.UPower.Device"
PROPS_IFACE = "org.freedesktop.DBus.Properties"

# UPower Device.State: 4 = fully charged
STATE_FULLY_CHARGED = 4

_last_hidden: bool | None = None

PLASMA_SCRIPT = r"""
function csvToList(s) {
  return s.split(",").filter(function (x) { return x.length > 0; });
}
function setInList(arr, pluginId, present) {
  var idx = arr.indexOf(pluginId);
  if (present && idx === -1) arr.push(pluginId);
  if (!present && idx !== -1) arr.splice(idx, 1);
  return arr;
}
function setHidden(pluginId, hide) {
  var panelsList = panels();
  for (var p = 0; p < panelsList.length; ++p) {
    var widgets = panelsList[p].widgets();
    for (var i = 0; i < widgets.length; ++i) {
      if (widgets[i].type !== "org.kde.plasma.systemtray") continue;
      var w = widgets[i];
      w.currentConfigGroup = ["General"];
      var hidden = csvToList(w.readConfig("hiddenItems", ""));
      var extra = csvToList(w.readConfig("extraItems", ""));
      var shown = csvToList(w.readConfig("shownItems", ""));
      hidden = setInList(hidden, pluginId, hide);
      extra = setInList(extra, pluginId, !hide);
      shown = setInList(shown, pluginId, false);
      w.writeConfig("hiddenItems", hidden.join(","));
      w.writeConfig("extraItems", extra.join(","));
      w.writeConfig("shownItems", shown.join(","));
      w.reloadConfig();
    }
  }
}
setHidden("PLUGIN", HIDE);
""".replace(
    "PLUGIN", PLUGIN
)


def battery_should_hide(percent, state) -> bool:
    try:
        pct = float(percent)
    except (TypeError, ValueError):
        pct = -1
    try:
        st = int(state)
    except (TypeError, ValueError):
        st = 0
    return pct >= 100 or st == STATE_FULLY_CHARGED


def set_tray_hidden(hide: bool) -> None:
    global _last_hidden
    if _last_hidden is hide:
        return
    script = PLASMA_SCRIPT.replace("HIDE", "true" if hide else "false")
    try:
        subprocess.run(
            [
                "qdbus6",
                "org.kde.plasmashell",
                "/PlasmaShell",
                "org.kde.PlasmaShell.evaluateScript",
                script,
            ],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=8,
        )
        _last_hidden = hide
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass


def read_battery(bus: Gio.DBusConnection):
    try:
        result = bus.call_sync(
            UP_NAME,
            UP_PATH,
            PROPS_IFACE,
            "GetAll",
            GLib.Variant("(s)", (UP_IFACE,)),
            GLib.VariantType("(a{sv})"),
            Gio.DBusCallFlags.NONE,
            3000,
            None,
        )
        props = result.unpack()[0]
        return props.get("Percentage", -1), props.get("State", 0)
    except GLib.Error:
        return None, None


def on_properties_changed(_conn, _sender, _path, _iface, _signal, params):
    iface, changed, _invalidated = params.unpack()
    if iface != UP_IFACE:
        return
    percent, state = read_battery(_conn)
    if percent is None:
        return
    if "Percentage" in changed:
        percent = changed["Percentage"]
    if "State" in changed:
        state = changed["State"]
    set_tray_hidden(battery_should_hide(percent, state))


def main() -> int:
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    percent, state = read_battery(bus)
    if percent is not None:
        set_tray_hidden(battery_should_hide(percent, state))

    bus.signal_subscribe(
        UP_NAME,
        PROPS_IFACE,
        "PropertiesChanged",
        UP_PATH,
        None,
        Gio.DBusSignalFlags.NONE,
        on_properties_changed,
    )

    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
