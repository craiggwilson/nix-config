import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    popoutWidth: 520

    property var emailList: []
    property var createCommand: ["maskedemail-new"]
    property var actionCommand: []
    property var filteredEmailList: []
    property string copyEmail: ""
    property string description: ""

    function trim(value) {
        return value.replace(/^\s+|\s+$/g, "")
    }

    function parseList(output) {
        const lines = output.split(/\r?\n/).filter(line => line.length > 0)
        if (lines.length === 0)
            return []

        const header = lines[0]
        const starts = [0,
            header.indexOf("For Domain"),
            header.indexOf("Description"),
            header.indexOf("State")]
        if (starts.some(start => start < 0))
            return []

        return lines.slice(1).map(line => {
            const email = root.trim(line.substring(starts[0], starts[1]))
            if (!email)
                return null
            return {
                email: email,
                domain: root.trim(line.substring(starts[1], starts[2])),
                description: root.trim(line.substring(starts[2], starts[3])),
                state: root.trim(line.substring(starts[3]))
            }
        }).filter(email => email !== null)
    }

    function applyFilter() {
        const filter = root.description.toLowerCase().trim()
        root.filteredEmailList = root.emailList.filter(email => {
            if (!filter)
                return true
            return [email.email, email.domain, email.description, email.state]
                .join(" ").toLowerCase().includes(filter)
        })
    }

    function refreshList() {
        listProcess.running = true
    }

    function createEmail() {
        root.createCommand = ["maskedemail-new"]
        if (root.description.length > 0)
            root.createCommand.push("-desc", root.description)
        createProcess.running = true
    }

    function runAction(action, email) {
        root.actionCommand = ["maskedemail-cli", action, email]
        actionProcess.running = true
    }

    function copyEmailToClipboard(email) {
        root.copyEmail = email
        copyProcess.running = true
    }

    Process {
        id: listProcess
        command: ["maskedemail-cli", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.emailList = root.parseList(text)
                root.applyFilter()
            }
        }
    }

    Process {
        id: createProcess
        command: root.createCommand
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.description = ""
                root.refreshList()
            }
        }
    }

    Process {
        id: actionProcess
        command: root.actionCommand
        onExited: function(exitCode) {
            if (exitCode === 0)
                root.refreshList()
        }
    }

    Process {
        id: copyProcess
        command: ["sh", "-c", "printf %s \"$MASKED_EMAIL\" | wl-copy"]
        environment: ({ "MASKED_EMAIL": root.copyEmail })
    }

    Component.onCompleted: root.refreshList()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refreshList()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: "mail"
                size: Theme.iconSize - 4
                color: Theme.surfaceText
            }
        }
    }

    verticalBarPill: Component {
        Column {
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                name: "mail"
                size: Theme.iconSize - 4
                color: Theme.surfaceText
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: "Masked Emails"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        width: parent.width - createButton.width - Theme.spacingS
                        placeholderText: "Description"
                        text: root.description
                        onTextChanged: {
                            root.description = text
                            root.applyFilter()
                        }
                    }

                    DankButton {
                        id: createButton
                        text: "Create"
                        onClicked: root.createEmail()
                    }
                }

                DankFlickable {
                    width: parent.width
                    height: Math.min(contentHeight, 380)
                    contentHeight: emailColumn.height
                    clip: true

                    Column {
                        id: emailColumn
                        width: parent.width
                        spacing: Theme.spacingXS

                        Repeater {
                            model: root.filteredEmailList

                            delegate: Row {
                                width: emailColumn.width
                                spacing: Theme.spacingS

                                Item {
                                    width: parent.width - stateLabel.width - copyButton.width - actionButton.width - deleteButton.width - Theme.spacingS * 4
                                    height: emailDetails.height

                                    Column {
                                        id: emailDetails
                                        width: parent.width
                                        spacing: 2

                                        StyledText {
                                            text: modelData.email
                                            color: Theme.surfaceText
                                        }

                                        StyledText {
                                            text: modelData.description
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            visible: text.length > 0
                                        }

                                        StyledText {
                                            text: modelData.domain
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyEmailToClipboard(modelData.email)
                                    }
                                }

                                StyledText {
                                    id: stateLabel
                                    text: modelData.state
                                    color: Theme.surfaceVariantText
                                }

                                DankActionButton {
                                    id: copyButton
                                    iconName: "content_copy"
                                    iconColor: Theme.surfaceVariantText
                                    buttonSize: 28
                                    tooltipText: "Copy email"
                                    onClicked: root.copyEmailToClipboard(modelData.email)
                                }

                                DankActionButton {
                                    id: actionButton
                                    iconName: modelData.state === "enabled" ? "pause" : "play_arrow"
                                    iconColor: Theme.surfaceVariantText
                                    buttonSize: 28
                                    tooltipText: modelData.state === "enabled" ? "Disable email" : "Enable email"
                                    onClicked: root.runAction(modelData.state === "enabled" ? "disable" : "enable", modelData.email)
                                }

                                DankActionButton {
                                    id: deleteButton
                                    iconName: "delete"
                                    iconColor: Theme.surfaceVariantText
                                    buttonSize: 28
                                    tooltipText: "Delete email"
                                    onClicked: root.runAction("delete", modelData.email)
                                }
                            }
                        }

                        StyledText {
                            text: root.emailList.length === 0
                                ? "No masked emails"
                                : "No matching masked emails"
                            visible: root.filteredEmailList.length === 0
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }
        }
    }
}
