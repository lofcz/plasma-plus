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
    property url frozenUrl: ""

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
                return;
            }
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
        interval: 0
        repeat: false
        property int tries: 0
        onTriggered: {
            if (!keepAlive.ready) {
                return;
            }
            slot.grabToImage(result => {
                if (result && result.url) {
                    slot.frozenUrl = result.url;
                    snapshot.tries = 0;
                    return;
                }
                if (snapshot.tries < 4) {
                    snapshot.tries += 1;
                    snapshot.interval = 50;
                    snapshot.restart();
                }
            });
        }
    }
}
