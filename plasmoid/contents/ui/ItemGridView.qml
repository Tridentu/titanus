/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Controls 2.15

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.draganddrop 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property bool dragEnabled: true
    property bool dropEnabled: false
    property bool showLabels: true
    property alias usesPlasmaTheme: gridView.usesPlasmaTheme

    property int iconSize: titanusRoot.iconSize

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias count: gridView.count
    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight

    property bool horizontalScrollBarPolicy: false
    property bool verticalScrollBarPolicy: false

    property alias hoverEnabled: mouseArea.hoverEnabled

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function currentRow() {
        if (currentIndex == -1) {
            return -1;
        }

        return Math.floor(currentIndex / Math.floor(width / cellWidth));
    }

    function currentCol() {
        if (currentIndex == -1) {
            return -1;
        }

        return currentIndex - (currentRow() * Math.floor(width / cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / cellWidth);
            var rows = Math.ceil(count / columns);
            row = Math.min(row, rows - 1);
            col = Math.min(col, columns - 1);
            currentIndex = Math.min(row ? ((Math.max(1, row) * columns) + col)
                : col,
                count - 1);

            gridView.forceActiveFocus();
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            var closeRequested = visualParent.actionTriggered(actionId, actionArgument);

            if (closeRequested) {
                titanusDash.toggle();
            }
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        onDragMove: {
            if (!dragEnabled || gridView.animating) {
                return;
            }

            var cPos = mapToItem(gridView.contentItem, event.x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item && item != kicker.dragSource && kicker.dragSource && kicker.dragSource.parent == gridView.contentItem) {
                item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
            }

        }

        Timer {
            id: resetAnimationDurationTimer

            interval: 80
            repeat: false

            onTriggered: {
                gridView.animationDuration = dragEnabled ? units.longDuration : 0;
            }
        }

        PlasmaComponents3.ScrollView {
            id: scrollArea

            focus: true
            width: parent.width
            height: parent.height
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            GridView {
                id: gridView

                property bool usesPlasmaTheme: false

                property bool animating: false
                property int animationDuration: dragEnabled ? units.longDuration : 0

                focus: true
                visible: false
                //enabled: visible
                currentIndex: -1

                move: Transition {
                    enabled: itemGrid.dragEnabled

                    SequentialAnimation {
                        PropertyAction { target: gridView; property: "animating"; value: true }
                        ColorAnimation {
                            target: mainPage
                            property: "color"
                            from: titanusDash.colorWithAlpha('#2e3440', (plasmoid.configuration.backgroundOpacity / 5 )/ 100)
                            to: titanusDash.colorWithAlpha('#d8dee9', (plasmoid.configuration.backgroundOpacity / 1.5 )/ 100)
                            duration: 500
                        }
                        NumberAnimation {
                            duration: gridView.animationDuration
                            properties: "x, y"
                            easing.type: Easing.OutBounce
                        }
                        ColorAnimation {
                            target: mainPage
                            property: "color"
                            from: titanusDash.colorWithAlpha('#d8dee9', (plasmoid.configuration.backgroundOpacity / 1.5 )/ 100)
                            to: titanusDash.colorWithAlpha('#2e3440', (plasmoid.configuration.backgroundOpacity / 5 )/ 100)
                            duration: 500
                        }
                        PropertyAction { target: gridView; property: "animating"; value: false }
                    }
                }

                moveDisplaced: Transition {
                    enabled: itemGrid.dragEnabled

                    SequentialAnimation {
                        PropertyAction { target: gridView; property: "animating"; value: true }
                        ColorAnimation {
                            target: mainPage
                            property: "color"
                            from: titanusDash.colorWithAlpha('#2e3440', (plasmoid.configuration.backgroundOpacity / 5 )/ 100)
                            to: titanusDash.colorWithAlpha('#d8dee9', (plasmoid.configuration.backgroundOpacity / 1.5 )/ 100)
                            duration: 500
                        }
                        NumberAnimation {
                            duration: gridView.animationDuration * 5
                            properties: "x, y"
                            easing.type: Easing.OutBounce
                        }
                        ColorAnimation {
                            target: mainPage
                            property: "color"
                            from: titanusDash.colorWithAlpha('#d8dee9', (plasmoid.configuration.backgroundOpacity / 1.5 )/ 100)
                            to: titanusDash.colorWithAlpha('#2e3440', (plasmoid.configuration.backgroundOpacity / 5 )/ 100)
                            duration: 500
                        }
                        PropertyAction { target: gridView; property: "animating"; value: false }
                    }
                }

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                delegate: ItemGridDelegate {
                    showLabel: showLabels
                }

                highlight: PlasmaComponents.Highlight {}
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

                onCountChanged: {
                    animationDuration = 0;
                    resetAnimationDurationTimer.start();
                }

                onModelChanged: {
                    currentIndex = -1;
                    visible =  (model != null) ? model.count > 0 : false
                }

                Keys.onLeftPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != 0) {
                        event.accepted = true;
                        moveCurrentIndexLeft();
                    } else {
                        itemGrid.keyNavLeft();
                    }
                }

                Keys.onRightPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    var columns = Math.floor(width / cellWidth);

                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != columns - 1 && currentIndex != count - 1) {
                        event.accepted = true;
                        moveCurrentIndexRight();
                    } else {
                        itemGrid.keyNavRight();
                    }
                }

                Keys.onUpPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() != 0) {
                        event.accepted = true;
                        moveCurrentIndexUp();
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        itemGrid.keyNavUp();
                    }
                }

                Keys.onDownPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() < itemGrid.lastRow()) {
                        // Fix moveCurrentIndexDown()'s lack of proper spatial nav down
                        // into partial columns.
                        event.accepted = true;
                        var columns = Math.floor(width / cellWidth);
                        var newIndex = currentIndex + columns;
                        currentIndex = Math.min(newIndex, count - 1);
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        itemGrid.keyNavDown();
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent

            property int pressX: -1
            property int pressY: -1
            property Item pressedItem: null

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            hoverEnabled: true

            function updatePositionProperties(x, y) {
                var cPos = mapToItem(gridView.contentItem, x, y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    gridView.currentIndex = -1;
                    pressedItem = null;
                } else {
                    gridView.currentIndex = item.itemIndex;
                }
                itemGrid.focus = true;

                return item;
            }

            onPressed: {
                mouse.accepted = true;

                updatePositionProperties(mouse.x, mouse.y);
                pressX = mouse.x;
                pressY = mouse.y;

                if (mouse.button == Qt.RightButton) {
                    if (gridView.currentItem && gridView.currentItem.hasActionList) {
                        var mapped = mapToItem(gridView.currentItem, mouse.x, mouse.y);
                        gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                    }
                } else {
                    pressedItem = gridView.currentItem;
                }
            }

            onReleased: {
                mouse.accepted = true;
                if (gridView.currentItem && gridView.currentItem == pressedItem) {
                    if ("trigger" in gridView.model) {
                        gridView.model.trigger(pressedItem.itemIndex, "", null);

                        if ("toggle" in titanusRoot) {
                            titanusRoot.toggle();
                        } else {
                            titanusRoot.visible = false;
                        }
                    }
                } else if (!pressedItem && mouse.button == Qt.LeftButton && !dragHelper.dragging) {
                    if ("toggle" in titanusRoot) {
                        titanusRoot.toggle();
                    } else {
                        titanusRoot.visible = false;
                    }
                }

                pressX = -1;
                pressY = -1;
                pressedItem = null;
            }

            onPressAndHold: {
                if (!dragEnabled) {
                    pressX = -1;
                    pressY = -1;
                    return;
                }

                var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    return;
                }

                if (!dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                    kicker.dragSource = item;
                    dragHelper.startDrag(kicker, item.url);
                }

                pressX = -1;
                pressY = -1;
                pressedItem = null;
            }

            onPositionChanged: {
                var item = updatePositionProperties(mouse.x, mouse.y);

                if (gridView.currentIndex != -1 && item != null && item.m != null) {
                    if (dragEnabled && pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                        if ("pluginName" in item.m) {
                            dragHelper.startDrag(kicker, item.url, item.icon,
                            "text/x-plasmoidservicename", item.m.pluginName);
                        } else {
                            dragHelper.startDrag(kicker, item.url, item.icon);
                        }

                        kicker.dragSource = item;

                        pressX = -1;
                        pressY = -1;
                    }
                }
            }

            onContainsMouseChanged: {
                if (!containsMouse) {
                    if (!actionMenu.opened) {
                        gridView.currentIndex = -1;
                    }

                    pressX = -1;
                    pressY = -1;
                    pressedItem = null;
                    //hoverEnabled = false;
                }
            }
        }
    }
}
