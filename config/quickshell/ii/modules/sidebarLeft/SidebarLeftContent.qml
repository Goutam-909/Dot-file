import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool webSearchEnabled: Config.options.sidebar.websearch.enable
    property bool wallhavenEnabled: Config.options.sidebar.wallhaven.enable

    property var tabButtonList: [
        ...(root.webSearchEnabled ? [{"icon": "travel_explore", "name": "Web Search"}] : []),
        ...(root.wallhavenEnabled ? [{"icon": "wallpaper", "name": "Wallpapers"}] : [])
    ]
    property int selectedTab: 0
    property int tabCount: swipeView.count

    function focusActiveItem() {
        if (swipeView.currentItem) {
            swipeView.currentItem.forceActiveFocus()
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabCount - 1)
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0)
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Tab) {
                root.selectedTab = (root.selectedTab + 1) % root.tabCount;
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Backtab) {
                root.selectedTab = (root.selectedTab - 1 + root.tabCount) % root.tabCount;
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: sidebarPadding

        spacing: sidebarPadding

        PrimaryTabBar { // Tab strip
            id: tabBar
            visible: root.tabButtonList.length > 1
            tabButtonList: root.tabButtonList
            externalTrackedTab: root.selectedTab
            function onCurrentIndexChanged(currentIndex) {
                root.selectedTab = currentIndex
            }
        }

        SwipeView { // Content pages
            id: swipeView
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            currentIndex: tabBar.externalTrackedTab
            onCurrentIndexChanged: {
                tabBar.enableIndicatorAnimation = true
                root.selectedTab = currentIndex
            }

            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            // Dynamically add items based on config
            contentChildren: [
                ...(root.webSearchEnabled ? [webSearchLoader.createObject(swipeView)] : []),
                ...(root.wallhavenEnabled ? [wallhavenLoader.createObject(swipeView)] : [])
            ]
        }

        Component {
            id: webSearchLoader
            WebSearch {}
        }

        Component {
            id: wallhavenLoader
            WallhavenView {}
        }
    }
}
