import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property string currentCategory: ""
    property string searchQuery: ""
    property int currentPage: 1

    // Safe URL opener - uses default browser
    Component {
        id: browserOpener
        Process {
            property string targetUrl: ""
            running: true
            // Firefox opens in new tab, Chromium in new window
            // Both are sandboxed and safe
            command: {
                // Try firefox first (better for background tabs)
                return ["firefox", targetUrl]
            }

            onExited: (code) => {
                if (code !== 0) {
                    // Fallback to xdg-open if firefox not available
                    var fallback = fallbackOpener.createObject(root, {
                        "targetUrl": targetUrl
                    })
                }
                destroy()
            }
        }
    }

    Component {
        id: fallbackOpener
        Process {
            property string targetUrl: ""
            running: true
            command: ["xdg-open", targetUrl]
            onExited: destroy()
        }
    }

    // Function to open URL in browser
    function openUrl(url) {
        // Basic validation - only wallhaven URLs
        if (typeof url !== 'string' || url.length === 0) {
            console.error("Invalid URL")
            return
        }

        if (!url.startsWith("https://wallhaven.cc/") &&
            !url.startsWith("https://w.wallhaven.cc/")) {
            console.error("Not a wallhaven URL:", url)
            return
            }

            console.log("Opening in browser:", url)
            browserOpener.createObject(root, { "targetUrl": url })
    }

    Connections {
        target: Wallhaven
        function onWallpapersLoaded() {
            if (wallpaperGrid.visible) {
                wallpaperGrid.positionViewAtBeginning()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Category buttons - Toplist, Latest, Random
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ListModel {
                    ListElement { name: "Toplist"; icon: "trending_up"; category: "toplist" }
                    ListElement { name: "Latest"; icon: "schedule"; category: "latest" }
                    ListElement { name: "Random"; icon: "shuffle"; category: "random" }
                }

                delegate: RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    buttonRadius: Appearance.rounding.small
                    toggled: root.currentCategory === model.category
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    colBackgroundToggled: Appearance.colors.colPrimaryContainer
                    colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover
                    colRippleToggled: Appearance.colors.colPrimaryContainerActive

                    contentItem: RowLayout {
                        spacing: 8
                        anchors.centerIn: parent

                        MaterialSymbol {
                            text: model.icon
                            iconSize: Appearance.font.pixelSize.large
                            color: parent.parent.toggled ?
                            Appearance.colors.colOnPrimaryContainer :
                            Appearance.colors.colOnLayer2
                        }

                        StyledText {
                            text: model.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: parent.parent.parent.toggled ?
                            Appearance.colors.colOnPrimaryContainer :
                            Appearance.colors.colOnLayer2
                        }
                    }

                    onClicked: {
                        root.currentCategory = model.category
                        root.searchQuery = ""
                        root.currentPage = 1
                        searchInput.text = ""
                        Wallhaven.fetchWallpapers(model.category, "", 1)
                    }
                }
            }
        }

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.small
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                MaterialSymbol {
                    text: "image_search"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnLayer2
                    selectionColor: Appearance.colors.colPrimary
                    selectedTextColor: Appearance.colors.colOnPrimary
                    verticalAlignment: TextInput.AlignVCenter
                    maximumLength: 200

                    Text {
                        anchors.fill: parent
                        text: "Search wallpapers..."
                        font: searchInput.font
                        color: Appearance.colors.colSubtext
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onReturnPressed: {
                        const trimmedText = text.trim()
                        if (trimmedText !== "") {
                            root.searchQuery = trimmedText
                            root.currentCategory = "search"
                            root.currentPage = 1
                            Wallhaven.fetchWallpapers("search", root.searchQuery, 1)
                        }
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    visible: searchInput.text !== ""

                    contentItem: MaterialSymbol {
                        text: "close"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        searchInput.text = ""
                        root.searchQuery = ""
                        searchInput.forceActiveFocus()
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive

                    contentItem: MaterialSymbol {
                        text: "search"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnPrimary
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        const trimmedText = searchInput.text.trim()
                        if (trimmedText !== "") {
                            root.searchQuery = trimmedText
                            root.currentCategory = "search"
                            root.currentPage = 1
                            Wallhaven.fetchWallpapers("search", root.searchQuery, 1)
                        }
                    }
                }
            }
        }

        // Pagination controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Wallhaven.wallpapers.length > 0 && !Wallhaven.loading

            RippleButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                enabled: root.currentPage > 1

                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.large
                    color: parent.enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    anchors.centerIn: parent
                }

                onClicked: {
                    if (root.currentPage > 1) {
                        root.currentPage--
                        Wallhaven.fetchWallpapers(root.currentCategory, root.searchQuery, root.currentPage)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small

                StyledText {
                    anchors.centerIn: parent
                    text: "Page " + root.currentPage
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
            }

            RippleButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                    anchors.centerIn: parent
                }

                onClicked: {
                    root.currentPage++
                    Wallhaven.fetchWallpapers(root.currentCategory, root.searchQuery, root.currentPage)
                }
            }
        }

        // Loading indicator
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Wallhaven.loading && Wallhaven.wallpapers.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                StyledIndeterminateProgressBar {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Loading wallpapers..."
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
            }
        }

        // Error message
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Wallhaven.errorMessage !== "" && Wallhaven.wallpapers.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "error"
                    iconSize: 64
                    color: Appearance.colors.colError
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Error loading wallpapers"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colError
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Wallhaven.errorMessage
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Wallpaper grid
        GridView {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Wallhaven.loading && Wallhaven.wallpapers.length > 0

            cellWidth: width / 2 - 4
            cellHeight: cellWidth * 0.6
            clip: true

            model: Wallhaven.wallpapers

            ScrollBar.vertical: StyledScrollBar {}

            delegate: Item {
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                RippleButton {
                    anchors.fill: parent
                    anchors.margins: 4
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active

                    contentItem: Item {
                        Rectangle {
                            id: thumbnailContainer
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            clip: true
                            color: Appearance.colors.colLayer1

                            StyledImage {
                                id: thumbnail
                                anchors.fill: parent
                                source: modelData.thumbs.small
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true

                                StyledIndeterminateProgressBar {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    visible: thumbnail.status === Image.Loading
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.colors.colScrim
                                opacity: parent.parent.parent.hovered ? 0.85 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "open_in_browser"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: "white"
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.resolution
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: "white"
                                    }

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 12

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "visibility"
                                                iconSize: Appearance.font.pixelSize.small
                                                color: "white"
                                            }
                                            StyledText {
                                                text: modelData.views
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: "white"
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4
                                            MaterialSymbol {
                                                text: "favorite"
                                                iconSize: Appearance.font.pixelSize.small
                                                color: "white"
                                            }
                                            StyledText {
                                                text: modelData.favorites
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: "white"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    onClicked: {
                        root.openUrl(modelData.url)
                    }
                }
            }
        }

        // Placeholder - shown when nothing loaded
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Wallhaven.wallpapers.length === 0 && !Wallhaven.loading && Wallhaven.errorMessage === ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "wallpaper"
                    iconSize: 72
                    color: Appearance.colors.colPrimary
                    opacity: 0.5
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wallhaven"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Click a button above to browse wallpapers"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Or search for specific wallpapers"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
