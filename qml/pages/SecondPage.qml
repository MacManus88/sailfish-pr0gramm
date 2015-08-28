import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import "../js/global.js" as Global

Page {
    id: page

    property var modelData

    property string imageProperty: modelData ? ("http://img.pr0gramm.com/" + modelData.image) : ""
    property string thumbProperty: modelData ? ("http://thumb.pr0gramm.com/" + modelData.thumb) : ""
    onThumbPropertyChanged: activeImageThumb = thumbProperty
    property string idProperty: modelData ? modelData.id : ""
    property string userProperty: modelData ? modelData.user : ""
    property string tagProperty: ""
    property string commentProperty: ""
    property bool beliebtProperty: false

    Column {
        id: column
        spacing: Theme.paddingLarge
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge

        Text{
            width: parent.width
            text: "User: " + userProperty + " "
            color: Theme.secondaryHighlightColor
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Text {
            width: parent.width
            text: tagProperty
            color: Theme.secondaryHighlightColor
            font.pixelSize: 20
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Item {
        id: loaderClip
        anchors.top: column.bottom
        anchors.bottom: row.top
        anchors.margins: Theme.paddingLarge
        width: parent.width
        clip: true

        Loader {
            id: loaderItem
            anchors.fill: parent
            property bool isWebm: /webm$/.test(imageProperty)
            property bool isGif: /gif$/.test(imageProperty)
            sourceComponent: isWebm ? webmComponent : (isGif ? gifComponent : imageComponent)
            active: true
        }
    }

    Row {
        id: row
        spacing: Theme.paddingLarge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
            text: "Zurück"
            onClicked: {
                request_prev()
            }
        }
        Button {
            text: "Weiter"
            onClicked: {
                request_next()
            }
        }
    }

    Component.onCompleted: {
        request_tags()
    }

    Component {
        id: webmComponent
        MouseArea {
            id: mArea

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                source: thumbProperty
            }

            Rectangle {
                anchors.verticalCenter: mCol.verticalCenter
                width: parent.width
                height: mCol.height + Theme.paddingLarge * 2
                color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
            }

            Column {
                id: mCol
                width: parent.width
                spacing: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "image://theme/icon-launcher-browser"
                }

                Label {
                    width: parent.width - Theme.paddingLarge * 2
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Application can't play webm videos. Click to open it in web browser."
                    font.bold: mArea.pressed && mArea.containsMouse
                }
            }
            onClicked: {
                Qt.openUrlExternally(imageProperty)
            }
        }
    }

    Component {
        id: gifComponent
        AnimatedImage {
            source: imageProperty
            fillMode: Image.PreserveAspectFit
            verticalAlignment: Image.AlignVCenter
            horizontalAlignment: Image.AlignHCenter
            cache: true
            smooth: true
        }
    }

    Component {
        id: imageComponent
        ImageViewer {
            source: imageProperty
            fit: page.isPortrait ? Fit.Width : Fit.Height
            enableZoom: true
        }
    }

    Timer {
        interval: 100 // wait 100msec
        repeat: false
        running: idProperty ? true : false // reload comments when id changed
        onTriggered: { pageStack.pushAttached(comments); }
    }

    function request_tags() {
        tagProperty = ""

        Global.api_request("api/items/info?itemId=" + idProperty,
                           function(json) {
                               for (var i = 0; i < json.tags.length; i++) {
                                   tagProperty += JSON.stringify(json.tags[i].tag) + ' | '
                               }
                               tagProperty = tagProperty.substring(0, tagProperty.length - 3)
                               tagProperty = tagProperty.replace(/"/g,"")
                           }
                          )
    }

    function request_next() {
        Global.api_request("api/items/get?flags=1" + (beliebtProperty ? "&promoted=1" : ""),
                           function(json) {
                               for (var i = 0; i < json.items.length; i++) {
                                   if (idProperty === JSON.stringify(json.items[i].id)){
                                       modelData = json.items[i+1]
                                       request_tags()
                                       break
                                   }
                               }
                           }
                          )
    }

    function request_prev() {
        Global.api_request("api/items/get?flags=1" + (beliebtProperty ? "&promoted=1" : ""),
                           function(json) {
                               for (var i = 0; i < json.items.length; i++) {
                                   if (idProperty === JSON.stringify(json.items[i].id) && i > 0){
                                       modelData = json.items[i-1]
                                       request_tags()
                                       break
                                   }
                               }
                           }
                          )
    }

    Component {
        id: comments
        Page {
            SilicaListView {
                id: view
                anchors.fill: parent
                anchors.margins: Theme.paddingLarge

                property var allcomments: []
                property var commendsdict: ({})

                onAllcommentsChanged: {
                    var comments = []
                    var m_commendsdict = {}
                    for (var i = 0; i < allcomments.length; i++) {
                        var parentId = allcomments[i].parent
                        if (parentId == 0) {
                            comments.push(allcomments[i])
                        }
                        else {
                            var commends = []
                            if (m_commendsdict.hasOwnProperty(parentId)) {
                                commends = m_commendsdict[parentId]
                            }
                            commends.push(allcomments[i])
                            m_commendsdict[parentId] = commends
                        }
                    }
                    commendsdict = m_commendsdict
                    comments.sort(function(a, b) {
                        return (b.up - b.down) - (a.up - a.down);
                    });
                    model = comments
                }

                delegate: commentDelegate

                VerticalScrollDecorator {}
            }

            Component.onCompleted: {
                comment_request()
            }

            function comment_request(){
                Global.api_request("api/items/info?itemId="+idProperty,
                                   function(json) {
                                       view.allcomments = json.comments
                                   }
                                  )
            }

            Component {
                id: commentDelegate
                Column {
                    id: comColumn
                    anchors.left: parent ? parent.left : undefined
                    anchors.right: parent ? parent.right : undefined
                    anchors.leftMargin: Theme.paddingSmall + (parent ? parent.anchors.leftMargin : 0)
                    Label {
                        width: parent.width
                        text: modelData.content
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        width: parent.width
                        text: modelData.name + " * " + (modelData.up - modelData.down) + " Punkte"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                    Repeater {
                        width: parent.width
                        model: {
                            if (view.commendsdict.hasOwnProperty(modelData.id)) {
                                var commends = view.commendsdict[modelData.id]
                                commends.sort(function(a, b) {
                                    return (b.up - b.down) - (a.up - a.down);
                                })
                                return commends
                            }
                            else {
                                return 0
                            }
                        }
                        delegate: commentDelegate
                    }
                }
            }
        }
    }
}
