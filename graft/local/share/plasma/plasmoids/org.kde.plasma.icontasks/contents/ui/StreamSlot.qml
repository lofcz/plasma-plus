/*
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

Item {
    id: slot

    required property string uuid
    required property int index

    property real lastUsed: 0
    property bool everReady: false
    property bool replacing: false
    property var frozenGrab: null

    readonly property url frozenUrl: frozenGrab ? frozenGrab.url : ""
    readonly property alias nodeId: waylandItem.nodeId
    readonly property alias ready: keepAlive.ready
    readonly property alias previewItem: keepAlive

    x: 0
    y: index * height
    width: 420
    height: 260
    visible: true
    layer.enabled: true

    function replace(): void {
        if (slot.replacing || slot.uuid.length === 0) {
            return;
        }
        slot.replacing = true;
        slot.everReady = false;
        resumeReplace.restart();
    }

    function takeSnapshot(): void {
        if (!keepAlive.ready) {
            return;
        }
        keepAlive.grabToImage(result => {
            // The URL is only valid while this grab result is kept alive.
            if (result && result.url) {
                slot.frozenGrab = result;
            }
        }, Qt.size(slot.width, slot.height));
    }

    TaskManager.ScreencastingRequest {
        id: waylandItem
        uuid: (slot.replacing || slot.uuid.length === 0) ? "" : slot.uuid
    }

    PipeWire.PipeWireSourceItem {
        id: keepAlive
        anchors.fill: parent
        nodeId: waylandItem.nodeId
        layer.enabled: true
        layer.smooth: true

        onReadyChanged: {
            if (keepAlive.ready) {
                slot.everReady = true;
                snapshot.restart();
                warmer.restart();
                return;
            }
            warmer.stop();
            if (slot.everReady && !slot.replacing && slot.uuid.length > 0) {
                slot.replace();
            }
        }
    }

    Timer {
        id: resumeReplace
        interval: 16
        repeat: false
        onTriggered: slot.replacing = false
    }

    Timer {
        id: snapshot
        interval: 80
        repeat: false
        onTriggered: slot.takeSnapshot()
    }

    // Keep a recent still so the tooltip has pixels before the
    // popup's own PipeWire viewer produces a frame.
    Timer {
        id: warmer
        interval: 750
        repeat: true
        onTriggered: slot.takeSnapshot()
    }
}
