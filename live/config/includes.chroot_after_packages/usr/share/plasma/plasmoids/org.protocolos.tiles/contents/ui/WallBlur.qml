import QtQuick
import QtQuick.Effects

// One shared downscaled+blurred wallpaper texture for all glass tiles.
// Avoids N× MultiEffect wallpaper blurs (was the heaviest desktop cost).
Item {
    id: root
    property url wallpaper: ""
    property int texWidth: 960
    property int texHeight: 540

    // Invisible; consumers sample via ShaderEffectSource(sourceItem: root).
    visible: false
    width: texWidth
    height: texHeight
    layer.enabled: true
    layer.smooth: true
    layer.mipmap: false

    Image {
        id: img
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
        blurMax: 28
        saturation: 0.75
        brightness: 0.06
    }
}
