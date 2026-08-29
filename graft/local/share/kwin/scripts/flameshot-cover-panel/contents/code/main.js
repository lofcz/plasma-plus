function isFlameshotWindow(window) {
    if (!window) {
        return false;
    }
    const cls = String(window.resourceClass || "").toLowerCase();
    const name = String(window.resourceName || "").toLowerCase();
    return cls.indexOf("flameshot") !== -1 || name.indexOf("flameshot") !== -1;
}

function isFlameshotOverlay(window) {
    if (!isFlameshotWindow(window)) {
        return false;
    }
    if (window.dialog || window.popupWindow || window.splash || window.tooltip) {
        return false;
    }
    const cap = String(window.caption || "").toLowerCase();
    if (cap.indexOf("config") !== -1 || cap.indexOf("launcher") !== -1) {
        return false;
    }
    return true;
}

function stripChrome(window) {
    try { window.noBorder = true; } catch (e) {}
    try { window.keepAbove = true; } catch (e) {}
}

function fullScreenArea(window) {
    try {
        return workspace.clientArea(KWin.FullScreenArea, window);
    } catch (e) {
    }
    try {
        return workspace.clientArea(Workspace.FullScreenArea, window);
    } catch (e) {
    }
    if (window.output && window.output.geometry) {
        return window.output.geometry;
    }
    return null;
}

function sameRect(a, b) {
    if (!a || !b) {
        return false;
    }
    return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
}

function coverPanel(window) {
    if (isFlameshotWindow(window)) {
        stripChrome(window);
    }
    if (!isFlameshotOverlay(window) || window._flameshotCovered) {
        return;
    }
    window._flameshotCovered = true;

    // Hide until the overlay is already full-screen. Otherwise the first
    // paint is the work-area size and the resize jumps the screenshot.
    // fullScreen must stay true: ShapeCorners skips rounding/outline on
    // fullscreen windows (DisableRoundFullScreen / DisableOutlineFullScreen).
    try { window.opacity = 0; } catch (e) {}
    try { window.keepAbove = true; } catch (e) {}
    try { window.skipTaskbar = true; } catch (e) {}
    try { window.skipPager = true; } catch (e) {}
    try { window.skipSwitcher = true; } catch (e) {}
    try { window.fullScreen = true; } catch (e) {}
    try { window.noBorder = true; } catch (e) {}

    function snap() {
        const area = fullScreenArea(window);
        if (!area || sameRect(window.frameGeometry, area)) {
            return;
        }
        window.frameGeometry = area;
    }

    snap();
    try {
        window.frameGeometryChanged.connect(snap);
    } catch (e) {
    }

    function reveal() {
        snap();
        try { window.opacity = 1; } catch (e) {}
    }

    try {
        const timer = new QTimer();
        timer.interval = 20;
        timer.repeat = false;
        timer.triggered.connect(function () {
            reveal();
            try { timer.destroy(); } catch (e) {}
        });
        timer.start();
    } catch (e) {
        reveal();
    }
}

workspace.windowAdded.connect(coverPanel);
workspace.windowList().forEach(coverPanel);

function launchFlameshot() {
    callDBus(
        "org.kde.kglobalaccel",
        "/component/flameshot_gui_desktop",
        "org.kde.kglobalaccel.Component",
        "invokeShortcut",
        "_launch"
    );
}

registerShortcut("Flameshot Capture", "Take screenshot with Flameshot", "F1", launchFlameshot);
registerShortcut("Flameshot Capture F13", "Take screenshot with Flameshot (F13)", "F13", launchFlameshot);
