/*
 * Copyright 2014-2015 Canonical Ltd.
 * Copyright (C) 2025 UBports Foundation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3

// Required for image provider to work
import Lomiri.Components.Extras 0.2

Item {
    id: viewer

    readonly property bool pinchInProgress: zoomPinchArea.pinch.active
    readonly property bool isPaused: isAnimated && imageLoader.item && imageLoader.item.paused
    readonly property bool userInteracting: pinchInProgress || !fullyUnzoomed
    readonly property bool fullyZoomed: zoomPinchArea.currentZoom == zoomPinchArea.maximumZoom
    readonly property bool fullyUnzoomed: zoomPinchArea.currentZoom == 1
    readonly property bool imageReady: image && image.status == Image.Ready
    readonly property alias image: imageLoader.item
    readonly property alias imageWidth: internal.imageWidth
    readonly property alias imageHeight: internal.imageHeight
    readonly property real aspectRatio: imageWidth / imageHeight
    readonly property alias thumbSize: internal.thumbSize
    readonly property string fileExtension: mediaUrl ? internal.getFileExtension(mediaUrl.toString()) : ""

    // Some animated formats share the same file extension as static ones
    // such as webp so we check the frame count once loaded to know
    // which is actually animated.
    readonly property bool hasMultipleFrames: internal.frameCount > 1

    property url mediaUrl
    property real maximumZoom: 10

    // Use system image provider but it will be limited to the paths it supports
    property bool useImageProvider: false

    // The high resolution image is scaled based on its current dimensions
    // otherwise, full resolution is loaded upon zooming in
    // This should be enabled if there are performance issues
    // when initially zooming in
    property bool dynamicImageScaling: false

    // Tiled image used as background in case there's transparency
    property alias backgroundTiledImageSource: backgroundImage.source

    // These can be overriden with custom logic for identifying the media type
    property bool isVideo: {
        switch(fileExtension) {
            case "3gp":
            case "avi":
            case "m4v":
            case "mkv":
            case "mov":
            case "mp4":
            case "mpeg":
            case "mpg":
            case "webm":
            case "wmv":
                return true
            default:
                return false
        }
    }
    property bool isAnimated: {
        switch(fileExtension) {
            case "gif":
            // TODO: webp can be animated or static
            // Let's treat it as animated so animated ones will be played
            // and static ones will still be displayed anyway.
            // We use hasMultipleFrames as another way to know
            // if it's actually animated
            case "webp":
            case "apng": // Possibly not supported but still displayed anyway
                return true
            default:
                return false
        }
    }

    signal clicked()

    onWidthChanged: {
        // Only change thumbSize if width increases more than 5%
        // that way we do not reload image for small resizes
        if (width > internal.thumbSize.width) {
            internal.thumbSize = Qt.size(width * 1.05, height * 1.05);
        }
    }

    onHeightChanged: {
        // Only change thumbSize if height increases more than 5%
        // that way we do not reload image for small resizes
        if (height > internal.thumbSize.height) {
            internal.thumbSize = Qt.size(width * 1.05, height * 1.05);
        }
    }

    onImageReadyChanged: {
        if (imageReady) {
            internal.imageWidth = image.paintedWidth;
            internal.imageHeight = image.paintedHeight;
        } else {
            // Reset frame count
            internal.frameCount = 0;
        }
    }

    function zoomIn(_contentWidth, _contentHeight, _centerPoint, _animated=false) {
        let _newZoom = Math.max(_contentWidth / flickable.width, _contentHeight / flickable.height);
        let _newWidth = _contentWidth;
        let _newHeight = _contentHeight;
        let _newPaintedWidth = viewer.imageWidth * _newZoom;
        let _newPaintedHeight = viewer.imageHeight * _newZoom;

        // Do not overshoot from maximum zoom
        if (_newZoom > zoomPinchArea.maximumZoom) {
            _newPaintedWidth = viewer.imageWidth * zoomPinchArea.maximumZoom;
            _newPaintedHeight = viewer.imageHeight * zoomPinchArea.maximumZoom;
        }

        // We eliminate the black bars when zoomed in and panning
        // so we limit the flickable content dimensions to the image's actual surface
        if (flickable.width >= _newPaintedWidth) {
            _newWidth = flickable.width;
        } else {
            _newWidth = _newPaintedWidth;
        }

        if (flickable.height >= _newPaintedHeight) {
            _newHeight = flickable.height;
        } else {
            _newHeight = _newPaintedHeight;
        }

        if (zoomPinchArea.currentZoom !== zoomPinchArea.maximumZoom
                || _newZoom <= zoomPinchArea.maximumZoom) {
            if (_animated) {
                flickable.animatedResizeContent(_newWidth, _newHeight, _centerPoint);
            } else {
                flickable.resizeContent(_newWidth, _newHeight, _centerPoint);
            }
        }
    }

    function zoomOut(_animate=false) {
        let _newWidth = flickable.width;
        let _newHeight = flickable.height;
        let _centerPoint = Qt.point(flickable.width / 2, flickable.height / 2);

        if (_animate) {
            flickable.animatedResizeContent(_newWidth, _newHeight, _centerPoint);
        } else {
            flickable.resizeContent(_newWidth, _newHeight, _centerPoint);
        }
    }

    function reset() {
        if (!viewer.isVideo) {
            zoomOut(false);
        }
    }

    function togglePlayback() {
        if (isAnimated && imageLoader.item) {
            imageLoader.item.paused = !imageLoader.item.paused;
        }
    }

    QtObject {
        id: internal

        // Original dimensions of the current image set when image is loaded
        property real imageWidth: 0
        property real imageHeight: 0
        property int frameCount: 0

        property size thumbSize: Qt.size(viewer.width * 1.05, viewer.height * 1.05)

        function getFileExtension(_filename) {
            const _arr = _filename.split('.');

            if (_arr.length > 1) {
                return _arr.pop();
            } else {
                return "";
            }
        }
    }

    ActivityIndicator {
        anchors.centerIn: parent
        visible: running
        running: viewer.image && viewer.image.status != Image.Ready && viewer.image.status != Image.Error
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        contentHeight: height
        contentWidth: width
        interactive: !viewer.pinchInProgress
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        function animatedResizeContent(_newWidth, _newHeight, _centerPoint) {
            let _newX = (_newWidth / (contentWidth / _centerPoint.x)) - (_centerPoint.x / zoomPinchArea.currentZoom);
            let _newY = (_newHeight / (contentHeight / _centerPoint.y)) - (_centerPoint.y / zoomPinchArea.currentZoom);

            contentXAnimation.to = _newX;
            contentYAnimation.to = _newY;
            contentWidthAnimation.to = _newWidth;
            contentHeightAnimation.to = _newHeight;

            resizeContentAnimation.restart();
        }

        ParallelAnimation {
            id: resizeContentAnimation

            property int duration: LomiriAnimation.FastDuration

            LomiriNumberAnimation {
                id: contentWidthAnimation

                target: flickable
                property: "contentWidth"
                duration: resizeContentAnimation.duration
            }

            LomiriNumberAnimation {
                id: contentHeightAnimation

                target: flickable
                property: "contentHeight"
                duration: resizeContentAnimation.duration
            }

            LomiriNumberAnimation {
                id: contentXAnimation

                target: flickable
                property: "contentX"
                duration: resizeContentAnimation.duration
            }

            LomiriNumberAnimation {
                id: contentYAnimation

                target: flickable
                property: "contentY"
                duration: resizeContentAnimation.duration
            }
        }

        PinchArea {
            id: zoomPinchArea

            // We get the higher value since that means that dimension is originally
            // equal to the container's dimension and can be used as basis of the zoom value
            readonly property real currentZoom: Math.max(flickable.contentWidth / flickable.width, flickable.contentHeight / flickable.height)

            property real initialWidth
            property real initialHeight
            property real maximumZoom: viewer.maximumZoom

            enabled: viewer.imageReady && !viewer.isVideo

            width: Math.max(flickable.contentWidth, flickable.width)
            height: Math.max(flickable.contentHeight, flickable.height)

            onPinchStarted: {
                initialWidth = flickable.contentWidth;
                initialHeight = flickable.contentHeight;
            }

            onPinchUpdated: {
                let _newWidth = initialWidth * pinch.scale;
                let _newHeight = initialHeight * pinch.scale;

                // Do not overshoot when zooming out
                if (_newWidth > flickable.width || _newHeight > flickable.height) {
                    flickable.contentX += pinch.previousCenter.x - pinch.center.x;
                    flickable.contentY += pinch.previousCenter.y - pinch.center.y;
                    viewer.zoomIn(_newWidth, _newHeight, pinch.center, false);
                } else {
                    viewer.zoomOut(false);
                }
            }

            onPinchFinished: {
                // Move its content within bounds.
                flickable.returnToBounds();
            }

            Item {
                id: media

                width: flickable.contentWidth
                height: flickable.contentHeight

                Image {
                    id: backgroundImage

                    // Reduce width/hight so background is not visible on the border of camera photos
                    width: viewer.image ? viewer.image.paintedWidth - 1 : parent.width
                    height: viewer.image ? viewer.image.paintedHeight - 1 : parent.height
                    anchors.centerIn: imageLoader
                    visible: !viewer.isVideo && viewer.image && viewer.image.opacity == 1.0

                    asynchronous: true
                    cache: true
                    fillMode: Image.Tile
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignTop
                }

                Loader {
                    id: imageLoader

                    anchors.fill: parent
                    asynchronous: true
                    sourceComponent: viewer.isAnimated ? animatedImageComponent : imageComponent
                }

                Component {
                    id: animatedImageComponent

                    AnimatedImage {
                        id: animatedImageRenderer
                        objectName: "animatedImageRenderer"

                        // TODO: Image provider doesn't support animated formats yet
                        // so we use direct path
                        source: viewer.mediaUrl

                        fillMode: Image.PreserveAspectFit
                        autoTransform: true
                        asynchronous: true
                        cache: false
                        opacity: status == Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                        onFrameCountChanged: internal.frameCount = frameCount;
                    }
                }

                Component {
                    id: imageComponent

                    Image {
                        id: imageRenderer
                        objectName: "imageRenderer"

                        source: {
                            if (viewer.isVideo) {
                                // Video thumbnails come from the image provider so we use it regardless of useImageProvider
                                return "image://thumbnailer/" + viewer.mediaUrl
                            } else {
                                if (viewer.useImageProvider) {
                                    return "image://photo/" + viewer.mediaUrl
                                }

                                return viewer.mediaUrl
                            }
                        }
                        autoTransform: true
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        opacity: status == Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                        sourceSize {
                            width: viewer.thumbSize.width
                            height: viewer.thumbSize.height
                        }
                    }
                }

                Image {
                    id: highResolutionImage

                    anchors.fill: parent
                    asynchronous: true
                    cache: false

                    // Display full resolution when zoomed in
                    source: {
                        if (!viewer.isAnimated && zoomPinchArea.currentZoom > 1) {
                            if (viewer.useImageProvider) {
                                return "image://photo/" + viewer.mediaUrl
                            }

                            return viewer.mediaUrl
                        }

                        return ""
                    }

                    sourceSize {
                        width: viewer.dynamicImageScaling ? width : undefined
                        height: viewer.dynamicImageScaling ? height : undefined
                    }

                    autoTransform: true
                    opacity: status == Image.Ready ? 1.0 : 0.0
                    visible: opacity > 0
                    fillMode: Image.PreserveAspectFit
                }

                Item {
                    id: mediaLoadingError

                    readonly property bool iconOnly: viewer.isVideo

                    anchors.centerIn: parent
                    width: parent.width
                    height: iconOnly ? mediaLoadingErrorIcon.height
                                     : mediaLoadingErrorIcon.height + units.gu(5) + mediaLoadingErrorLabel.contentHeight
                    visible: opacity > 0
                    opacity: viewer.image && viewer.image.status == Image.Error ? 1.0 : 0.0
                    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                    Icon {
                        id: mediaLoadingErrorIcon

                        anchors.horizontalCenter: parent.horizontalCenter
                        width: mediaLoadingError.iconOnly ? units.gu(30) : units.gu(8)
                        height: width
                        name: viewer.isVideo ? "stock_video" : "stock_image"
                        color: "white"
                        opacity: 0.8
                    }

                    Label {
                        id: mediaLoadingErrorLabel

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: mediaLoadingErrorIcon.bottom
                            topMargin: units.gu(5)
                        }

                        visible: !mediaLoadingError.iconOnly
                        width: units.gu(30)
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n.tr("An error has occurred attempting to load media")
                        fontSize: "large"
                        color: "lightgrey"
                    }
                }

                // If video is enabled and the media is a video, show a 'play' icon
                Loader {
                    active: viewer.isVideo
                    anchors.centerIn: parent
                    width: units.gu(7)
                    height: width
                    sourceComponent: PlayIcon {}
                }

                MouseArea {
                    id: viewerMouseArea

                    readonly property real zoomStepSize: 0.1
                    property bool eventAccepted: false

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: !viewer.fullyUnzoomed && (containsPress || flickable.dragging) ? Qt.ClosedHandCursor : Qt.ArrowCursor

                    onWheel: {
                        let _newWidth = wheel.angleDelta.y / 120 * flickable.contentWidth * zoomStepSize + flickable.contentWidth;
                        let _newHeight = wheel.angleDelta.y / 120 * flickable.contentHeight * zoomStepSize + flickable.contentHeight;
                        let _centerPoint = viewerMouseArea.mapToItem(flickable, flickable.contentX + viewerMouseArea.mouseX, flickable.contentY + viewerMouseArea.mouseY);

                        if (_newWidth > flickable.width || _newHeight > flickable.height) {
                            viewer.zoomIn(_newWidth, _newHeight, _centerPoint, false);
                            flickable.returnToBounds();
                        } else {
                            viewer.zoomOut(false);
                            flickable.returnToBounds();
                        }
                    }

                    onDoubleClicked: {
                        if (viewerMouseArea.eventAccepted)
                            return;

                        clickTimer.stop();

                        if (viewer.ListView.view && viewer.ListView.view.moving) {
                            // FIXME: workaround for Qt bug specific to touch:
                            // doubleClicked is received even though the MouseArea
                            // was tapped only once but another MouseArea was also
                            // tapped shortly before.
                            // Ref.: https://bugreports.qt.io/browse/QTBUG-39332
                            return;
                        }

                        if (viewer.isVideo) return;

                        if (viewer.imageReady && viewer.fullyUnzoomed) {
                            const _centerPoint = viewerMouseArea.mapToItem(flickable, flickable.contentX + viewerMouseArea.mouseX, flickable.contentY + viewerMouseArea.mouseY);
                            const _maxZoom = zoomPinchArea.maximumZoom;
                            const _currentZoom = zoomPinchArea.currentZoom;
                            const _imageWidth = viewer.imageWidth;
                            const _imageHeight = viewer.imageHeight;
                            const _contentWidth = flickable.contentWidth;
                            const _contentHeight = flickable.contentHeight;
                            const _flickableWidth = flickable.width;
                            const _flickableHeight = flickable.height;
                            const _newWidth = _flickableWidth * _maxZoom;
                            const _newHeight = _flickableHeight * _maxZoom;

                            // When zoomed in, black bars/empty spaces are eliminated
                            // by making the flickable content dimensions equal to the image dimensions
                            // once the image becomes larger than the flickable container.
                            // Because of this, the mouse center point has to be adjusted
                            // so that the image's position when max zoomed in will still be accurate
                            // based on where the user double clicked

                            // We first calculate the adjusted contentX and contextY
                            const _newContentX = (_centerPoint.x * (_maxZoom - 1)) + ((_maxZoom * (_imageWidth - _flickableWidth)) / 2);
                            const _newContentY = (_centerPoint.y * (_maxZoom - 1)) + ((_maxZoom * (_imageHeight - _flickableHeight)) / 2);

                            // We then derive the adjusted center point from the adjusted contentX and contextY
                            const _newX = (_newContentX * _contentWidth * _currentZoom) / ((_imageWidth * _maxZoom * _currentZoom) - _contentWidth);
                            const _newY = (_newContentY * _contentHeight * _currentZoom) / ((_imageHeight * _maxZoom * _currentZoom) - _contentHeight);
                            const _adjustedCenterPoint = Qt.point(_newX, _newY);

                            viewer.zoomIn(_newWidth, _newHeight, _adjustedCenterPoint, true);
                        } else {
                            viewer.zoomOut(true);
                        }
                    }

                    onClicked: {
                        // For videos, we check for a tap in the center on the
                        // play button icon
                        if (viewer.isVideo
                            && mouse.x > width / 2 - units.gu(5)
                            && mouse.x < width / 2 + units.gu(5)
                            && mouse.y > height / 2 - units.gu(5)
                            && mouse.y < height / 2 + units.gu(5)) {
                            var url = viewer.mediaUrl.toString().replace("file://", "video://");
                            Qt.openUrlExternally(url);
                        } else {
                            viewerMouseArea.eventAccepted = false;
                            clickTimer.start();
                        }
                    }

                    Timer {
                        id: clickTimer

                        interval: 200
                        onTriggered: {
                            viewerMouseArea.eventAccepted = true;
                            viewer.clicked();
                        }
                    }
                }
            }
        }
    }
}
