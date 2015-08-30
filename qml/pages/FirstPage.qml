import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/global.js" as Global

Page {
    id: page

    property bool beliebt: true
    onStatusChanged: {
        if (status == PageStatus.Active) {
            activeImageThumb = ""
        }
    }

    SilicaGridView {
        id: view
        anchors.fill: parent
        cellWidth: width / 4
        cellHeight: width / 4

        PullDownMenu {
            //MenuItem {
            //    text: qsTr("Suchen")
            //Muss noch implementiert werden - über Drawer wie in SecondPage
            //}

            MenuItem {
                text: beliebt ? qsTr("Wechsel zu allen Inhalten") : qsTr("Wechsel zu beliebten Inhalten")
                onClicked: {
                    beliebt = !beliebt
                    request()
                }
            }
            MenuItem {
                text: qsTr("Inhalte neu laden")
                onClicked: request()
            }
        }

        delegate: Component {
            Image {
                source: "http://thumb.pr0gramm.com/"+modelData.thumb
                sourceSize.width: width
                sourceSize.height: height
                smooth: true
                cache: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push("SecondPage.qml", {"modelData": modelData, "beliebtProperty": beliebt})
                    }
                }
            }
        }

        Component.onCompleted: {
            request()
        }

        VerticalScrollDecorator {}
    }

    function request(){
        Global.api_request("api/items/get?flags=1" + (beliebt ? "&promoted=1" : ""),
                           function(json) {
                               view.model = json.items
                           }
                          )
    }
}


