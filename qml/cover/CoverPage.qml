import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/global.js" as Global

CoverBackground {
    Image {
        id: coverImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: activeImageThumb
        smooth: true
    }

    Rectangle {
        id: highlightRect
        anchors.bottom: parent.bottom
        height: label.height + Theme.paddingLarge * 2
        width: parent.width
        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
        visible: coverImg.status == Image.Ready
    }

    Label {
        id: label
        anchors.centerIn: coverImg.status == Image.Ready ? highlightRect : parent
        text: qsTr("pr0gramm")
    }
}


