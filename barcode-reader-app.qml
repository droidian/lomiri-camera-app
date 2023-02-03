/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.4
import QtQuick.Window 2.2
import QtMultimedia 5.0
import Lomiri.Components 1.3
import UserMetrics 0.1
import Lomiri.Content 1.3
import CameraApp 0.1
import Qt.labs.settings 1.0
import QZXing 3.3

Window {
    id: main
    objectName: "main"
    width: Math.min(Screen.width, height * viewFinderView.aspectRatio)
    height: Math.min(Screen.height, units.gu(80))
    color: "black"
    title: "Camera"
    // special flag only supported by Unity8/MIR so far that hides the shell's
    // top panel in Staged mode
    flags: Qt.Window | 0x00800000

      Settings {
        id: appSettings

        property bool blurEffects:true
        property bool blurEffectsPreviewOnly: true
      }

    property int preFullScreenVisibility

    function toggleFullScreen() {
        if (main.visibility != Window.FullScreen) {
            preFullScreenVisibility = main.visibility;
            main.visibility = Window.FullScreen;
        } else {
            main.visibility = preFullScreenVisibility;
        }
    }

    function exitFullScreen() {
        if (main.visibility == Window.FullScreen) {
            main.visibility = preFullScreenVisibility;
        }
    }

    Component.onCompleted: {
        i18n.domain = "lomiri-camera-app";
        main.show();
    }

    QZXingFilter {
        id: qrCodeScanner
        orientation: viewFinderView.finderOverlay.sensorOrientation

        active: true
        decoder {
            enabledDecoders: QZXing.DecoderFormat_QR_CODE
            imageSourceFilter: QZXing.SourceFilter_ImageNormal

            onTagFoundAdvanced: {
                viewFinderView.recentlyScannedTag = tag
            }
        }
    }

    ViewFinderView {
        id: viewFinderView
        anchors.fill: parent
        overlayVisible: true
        inView: true
        focus: true
        opacity: inView ? 1.0 : 0.0
        readOnly: true
        cameraFilters: [ qrCodeScanner ]
    }

    property bool contentExportMode: transfer !== null
    property var transfer: null
    property var transferContentType: transfer ? transfer.contentType : "image"

    function exportContent(urls) {
        if (!main.transfer) return;

        var item;
        var items = [];
        for (var i=0; i<urls.length; i++) {
            item = contentItemComponent.createObject(main.transfer, {"url": urls[i]});
            items.push(item);
        }
        main.transfer.items = items;
        main.transfer.state = ContentTransfer.Charged;
        main.transfer = null;
    }

    function cancelExport() {
        main.transfer.state = ContentTransfer.Aborted;
        main.transfer = null;
    }

    Component {
        id: contentItemComponent
        ContentItem {
        }
    }
}
