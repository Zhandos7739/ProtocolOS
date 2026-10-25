import QtQuick
import QtQuick.Effects

// Shared wallpaper blur — matches HTML: backdrop-filter: blur(28px) saturate(170%).
Item {
    id: root
    property url wallpaper: ""
    property int texWidth: 960
    property int texHeight: 540

    visible: false
    width: texWidth
    height: texHeight
    layer.enabled: true
    layer.smooth: true
    layer.mipmap: false

    Image {
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.texWidth
        sourceSize.height: root.texHeight
        asynchronous: true
        cache: true
        visible: root.wallpaper != ""
    }

    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 1.0
        blurMax: 40
        saturation: 1.7
        brightness: 0.04
    }
}
