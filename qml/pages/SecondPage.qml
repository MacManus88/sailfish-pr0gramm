/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string imageProperty
    property string idProperty
    property string userProperty
    property string tagProperty
    property string commentProperty
    property bool beliebtProperty
    property bool zoom : false
    property int transformX : 0
    property int transformY : 0


    SilicaFlickable {

        //contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

            Text{
                width: page.width
                text: "User: "+userProperty
                color: Theme.secondaryHighlightColor
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeSmall
            }

            Text {
                width: page.width
                //height: page.height/6
                text: tagProperty
                color: Theme.secondaryHighlightColor
                //font.pixelSize: Theme.fontSizeSmall
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                width: page.width
                height: page.height/4*3

                property int startX
                property int startY

                AnimatedImage{
                    id: image
                    width: {
                        if(zoom === false)
                            page.width
                    }
                    height: {
                        if(zoom === false)
                            page.height
                    }
                    fillMode: {
                        if(zoom === false)
                            Image.PreserveAspectFit
                    }
                    verticalAlignment: AnimatedImage.AlignTop
                    transform: Translate { y: transformY*image.scale; x: transformX*image.scale }
                    source: {
                        var patt = /webm$/;
                        if(patt.test(imageProperty))
                            "https://crockettdavidson.files.wordpress.com/2011/10/no.gif"
                        else
                            "http://img.pr0gramm.com/"+imageProperty
                    }
                }

                onDoubleClicked: {
                    zoom ? zoom = false : zoom = true
                    transformY = 0
                    transformX = 0
                }
                onPressed: {
                    startX = mouseX
                    startY = mouseY
                }
                onPositionChanged: {
                    if(zoom===true){
                        transformX += mouseX - startX
                        transformY += mouseY - startY
                        startX = mouseX
                        startY = mouseY
                    }
                }
            }
            Row {
                spacing: Theme.paddingLarge
                //anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    text: "Zurück"
                    onClicked: print("test")
                }
                Button {
                    text: "Weiter"
                    onClicked: {
                        request_next()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        request()
    }

    Timer {
        interval: 100 // wait 100msec
        repeat: false
        running: true
        onTriggered: { pageStack.pushAttached(comments); }
    }

    function request(){
        tagProperty = ""
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function(){
            if (xhr.readyState === XMLHttpRequest.DONE){
                print('DONE')
                var json = JSON.parse(xhr.responseText.toString())
                //view.model = json.comments
                for (var i = 0; i < json.tags.length; i++) {
                    tagProperty += JSON.stringify(json.tags[i].tag) + ' | '
                }
                tagProperty = tagProperty.substring(0, tagProperty.length - 3)
                tagProperty = tagProperty.replace(/"/g,"")
                console.log(tagProperty)
            }
        }
        xhr.open("GET","http://pr0gramm.com/api/items/info?itemId="+idProperty);
        xhr.send();
    }

    function request_next(){
        if (beliebtProperty == true) {
            var url = "http://pr0gramm.com/api/items/get?flags=1&promoted=1";
        }
        else {
            var url = "http://pr0gramm.com/api/items/get?flags=1"
        }

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function(){
            if (xhr.readyState === XMLHttpRequest.DONE){
                print('DONE')
                var json = JSON.parse(xhr.responseText.toString())

                for (var i = 0; i < json.items.length; i++) {
                    if (idProperty === JSON.stringify(json.items[i].id)){
                        idProperty = JSON.stringify(json.items[(i+1)].id)
                        imageProperty = JSON.stringify(json.items[(i+1)].image)
                        imageProperty = imageProperty.replace(/"/g,"")
                        userProperty = JSON.stringify(json.items[(i+1)].user)
                        break
                    }
                }
            }
        }
        xhr.open("GET",url);
        xhr.send();
        request() //doesn't get new tags - don't know the reason...
    }

    Component {
        id: comments
        Page {
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: column.height

                Column {
                    id: column

                    width: page.width
                    spacing: Theme.paddingLarge

                    Label {
                        SilicaListView {
                            id: view
                            height: page.height
                            width: page.width

                            delegate: Component {
                                Text {
                                    text: {
                                        if (modelData.parent === 0)
                                            modelData.name + ": " + modelData.content
                                        else
                                            "\t" + modelData.name + ": " + modelData.content
                                    }
                                    width: page.width
                                    color: Theme.secondaryHighlightColor
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                comment_request()
            }

            function comment_request(){
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function(){
                    if (xhr.readyState === XMLHttpRequest.DONE){
                        print('DONE')
                        var json = JSON.parse(xhr.responseText.toString())
                        view.model = json.comments
                    }
                }
                xhr.open("GET","http://pr0gramm.com/api/items/info?itemId="+idProperty);
                xhr.send();
            }
        }
    }
}
