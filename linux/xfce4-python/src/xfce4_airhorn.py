#!/home/they4kman/.virtualenvs/airhorn/bin/python
import inspect
import logging
import math
import os
import threading
from pathlib import Path
from threading import Thread
from typing import cast, Dict, List, Optional

import canberra
import gi
import PIL.ImageEnhance
import pulsectl
from PIL import Image
from pulsectl import PulseEventInfo

gi.require_version('Gtk', '3.0')
gi.require_version('Libxfce4panel', '2.0')
from gi.repository import Gtk, Gdk, Gio, GLib, GdkPixbuf, Libxfce4panel as Xfce4Panel

logging.basicConfig(level=os.getenv('AIRHORN_LOG_LEVEL', 'INFO').upper())
logger = logging.getLogger(__name__)

DEBUG = bool(os.getenv('AIRHORN_REMOTE_DEBUG'))

if DEBUG:
    try:
        import pydevd_pycharm
    except ImportError:
        pass
    else:
        port = int(os.getenv('AIRHORN_REMOTE_DEBUG_PORT', 57024))

        try:
            pydevd_pycharm.settrace('localhost', port=port, stdoutToServer=True, stderrToServer=True, suspend=False)
        except ConnectionRefusedError:
            logger.error('Unable to connect to remote debugging server, port %s', port)


SCRIPT_PATH = Path(__file__)
SCRIPT_DIR = SCRIPT_PATH.parent.absolute()
RESOURCES_DIR = SCRIPT_DIR / 'share'

GLADE_PATH = SCRIPT_DIR / 'xfce4-airhorn.glade'
CSS_PATH = RESOURCES_DIR / 'xfce4-airhorn.css'


class Xfce4Airhorn:

    plugin: Xfce4Panel.PanelPlugin

    volume: int
    volume_delta: int

    ca_ctx: Optional[canberra.Context]
    device: Optional[int]
    pulse: Optional[pulsectl.Pulse]
    _is_pulse_ready: threading.Event
    _pulse_event_thread: Optional[threading.Thread]
    _pulse_sinks_changed: bool

    builder: Optional[Gtk.Builder]
    container: Optional[Gtk.Widget]
    button: Optional[Gtk.Button]
    volume_overlay: Optional[Gtk.DrawingArea]

    sink_names: Dict[int, str]
    device_items: Dict[int, Gtk.ImageMenuItem]

    css_provider: Optional[Gtk.CssProvider]

    monitors: List[Gio.FileMonitor]

    # Event ID to use with libcanberra, so airhorn sounds can be canceled.
    CA_AIRHORN_ID = 1

    def __init__(self, plugin: Xfce4Panel.PanelPlugin):
        self.plugin = plugin

        self.volume = 100
        self.volume_delta = 12

        self.ca_ctx = None
        self.device = None
        self.pulse = None
        self._is_pulse_ready = threading.Event()
        self._pulse_event_thread = None
        self._pulse_sinks_changed = False
        self.init_pulse(autospawn=True)
        self.init_sound()

        self.builder = None
        self.container = None
        self.button = None
        self.volume_overlay = None
        self.build_ui()

        self.sink_names = {}
        self.device_items = {}
        self.init_menu()
        self.watch_for_device_changes()

        self.plugin.connect('size-changed', self.on_size_changed)

        # For some reason, I can only get the parent window to accept scroll events
        self.plugin.get_window().set_events(Gdk.EventMask.SCROLL_MASK)
        self.plugin.get_parent().connect('scroll-event', self.on_scroll)

        self.css_provider = None
        self.init_styles()

        self.plugin.show_all()

        self.monitors = []
        self.monitor_ui_source_changes()

        logger.info('Initialized airhorn GUI')

    def init_pulse(self, autospawn: bool = False, wait: bool = False):
        if self.pulse and self.pulse.connected:
            self.pulse.close()
            self.pulse = None
            self._is_pulse_ready.clear()

        self.pulse = pulsectl.Pulse('airhorn', threading_lock=True, connect=False)
        self.pulse.connect(autospawn=autospawn, wait=wait)

    def background_init_pulse(self, autospawn: bool = False) -> threading.Event:
        self._is_pulse_ready.clear()

        def init_pulse_thread():
            self.init_pulse(autospawn=autospawn, wait=True)
            self._is_pulse_ready.set()

        thread = threading.Thread(target=init_pulse_thread, name='init-pulse-thread')
        thread.start()

        return self._is_pulse_ready

    def init_sound(self):
        self.ca_ctx = canberra.Context()

        if self.device is not None:
            self.ca_ctx.change_device(str(self.device))

        self.ca_ctx.cache(event_id='airhorn')

    def watch_for_device_changes(self):
        def event_listen_loop():
            while True:
                try:
                    self.pulse.event_mask_set('sink')
                    self.pulse.event_callback_set(self._on_pulse_sink_event)
                    self.pulse.event_listen()
                except pulsectl.PulseDisconnected:
                    logger.warning('Disconnected from the PulseAudio server. Attempting to reconnect ...')

                    is_pulse_ready = self.background_init_pulse(autospawn=True)
                    while not is_pulse_ready.wait(timeout=0.1):
                        continue

                    continue

                logger.debug('Pulse event listener halted')

                new_sink_names = self._get_sink_names()
                if new_sink_names != self.sink_names:
                    logger.info('Pulse sinks changed, triggering device menu rebuild')
                    self.sink_names = new_sink_names
                    self.rebuild_menu(refresh_sinks=False)

        self._pulse_event_thread = Thread(target=event_listen_loop)
        self._pulse_event_thread.daemon = True
        self._pulse_event_thread.start()

    def _on_pulse_sink_event(self, event: PulseEventInfo):
        logger.debug('Received pulseaudio sink event: %s', event)

        # Because we must interact with the pulse daemon to determine whether
        # we must rebuild the menu, we must first stop listening for events,
        # otherwise the API calls through pulsectl will hang (as pulsectl is
        # not *actually* synchronous, but instead a wrapper around an event loop).
        raise pulsectl.PulseLoopStop

    def build_ui(self):
        self.builder = Gtk.Builder()
        self.builder.add_objects_from_file(str(GLADE_PATH), ('airhorn-icon', 'container'))
        # XXX: for some reason, connect_signals(self) is not working
        self.builder.connect_signals({
            name: method
            for name, method in inspect.getmembers(self, inspect.ismethod)
            if name.startswith('on_')
        })

        self.container: Gtk.Widget = cast(Gtk.Widget, self.builder.get_object('container'))
        assert isinstance(self.container, Gtk.Widget)
        self.plugin.add(self.container)

        self.button = self.builder.get_object('airhorn-button')
        self.volume_overlay = self.builder.get_object('volume-overlay')

        self.on_size_changed(self.plugin, self.plugin.props.size)

    def rebuild_ui(self):
        logger.debug('Rebuilding UI ...')

        for widget in self.plugin.get_children():
            widget.destroy()

        self.build_ui()
        self.plugin.show_all()

    def _get_sink_names(self) -> Dict[int, str]:
        if not self.pulse:
            return {}

        return {
            sink.index: sink.description
            for sink in self.pulse.sink_list()
        }

    def refresh_sink_names(self) -> None:
        self.sink_names = self._get_sink_names()

    def init_menu(self, *, refresh_sinks: bool = True):
        if refresh_sinks:
            self.refresh_sink_names()

        for index, name in self.sink_names.items():
            item = cast(Gtk.ImageMenuItem, Gtk.ImageMenuItem.new_with_label(name))
            item.set_visible(True)
            item.set_sensitive(True)
            item.connect('activate', self.on_change_device, index)
            self.plugin.menu_insert_item(item)

            self.device_items[index] = item
            self._set_device_item_image(index, item)

    def rebuild_menu(self, *, refresh_sinks: bool = True):
        logger.debug('Rebuilding device menu ...')

        for item in self.device_items.values():
            item.destroy()
        self.device_items.clear()
        logger.debug('Removed device menu items')

        logger.debug('Building device menu items ...')
        self.init_menu(refresh_sinks=refresh_sinks)
        logger.debug('Built device menu items.')

        if self.device is not None and self.device not in self.device_items:
            logger.debug(f'Selected device {self.device} no longer found in available sinks {set(self.device_items)}')
            self.device = None
            self.init_sound()
            logger.info('Reinitialized sound context '
                        'due to selected device becoming unavailable')

        logger.info('Rebuilt device menu')

    def on_change_device(self, menu_item: Gtk.MenuItem, device: int):
        self.device = device

        for item_device, item in self.device_items.items():
            self._set_device_item_image(item_device, item)

        self.init_sound()

    def _set_device_item_image(self, item_device, item: Gtk.ImageMenuItem):
        if item_device == self.device:
            # Checkmark
            image = Gtk.Image.new_from_icon_name('emblem-default-symbolic', -1)
        else:
            image = None

        item.set_image(image)

    def init_styles(self):
        self.css_provider = Gtk.CssProvider()
        style_context = Gtk.StyleContext()
        screen = Gdk.Screen.get_default()
        style_context.add_provider_for_screen(screen, self.css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.load_styles()

    def load_styles(self):
        with CSS_PATH.open('rb') as fp:
            self.css_provider.load_from_data(fp.read())

    def reload_styles(self):
        logger.debug('Reloading styles ...')
        self.load_styles()

    def monitor_ui_source_changes(self):
        watches = [
            (GLADE_PATH, self.rebuild_ui),
            (CSS_PATH, self.reload_styles),
        ]
        for path, callback in watches:
            gio_file = Gio.File.new_for_path(str(path))
            monitor = gio_file.monitor_file(Gio.FileMonitorFlags.NONE, None)
            monitor.connect('changed', self.file_changed_handler(callback))
            self.monitors.append(monitor)

    def file_changed_handler(self, callback):
        def on_file_changed(monitor, gfile, o, event):
            if event == Gio.FileMonitorEvent.CHANGES_DONE_HINT:
                callback()

        return on_file_changed

    @property
    def volume_db(self) -> float:
        """Volume in decibels

        libcanberra accepts its volume inputs in decibels, not nice amplitudes
        using floats or 0-100. So, we must convert.

        Calculations sourced from: https://blog.demofox.org/2015/04/14/decibels-db-and-amplitude/
        """
        if self.volume <= 0:
            return -96
        else:
            return 20 * math.log10(self.volume / 100)

    def play_airhorn_sound(self):
        self.ca_ctx.play(
            event_id='airhorn',
            canberra_volume=f'{self.volume_db:.2f}',
        )
        logger.info('Playing airhorn sound')

    def stop_airhorn_sounds(self):
        self.ca_ctx.cancel()
        logger.info('Stopped airhorn sounds')

    def on_airhorn_button_pressed(self, airhorn_button: Gtk.Button, event: Gdk.EventButton, *args):
        if event.type == Gdk.EventType.BUTTON_PRESS:

            if event.button == Gdk.BUTTON_PRIMARY:
                if DEBUG and event.state & Gdk.ModifierType.CONTROL_MASK:
                    print('ctrl click')
                else:
                    self.play_airhorn_sound()

            elif event.button == Gdk.BUTTON_MIDDLE:
                self.stop_airhorn_sounds()

    def on_volume_overlay_realize(self, volume_overlay: Gtk.DrawingArea, *args):
        # We have to manually set pass-through on the volume overlay's Gdk.Window,
        # or it won't allow mouse events to pass through to the button.
        #
        # This is in addition to setting pass-through on the actual Gtk.DrawingArea,
        # which we do in Glade.
        # (Technically, it calls gtk_overlay.set_overlay_pass_through(volume_overlay, true))
        #
        window = volume_overlay.get_window()
        window.set_pass_through(True)

    def on_scroll(self, widget, event: Gdk.EventScroll):
        prev_volume = self.volume

        volume_change = self.volume_delta * -event.delta_y
        self.volume += volume_change
        self.volume = max(min(self.volume, 100), 0)

        if prev_volume != self.volume:
            self.update_button_image()

    def on_size_changed(self, plugin, size: int):
        if size == 0:
            # hell naw
            return

        orientation = plugin.props.orientation
        if orientation == Gtk.Orientation.HORIZONTAL:
            plugin.set_size_request(-1, size)
        else:
            plugin.set_size_request(size, -1)

        self.update_button_image()

    def update_button_image(self):
        size = self.plugin.props.size

        icon_theme = Gtk.IconTheme.get_default()
        icon = icon_theme.load_icon('airhorn', size-10, Gtk.IconLookupFlags(0))

        volume_frac = self.volume / 100
        gray_frac = 1.0 - volume_frac
        gray_height = int(icon.get_height() * gray_frac)

        im = convert_pixbuf_to_image(icon)
        gray_area = PIL.ImageEnhance.Brightness(im.crop((0, 0, icon.get_width(), gray_height))).enhance(0.5)
        im.paste(gray_area)

        grayed_icon = convert_image_to_pixbuf(im)

        button_img = self.button.get_image()
        button_img.set_from_pixbuf(grayed_icon)

    def on_destroy(self, widget, data=None):
        Gtk.main_quit()


def plugin_load(plugin: Xfce4Panel.PanelPlugin):
    inst = Xfce4Airhorn(plugin)

    # Without this call, none of the widgets are displayed, and the Xfce4PanelPlugin
    # widget and its children appear grayed out in the GTK inspector.
    plugin.map()


def convert_pixbuf_to_image(pix):
    """Convert gdkpixbuf to PIL image"""
    data = pix.get_pixels()
    w = pix.props.width
    h = pix.props.height
    stride = pix.props.rowstride

    mode = 'RGB'
    if pix.props.has_alpha:
        mode = 'RGBA'

    im = Image.frombytes(mode, (w, h), data, 'raw', mode, stride)
    return im


def convert_image_to_pixbuf(im):
    """Convert Pillow image to GdkPixbuf
    """
    data = im.tobytes()
    width, height = im.size
    data = GLib.Bytes.new(data)
    has_alpha = im.mode == 'RGBA'
    rowstride = width * (4 if has_alpha else 3)
    pix = GdkPixbuf.Pixbuf.new_from_bytes(
        data,
        GdkPixbuf.Colorspace.RGB,
        has_alpha,
        8,
        width, height,
        rowstride,
    )
    return pix.copy()
