/*
    SPDX-FileCopyrightText: 2020 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

PipeWire.PipeWireSourceItem {
    id: pipeWireSourceItem

    readonly property alias hasThumbnail: pipeWireSourceItem.ready

    readonly property string windowUuid: {
        const id = thumbnailSourceItem.winId
        if (id === undefined || id === null || id === 0 || id === "") {
            return ""
        }
        return String(id)
    }

    readonly property bool canCapture: windowUuid.length > 0
        && thumbnailSourceItem.isReadyForPainting

    anchors.fill: parent
    nodeId: waylandItem.nodeId

    TaskManager.ScreencastingRequest {
        id: waylandItem
        // Drop the uuid to tear the stream down, then set it again to retry.
        // KWin rejects Chromium/Wayland requests that arrive before a buffer
        // is attached; a stale rejected request never recovers on its own.
        uuid: (canCapture && !retry.paused) ? windowUuid : ""
    }

    QtObject {
        id: retry
        property bool paused: false
        property int attempts: 0
    }

    Timer {
        id: retryWatchdog
        interval: 280
        repeat: false
        running: canCapture && !pipeWireSourceItem.ready && retry.attempts < 4 && !retry.paused
        onTriggered: {
            retry.attempts += 1
            retry.paused = true
            retryResume.start()
        }
    }

    Timer {
        id: retryResume
        interval: 16
        repeat: false
        onTriggered: retry.paused = false
    }

    onReadyChanged: {
        if (pipeWireSourceItem.ready) {
            retry.attempts = 0
        }
    }

    onCanCaptureChanged: {
        if (canCapture) {
            retry.attempts = 0
            retry.paused = false
        }
    }
}
