import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// In-desktop layout sheet (opened from edit bar or settings launcher).
Item {
    id: sheet
    property real s: 1
    property var cfg
    property url wallpaper: ""
    property Item wallLayer: null
    property real wallW: 1920
    property real wallH: 1080
    signal close()

    width: Math.round(420 * s)
    height: col.implicitHeight + 36 * s

    Glass {
        anchors.fill: parent; radius: 24 * sheet.s; tint: 1.25
        wallpaper: sheet.wallpaper; wallLayer: sheet.wallLayer
        wallW: sheet.wallW; wallH: sheet.wallH
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18 * sheet.s
        spacing: 12 * sheet.s

        Text {
            text: "Расположение рабочего стола"
            color: "white"; font.family: "Inter"; font.pixelSize: Math.max(14, 18 * sheet.s); font.weight: Font.Bold
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Столбцы"; color: "white"; font.family: "Inter"; font.pixelSize: Math.max(12, 14 * sheet.s); Layout.fillWidth: true }
            QQC2.SpinBox {
                from: 3; to: 6; value: sheet.cfg.columns
                onValueModified: sheet.cfg.columns = value
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Папки"; color: "white"; font.family: "Inter"; font.pixelSize: Math.max(12, 14 * sheet.s); Layout.fillWidth: true }
            QQC2.ComboBox {
                model: ["Справа", "Слева"]
                currentIndex: sheet.cfg.folderSide === "left" ? 1 : 0
                onActivated: sheet.cfg.folderSide = currentIndex === 1 ? "left" : "right"
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Отступ слева"; color: "white"; font.family: "Inter"; font.pixelSize: Math.max(12, 14 * sheet.s); Layout.fillWidth: true }
            QQC2.SpinBox {
                from: 20; to: 400; stepSize: 10; value: sheet.cfg.marginLeft
                onValueModified: sheet.cfg.marginLeft = value
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Отступ сверху"; color: "white"; font.family: "Inter"; font.pixelSize: Math.max(12, 14 * sheet.s); Layout.fillWidth: true }
            QQC2.SpinBox {
                from: 40; to: 400; stepSize: 10; value: sheet.cfg.marginTop
                onValueModified: sheet.cfg.marginTop = value
            }
        }
        QQC2.CheckBox {
            text: "Карточка «Защита»"
            checked: sheet.cfg.showCard
            onToggled: sheet.cfg.showCard = checked
            contentItem: Text {
                text: parent.text; color: "white"; font.family: "Inter"
                font.pixelSize: Math.max(12, 14 * sheet.s)
                leftPadding: parent.indicator.width + 8
                verticalAlignment: Text.AlignVCenter
            }
        }
        QQC2.CheckBox {
            text: "Анимации иконок"
            checked: sheet.cfg.animIcons
            onToggled: sheet.cfg.animIcons = checked
            contentItem: Text {
                text: parent.text; color: "white"; font.family: "Inter"
                font.pixelSize: Math.max(12, 14 * sheet.s)
                leftPadding: parent.indicator.width + 8
                verticalAlignment: Text.AlignVCenter
            }
        }
        QQC2.CheckBox {
            text: "Открытие как у Apple"
            checked: sheet.cfg.appleOpen
            onToggled: sheet.cfg.appleOpen = checked
            contentItem: Text {
                text: parent.text; color: "white"; font.family: "Inter"
                font.pixelSize: Math.max(12, 14 * sheet.s)
                leftPadding: parent.indicator.width + 8
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Плитки и папки также можно перетаскивать в режиме «Настроить рабочий стол»."
            color: Qt.rgba(1, 1, 1, 0.75)
            font.family: "Inter"; font.pixelSize: Math.max(10, 12 * sheet.s)
        }

        Row {
            spacing: 10 * sheet.s
            Layout.alignment: Qt.AlignRight
            Rectangle {
                height: 34 * sheet.s; width: rst.implicitWidth + 24 * sheet.s; radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.18); border.color: Qt.rgba(1, 1, 1, 0.45)
                Text { id: rst; anchors.centerIn: parent; text: "Сброс"; color: "white"
                    font.family: "Inter"; font.pixelSize: Math.max(11, 13 * sheet.s) }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sheet.cfg.columns = 4
                        sheet.cfg.folderSide = "right"
                        sheet.cfg.marginLeft = 80
                        sheet.cfg.marginTop = 110
                        sheet.cfg.showCard = true
                        sheet.cfg.appleOpen = true
                    }
                }
            }
            Rectangle {
                height: 34 * sheet.s; width: ok.implicitWidth + 28 * sheet.s; radius: height / 2
                color: Qt.rgba(80/255, 1, 170/255, 0.35); border.color: Qt.rgba(140/255, 1, 200/255, 0.7)
                Text { id: ok; anchors.centerIn: parent; text: "Готово"; color: "white"
                    font.family: "Inter"; font.pixelSize: Math.max(11, 14 * sheet.s); font.weight: Font.Bold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheet.close() }
            }
        }
    }
}
