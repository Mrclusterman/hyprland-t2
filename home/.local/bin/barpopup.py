"""Base común de los popups de waybar (bright-slider, wifi-popup, bt-popup, battery-popup, cal-popup, system-menu, idea-popup): estilo Centro de control de macOS.
Un solo popup a la vez; clic de nuevo en el mismo icono, sacar el ratón o Esc = cerrar."""
import json, os, signal, subprocess, sys, threading
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GLibUnix, GtkLayerShell

PIDFILE = f"/run/user/{os.getuid()}/barpopup.pid"

# Selectores también en :backdrop (el popup nunca tiene foco y Adwaita lo apagaría)
BASE_CSS = """
window, window:backdrop { background: transparent; }
.panel { background: #242428; border: 1px solid rgba(255,255,255,0.12); border-radius: 18px; }
.title, .title:backdrop { color: #f2f2f7; font-family: "Adwaita Sans"; font-size: 13px; font-weight: 700; }
/* Popups con lista (wifi-popup, bt-popup) */
label, label:backdrop { color: #f2f2f7; font-family: "Adwaita Sans"; font-size: 13px; }
.dim, .dim:backdrop { color: #8e8e93; font-size: 12px; }
.glyph, .glyph:backdrop { font-family: "JetBrainsMono Nerd Font Propo"; font-size: 14px; }
.active .name, .active .name:backdrop { font-weight: 700; }
.error, .error:backdrop { color: #ff453a; font-size: 12px; }
list, list:backdrop { background: transparent; }
row, row:backdrop { background: transparent; border-radius: 8px; padding: 6px 8px; outline: none; }
row:hover { background: rgba(255,255,255,0.10); }
separator { background: rgba(255,255,255,0.12); min-height: 1px; }
switch, switch:backdrop { background: rgba(255,255,255,0.16); border: none; border-radius: 14px; box-shadow: none; }
switch:checked, switch:checked:backdrop { background: #0a84ff; }
switch slider, switch slider:backdrop { background: #f5f5f7; border: none; border-radius: 12px; box-shadow: none; min-width: 20px; min-height: 20px; }
entry, entry:backdrop { background: rgba(255,255,255,0.10); color: #f2f2f7; border: 1px solid rgba(255,255,255,0.16); border-radius: 8px; box-shadow: none; padding: 4px 8px; }
button.flat, button.flat:backdrop { background: transparent; border: none; box-shadow: none; padding: 6px 8px; border-radius: 8px; }
button.flat:hover { background: rgba(255,255,255,0.10); }
spinner { color: #8e8e93; }
"""

def sh(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def run(*cmd):
    return sh(*cmd).stdout

def background(fn, done):
    """Ejecuta fn en un hilo y llama done(resultado) en el hilo de GTK."""
    threading.Thread(target=lambda: GLib.idle_add(done, fn()), daemon=True).start()

def claim(kind):
    """Cierra el popup abierto; si era este mismo, sale (toggle)."""
    try:
        pid, old = open(PIDFILE).read().split()
        os.kill(int(pid), signal.SIGTERM)
        if old == kind:
            sys.exit(0)
    except (OSError, ValueError):
        pass
    open(PIDFILE, "w").write(f"{os.getpid()} {kind}")

def quit_(*_):
    try:
        if open(PIDFILE).read().split()[0] == str(os.getpid()):
            os.remove(PIDFILE)
    except (OSError, IndexError):
        pass
    Gtk.main_quit()

def window(kind, width, css="", keyboard=False, top=None, close_on_leave=True):
    """Ventana layer-shell bajo el cursor (que está sobre el icono), o centrada a `top` px del borde
    superior si se da (popups de atajo de teclado). Devuelve (win, caja interior)."""
    claim(kind)
    provider = Gtk.CssProvider()
    provider.load_from_data((BASE_CSS + css).encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                             Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    cx = int(run("hyprctl", "cursorpos").split(",")[0])
    mon = next(m for m in json.loads(run("hyprctl", "monitors", "-j")) if m["focused"])
    mon_w = int(mon["width"] / mon["scale"])
    left = max(8, min(cx - mon["x"] - width // 2, mon_w - width - 8)) if top is None else (mon_w - width) // 2

    win = Gtk.Window()
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_namespace(win, "barpopup")  # layer rule no_anim en hyprland.lua
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 4 if top is None else top)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.LEFT, left)
    if keyboard:
        GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

    panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    panel.get_style_context().add_class("panel")
    inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=14)
    inner.set_size_request(width - 28, -1)
    panel.add(inner)
    win.add(panel)

    if close_on_leave:
        win.connect("leave-notify-event", lambda w, e: e.detail != Gdk.NotifyType.INFERIOR and quit_())
    win.connect("key-press-event", lambda w, e: e.keyval == Gdk.KEY_Escape and quit_())
    win.connect("destroy", quit_)
    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, quit_)
    return win, inner

def label(text, *classes, **kw):
    l = Gtk.Label(label=text, **kw)
    for c in classes:
        l.get_style_context().add_class(c)
    return l

class ListPopup:
    """Cabecera (título + spinner + interruptor si on no es None), aviso de error y lista de filas clicables."""
    def __init__(self, inner, title, on, on_toggle, on_row):
        head = Gtk.Box(spacing=8)
        head.pack_start(label(title, "title", xalign=0), True, True, 0)
        self.spinner = Gtk.Spinner()
        head.pack_start(self.spinner, False, False, 0)
        if on is not None:
            self.toggle = Gtk.Switch(valign=Gtk.Align.CENTER, active=on)
            self.toggle.connect("notify::active", lambda sw, _: on_toggle(sw.get_active()))
            head.pack_start(self.toggle, False, False, 0)
        inner.add(head)
        self.status = label("", "error", xalign=0, wrap=True, no_show_all=True)
        inner.add(self.status)
        inner.add(Gtk.Separator())
        self.list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        self.list.connect("row-activated", lambda _, row: hasattr(row, "data") and on_row(row))
        inner.add(self.list)

    def busy(self, on, msg=""):
        self.spinner.start() if on else self.spinner.stop()
        self.status.set_text(msg)
        self.status.set_visible(bool(msg))

    def clear(self, empty_msg=None):
        for c in self.list.get_children():
            self.list.remove(c)
        if empty_msg:
            self.list.add(label(empty_msg, "dim", xalign=0, margin=6))
            self.list.show_all()

    def add_row(self, glyph, name, active, data, extras=()):
        row = Gtk.ListBoxRow()
        if active:
            row.get_style_context().add_class("active")
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        line = Gtk.Box(spacing=8)
        line.pack_start(label(glyph, "glyph"), False, False, 0)
        line.pack_start(label(name, "name", xalign=0, ellipsize=3), True, True, 0)
        for e in extras:
            line.pack_start(label(e, "glyph", "dim"), False, False, 0)
        if active:
            line.pack_start(label("\u2713", "title"), False, False, 0)
        box.add(line)
        row.add(box)
        row.data = data
        self.list.add(row)
        row.show_all()
        return row

    def section(self, text):
        self.list.add(label(text, "dim", xalign=0, margin=6))
        self.list.show_all()

def footer_button(inner, text, on_click):
    inner.add(Gtk.Separator())
    btn = Gtk.Button(relief=Gtk.ReliefStyle.NONE)
    btn.get_style_context().add_class("flat")
    btn.add(label(text, xalign=0))
    btn.connect("clicked", lambda *_: on_click())
    inner.add(btn)
