"""Render the SDDM theme offscreen with mocked SDDM objects.

usage: harness.py THEME_DIR OUT_PNG WIDTH HEIGHT [state]
state: default | typing | failed | popup
"""
import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import (QAbstractListModel, QModelIndex, QObject, QTimer,
                            QUrl, Property, Signal, Slot, Qt)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

theme_dir, out_png, width, height = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
state = sys.argv[5] if len(sys.argv) > 5 else "default"


class Sddm(QObject):
    loginFailed = Signal()
    loginSucceeded = Signal()

    @Property(str, constant=True)
    def hostName(self):
        return "archlinux"

    @Property(bool, constant=True)
    def canPowerOff(self):
        return True

    @Property(bool, constant=True)
    def canReboot(self):
        return True

    @Property(bool, constant=True)
    def canSuspend(self):
        return True

    @Slot(str, str, int)
    def login(self, user, password, session):
        print("login called:", user, len(password), session)

    @Slot()
    def powerOff(self):
        print("powerOff")

    @Slot()
    def reboot(self):
        print("reboot")

    @Slot()
    def suspend(self):
        print("suspend")


class Sessions(QAbstractListModel):
    def __init__(self, names):
        super().__init__()
        self._names = names

    def rowCount(self, parent=QModelIndex()):
        return len(self._names)

    def roleNames(self):
        return {Qt.UserRole + 1: b"name"}

    def data(self, index, role=Qt.DisplayRole):
        if role == Qt.UserRole + 1:
            return self._names[index.row()]
        return None

    @Property(int, constant=True)
    def lastIndex(self):
        return 0


class Users(QObject):
    @Property(str, constant=True)
    def lastUser(self):
        return "testing"


class Keyboard(QObject):
    @Property(bool, constant=True)
    def capsLock(self):
        return state == "caps"


app = QGuiApplication(sys.argv)
view = QQuickView()
ctx = view.rootContext()
sddm = Sddm()
sessions = Sessions(["i3", "Xfce Session", "Plasma (Wayland)"])
users = Users()
kb = Keyboard()
ctx.setContextProperty("sddm", sddm)
ctx.setContextProperty("sessionModel", sessions)
ctx.setContextProperty("userModel", users)
ctx.setContextProperty("keyboard", kb)
# config: empty -> every setting falls back to the defaults in Main.qml
# but use a font that exists in this sandbox so the preview is readable
cfgd = {"font": "DejaVu Sans Mono"}
if os.environ.get("LOCKMODE"):
    cfgd["lockmode"] = os.environ["LOCKMODE"]
ctx.setContextProperty("config", cfgd)

view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(os.path.join(theme_dir, "Main.qml")))
if view.status() != QQuickView.Ready:
    for e in view.errors():
        print("QML ERROR:", e.toString())
    sys.exit(1)
view.resize(width, height)
view.show()

root = view.rootObject()


def apply_state():
    if state in ("typing", "failed", "popup"):
        pw = root.findChild(QObject, "") if False else None
    # drive the UI through QML-visible properties
    if state == "failed":
        sddm.loginFailed.emit()


def grab():
    print("RING", root.property("ringFx"), root.property("ringFy"))
    img = view.grabWindow()
    ok = img.save(out_png)
    print("saved", out_png, img.width(), img.height(), ok)
    app.quit()


QTimer.singleShot(150, apply_state)
QTimer.singleShot(900, grab)
sys.exit(app.exec())
