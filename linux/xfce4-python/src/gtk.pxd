from glib_object cimport GType

cdef extern from '<gtk-3.0/gtk/gtk.h>':
    ctypedef enum GtkOrientation:
        GTK_ORIENTATION_HORIZONTAL
        GTK_ORIENTATION_VERTICAL

    ctypedef enum GtkArrowType:
        GTK_ARROW_UP
        GTK_ARROW_DOWN
        GTK_ARROW_LEFT
        GTK_ARROW_RIGHT
        GTK_ARROW_NONE

    ctypedef struct GtkWindow
    ctypedef struct GtkWidget
    ctypedef struct GtkMenuItem
    ctypedef struct GtkMenu

    GType gtk_widget_get_type()
    GType gtk_window_get_type()
    GType gtk_menu_item_get_type()
    GType gtk_menu_get_type()
