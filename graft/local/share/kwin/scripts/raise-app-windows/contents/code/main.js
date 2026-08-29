var raising = false;
var minimizing = false;
var ignoreActivations = false;
var lastActive = null;
var sawShell = false;
// Oldest → newest focus. Do not read workspace stacking at raise time:
// Plasma has already raised the clicked window, which corrupts group order.
var mru = [];

function str(value) {
    try {
        return String(value || "").toLowerCase();
    } catch (e) {
        return "";
    }
}

function isShellWindow(window) {
    if (!window) {
        return true;
    }
    try {
        if (window.dock || window.desktopWindow || window.splash || window.tooltip || window.popupWindow) {
            return true;
        }
        if (window.specialWindow && !window.normalWindow) {
            return true;
        }
        var cls = str(window.resourceClass);
        var name = str(window.resourceName);
        var desktop = str(window.desktopFileName);
        var caption = str(window.caption);
        if (cls.indexOf("plasmashell") !== -1 || name.indexOf("plasmashell") !== -1) {
            return true;
        }
        if (cls.indexOf("krunner") !== -1 || desktop.indexOf("krunner") !== -1) {
            return true;
        }
        if (cls.indexOf("xembedsniproxy") !== -1) {
            return true;
        }
        if (caption.indexOf("plasma") !== -1 && window.skipTaskbar) {
            return true;
        }
        if (window.dialog && window.skipTaskbar) {
            return true;
        }
    } catch (e) {
        return true;
    }
    return false;
}

function appKey(window) {
    if (!window || isShellWindow(window)) {
        return "";
    }
    try {
        // Class first: the taskbar groups by WM class. Desktop files differ for
        // Chromium vs chrome-devtools-mcp ("Chrome Automated") even though both
        // are class=Chromium and share one icon.
        var cls = str(window.resourceClass);
        if (cls) {
            return "class:" + cls;
        }
        var desktopFile = str(window.desktopFileName);
        if (desktopFile && desktopFile !== "unknown") {
            return "desktop:" + desktopFile;
        }
        var name = str(window.resourceName);
        if (name) {
            var base = name.split(" ")[0].split("/")[0];
            if (base) {
                return "name:" + base;
            }
        }
    } catch (e) {
    }
    return "";
}

function isAppWindow(window) {
    if (!window || isShellWindow(window)) {
        return false;
    }
    try {
        if (window.skipTaskbar) {
            return false;
        }
        return !!window.normalWindow;
    } catch (e) {
        return false;
    }
}

function sameDesktop(a, b) {
    if (!a || !b) {
        return false;
    }
    try {
        if (a.onAllDesktops || b.onAllDesktops) {
            return true;
        }
        var aDesktops = a.desktops || [];
        var bDesktops = b.desktops || [];
        if (!aDesktops.length || !bDesktops.length) {
            return true;
        }
        for (var i = 0; i < aDesktops.length; i++) {
            for (var j = 0; j < bDesktops.length; j++) {
                if (aDesktops[i] === bDesktops[j]) {
                    return true;
                }
            }
        }
    } catch (e) {
    }
    return false;
}

function sameWindow(a, b) {
    if (!a || !b) {
        return false;
    }
    if (a === b) {
        return true;
    }
    try {
        var aid = a.internalId;
        var bid = b.internalId;
        if (aid && bid && String(aid) === String(bid)) {
            return true;
        }
    } catch (e) {
    }
    return false;
}

function removeMru(window) {
    for (var i = mru.length - 1; i >= 0; i--) {
        if (sameWindow(mru[i], window)) {
            mru.splice(i, 1);
        }
    }
}

function touchMru(window) {
    if (!isAppWindow(window)) {
        return;
    }
    removeMru(window);
    mru.push(window);
}

function mruIndex(window) {
    for (var i = 0; i < mru.length; i++) {
        if (sameWindow(mru[i], window)) {
            return i;
        }
    }
    return -1;
}

function stackingList() {
    try {
        var order = workspace.stackingOrder;
        if (order && order.length) {
            return order;
        }
    } catch (e) {
    }
    try {
        return workspace.windowList();
    } catch (e2) {
        return [];
    }
}

function stackingIndex(window, snapshot) {
    var order = snapshot || stackingList();
    for (var i = 0; i < order.length; i++) {
        if (sameWindow(order[i], window)) {
            return i;
        }
    }
    try {
        var raw = window.stackingOrder;
        if (typeof raw === "number") {
            return raw;
        }
    } catch (e) {
    }
    return 0;
}

function sortByFocusOrder(windows) {
    var stack = stackingList();
    windows.sort(function (a, b) {
        var fa = mruIndex(a);
        var fb = mruIndex(b);
        if (fa !== -1 && fb !== -1 && fa !== fb) {
            return fa - fb;
        }
        if (fa !== fb) {
            return fa === -1 ? -1 : 1;
        }
        return stackingIndex(a, stack) - stackingIndex(b, stack);
    });
    return windows;
}

function seedMruFromStack() {
    var order = stackingList();
    for (var i = 0; i < order.length; i++) {
        if (isAppWindow(order[i])) {
            touchMru(order[i]);
        }
    }
}

function pointInRect(pos, rect) {
    if (!pos || !rect) {
        return false;
    }
    return pos.x >= rect.x && pos.x < rect.x + rect.width &&
        pos.y >= rect.y && pos.y < rect.y + rect.height;
}

function isPanelWindow(window) {
    if (!window) {
        return false;
    }
    try {
        return !!window.dock;
    } catch (e) {
        return false;
    }
}

function isCursorOnPanel() {
    var pos = null;
    try {
        pos = workspace.cursorPos;
    } catch (e) {
        return false;
    }
    if (!pos) {
        return false;
    }

    try {
        var underCursor = workspace.windowAt(pos);
        if (isPanelWindow(underCursor)) {
            return true;
        }
        // Thumbnail flyout / plasma popup: click a preview to raise
        // that window only, not the whole group.
        if (underCursor && isShellWindow(underCursor)) {
            return false;
        }
    } catch (e) {
    }

    try {
        var output = workspace.screenAt(pos);
        var work = workspace.clientArea(KWin.WorkArea, output, workspace.currentDesktop);
        var full = workspace.clientArea(KWin.FullScreenArea, output, workspace.currentDesktop);
        if (work && full && pointInRect(pos, full) && !pointInRect(pos, work)) {
            return true;
        }
    } catch (e) {
    }

    return false;
}

function appWindows(reference) {
    var key = appKey(reference);
    var matches = [];
    if (!key) {
        return matches;
    }
    var windows = stackingList();
    for (var i = 0; i < windows.length; i++) {
        var window = windows[i];
        if (!isAppWindow(window)) {
            continue;
        }
        if (appKey(window) !== key || !sameDesktop(window, reference)) {
            continue;
        }
        matches.push(window);
    }
    return matches;
}

function siblingStats(reference) {
    var wins = appWindows(reference);
    var minimized = 0;
    var visible = 0;
    for (var i = 0; i < wins.length; i++) {
        if (sameWindow(wins[i], reference)) {
            continue;
        }
        if (wins[i].minimized) {
            minimized++;
        } else {
            visible++;
        }
    }
    return { minimized: minimized, visible: visible, total: wins.length };
}

function isMinimizedSafe(window) {
    try {
        return !!window.minimized;
    } catch (e) {
        return false;
    }
}

function armIgnore(ms) {
    ignoreActivations = true;
    try {
        var timer = new QTimer();
        timer.interval = ms || 400;
        timer.repeat = false;
        timer.triggered.connect(function () {
            ignoreActivations = false;
            try { timer.destroy(); } catch (e) {}
        });
        timer.start();
    } catch (e) {
        ignoreActivations = false;
    }
}

function raiseAppWindows(active) {
    var siblings = appWindows(active);
    if (!siblings.length) {
        rememberActive(active);
        return;
    }

    sortByFocusOrder(siblings);

    raising = true;
    try {
        for (var i = 0; i < siblings.length; i++) {
            if (siblings[i].minimized) {
                siblings[i].minimized = false;
            }
            workspace.raiseWindow(siblings[i]);
        }
        var top = siblings[siblings.length - 1];
        if (top.minimized) {
            top.minimized = false;
        }
        workspace.raiseWindow(top);
        workspace.activeWindow = top;
        lastActive = top;
    } finally {
        raising = false;
    }
    // Absorb Plasma cycling another window in the group on the same click.
    armIgnore(350);
}

function minimizeAppWindows(reference) {
    var siblings = appWindows(reference);
    if (!siblings.length) {
        return;
    }

    minimizing = true;
    armIgnore(450);
    try {
        for (var i = 0; i < siblings.length; i++) {
            if (!siblings[i].minimized) {
                siblings[i].minimized = true;
            }
        }
    } finally {
        minimizing = false;
    }
}

function rememberActive(window) {
    if (isAppWindow(window)) {
        lastActive = window;
        touchMru(window);
    }
}

function handlePanelClick(prev, window) {
    // Group raise/minimize-all is no longer done on a single taskbar click.
    // The taskbar applet shows thumbnails on click and toggles the whole
    // group on a quick double-click. Only keep MRU tracking here.
    rememberActive(window);
}

function onWindowActivated(window) {
    if (raising) {
        return;
    }

    if (minimizing || ignoreActivations) {
        if (isAppWindow(window) && lastActive && appKey(window) !== appKey(lastActive)) {
            rememberActive(window);
        }
        return;
    }

    if (isShellWindow(window) || !isAppWindow(window)) {
        // Remember that chrome stole focus so a later same-window refocus
        // (calendar/start menu close) is not treated as a taskbar toggle.
        // Do NOT arm a timed ignore — that swallows the next real taskbar click.
        sawShell = true;
        return;
    }

    var prev = lastActive;
    var onPanel = isCursorOnPanel();

    if (!onPanel) {
        sawShell = false;
        rememberActive(window);
        return;
    }

    handlePanelClick(prev, window);
    sawShell = false;
}

function onWindowAdded(window) {
    if (isShellWindow(window)) {
        sawShell = true;
        return;
    }
    if (isAppWindow(window)) {
        touchMru(window);
    }
}

function onWindowRemoved(window) {
    if (isShellWindow(window)) {
        sawShell = true;
    }
    removeMru(window);
    if (sameWindow(lastActive, window)) {
        lastActive = null;
    }
}

workspace.windowActivated.connect(onWindowActivated);
workspace.windowAdded.connect(onWindowAdded);
workspace.windowRemoved.connect(onWindowRemoved);
seedMruFromStack();
if (isAppWindow(workspace.activeWindow)) {
    lastActive = workspace.activeWindow;
    touchMru(workspace.activeWindow);
}
