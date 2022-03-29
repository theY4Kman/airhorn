#include <string.h>
#include <dlfcn.h>

#include <libxfce4util/libxfce4util.h>
#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-macros.h>
#include <gtk/gtk.h>
#include <Python.h>
#include <canberra.h>
#include <gsound.h>
#include <pygobject.h>

#include "libxfce4airhorn.h"


/* prototypes */
static void
airhorn_construct(XfcePanelPlugin *plugin);


/* register the plugin */
XFCE_PANEL_PLUGIN_REGISTER (airhorn_construct);


#define CONFIG_SET(attr, value) \
    status = PyConfig_SetBytesString(&config, &config.attr, value); \
    if (PyStatus_Exception(status)) { \
        goto fail; \
    }


static void
airhorn_construct(XfcePanelPlugin *xpp) {
    PyStatus status;
    PyConfig config;

    dlopen("libpython3.10.so", RTLD_LAZY | RTLD_GLOBAL);
    dlopen("libcanberra.so", RTLD_LAZY | RTLD_GLOBAL);
    dlopen("libgsound.so", RTLD_LAZY | RTLD_GLOBAL);

    setbuf(stdout, NULL);

    if (PyImport_AppendInittab("libxfce4airhorn", PyInit_libxfce4airhorn) == -1) {
        fprintf(stderr, "Error: could not extend in-built modules table\n");
        exit(1);
    }


    init_plugin(xpp);

//    PyConfig_InitPythonConfig(&config);
//    config.site_import = 1;
//
//    CONFIG_SET(home, "/usr");
//    CONFIG_SET(base_prefix, "/usr");
//    CONFIG_SET(prefix, "/home/they4kman/.virtualenvs/airhorn");
//    CONFIG_SET(exec_prefix, "/home/they4kman/.virtualenvs/airhorn");
//    CONFIG_SET(base_exec_prefix, "/usr");
//    CONFIG_SET(executable, "/home/they4kman/.virtualenvs/airhorn/bin/python");
//
//
//    Py_InitializeFromConfig(&config);
//
//    PyObject *sys_path = PySys_GetObject("path");
//    PyList_Append(sys_path, PyUnicode_FromString("/usr/lib/xfce4/panel/plugins/airhorn"));
//
//    PyObject *gi = PyImport_Import(PyUnicode_FromString("gi"));
//    PyObject_CallMethod(gi, "require_version", "ss", "Gtk", "3.0");
//    if (PyErr_Occurred()) goto py_error;

//    PyObject *_gi = PyImport_Import(PyUnicode_FromString("gi._gi"));
//    PyObject *_gi_so_path_o = PyObject_GetAttrString(_gi, "__file__");
//    const char *_gi_so_path = PyUnicode_AsUTF8(_gi_so_path_o);
//    dlopen(_gi_so_path, RTLD_LAZY | RTLD_GLOBAL);
//    if (PyErr_Occurred()) goto py_error;

//    PyObject *_gobject = PyImport_Import(PyUnicode_FromString("gi._gi"));
//    PyObject *cobject = PyObject_GetAttrString(_gobject, "_PyGObject_API");
//    _PyGObject_API = (struct _PyGObject_Functions *) PyCapsule_GetPointer(cobject, "gobject._PyGObject_API");
//    if (PyErr_Occurred()) goto py_error;


//    PyObject *GtkWindow = PyObject_GetAttrString(Gtk, "Window");
//
//    PyObject *capsule = PyCapsule_New(xpp, "airhorn window", NULL);
//    PyObject *window = PyObject_CallFunction(GtkWindow, "");
//    PyObject_SetAttrString(window, "__gpointer__", capsule);

    // Load Gtk first, to initialize widget classes
//    PyImport_Import(PyUnicode_FromString("gi.repository.Gtk"));
//    if (PyErr_Occurred()) goto py_error;
//
//    PyObject *window = pygobject_new((GObject *)xpp);
//    if (PyErr_Occurred()) goto py_error;

    // Call the libxfce4airhorn init func
//    PyImport_ImportModule("libxfce4airhorn");
//    init_plugin(xpp);

//    if (PyErr_Occurred()) goto py_error;
//    PyObject_CallMethod(libxfce4airhorn, "init_plugin", "O", window);
//    if (PyErr_Occurred()) goto py_error;

//    PyObject *xfce4_airhorn = PyImport_ImportModule("xfce4_airhorn");
//    if (PyErr_Occurred()) goto py_error;
//
////    PyObject *plugin = PyObject_CallMethod(xfce4_airhorn, "Xfce4Airhorn", "O", window);
//    PyObject_CallMethod(xfce4_airhorn, "plugin_load", "O", window);
//    if (PyErr_Occurred()) goto py_error;
//
//    printf("initialized plugin!\n\n");
//
//    PyRun_SimpleString("from gi.repository import Gtk\nGtk.main()");
//    if (PyErr_Occurred()) goto py_error;
//    PyObject *Gtk = PyImport_Import(PyUnicode_FromString("gi.repository.Gtk"));
//    PyObject_CallMethod(Gtk, "main", "");

    printf("exiting ...\n\n");

    goto done;

py_error:
    PyErr_Print();

done:
    Py_Finalize();
    return;

fail:
    PyConfig_Clear(&config);
    Py_ExitStatusException(status);
}
