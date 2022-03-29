# distutils: language = c
# cython: language_level=3
# cython: binding=True

from libc.stddef cimport wchar_t
from libc.stdio cimport (
    fclose,
    fread,
    FILE,
    FILENAME_MAX,
    fopen,
    fprintf,
    getline,
    printf,
    sscanf,
    stderr,
)
from libc.string cimport strcat, strcpy, memset, strncpy, strlen
from posix.dlfcn cimport dlopen, RTLD_LAZY, RTLD_GLOBAL, dlsym

from cpython.dict cimport PyDict_New, PyDict_SetItemString
from cpython.module cimport PyImport_ImportModule, PyImport_AddModule, PyModule_GetDict
from cpython.object cimport PyObject, PyObject_IsInstance
from cpython.pycapsule cimport PyCapsule_GetPointer
from cpython.pylifecycle cimport Py_SetPythonHome, Py_Initialize

from glib cimport g_free, g_strdup, g_strrstr, g_strstr_len, g_strdup_printf, g_strfreev
from gtk cimport *
from libxfce4panel cimport *
from libxfce4util cimport *
from pygobject cimport _PyGObject_Functions
from pygobject cimport *
from python cimport PyRun_String, Py_file_input
from stdlib cimport mbstowcs

import gi
from gi import _gobject
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

# Load in Python symbols
dlopen("libpython3.10.so", RTLD_LAZY | RTLD_GLOBAL)
printf("[libxfce4airhorn] Loaded Python symbols\n")

# Load in symbols from pygobject
_PyGObject_API = <_PyGObject_Functions *>PyCapsule_GetPointer(_gobject._PyGObject_API, "gobject._PyGObject_API")
printf("[libxfce4airhorn] Loaded _PyGObject_API\n")


cdef object PyXfcePanelPlugin = <object>pygobject_lookup_class(xfce_panel_plugin_get_type())
cdef object PyGtkWidget = <object>pygobject_lookup_class(gtk_widget_get_type())
cdef object PyGtkWindow = <object>pygobject_lookup_class(gtk_window_get_type())
cdef object PyGtkMenu = <object>pygobject_lookup_class(gtk_menu_get_type())
cdef object PyGtkMenuItem = <object>pygobject_lookup_class(gtk_menu_item_get_type())


cdef GObject *as_gobject(obj, tp):
    if not PyObject_IsInstance(obj, tp):
        raise TypeError(f'argument must be a {tp} object, not {repr(type(obj))!r}')
    return pygobject_get(<PyGObject *>obj)


cdef XfcePanelPlugin *as_panel_plugin(obj):
    return <XfcePanelPlugin *>as_gobject(obj, PyXfcePanelPlugin)


cdef GtkWidget *as_gtk_widget(obj):
    return <GtkWidget *>as_gobject(obj, PyGtkWidget)


cdef GtkWindow *as_gtk_window(obj):
    return <GtkWindow *>as_gobject(obj, PyGtkWindow)


cdef GtkMenu *as_gtk_menu(obj):
    return <GtkMenu *>as_gobject(obj, PyGtkMenu)


cdef GtkMenuItem *as_gtk_menu_item(obj):
    return <GtkMenuItem *>as_gobject(obj, PyGtkMenuItem)


def py_xfce_panel_plugin_take_window(self, window):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef GtkWindow *gtk_window = as_gtk_window(window)
    xfce_panel_plugin_take_window(plugin, gtk_window)


def py_xfce_panel_plugin_add_action_widget(self, widget):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef GtkWidget *gtk_widget = as_gtk_widget(widget)
    xfce_panel_plugin_add_action_widget(plugin, gtk_widget)


def py_xfce_panel_plugin_menu_insert_item(self, menu_item):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef GtkMenuItem *gtk_menu_item = as_gtk_menu_item(menu_item)
    xfce_panel_plugin_menu_insert_item(plugin, gtk_menu_item)


def py_xfce_panel_plugin_menu_show_configure(self):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    xfce_panel_plugin_menu_show_configure(plugin)


def py_xfce_panel_plugin_menu_show_about(self):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    xfce_panel_plugin_menu_show_about(plugin)


def py_xfce_panel_plugin_block_menu(self):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    xfce_panel_plugin_block_menu(plugin)


def py_xfce_panel_plugin_unblock_menu(self):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    xfce_panel_plugin_unblock_menu(plugin)


def py_xfce_panel_plugin_register_menu(self, menu):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef GtkMenu *gtk_menu = as_gtk_menu(menu)
    xfce_panel_plugin_register_menu(plugin, gtk_menu)


# TODO: py_xfce_panel_plugin_position_widget ???
# TODO: xfce_panel_plugin_position_menu ???


def py_xfce_panel_plugin_focus_widget(self, widget):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef GtkWidget *gtk_widget = as_gtk_widget(widget)
    xfce_panel_plugin_focus_widget(plugin, gtk_widget)


def py_xfce_panel_plugin_block_autohide(self, gboolean blocked):
    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    xfce_panel_plugin_block_autohide(plugin, blocked)


def py_xfce_panel_plugin_lookup_rc_file(self):
    cdef bytes rc_file_bytes
    cdef str rc_file

    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef gchar *rc_file_chars = xfce_panel_plugin_lookup_rc_file(plugin)

    if rc_file_chars is not NULL:
        rc_file_bytes = rc_file_chars
        rc_file = rc_file_bytes.decode('utf-8')
        g_free(rc_file_chars)
        return rc_file


def py_xfce_panel_plugin_save_location(self, gboolean create):
    cdef bytes save_location_bytes
    cdef str save_location

    cdef XfcePanelPlugin *plugin = as_panel_plugin(self)
    cdef gchar *save_location_chars = xfce_panel_plugin_save_location(plugin, create)

    if save_location_chars is not NULL:
        save_location_bytes = save_location_chars
        save_location = save_location_bytes.decode('utf-8')
        g_free(save_location_chars)
        return save_location


cdef public void init_plugin(XfcePanelPlugin *xpp):
    # 1. Read /proc/self/cmdline
    cdef FILE *cmdline_fp = fopen('/proc/self/cmdline', 'rb')
    if cmdline_fp is NULL:
        fprintf(stderr, 'Unable to open /proc/self/cmdline to find module path\n')
        exit(1)

    cdef char buf[4096]
    if fread(<void *>&buf, sizeof(char), sizeof(buf), cmdline_fp) <= 0:
        fprintf(stderr, 'Unable to read /proc/self/cmdline to find module path\n')
        exit(1)

    # 2. Get second argument
    cdef gchar *module_path = g_strdup(<char *>&buf[strlen(<char *>&buf)+1])

    # 3. Remove libxfce4airhorn.so from end
    # XXX: don't hardcode .so name
    cdef gchar *module_so_loc = g_strrstr(module_path, 'libxfce4airhorn.so')
    if module_so_loc is NULL:
        fprintf(stderr, 'Unable to find module .so in %s\n', module_path)
        exit(1)

    module_so_loc[0] = 0

    # 4. Replace "lib" with "share"
    memset(<void *>&buf, 0, sizeof(buf))

    cdef gchar *lib_loc = g_strstr_len(module_path, -1, '/lib')
    if lib_loc is NULL:
        fprintf(stderr, 'Unable to find "/lib" in %s\n', module_path)
        exit(1)

    cdef size_t prefix_len = lib_loc - module_path
    strncpy(<char *>&buf, module_path, prefix_len)
    strcat(<char *>&buf, '/share')
    strcat(<char *>&buf, &lib_loc[strlen('/lib')])

    cdef gchar *panel_plugins_data_dir = g_strdup(<char *>&buf)
    g_free(module_path)

    # 5. Add (plugin->get_name() + '.desktop') to path
    cdef gchar *desktop_path = g_strdup_printf(
        '%s%s.desktop',
        panel_plugins_data_dir,
        xfce_panel_plugin_get_name(xpp),
    )

    # 6. Read .desktop RC file
    cdef XfceRc *rc = xfce_rc_simple_open(desktop_path, True)
    xfce_rc_set_group(rc, 'Xfce Panel')

    # 7. Read X-Python-Venv as PYTHONHOME
    cdef char *venv = xfce_rc_read_entry_untranslated(rc, 'X-Python-Venv', NULL)
    if venv is NULL:
        fprintf(stderr, 'Unable to find X-Python-Venv entry in %s\n', desktop_path)
        exit(1)

    venv = g_strdup(venv)

    # 8. Read any X-Python-Path to include in sys.path
    cdef gchar **extra_paths = xfce_rc_read_list_entry(rc, 'X-Python-Path', ':')

    # 9. Read X-Python-Module as module to import and call plugin_load() from
    cdef gchar *plugin_module_name = g_strdup(xfce_rc_read_entry_untranslated(rc, 'X-Python-Module', NULL))
    if plugin_module_name is NULL:
        fprintf(stderr, 'Unable to find X-Python-Module entry in %s\n', desktop_path)
        exit(1)

    xfce_rc_close(rc)

    cdef char pyvenv_cfg_path[FILENAME_MAX]
    strcpy(<char *>&pyvenv_cfg_path, venv)
    strcat(<char *>&pyvenv_cfg_path, '/pyvenv.cfg')

    cdef FILE *fp = fopen(<char *>&pyvenv_cfg_path, 'r')
    if fp is NULL:
        fprintf(stderr, 'Unable to open %s\n', <char *>&pyvenv_cfg_path)
        exit(1)

    cdef char *line
    cdef size_t line_len = 0
    cdef char home[FILENAME_MAX]
    home[0] = 0
    while getline(&line, &line_len, fp) != -1:
        if sscanf(line, 'home = %s', <char *>&home) == 1:
            break

    fclose(fp)
    fp = NULL

    if home[0] == 0:
        fprintf(stderr, 'Unable to locate "home" directive in %s\n', <char *>&pyvenv_cfg_path)
        exit(1)

    cdef wchar_t whome[FILENAME_MAX * 2]
    mbstowcs(<wchar_t *>&whome, <char *>&home, FILENAME_MAX)

    Py_SetPythonHome(<wchar_t *>&whome)
    Py_Initialize()

    cdef char venv_bin_chars[FILENAME_MAX]
    strcpy(<char *>&venv_bin_chars, venv)
    strcat(<char *>&venv_bin_chars, '/bin/python')

    cdef bytes venv_bin_bytes = <char *>&venv_bin_chars
    cdef str venv_bin = venv_bin_bytes.decode('utf-8')

    cdef dict locals = PyDict_New()
    PyDict_SetItemString(locals, 'venv_bin', venv_bin)

    cdef PyObject *main = PyImport_AddModule('__main__')
    cdef PyObject *globals = PyModule_GetDict(<object>main)

    PyRun_String('''
import sys
sys.executable = venv_bin
path = sys.path
for i in range(len(path)-1, -1, -1):
    if 'site-packages' in path[i] or 'dist-packages' in path[i]:
        path.pop(i)
import site
site.main()
del sys, path, i, site
    ''', Py_file_input, globals, <PyObject *>locals)

    ###
    # Initialize our Cython module
    #  (this allows us to use true Python in the following lines)
    #
    PyImport_ImportModule('libxfce4airhorn')

    ###
    # Monkey-patch in the XfcePanelPlugin methods not exposed by gi
    #
    init_xfce_panel_plugin_class()

    ###
    # Add all extra Python paths
    #
    cdef size_t i = 0
    cdef gchar *path
    cdef bytes path_bytes
    cdef str path_str

    if extra_paths is not NULL:
        import sys

        while True:
            path = extra_paths[i]
            if path is not NULL:
                path_bytes = path
                path_str = path_bytes.decode('utf-8')
                sys.path.append(path_str)
            else:
                break

            i += 1

        g_strfreev(extra_paths)

    ###
    # Load the plugin module
    #
    import importlib
    try:
        plugin_module = importlib.import_module(plugin_module_name.decode('utf-8'))
    except ImportError as e:
        fprintf(stderr, 'Unable to load plugin module %s\n', plugin_module_name)
        print(e)
        exit(1)
    else:
        # We no longer need our duped module name, now that we're imported
        g_free(plugin_module_name)

    ###
    # Create the PyGObject for our XfcePanelPlugin
    #
    cdef object plugin = <object>pygobject_new(<GObject *>xpp)

    ###
    # Pass the plugin PyGObject to the plugin module
    #
    plugin_module.plugin_load(plugin)

    ###
    # Finally, start the mainloop
    #
    Gtk.main()


cdef init_xfce_panel_plugin_class():
    PyXfcePanelPlugin.take_window = py_xfce_panel_plugin_take_window
    PyXfcePanelPlugin.add_action_widget = py_xfce_panel_plugin_add_action_widget
    PyXfcePanelPlugin.menu_insert_item = py_xfce_panel_plugin_menu_insert_item
    PyXfcePanelPlugin.menu_show_configure = py_xfce_panel_plugin_menu_show_configure
    PyXfcePanelPlugin.menu_show_about = py_xfce_panel_plugin_menu_show_about
    PyXfcePanelPlugin.block_menu = py_xfce_panel_plugin_block_menu
    PyXfcePanelPlugin.unblock_menu = py_xfce_panel_plugin_unblock_menu
    PyXfcePanelPlugin.register_menu = py_xfce_panel_plugin_register_menu
    PyXfcePanelPlugin.focus_widget = py_xfce_panel_plugin_focus_widget
    PyXfcePanelPlugin.block_autohide = py_xfce_panel_plugin_block_autohide
    PyXfcePanelPlugin.lookup_rc_file = py_xfce_panel_plugin_lookup_rc_file
    PyXfcePanelPlugin.save_location = py_xfce_panel_plugin_save_location


cdef load_plugin(XfcePanelPlugin *xpp) with gil:

    cdef object plugin = <object>pygobject_new(<GObject *>xpp)

    import xfce4_airhorn
    xfce4_airhorn.plugin_load(plugin)

    Gtk.main()
