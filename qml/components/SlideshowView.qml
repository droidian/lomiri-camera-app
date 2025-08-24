/*
 * Copyright 2014 Canonical Ltd.
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
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3
import Lomiri.Thumbnailer 0.1
import QtGraphicalEffects 1.0

import CameraApp 0.1
import "MimeTypeMapper.js" as MimeTypeMapper

FocusScope {
    id: slideshowView

    property var model
    property int currentIndex: listView.currentIndex
    property bool touchAcquired: listView.currentItem ? listView.currentItem.pinchInProgress ||
                                                        editor.active || photoBottomEdge.dragProgress != 0 : false
    property bool inView
    property bool editingAvailable: false
    property bool inSelectionMode: false
    signal toggleHeader
    signal toggleSelection
    signal bottomEdgeCommit
    property var actions: inSelectionMode ? slideShowSelectionActions : slideShowActions

    property list<Action> slideShowSelectionActions: [
        Action {
            text: i18n.tr("Select")
            iconName: listView.currentItem && listView.currentItem.isSelected ? "close" : "ok"
            onTriggered: slideshowView.toggleSelection()
        }
    ]

    property list<Action> slideShowActions: [
        Action {
            text: i18n.tr("Share")
            iconName: "share"
            onTriggered: {
                var dialog = PopupUtils.open(sharePopoverComponent)
                dialog.parent = slideshowView
            }
        },
        Action {
            text: i18n.tr("Image Info")
            iconName: "info"
            onTriggered: {
                infoPopover.show()
            }
        },
        Action {
            text: i18n.tr("Delete")
            iconName: "delete"
            onTriggered: {
                var dialog = PopupUtils.open(deleteDialogComponent)
                dialog.parent = slideshowView
            }
        },
        Action {
            text: i18n.tr("Settings")
            objectName: "openSettingsPage"
            iconName: "settings"
            onTriggered: {
                galleryPageStack.clear();
                galleryPageStack.push(advancedOptionsComponent)
            }
        },
        Action {
            text: i18n.tr("About")
            objectName: "openAboutPage"
            iconName: "info"
            onTriggered: {
                galleryPageStack.clear();
                galleryPageStack.push(infoPageComponent);
            }
        }
    ]

    Action {
        id: editAction
        text: i18n.tr("Edit")
        iconName: "edit"

        onTriggered: {
            let path = listView.currentItem.mediaUrl.toString();
            path = path.replace("file://", "");

            editor.start(path)
        }
        enabled: listView.currentItem && !listView.currentItem.isVideo
    }

    Component.onCompleted: {
        // The PhotoEditor is only available in Lomiri.Components.Extras 0.2
        // If we succeed here we add the edit button to the list of actions.
        try { Qt.createQmlObject('import QtQuick 2.12; import Lomiri.Components.Extras 0.2; Item {}', slideshowView) }
        catch (e) { return; }

        editingAvailable = true;
        var newActions = [];
        for (var i = 0; i < slideShowActions.length; i++) newActions.push(slideShowActions[i]);
        newActions.unshift(editAction);
        slideShowActions = newActions;
    }

    function showPhotoAtIndex(index) {
        listView.positionViewAtIndex(index, ListView.Contain);
    }

    function showLastPhotoTaken() {
        listView.currentIndex = 0;
    }

    function exit() {
        if (listView.currentItem) {
            listView.currentItem.zoomOut(true);
        }
        showPhotoAtIndex(0);
    }

    ListView {
        id: listView
        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        anchors.fill: parent
        model: slideshowView.model
        focus: true
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: width
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: LomiriAnimation.FastDuration
        snapMode: ListView.SnapOneItem
        onCountChanged: {
            // currentIndex is -1 by default and stays so until manually set to something else
            if (currentIndex == -1 && count != 0) {
                currentIndex = 0;
            }
        }
        spacing: units.gu(1)
        interactive: currentItem ? !currentItem.pinchInProgress : true
        property real maxDimension: Math.max(width, height)

        removeDisplaced: Transition {
            LomiriNumberAnimation { property: "x" }
        }
        remove: Transition {
            ParallelAnimation {
                LomiriNumberAnimation { property: "opacity"; to: 0 }
            }
        }
        delegate: SingleMediaViewer {
            id: delegate
            objectName: "mediaItem" + index

            scale: 1 - (photoBottomEdge.dragProgress * 0.05)
            mediaUrl: model.fileURL
            useImageProvider: true

            // TODO: This needs to be enabled because for some reason
            // initial zoom in stutters when loading the full resolution
            // version of the image. This doesn't seem to happen in other apps
            // like File Manager
            dynamicImageScaling: true

            backgroundTiledImageSource: "../../assets/transparency-bg.png"
            isVideo: MimeTypeMapper.mimeTypeToContentType(model.fileType) === ContentType.Videos

            width: ListView.view.width
            height: ListView.view.height

            property bool isSelected: selected

            // Needed as ListView.isCurrentItem can't be used directly in a change handler
            property bool isActive: ListView.isCurrentItem
            onIsActiveChanged: if (!isActive) reset();

            onClicked: slideshowView.toggleHeader();

            function reload() {
                mediaUrl = "";
                mediaUrl = model.fileURL;
            }
        }
    }

   Component {
        id: sharePopoverComponent

        SharePopover {
            id: sharePopover

            ContentItem {
                id: contentItem
            }

            Component.onCompleted: {
                contentItem.url = slideshowView.model.get(slideshowView.currentIndex, "filePath");
                transferItems = [contentItem];
            }
            onVisibleChanged: toggleHeader()

            transferContentType: MimeTypeMapper.mimeTypeToContentType(slideshowView.model.get(slideshowView.currentIndex, "fileType"));
        }
    }

   MediaInfoPopover {
        id: infoPopover
        contentWidth:slideshowView.width > units.gu(45) ? units.gu(40) : slideshowView.width*0.85
        mediaUrl: listView.currentItem && listView.currentItem.mediaUrl && !listView.currentItem.isVideo
                        ? listView.currentItem.mediaUrl : ""
        model:{
            "fileName": slideshowView.model.get(slideshowView.currentIndex, "fileName"),
            "fileType": slideshowView.model.get(slideshowView.currentIndex, "fileType"),
        }
     }

    Component {
        id: deleteDialogComponent

        DeleteDialog {
            id: deleteDialog

            FileOperations {
                id: fileOperations
            }

            onDeleteFiles: {
                // FIXME: workaround bug in ListView with snapMode: ListView.SnapOneItem
                // whereby after deleting the last item in the list the first
                // item would be shown even though the currentIndex was not set to 0
                var toBeDeleted = listView.currentIndex;
                if (listView.currentIndex == listView.count - 1) {
                    listView.currentIndex = listView.currentIndex - 1;
                }

                var currentFilePath = slideshowView.model.get(toBeDeleted, "filePath");
                fileOperations.remove(currentFilePath);
            }
            onVisibleChanged: toggleHeader()
        }
    }

    Binding {
        target: header
        property: "editMode"
        value: editor.active
    }

    Binding {
        target: header
        property: "editModeActions"
        value: editor.item ? editor.item.actions : 0;
        when: editor.active && editor.item
    }

    Loader {
        id: editor
        source: "PhotoEditorLoader.qml"
        active: false
        anchors.fill: parent

        function start(url) {
            editor.active = true;
            editor.item.start(url);
        }

        Connections {
            target: editor.item
            onClosed: {
                editor.active = false;
                if (photoWasModified) listView.currentItem.reload();
            }
        }
    }

    OverlayPanel {
        id:bottomimageBlur

        overlayItem: photoBottomEdge
        anchorTo: photoBottomEdge

        visible: photoBottomEdge.status !== BottomEdge.Hidden
        transform: Translate {
            id:beTransalte
            y: photoBottomEdge.height - (photoBottomEdge.height*photoBottomEdge.dragProgress)
            Behavior on y { LomiriNumberAnimation {duration:LomiriAnimation.FastDuration}}
        }

        blur.visible: appSettings.blurEffects && !appSettings.blurEffectsPreviewOnly
        blur.backgroundItem:  listView
        blur.transparentBorder:false
        blur.offset: Qt.point(photoBottomEdge.x,beTransalte.y)
    }

    BottomEdge {
        id: photoBottomEdge
        enabled: !editor.active
        visible: enabled
        height:units.gu(8)
        hint.text: i18n.tr("Back to Photo roll");
        hint.iconName: "go-up"
        hint.visible:enabled
        hint.opacity: 1.0 - photoBottomEdge.dragProgress

        contentComponent: Page {
            id:bottomReturn
            opacity: photoBottomEdge.dragProgress
            header: PageHeader { opacity: 0 }

            Icon {
                id:bottomEdgeGoUpIcon
                height:units.gu(3)
                width:units.gu(3)
                name:"go-up"
                color: theme.palette.normal.backgroundText
                anchors.top:parent.top
                anchors.horizontalCenter:parent.horizontalCenter
            }
            Label {
                anchors.horizontalCenter:parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                height:photoBottomEdge.height
                text: photoBottomEdge.hint.text
                color: theme.palette.normal.backgroundText
                fontSize: "x-large"
            }
        }

        onCommitCompleted:  { bottomEdgeCommit(); photoBottomEdge.collapse(); }
    }
}
