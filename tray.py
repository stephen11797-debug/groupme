#!/usr/bin/env python3
"""
GroupMe Tray — opens GroupMe web, and can be turned off.
"""
import os
import subprocess
import sys
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf

CHROME = "/usr/bin/google-chrome"
DISPLAY = ":0"

APP = {
    "name": "GroupMe",
    "url": "https://web.groupme.com/",
    "profile": os.path.expanduser("~/.config/groupme-web-chrome"),
    "pos": (1280, 655),
    "size": (1200, 395),
}


def launch():
    def run():
        x, y = APP["pos"]
        w, h = APP["size"]
        cmd = [
            CHROME,
            f"--app={APP['url']}",
            f"--user-data-dir={APP['profile']}",
            "--no-first-run",
            f"--window-position={x},{y}",
            f"--window-size={w},{h}",
        ]
        env = dict(os.environ)
        env["DISPLAY"] = DISPLAY
        subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    threading.Thread(target=run, daemon=True).start()


def _wmctrl(args):
    env = dict(os.environ)
    env["DISPLAY"] = DISPLAY
    try:
        out = subprocess.check_output(
            ["wmctrl"] + args, env=env, stderr=subprocess.DEVNULL, timeout=3
        )
        return out.decode("utf-8", errors="replace")
    except Exception:
        return ""


def find_groupme_window():
    out = _wmctrl(["-lG"])
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 7 and "GroupMe" in " ".join(parts[6:]):
            return parts[0]
    return None


def turn_off():
    wid = find_groupme_window()
    if wid:
        _wmctrl(["-i", "-c", wid])
    try:
        subprocess.Popen(
            ["pkill", "-f", APP["profile"]],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass
    Gtk.main_quit()


def make_icon():
    icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.png")
    if os.path.isfile(icon_path):
        return GdkPixbuf.Pixbuf.new_from_file_at_scale(icon_path, 48, 48, True)
    import cairo
    import io

    w, h = 48, 48
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    ctx = cairo.Context(surf)
    ctx.set_source_rgb(0.0, 0.4, 1.0)
    ctx.rectangle(2, 2, w - 4, h - 4)
    ctx.fill()
    ctx.set_source_rgb(1.0, 1.0, 1.0)
    ctx.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(22)
    ctx.move_to(14, 34)
    ctx.show_text("G")
    png = io.BytesIO()
    surf.write_to_png(png)
    data = png.getvalue()
    loader = GdkPixbuf.PixbufLoader.new_with_type("png")
    loader.write(data)
    loader.close()
    return loader.get_pixbuf()


def on_quit(widget):
    Gtk.main_quit()


def build_menu():
    menu = Gtk.Menu()
    item = Gtk.MenuItem(label="Open GroupMe")
    item.connect("activate", lambda w: launch())
    menu.append(item)
    sep = Gtk.SeparatorMenuItem()
    menu.append(sep)
    off_item = Gtk.MenuItem(label="Turn Off")
    off_item.connect("activate", lambda w: turn_off())
    menu.append(off_item)
    quit_item = Gtk.MenuItem(label="Quit")
    quit_item.connect("activate", on_quit)
    menu.append(quit_item)
    menu.show_all()
    return menu


def main():
    if "DISPLAY" not in os.environ:
        print("No DISPLAY", file=sys.stderr)
        sys.exit(1)
    icon = Gtk.StatusIcon()
    icon.set_from_pixbuf(make_icon())
    icon.set_tooltip_text("GroupMe")
    icon.connect("popup-menu", lambda i, b, t: build_menu().popup(None, None, None, None, b, t))
    icon.connect("activate", lambda i: build_menu().popup(None, None, None, None, 0, Gtk.get_current_event_time()))
    Gtk.main()


if __name__ == "__main__":
    main()
