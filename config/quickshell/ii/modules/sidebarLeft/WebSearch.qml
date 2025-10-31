import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property var searchResults: []
    property bool searching: false
    property string lastQuery: ""
    property int currentPage: 1
    property int totalResults: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Search input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.small
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                MaterialSymbol {
                    text: "search"
                    iconSize: Appearance.font.pixelSize.large
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

                    Text {
                        anchors.fill: parent
                        text: "Search the web..."
                        font: searchInput.font
                        color: Appearance.colors.colSubtext
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onReturnPressed: {
                        if (text.trim() !== "") {
                            performSearch(text.trim(), 1)
                        }
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive
                    visible: searchInput.text !== "" || root.searchResults.length > 0

                    contentItem: MaterialSymbol {
                        text: "close"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnErrorContainer
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        searchInput.text = ""
                        root.searchResults = []
                        root.lastQuery = ""
                        root.currentPage = 1
                        root.totalResults = 0
                        searchInput.forceActiveFocus()
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive

                    contentItem: MaterialSymbol {
                        text: "search"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnPrimary
                        anchors.centerIn: parent
                    }

                    onClicked: {
                        if (searchInput.text.trim() !== "") {
                            performSearch(searchInput.text.trim(), 1)
                        }
                    }
                }
            }
        }

        // Pagination controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.searchResults.length > 0 && !root.searching

            RippleButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                buttonRadius: Appearance.rounding.small
                enabled: root.currentPage > 1
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.large
                    color: parent.enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    anchors.centerIn: parent
                }

                onClicked: {
                    if (root.currentPage > 1) {
                        performSearch(root.lastQuery, root.currentPage - 1)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Page " + root.currentPage
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.totalResults > 0 ? (root.totalResults + " results") : ""
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                        visible: root.totalResults > 0
                    }
                }
            }

            RippleButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                buttonRadius: Appearance.rounding.small
                enabled: root.searchResults.length === 10
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.large
                    color: parent.enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    anchors.centerIn: parent
                }

                onClicked: {
                    performSearch(root.lastQuery, root.currentPage + 1)
                }
            }
        }

        // Loading indicator
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searching

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                StyledIndeterminateProgressBar {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Searching for \"" + root.lastQuery + "\"..."
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
            }
        }

        // Search results
        StyledListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searchResults.length > 0 && !root.searching
            spacing: 8

            model: root.searchResults

            delegate: RippleButton {
                width: resultsList.width
                implicitHeight: resultContent.implicitHeight + 24
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                contentItem: ColumnLayout {
                    id: resultContent
                    spacing: 6
                    anchors.margins: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: "link"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colPrimary
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.url
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSecondary
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.description
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer2
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: modelData.description !== ""
                    }
                }

                onClicked: {
                    openUrl(modelData.url)
                }
            }
        }

        // No results message
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searchResults.length === 0 && !root.searching && root.lastQuery !== ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search_off"
                    iconSize: 64
                    color: Appearance.colors.colSubtext
                    opacity: 0.5
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No results found"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try different keywords for \"" + root.lastQuery + "\""
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Placeholder when no search
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searchResults.length === 0 && !root.searching && root.lastQuery === ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "travel_explore"
                    iconSize: 72
                    color: Appearance.colors.colPrimary
                    opacity: 0.5
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Web Search"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Search results will appear here"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    spacing: 4

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "• Type your search query"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "• Press Enter or click search button"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "• Click any result to open in browser"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    // URL opener process
    Process {
        id: urlOpener
        property string pendingUrl: ""
        running: false
        command: ["xdg-open", pendingUrl]
    }

    // Search process using Python script
    Process {
        id: searchProcess
        running: false
        property string query: ""
        property int page: 1
        command: ["python3", Directories.scriptPath + "/websearch/search.py", query, page.toString()]

        stdout: StdioCollector {
            id: searchCollector
            onStreamFinished: {
                parseSearchResults(searchCollector.text)
                root.searching = false
            }
        }

        stderr: StdioCollector {
            id: errorCollector
            onStreamFinished: {
                if (errorCollector.text) {
                    console.log("Search error:", errorCollector.text)
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.searching = false
                root.searchResults = []
                console.log("Search failed with exit code:", code)
            }
        }
    }

    // Functions
    function performSearch(query, page) {
        root.searching = true
        root.searchResults = []
        root.lastQuery = query
        root.currentPage = page
        searchProcess.query = query
        searchProcess.page = page
        searchProcess.running = true
    }

    function parseSearchResults(jsonText) {
        try {
            const data = JSON.parse(jsonText)

            if (data.error) {
                console.log("Search error:", data.error)
                root.searchResults = []
                return
            }

            // Handle both formats: {results: [], totalResults: N} or just []
            if (Array.isArray(data)) {
                root.searchResults = data
                root.totalResults = 0
            } else {
                root.searchResults = data.results || []
                root.totalResults = data.totalResults || 0
            }

            console.log("Found", root.searchResults.length, "results on page", root.currentPage)
            if (root.totalResults > 0) {
                console.log("Total results available:", root.totalResults)
            }
        } catch (e) {
            console.log("Failed to parse search results:", e)
            console.log("Raw output:", jsonText.substring(0, 500))
            root.searchResults = []
        }
    }

    function openUrl(url) {
        console.log("Opening URL:", url)
        urlOpener.pendingUrl = url
        urlOpener.running = true
    }
}
