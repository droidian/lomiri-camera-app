/*
 * Copyright 2012 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1 as SDK

Item {
    id: zoom
    property alias maximumValue: slider.maximumValue
    property alias value: slider.value
    property real zoomStep: (slider.maximumValue - slider.minimumValue) / 20

    SDK.AbstractButton {
        id: minus
        objectName: "zoomMinus"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: minusIcon.width
        height: minusIcon.height
        onClicked: slider.value = Math.max(value - zoom.zoomStep, slider.minimumValue)
        onPressedChanged: if (pressed) minusTimer.restart(); else minusTimer.stop();

        Image {
            id: minusIcon
            anchors.centerIn: parent
            source: "assets/zoom_minus.png"
            sourceSize.height: units.gu(2)
            smooth: true
        }

        Timer {
            id: minusTimer
            interval: 40
            repeat: true
            onTriggered: slider.value = Math.max(value - zoom.zoomStep, slider.minimumValue)
        }
    }

    Slider {
        id: slider
        objectName: "zoomSlider"
        anchors.left: minus.right
        anchors.right: plus.left
        anchors.verticalCenter: parent.verticalCenter
        height: zoom.height

        live: true
        minimumValue: 1.0 // No zoom => 1.0 zoom factor
        value: minimumValue

        backgroundDelegate: Image {
            source: Qt.resolvedUrl("assets/zoom_bar.png")
        }

        thumbDelegate: Image {
            source: Qt.resolvedUrl("assets/zoom_point.png")
            height: units.gu(1.5)
            width: height
        }
    }

    SDK.AbstractButton {
        id: plus
        objectName: "zoomPlus"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: plusIcon.width
        height: plusIcon.height
        onClicked: slider.value = Math.min(value + zoom.zoomStep, slider.maximumValue)
        onPressedChanged: if (pressed) plusTimer.restart(); else plusTimer.stop();

        Image {
            id: plusIcon
            anchors.centerIn: parent
            source: "assets/zoom_plus.png"
            sourceSize.height: units.gu(2)
            smooth: true
        }

        Timer {
            id: plusTimer
            interval: 40
            repeat: true
            onTriggered: slider.value = Math.min(value + zoom.zoomStep, slider.maximumValue)
        }
    }
}

