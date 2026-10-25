import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_columns: columnsSpin.value
    property alias cfg_marginLeft: marginLeftSpin.value
    property alias cfg_marginTop: marginTopSpin.value
    property alias cfg_showCard: showCardBox.checked
    property alias cfg_animIcons: animIconsBox.checked
    property alias cfg_appleOpen: appleOpenBox.checked
    property string cfg_folderSide

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: columnsSpin
            Kirigami.FormData.label: "Столбцов плиток:"
            from: 3; to: 6
        }
        QQC2.ComboBox {
            id: folderSideBox
            Kirigami.FormData.label: "Папки:"
            model: ["Справа", "Слева"]
            Component.onCompleted: currentIndex = cfg_folderSide === "left" ? 1 : 0
            onActivated: cfg_folderSide = currentIndex === 1 ? "left" : "right"
        }
        QQC2.SpinBox {
            id: marginLeftSpin
            Kirigami.FormData.label: "Отступ слева (px @1920):"
            from: 20; to: 400; stepSize: 10
        }
        QQC2.SpinBox {
            id: marginTopSpin
            Kirigami.FormData.label: "Отступ сверху (px @1920):"
            from: 40; to: 400; stepSize: 10
        }
        QQC2.CheckBox {
            id: showCardBox
            Kirigami.FormData.label: "Карточка «Защита»:"
            text: "Показывать"
        }
        QQC2.CheckBox {
            id: animIconsBox
            Kirigami.FormData.label: "Анимации иконок:"
            text: "Включены"
        }
        QQC2.CheckBox {
            id: appleOpenBox
            Kirigami.FormData.label: "Открытие окон:"
            text: "Как у Apple (масштаб + появление)"
        }
    }
}
