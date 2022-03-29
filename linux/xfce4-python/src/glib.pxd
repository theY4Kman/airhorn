cdef extern from '<glib.h>':
    ctypedef char gchar
    ctypedef int gint
    ctypedef unsigned int guint
    ctypedef unsigned long gsize
    ctypedef unsigned long gulong
    ctypedef void *gpointer
    ctypedef gint gboolean
    ctypedef signed long gssize

    ctypedef struct GError
    ctypedef struct GOptionGroup

    void g_free(gpointer mem);

    gchar** g_strsplit(const gchar *string, const gchar *delimiter, gint max_tokens)
    void g_strfreev(gchar **str_array)

    gchar *g_strdup(const gchar *str)
    gchar *g_strrstr(const gchar *haystack, const gchar *needle)
    gchar *g_strstr_len(const gchar *haystack, gssize haystack_len, const gchar *needle)
    gchar *g_strdup_printf(const gchar *format, ...)
