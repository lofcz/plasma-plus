/*
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

Item {
    id: broker

    readonly property int maxStreams: 8
    property int generation: 0

    // Off-screen but actually rendered so the live texture exists
    // before the tooltip opens (avoids a blank first frame).
    x: -20000
    y: 0
    width: 420
    height: 260 * maxStreams
    visible: true
    clip: true

    function bump(): void {
        generation += 1;
    }

    ListModel {
        id: uuidModel
    }

    Repeater {
        id: slots
        model: uuidModel
        delegate: StreamSlot {
            onNodeIdChanged: broker.bump()
            onReadyChanged: broker.bump()
            onFrozenUrlChanged: broker.bump()
            Component.onCompleted: lastUsed = Date.now()
        }
        onItemAdded: broker.bump()
        onItemRemoved: broker.bump()
    }

    function slotAt(uuid: string): var {
        const n = slots.count;
        for (let i = 0; i < n; i++) {
            const item = slots.itemAt(i);
            if (item && item.uuid === uuid) {
                return item;
            }
        }
        return null;
    }

    function evictOldest(): void {
        if (uuidModel.count === 0) {
            return;
        }
        let oldestIndex = 0;
        let oldestTime = Number.POSITIVE_INFINITY;
        const n = slots.count;
        for (let i = 0; i < n; i++) {
            const item = slots.itemAt(i);
            if (!item) {
                continue;
            }
            if (item.lastUsed < oldestTime) {
                oldestTime = item.lastUsed;
                oldestIndex = i;
            }
        }
        uuidModel.remove(oldestIndex);
    }

    function acquire(uuid): void {
        const id = (uuid === undefined || uuid === null || uuid === 0) ? "" : String(uuid);
        if (id.length === 0) {
            return;
        }

        const slot = slotAt(id);
        if (!slot) {
            while (uuidModel.count >= broker.maxStreams) {
                evictOldest();
            }
            uuidModel.append({ uuid: id });
            return;
        }

        slot.lastUsed = Date.now();
        if (slot.ready) {
            return;
        }
        if (!slot.everReady && !slot.replacing) {
            return;
        }
        if (!slot.replacing) {
            slot.replace();
        }
    }

    function nodeIdFor(uuid): int {
        const id = (uuid === undefined || uuid === null || uuid === 0) ? "" : String(uuid);
        const slot = slotAt(id);
        return slot ? slot.nodeId : 0;
    }

    function previewItem(uuid): var {
        const id = (uuid === undefined || uuid === null || uuid === 0) ? "" : String(uuid);
        const slot = slotAt(id);
        return slot ? slot.previewItem : null;
    }

    function isReady(uuid): bool {
        const id = (uuid === undefined || uuid === null || uuid === 0) ? "" : String(uuid);
        const slot = slotAt(id);
        return !!(slot && slot.ready);
    }

    function frozenUrl(uuid): url {
        const id = (uuid === undefined || uuid === null || uuid === 0) ? "" : String(uuid);
        const slot = slotAt(id);
        return slot ? slot.frozenUrl : "";
    }
}
