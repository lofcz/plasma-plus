/*
    SPDX-FileCopyrightText: 2020 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.pipewire as PipeWire

Item {
    id: root

    readonly property bool hasThumbnail: live.ready || frozen.source !== ""

    readonly property string windowUuid: {
        const id = thumbnailSourceItem.winId
        if (id === undefined || id === null || id === 0 || id === "") {
            return ""
        }
        return String(id)
    }

    readonly property url frozenUrl: {
        const _ = tasks.streamBroker.generation
        return tasks.streamBroker.frozenUrl(windowUuid)
    }

    function warm(): void {
        if (windowUuid.length === 0 || !tasks.streamBroker) {
            return;
        }
        tasks.streamBroker.acquire(windowUuid);
        tasks.streamBroker.snapshot(windowUuid);
    }

    Image {
        id: frozen
        anchors.fill: parent
        source: root.frozenUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        visible: source !== ""
    }

    PipeWire.PipeWireSourceItem {
        id: live
        anchors.fill: parent
        visible: ready
        nodeId: {
            const _ = tasks.streamBroker.generation
            return tasks.streamBroker.nodeIdFor(windowUuid)
        }
    }

    function rememberFrame(): void {
        if (!live.ready || windowUuid.length === 0) {
            return;
        }
        root.grabToImage(result => {
            if (result) {
                tasks.streamBroker.keepGrab(windowUuid, result);
            }
        });
    }

    onWindowUuidChanged: root.warm()
    onVisibleChanged: if (visible) root.warm()
    Component.onCompleted: root.warm()

    Connections {
        target: live
        function onReadyChanged(): void {
            if (live.ready) {
                rememberVisible.restart();
            }
        }
    }

    Timer {
        id: rememberVisible
        interval: 50
        repeat: false
        onTriggered: root.rememberFrame()
    }

    Timer {
        interval: 700
        running: root.visible && live.ready
        repeat: true
        onTriggered: root.rememberFrame()
    }
}
