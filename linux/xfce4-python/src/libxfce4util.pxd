from glib cimport gchar, gboolean


cdef extern from "libxfce4util/libxfce4util.h":
    ctypedef struct XfceRc

    XfceRc* xfce_rc_simple_open (const gchar *filename, gboolean readonly)
    void xfce_rc_close (XfceRc *rc)

    void xfce_rc_set_group (XfceRc *rc, const gchar *group)
    const gchar* xfce_rc_read_entry_untranslated (const XfceRc *rc, const gchar *key, const gchar *fallback)
    gchar** xfce_rc_read_list_entry (const XfceRc *rc, const gchar *key, const gchar *delimiter)
