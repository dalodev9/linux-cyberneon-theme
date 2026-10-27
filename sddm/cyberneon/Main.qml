import QtQuick
import QtQuick.Controls

// Cyber Neon - a synthwave / cyberpunk SDDM theme.
// Everything is drawn with plain QtQuick items (no shaders, no images except a tiny
// scanline tile), so it also renders with the software backend in a VM.

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#07010f"
    clip: true

    // ---- scaling: all sizes are written for 1920x1080 and multiplied by u ----
    readonly property real u: Math.min(width / 1920, height / 1080)

    // ---- settings from theme.conf, with fallbacks ----
    function cfg(name, fallback) {
        var v = config[name]
        return (v !== undefined && v !== null && v !== "") ? v : fallback
    }
    readonly property string fontName: cfg("font", "monospace")
    readonly property color cPink: cfg("pink", "#ff2a6d")
    readonly property color cCyan: cfg("cyan", "#05d9e8")
    readonly property color cYellow: cfg("yellow", "#f9f002")
    readonly property color cText: cfg("text", "#d1f7ff")
    readonly property string titleText: cfg("title", "ACCESS TERMINAL")
    readonly property string subtitleText: cfg("subtitle", "AUTHENTICATION REQUIRED")

    // lockmode is only used to render still images for the i3 lock screen:
    //   ""      normal login screen
    //   "panel" static scene + panel frame (no live clock, no live fields)
    //   "bg"    static scene only
    readonly property string lockMode: cfg("lockmode", "")
    // where the unlock ring should sit, as fractions of the screen (read by the render tool)
    readonly property real ringFx: (panel.x + panel.width / 2) / width
    readonly property real ringFy: (panel.y + content.y + ringHolder.y + ringHolder.height / 2) / height

    // ---- scene geometry ----
    readonly property real horizonY: height * 0.62
    readonly property color skyTop: "#05010d"
    readonly property color skyLow: "#2b0b52"

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }
    function skyAt(y) {
        return mix(skyTop, skyLow, Math.max(0, Math.min(1, y / horizonY)))
    }

    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // =====================================================================
    //  INLINE COMPONENTS
    // =====================================================================

    // L-shaped HUD corner
    component Bracket: Item {
        id: br
        property color col: root.cPink
        property bool atRight: false
        property bool atBottom: false
        width: 30 * root.u
        height: 30 * root.u
        Rectangle {
            width: parent.width
            height: 3 * root.u
            color: br.col
            y: br.atBottom ? parent.height - height : 0
        }
        Rectangle {
            width: 3 * root.u
            height: parent.height
            color: br.col
            x: br.atRight ? parent.width - width : 0
        }
    }

    // Small caption above a field
    component FieldLabel: Text {
        color: root.cCyan
        font.family: root.fontName
        font.pixelSize: 15 * root.u
        font.letterSpacing: 4 * root.u
        opacity: 0.85
        topPadding: 10 * root.u
    }

    // Text input with a neon underline
    component HudField: TextField {
        id: fld
        width: parent ? parent.width : 400
        height: 54 * root.u
        font.family: root.fontName
        font.pixelSize: 24 * root.u
        color: root.cText
        selectionColor: root.cPink
        selectedTextColor: "#07010f"
        placeholderTextColor: Qt.rgba(0.82, 0.97, 1.0, 0.3)
        leftPadding: 16 * root.u
        rightPadding: 16 * root.u
        verticalAlignment: TextInput.AlignVCenter
        background: Rectangle {
            color: "#14042b"
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2 * root.u
                color: fld.activeFocus ? root.cPink : root.cCyan
            }
        }
    }

    // Outlined button that fills with colour on hover
    component HudButton: Item {
        id: btn
        property string label: ""
        property color accent: root.cPink
        signal clicked()
        width: parent ? parent.width : 400
        height: 58 * root.u
        Rectangle {
            anchors.fill: parent
            color: ma.pressed ? Qt.darker(btn.accent, 1.4) : (ma.containsMouse ? btn.accent : "transparent")
            border.color: btn.accent
            border.width: 2 * root.u
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Text {
            anchors.centerIn: parent
            text: btn.label
            color: ma.containsMouse ? "#07010f" : btn.accent
            font.family: root.fontName
            font.pixelSize: 22 * root.u
            font.bold: true
            font.letterSpacing: 6 * root.u
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // Text-style button for power actions
    component PowerLink: Text {
        id: pl
        signal clicked()
        color: pma.containsMouse ? root.cYellow : root.cCyan
        font.family: root.fontName
        font.pixelSize: 18 * root.u
        font.letterSpacing: 3 * root.u
        MouseArea {
            id: pma
            anchors.fill: parent
            anchors.margins: -8 * root.u
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pl.clicked()
        }
    }

    // =====================================================================
    //  BACKGROUND SCENE
    // =====================================================================

    // Sky
    Rectangle {
        id: sky
        width: root.width
        height: root.horizonY
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.skyTop }
            GradientStop { position: 1.0; color: root.skyLow }
        }
    }

    // Stars
    Repeater {
        model: 60
        Rectangle {
            readonly property real seedA: ((index * 7919) % 997) / 997
            readonly property real seedB: ((index * 104729) % 991) / 991
            x: seedA * root.width
            y: seedB * root.horizonY * 0.75
            width: (index % 5 === 0 ? 3 : 2) * root.u
            height: width
            radius: width / 2
            color: index % 3 === 0 ? root.cCyan : "#ffffff"
            opacity: 0.25 + (index % 4) * 0.12
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: index % 3 === 0 && root.lockMode === ""
                NumberAnimation { to: 0.1; duration: 1200 + (index % 7) * 300 }
                NumberAnimation { to: 0.7; duration: 1200 + (index % 5) * 300 }
            }
        }
    }

    // Sun
    Item {
        id: sun
        readonly property real d: 460 * root.u
        width: d
        height: d
        x: root.width * 0.33 - d / 2
        y: root.horizonY - d * 0.78

        // soft halo (stacked translucent discs)
        Repeater {
            model: 5
            Rectangle {
                readonly property real grow: (index + 1) * 26 * root.u
                width: sun.d + grow
                height: sun.d + grow
                radius: width / 2
                x: -grow / 2
                y: -grow / 2
                color: root.cPink
                opacity: 0.045
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cYellow }
                GradientStop { position: 0.5; color: root.cPink }
                GradientStop { position: 1.0; color: "#b5179e" }
            }
        }
        // horizontal slits in the lower half, coloured like the sky behind them
        Repeater {
            model: 7
            Rectangle {
                readonly property real cy: sun.d * (0.46 + index * 0.05)
                readonly property real dy: cy - sun.d / 2
                readonly property real chord: 2 * Math.sqrt(Math.max(0, (sun.d / 2) * (sun.d / 2) - dy * dy))
                width: chord + 4
                height: (2 + index * 2.2) * root.u
                x: (sun.d - width) / 2
                y: cy
                color: root.skyAt(sun.y + cy)
            }
        }
    }

    // Glow band just above the horizon
    Rectangle {
        y: root.horizonY - 150 * root.u
        width: root.width
        height: 150 * root.u
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00ff2a6d" }
            GradientStop { position: 1.0; color: "#55ff2a6d" }
        }
    }

    // Ground with moving perspective grid
    Rectangle {
        id: ground
        y: root.horizonY
        width: root.width
        height: root.height - root.horizonY
        clip: true
        property real phase: 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1c0638" }
            GradientStop { position: 1.0; color: "#07010f" }
        }
        NumberAnimation on phase {
            from: 0
            to: 1
            duration: 2600
            loops: Animation.Infinite
            running: root.lockMode === ""
        }

        // lines running across (they move toward the viewer)
        Repeater {
            model: 16
            Rectangle {
                readonly property real t: (index + ground.phase) / 16
                y: ground.height * Math.pow(t, 2.3)
                width: ground.width
                height: Math.max(1, 2.5 * root.u * (0.4 + t))
                color: root.cPink
                opacity: 0.10 + 0.75 * t
            }
        }
        // lines converging on the vanishing point
        Repeater {
            model: 27
            Rectangle {
                readonly property real dx: (index - 13) * root.width * 0.085
                readonly property real len: Math.sqrt(dx * dx + ground.height * ground.height)
                width: Math.max(1, 2 * root.u)
                height: len
                x: ground.width / 2 - width / 2
                y: 0
                transformOrigin: Item.Top
                rotation: -Math.atan2(dx, ground.height) * 180 / Math.PI
                color: root.cPink
                opacity: 0.45
            }
        }
    }

    // Horizon line with a fake glow
    Repeater {
        model: [ { h: 26, a: 0.06 }, { h: 12, a: 0.14 }, { h: 4, a: 0.9 } ]
        Rectangle {
            width: root.width
            height: modelData.h * root.u
            y: root.horizonY - height / 2
            color: root.cPink
            opacity: modelData.a
        }
    }

    // Vignette
    Rectangle {
        width: parent.width * 0.25
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#99000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }
    Rectangle {
        width: parent.width * 0.25
        height: parent.height
        x: parent.width - width
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#99000000" }
        }
    }

    // =====================================================================
    //  CLOCK (top left) with glitch effect
    // =====================================================================
    Item {
        id: clockBlock
        visible: root.lockMode === ""
        x: root.width * 0.06
        y: root.height * 0.07
        width: 800 * root.u
        height: 300 * root.u
        property real glitch: 3 * root.u
        readonly property string timeStr: Qt.formatTime(root.now, "hh:mm")

        Text {
            x: -clockBlock.glitch
            text: clockBlock.timeStr
            color: root.cPink
            opacity: 0.85
            font.family: root.fontName
            font.pixelSize: 170 * root.u
            font.bold: true
        }
        Text {
            x: clockBlock.glitch
            text: clockBlock.timeStr
            color: root.cCyan
            opacity: 0.85
            font.family: root.fontName
            font.pixelSize: 170 * root.u
            font.bold: true
        }
        Text {
            id: clockMain
            text: clockBlock.timeStr
            color: "#ffffff"
            font.family: root.fontName
            font.pixelSize: 170 * root.u
            font.bold: true
        }
        Text {
            anchors.top: clockMain.bottom
            anchors.topMargin: -6 * root.u
            text: Qt.formatDate(root.now, "dddd  dd . MMMM . yyyy").toUpperCase()
            color: root.cCyan
            font.family: root.fontName
            font.pixelSize: 26 * root.u
            font.letterSpacing: 5 * root.u
        }

        Timer {
            interval: 3500
            running: true
            repeat: true
            onTriggered: glitchAnim.restart()
        }
        SequentialAnimation {
            id: glitchAnim
            NumberAnimation { target: clockBlock; property: "glitch"; to: 18 * root.u; duration: 50 }
            NumberAnimation { target: clockBlock; property: "glitch"; to: -9 * root.u; duration: 60 }
            NumberAnimation { target: clockBlock; property: "glitch"; to: 3 * root.u; duration: 90 }
        }
    }

    // =====================================================================
    //  LOGIN PANEL (right)
    // =====================================================================
    Item {
        id: panel
        visible: root.lockMode !== "bg"
        width: 580 * root.u
        height: content.implicitHeight + 100 * root.u
        property real shake: 0
        x: root.width * 0.73 - width / 2 + shake
        y: (root.height - height) / 2 - 30 * root.u

        Rectangle {
            anchors.fill: parent
            color: "#d90a0216"
            border.width: 1
            border.color: Qt.rgba(root.cCyan.r, root.cCyan.g, root.cCyan.b, 0.35)
        }
        Bracket { x: -3 * root.u; y: -3 * root.u; col: root.cPink }
        Bracket { x: parent.width - width + 3 * root.u; y: -3 * root.u; col: root.cCyan; atRight: true }
        Bracket { x: -3 * root.u; y: parent.height - height + 3 * root.u; col: root.cCyan; atBottom: true }
        Bracket {
            x: parent.width - width + 3 * root.u
            y: parent.height - height + 3 * root.u
            col: root.cPink
            atRight: true
            atBottom: true
        }

        Column {
            id: content
            x: 50 * root.u
            y: 46 * root.u
            width: parent.width - 100 * root.u
            spacing: 12 * root.u

            // header with blinking cursor
            Row {
                spacing: 0
                Text {
                    text: "// " + root.titleText
                    color: root.cCyan
                    font.family: root.fontName
                    font.pixelSize: 26 * root.u
                    font.bold: true
                    font.letterSpacing: 4 * root.u
                }
                Text {
                    id: cursorBlink
                    visible: root.lockMode === ""
                    text: "_"
                    color: root.cPink
                    font.family: root.fontName
                    font.pixelSize: 26 * root.u
                    font.bold: true
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }
            Text {
                text: root.subtitleText
                color: root.cPink
                font.family: root.fontName
                font.pixelSize: 15 * root.u
                font.letterSpacing: 4 * root.u
            }
            Item { width: 1; height: 8 * root.u }

            FieldLabel { text: "USER_ID" }
            HudField {
                id: userField
                text: userModel.lastUser
                placeholderText: "username"
                KeyNavigation.tab: passField
                onAccepted: passField.forceActiveFocus()
            }

            FieldLabel { text: "PASSPHRASE" }
            Item {
                id: ringHolder
                visible: root.lockMode !== ""
                width: 1
                height: 290 * root.u
            }
            Text {
                visible: root.lockMode !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "TYPE PASSPHRASE + ENTER"
                color: root.cPink
                opacity: 0.85
                font.family: root.fontName
                font.pixelSize: 15 * root.u
                font.letterSpacing: 4 * root.u
            }
            HudField {
                id: passField
                visible: root.lockMode === ""
                echoMode: TextInput.Password
                passwordCharacter: "*"
                placeholderText: "********"
                KeyNavigation.tab: sessionBox
                onAccepted: root.doLogin()
            }

            FieldLabel { text: "SESSION"; visible: root.lockMode === "" }
            ComboBox {
                id: sessionBox
                visible: root.lockMode === ""
                width: parent.width
                height: 54 * root.u
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                font.family: root.fontName
                font.pixelSize: 22 * root.u
                KeyNavigation.tab: loginButton

                delegate: ItemDelegate {
                    width: sessionBox.width
                    height: 46 * root.u
                    highlighted: sessionBox.highlightedIndex === index
                    contentItem: Text {
                        text: model.name
                        color: highlighted ? root.cPink : root.cText
                        font: sessionBox.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: highlighted ? "#2a0a4a" : "#14042b" }
                }
                indicator: Text {
                    x: sessionBox.width - width - 16 * root.u
                    y: (sessionBox.height - height) / 2
                    text: "v"
                    color: root.cCyan
                    font.family: root.fontName
                    font.pixelSize: 20 * root.u
                    font.bold: true
                }
                contentItem: Text {
                    leftPadding: 16 * root.u
                    rightPadding: 40 * root.u
                    text: sessionBox.displayText
                    color: root.cText
                    font: sessionBox.font
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "#14042b"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2 * root.u
                        color: sessionBox.activeFocus ? root.cPink : root.cCyan
                    }
                }
                popup: Popup {
                    y: sessionBox.height
                    width: sessionBox.width
                    implicitHeight: contentItem.implicitHeight + 2
                    padding: 1
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        currentIndex: sessionBox.highlightedIndex
                    }
                    background: Rectangle {
                        color: "#14042b"
                        border.color: root.cCyan
                        border.width: 1
                    }
                }
            }

            // status line
            Text {
                id: status
                visible: root.lockMode === ""
                width: parent.width
                height: 30 * root.u
                text: ""
                color: root.cCyan
                font.family: root.fontName
                font.pixelSize: 19 * root.u
                font.bold: true
                font.letterSpacing: 3 * root.u
                verticalAlignment: Text.AlignVCenter
            }

            HudButton {
                id: loginButton
                visible: root.lockMode === ""
                label: "LOGIN"
                accent: root.cPink
                onClicked: root.doLogin()
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: root.lockMode === ""
                text: "CAPS LOCK IS ON"
                color: root.cYellow
                font.family: root.fontName
                font.pixelSize: 15 * root.u
                font.letterSpacing: 3 * root.u
                opacity: keyboard.capsLock ? 1 : 0
            }
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: panel; property: "shake"; to: -22 * root.u; duration: 45 }
            NumberAnimation { target: panel; property: "shake"; to: 22 * root.u; duration: 70 }
            NumberAnimation { target: panel; property: "shake"; to: -14 * root.u; duration: 60 }
            NumberAnimation { target: panel; property: "shake"; to: 14 * root.u; duration: 60 }
            NumberAnimation { target: panel; property: "shake"; to: 0; duration: 50 }
        }
    }

    // =====================================================================
    //  FOOTER + POWER
    // =====================================================================
    Text {
        visible: root.lockMode === ""
        x: 40 * root.u
        y: root.height - height - 34 * root.u
        text: "NODE // " + sddm.hostName.toUpperCase() + "   |   CYBERNEON"
        color: root.cCyan
        opacity: 0.6
        font.family: root.fontName
        font.pixelSize: 16 * root.u
        font.letterSpacing: 3 * root.u
    }
    Row {
        visible: root.lockMode === ""
        x: root.width - width - 40 * root.u
        y: root.height - height - 30 * root.u
        spacing: 36 * root.u
        PowerLink {
            text: "[ SUSPEND ]"
            visible: sddm.canSuspend
            onClicked: sddm.suspend()
        }
        PowerLink {
            text: "[ REBOOT ]"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }
        PowerLink {
            text: "[ SHUTDOWN ]"
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }

    // CRT scanlines over everything
    Image {
        anchors.fill: parent
        source: "assets/scanlines.png"
        fillMode: Image.Tile
        opacity: 0.35
        z: 100
    }

    // =====================================================================
    //  LOGIC
    // =====================================================================
    function doLogin() {
        if (userField.text === "")
            return
        status.text = "AUTHENTICATING..."
        status.color = root.cCyan
        sddm.login(userField.text, passField.text, sessionBox.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            status.text = "ACCESS DENIED"
            status.color = root.cPink
            passField.text = ""
            passField.forceActiveFocus()
            shakeAnim.restart()
        }
        function onLoginSucceeded() {
            status.text = "ACCESS GRANTED"
            status.color = root.cCyan
        }
    }

    Component.onCompleted: {
        if (userField.text === "")
            userField.forceActiveFocus()
        else
            passField.forceActiveFocus()
    }
}
