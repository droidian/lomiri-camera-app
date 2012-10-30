class MainWindow(object):
    """An emulator class that makes it easy to interact with the camera-app."""

    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickView")

    def get_camera(self):
        """Returns the whole camera screen."""
        return self.app.select_single("QQuickRootItem").get_children_by_type("QQuickRectangle")[0]

    def get_focus_ring(self):
        """Returns the focus ring of the camera"""
        return self.app.select_single("FocusRing")
      
    def get_exposure_button(self):
        """Returns the button that takes pictures"""
        return self.app.select_single("ShootButton")

    def get_record_control(self):
        """Returns the button that switches between photo and video recording"""
        return self.app.select_single("ToolbarButton", objectName="recordModeButton")

    def get_flash_button(self):
        """Returns the flash control button of the camera"""
        return self.app.select_single("FlashButton")

    def get_stop_watch(self):
        """Returns the stop watch when using the record button of the camera"""
        return self.app.select_single("StopWatch")

    def get_toolbar(self):
        """Returns the toolbar that holds the flash and record button"""
        return self.app.select_single("Toolbar")

    def get_zoom_button(self):
        """Returns the zoom button"""
        return self.app.select_single("TextCustom", text="ZOOM")

    def get_zoom_control(self):
        """Returns the left zoom control"""
        return self.app.select_single("ZoomControl")