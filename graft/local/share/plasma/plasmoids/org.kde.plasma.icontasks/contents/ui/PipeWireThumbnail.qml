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

    onWindowUuidChanged: {
        if (windowUuid.length > 0) {
            tasks.streamBroker.acquire(windowUuid)
        }
    }

    Component.onCompleted: {
        if (windowUuid.length > 0) {
            tasks.streamBroker.acquire(windowUuid)
        }
    }
}
