import QtQuick

// gentle wiggle used in edit mode; resets the rotation when stopped
SequentialAnimation {
    id: w
    property Item target
    property int phase: 0
    loops: Animation.Infinite
    onRunningChanged: if (!running && target) target.rotation = 0
    PauseAnimation { duration: (w.phase % 4) * 45 }
    NumberAnimation { target: w.target; property: "rotation"; to: 1.4; duration: 130; easing.type: Easing.InOutSine }
    NumberAnimation { target: w.target; property: "rotation"; to: -1.4; duration: 260; easing.type: Easing.InOutSine }
    NumberAnimation { target: w.target; property: "rotation"; to: 0; duration: 130; easing.type: Easing.InOutSine }
}
