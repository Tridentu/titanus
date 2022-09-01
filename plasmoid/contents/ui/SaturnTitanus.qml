import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.15
import QtQuick.Controls.Styles 1.4
import QtGamepad 1.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwindowsystem 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.shell 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: titanusRoot

    anchors.fill: parent

    signal reset

    property bool isDash: false

    property int iconSize:    plasmoid.configuration.iconSize
    property int iconSizeFavorites:    plasmoid.configuration.iconSizeFavorites
    property int spaceWidth:  plasmoid.configuration.spaceWidth
    property int spaceHeight: plasmoid.configuration.spaceHeight
    property int cellSizeWidth: spaceWidth + iconSize + theme.mSize(theme.defaultFont).height
                                + (2 * units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeHeight: spaceHeight + iconSize + theme.mSize(theme.defaultFont).height
                                 + (2 * units.smallSpacing)
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int gridNumCols:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberColumns : Math.floor(width  * 0.85  / cellSizeWidth)
    property int gridNumRows:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberRows : Math.floor(height * 0.8  /  cellSizeHeight)
    property int widthScreen:  gridNumCols * cellSizeWidth
    property int heightScreen: gridNumRows * cellSizeHeight


    property QtObject globalFavorites: rootModel.favoritesModel

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    onVisibleChanged: {
        animationSearch.start()
        reset();
        rootModel.pageSize = gridNumCols*gridNumRows
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: plasmoid.configuration.appNameFormat
        flat: true
        sorted: true
        showSeparators: false
        appletInterface: plasmoid

        paginate: true
        showAllApps: true
        showRecentApps: false
        showRecentDocs: false
        showRecentContacts: false
        showPowerSession: false

        onFavoritesModelChanged: {
            if ("initForClient" in favoritesModel) {
                favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)

                if (!plasmoid.configuration.favoritesPortedToKAstats) {
                    favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                    plasmoid.configuration.favoritesPortedToKAstats = true;
                }
            } else {
                favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }

            favoritesModel.maxFavorites = pageSize;
        }

        Component.onCompleted: {
            if ("initForClient" in favoritesModel) {
                favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)
                if (!plasmoid.configuration.favoritesPortedToKAstats) {
                    favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                    plasmoid.configuration.favoritesPortedToKAstats = true;
                }
            } else {
                favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }
            favoritesModel.maxFavorites = pageSize;
            rootModel.refresh();
        }
    }

    Kicker.RunnerModel {
        id: runnerModel
        favoritesModel: globalFavorites
        runners: {
                    var runners = ["services", "krunner_systemsettings"]

                    if (plasmoid.configuration.useExtraRunners) {
                        runners = runners.concat(plasmoid.configuration.extraRunners);
                    }

                    return runners;
                }
        appletInterface: plasmoid
        deleteWhenEmpty: false
    }
    
    Component {
        id: compactRepresentation
        CompactRepresentation {
        
        }
    }


    Plasmoid.compactRepresentation: compactRepresentation
    
    Kicker.DashboardWindow {
            id: titanusDash
            backgroundColor: "transparent"
            property int startIndex: 1 //(showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1
            property bool searching: (searchBar.text != "")
            property bool showFavorites: plasmoid.configuration.showFavorites
            property bool gamepadClosing: false
            property bool powerVisible: true
            property bool gamepadMenuVisible: false
            
            keyEventProxy: searchBar

            onGamepadClosingChanged: {
              if (gamepadClosing) {
                  titanusDash.toggle();
                  gamepadClosing = false;
                  return;
              }
            }
            
            onGamepadMenuVisibleChanged: {
              if(gamepadMenuVisible){
                  powerVisible = !powerVisible;
                  gamepadMenuVisible = false;
                  return
              }
            }
            
            onSearchingChanged: {
                 if (searching) {
                    pageList.model = runnerModel;
                    paginationBar.model = runnerModel;
                } else {
                    reset();
                }
            }
            
            function reset() {
                if (!titanusDash.searching) {
                    pageList.model = rootModel.modelForRow(0);
                    paginationBar.model = rootModel.modelForRow(0);
                }
                searchBar.text = "";
                pageListScrollArea.focus = true;
                pageList.currentIndex = titanusDash.startIndex;
                pageList.positionViewAtIndex(pageList.currentIndex, ListView.Contain);
                pageList.currentItem.itemGrid.currentIndex = -1;
            }
                onKeyEscapePressed: {
                if (searching) {
                    searchBar.text = "";
                } else
                    titanusDash.toggle();
            }
            function colorWithAlpha(color, alpha) {
                return Qt.rgba(color.r, color.g, color.b, alpha)
            }
            

            mainItem: Rectangle {
                anchors.fill: parent
                color: "transparent"


                Rectangle {
                    anchors.fill: parent
                    color: titanusDash.colorWithAlpha('#2e3440', plasmoid.configuration.backgroundOpacity / 100)
                }

                 PlasmaExtras.Heading {
                    id: dummyHeading
                    visible: false
                    width: 0
                    level: 5
                }

                ScaleAnimator{
                    id: animationSearch
                    from: 1.1
                    to: 1
                    target: mainPage
                }

                MouseArea {
                    id: mainMouseArea
                    property int wheelDelta: 0
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
                    LayoutMirroring.childrenInherit: true
                    hoverEnabled: true

                    onClicked: titanusDash.toggle()
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Escape) {
                            event.accepted = true;
                            if (searching)
                                reset();
                            else
                                root.toggle();
                            return ;
                        }
                        if (searchBar.focus)
                            return ;

                        if (event.key == Qt.Key_Backspace) {
                            event.accepted = true;
                            searchBar.backspace();
                        } else if (event.key == Qt.Key_Tab) {
                            event.accepted = true;
                            if (pageList.currentItem.itemGrid.currentIndex == -1) {
                                pageList.currentItem.itemGrid.tryActivate(0, 0);
                            } else {
                                //pageList.currentItem.itemGrid.keyNavDown();
                                pageList.currentItem.itemGrid.currentIndex = -1;
                                searchBar.focus = true;
                            }
                        } else if (event.key == Qt.Key_Backtab) {
                            event.accepted = true;
                            pageList.currentItem.itemGrid.keyNavUp();
                        } else if (event.text != "") {
                            event.accepted = true;
                            searchBar.appendText(event.text);
                        }
                    }
                    
                     function scrollByWheel(wheelDelta, eventDelta) {
                        // magic number 120 for common "one click"
                        // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                        wheelDelta += (Math.abs(eventDelta.x) > Math.abs(eventDelta.y)) ? eventDelta.x : eventDelta.y;
                        var increment = 0;
                        while (wheelDelta >= 120) {
                            wheelDelta -= 120;
                            increment++;
                        }
                        while (wheelDelta <= -120) {
                            wheelDelta += 120;
                            increment--;
                        }
                        while (increment != 0) {
                            pageList.activateNextPrev(increment < 0, false);
                            increment += (increment < 0) ? 1 : -1;
                        }
                        return wheelDelta;
                    }
                    Rectangle {
                        anchors.centerIn: searchBar
                        width: searchBar.width + 12
                        height: searchBar.height + 12
                        color: '#2e3440ff'
                        radius: 12
                    }

                    ActionMenu {
                        id: actionMenu
                        onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
                        onClosed: {
                            if (pageList.currentItem) {
                                pageList.currentItem.itemGrid.currentIndex = -1;
                            }
                        }
                    }

                    PlasmaComponents.TextField {
                        id: searchBar
                        anchors.top: parent.top
                        anchors.topMargin: units.iconSizes.large
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: units.gridUnit * 60
                        font.pointSize: Math.ceil(dummyHeading.font.pointSize) + 6
                        style: TextFieldStyle {
                            textColor: '#fcfcfc'
                            background: Rectangle {
                                opacity: 0.1
                            }
                        }
                        placeholderText: i18n("<font color='#eceff4'>Type to search</font>")
                        horizontalAlignment: TextInput.AlignHCenter
                        onTextChanged: {
                                runnerModel.query = text;
                        }
                    }

                    PlasmaComponents3.Button {
                        id: backButton
                        anchors.left: searchBar.right
                        anchors.leftMargin: units.iconSizes.large * 3
                        anchors.top: parent.top
                        anchors.topMargin: units.iconSizes.large - 6
                        width: units.gridUnit * 6
                        font.pointSize: Math.ceil(dummyHeading.font.pointSize) + 9
                        text: "Back"
                        icon.name: "backdoor-factory"
                        onClicked: titanusDash.toggle()

                    }


                    Rectangle {
                        id: powerBar
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: units.iconSizes.large
                        color: "#eaeff2"
                        width: units.iconSizes.large * 1.5
                        height: units.iconSizes.large * 5.5
                        radius: 12
                        visible: titanusDash.powerVisible
                        Rectangle {
                            id: buttonPower
                            anchors {
                               horizontalCenter: parent.horizontalCenter
                                top: parent.top
                                margins: 2
                            }
                            width: units.iconSizes.large * 1.25
                            height: width
                            radius: width * 0.5
                            color:  buttonPowerMouseArea.containsMouse ? theme.highlightColor : '#2e3440'

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: buttonPower.width * 0.75
                                source: "system-shutdown"
                            }

                            ToolTip {
                                parent: buttonPower
                                visible: buttonPowerMouseArea.containsMouse
                                text: 'Leave ...'
                            }

                            MouseArea {
                                id: buttonPowerMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:  { pmEngine.performOperation("requestShutDown"); titanusDash.toggle();}
                            }
                        }

                        Rectangle {
                            id: buttonLock
                            anchors {
                               horizontalCenter: parent.horizontalCenter
                                top: buttonPower.bottom
                                margins: 2
                            }

                            width: units.iconSizes.large * 1.25
                            height: width
                            radius: width * 0.5
                            visible: pmEngine.data["Sleep States"]["LockScreen"]
                            color:  buttonLockMouseArea.containsMouse ? theme.highlightColor : '#2e3440'

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: buttonPower.width * 0.75
                                source: "system-lock-screen"
                            }

                            ToolTip {
                                parent: buttonLock
                                visible: buttonLockMouseArea.containsMouse
                                text: 'Lock Screen'
                            }

                            MouseArea {
                                id: buttonLockMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:  { pmEngine.performOperation("lockScreen"); titanusDash.toggle();}
                            }
                        }

                        Rectangle {
                            id: buttonReboot
                            anchors {
                               horizontalCenter: parent.horizontalCenter
                                top: buttonLock.bottom
                                margins: 2
                            }

                            width: units.iconSizes.large * 1.25
                            height: width
                            radius: width * 0.5
                            color:  buttonRebootMouseArea.containsMouse ? theme.highlightColor : '#2e3440'

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: buttonPower.width * 0.75
                                source: "system-reboot"
                            }

                            ToolTip {
                                parent: buttonLock
                                visible: buttonRebootMouseArea.containsMouse
                                text: 'Restart Tridentu-RK'
                            }

                            MouseArea {
                                id: buttonRebootMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:  { pmEngine.performOperation("requestReboot"); titanusDash.toggle();}
                            }
                        }

                        Rectangle {
                            id: buttonLogout
                            anchors {
                               horizontalCenter: parent.horizontalCenter
                                top: buttonReboot.bottom
                                margins: 2
                            }

                            width: units.iconSizes.large * 1.25
                            height: width
                            radius: width * 0.5
                            color:  buttonLogoutMouseArea.containsMouse ? theme.highlightColor : '#2e3440'

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: buttonPower.width * 0.75
                                source: "system-log-out"
                            }

                            ToolTip {
                                parent: buttonLock
                                visible: buttonLogoutMouseArea.containsMouse
                                text: 'Restart Tridentu-RK'
                            }

                            MouseArea {
                                id: buttonLogoutMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:  { pmEngine.performOperation("requestLogout"); titanusDash.toggle();}
                            }
                        }
                    }
                    
                

                    Rectangle {

                        id: mainPage

                        width:   widthScreen * 1
                        height:  heightScreen * 1
                        color: titanusDash.colorWithAlpha('#2e3440', (plasmoid.configuration.backgroundOpacity / 5 )/ 100)
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                        PlasmaComponents3.ScrollView {
                            id: pageListScrollArea
                            width: parent.width
                            height: parent.height
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff


                            ListView {
                                id: pageList
                                anchors.fill: parent
                                snapMode: ListView.SnapOneItem
                                orientation: Qt.Horizontal
                                highlightFollowsCurrentItem: false
                                property int direction: 0
                                
                                onDirectionChanged: {
                                    pageList.currentIndex += direction;
                                }
                                highlightRangeMode : ListView.StrictlyEnforceRange
                                    Connections {
                                        target: GamepadManager
                                        onGamepadConnected: gamepad.deviceId = deviceId
                                    }
                                    
                                    states : [
                                            State  {
                                                when: gamepad.buttonLeft && !titanusDash.gamepadSelecting;
                                                PropertyChanges { target: pageList; direction: -1 }
                                            },
                                            State {
                                                when: gamepad.buttonRight && !titanusDash.gamepadSelecting;
                                                PropertyChanges { target: pageList; direction: 1; }
                                            },
                                            State {
                                                when: gamepad.buttonB;
                                                PropertyChanges { target: titanusDash; gamepadClosing: true } 
                                            },
                                            State {
                                                when: gamepad.buttonStart;
                                                PropertyChanges { target: titanusDash; gamepadMenuVisible: true } 
                                            }
                                    ]

                                    Gamepad {
                                        id: gamepad
                                        deviceId: GamepadManager.connectedGamepads.length > 0 ? GamepadManager.connectedGamepads[0] : -1
                                        
                                    }
                                    highlight: Component {
                                    id: highlight
                                    Rectangle {
                                        width: mainPage.width; height: mainPage.height
                                        color: "transparent"
                                        x: pageList.currentItem.x
                                        Behavior on x {
                                            PropertyAnimation {
                                                duration: plasmoid.configuration.scrollAnimationDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }

                                // Attempts to change index based on next. If next is true, increments,
                                // otherwise decrements. Stops on list boundaries. If activate is true,
                                // also tries to activate what appears to be the next selected gridItem
                                function activateNextPrev(next, activate = true) {
                                    // Carry over row data for smooth transition.
                                    var lastRow = pageList.currentItem.itemGrid.currentRow();
                                    if (activate)
                                        pageList.currentItem.itemGrid.hoverEnabled = false;

                                    var oldItem = pageList.currentItem;
                                    if (next) {
                                        var newIndex = pageList.currentIndex + 1;

                                        if (newIndex < pageList.count) {
                                            pageList.currentIndex = newIndex;
                                        }
                                    } else {
                                        var newIndex = pageList.currentIndex - 1;

                                        if (newIndex >= (titanusDash.showFavorites ? 0 : 1)) {
                                            pageList.currentIndex = newIndex;
                                        }
                                    }

                                    // Give old values to next grid if we changed
                                    if(oldItem != pageList.currentItem && activate) {
                                        pageList.currentItem.itemGrid.hoverEnabled = false;
                                        pageList.currentItem.itemGrid.tryActivate(lastRow, next ? 0 : gridNumCols - 1);
                                    }
                                }



                                delegate: Item {
                                    width:   gridNumCols * cellSizeWidth
                                    height:  gridNumRows * cellSizeHeight
                                    property Item itemGrid: gridView

                                    visible: (titanusDash.showFavorites || titanusDash.searching) ? true : (index != 0)

                                    ItemGridView {
                                        id: gridView

                                        property bool isCurrent: (pageList.currentIndex == index)
                                        hoverEnabled: isCurrent
                                        model: titanusDash.searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)

                                        visible: false
                                        anchors.fill: parent

                                        cellWidth:  cellSizeWidth
                                        cellHeight: cellSizeHeight


                                        dragEnabled: (index == 0) && plasmoid.configuration.showFavorites
                                        onModelChanged: {
                                             visible = (model != null) ? model.count > 0 : false
                                        }

                                        onCurrentIndexChanged: {
                                            if (currentIndex != -1 && !titanusDash.searching) {
                                                pageListScrollArea.focus = true;
                                                focus = true;
                                            }
                                        }

                                        onCountChanged: {
                                            if (index == 0) {
                                                if (titanusDash.searching) {
                                                    currentIndex = 0;
                                                } else if (count == 0) {
                                                    titanusDash.showFavorites = false;
                                                    titanusDash.startIndex = 1;
                                                    if (pageList.currentIndex == 0) {
                                                        pageList.currentIndex = 1;
                                                    }
                                                } else {
                                                    titanusDash.showFavorites = plasmoid.configuration.showFavorites;
                                                    titanusDash.startIndex = 1 //<> (showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1
                                                }
                                            }
                                        }

                                         onKeyNavRight: {
                                            pageList.activateNextPrev(1);
                                        }

                                        onKeyNavLeft: {
                                            pageList.activateNextPrev(0);
                                        }
                                    }
                                    
                                    Kicker.WheelInterceptor {
                                        anchors.fill: parent
                                        z: 1
                                        onWheelMoved: {
                                            //event.accepted = false;
                                            mainMouseArea.wheelDelta = mainMouseArea.scrollByWheel(mainMouseArea.wheelDelta, delta);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    ListView {
                      id: paginationBar   
                      width: model.count * units.iconSizes.medium
                      height: units.largeSpacing
                      orientation: Qt.Horizontal
                      
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: units.gridUnit * -2
                            horizontalCenter: parent.horizontalCenter
                        }
                        
                        delegate: Item {
                            width: units.iconSizes.small
                            height: width   
                            Rectangle {
                                id: pageDelegate
                                property bool isCurrent: (pageList.currentIndex == index)
                                width: parent.width * 0.5
                                height: width
                                radius: width / 2
                                color: "#eceff4"
                                visible: (index != 0)
                                opacity: 0.5
                                states: [
                                    State {
                                        when: pageDelegate.isCurrent

                                        PropertyChanges {
                                            target: pageDelegate
                                            opacity: 1
                                        }

                                    }
                                ]

                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    verticalCenter: parent.verticalCenter
                                    margins: 10
                                }

                                Behavior on opacity {
                                    SmoothedAnimation {
                                        duration: units.longDuration
                                        velocity: 0.01
                                    }
                                }
                                
                                MouseArea {
                                        property int wheelDelta: 0

                                        function scrollByWheel(wheelDelta, eventDelta) {
                                            // magic number 120 for common "one click"
                                            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                                            wheelDelta += eventDelta;
                                            var increment = 0;
                                            while (wheelDelta >= 50) {
                                                wheelDelta -= 50;
                                                increment++;
                                            }
                                            while (wheelDelta <= -50) {
                                                wheelDelta += 50;
                                                increment--;
                                            }
                                            while (increment != 0) {
                                                pageList.activateNextPrev(increment < 0);
                                                increment += (increment < 0) ? 1 : -1;
                                            }
                                            return wheelDelta;
                                        }

                                        anchors.fill: parent
                                        onClicked: pageList.currentIndex = index
                                        onWheel: {
                                            wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y, wheel.angleDelta.x);
                                        }
                                    }
                            }
                        }
                    }

                }
            }
             Component.onCompleted: {
                rootModel.pageSize = gridNumCols*gridNumRows
                pageList.model = rootModel.modelForRow(0);
                paginationBar.model = rootModel.modelForRow(0);
                searchBar.text = "";
                pageListScrollArea.focus = true;
                pageList.currentIndex = startIndex;
                titanusRoot.reset.connect(reset);
            }
    }


    Plasmoid.fullRepresentation: null

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    PlasmaCore.DataSource {
        id: pmEngine
        engine: "powermanagement"
        connectedSources: ["PowerDevil", "Sleep States"]
        function performOperation(what) {
            var service = serviceForSource("PowerDevil")
            var operation = service.operationDescription(what)
            service.startOperationCall(operation)
        }
    }

    Component.onCompleted: {
        plasmoid.setAction("menuedit", i18n("Edit Applications..."));
        rootModel.refreshed.connect(reset);
        //dragHelper.dropped.connect(resetDragSource);
    }
}
