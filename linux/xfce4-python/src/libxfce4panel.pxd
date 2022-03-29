from gtk cimport GtkOrientation, GtkArrowType, GtkWindow, GtkWidget, GtkMenuItem, GtkMenu
from glib cimport gchar, gint, guint, gpointer, gboolean
from glib_object cimport GType


cdef extern from '<libxfce4panel/xfce-panel-plugin.h>':
    ctypedef struct XfcePanelPlugin

    ctypedef enum XfcePanelPluginMode:
        XFCE_PANEL_PLUGIN_MODE_HORIZONTAL
        XFCE_PANEL_PLUGIN_MODE_VERTICAL
        XFCE_PANEL_PLUGIN_MODE_DESKBAR

    ctypedef enum XfceScreenPosition:
        XFCE_SCREEN_POSITION_NONE

        # top
        XFCE_SCREEN_POSITION_NW_H           # North West Horizontal
        XFCE_SCREEN_POSITION_N              # North
        XFCE_SCREEN_POSITION_NE_H           # North East Horizontal

        # left
        XFCE_SCREEN_POSITION_NW_V           # North West Vertical
        XFCE_SCREEN_POSITION_W              # West
        XFCE_SCREEN_POSITION_SW_V           # South West Vertical

        # right
        XFCE_SCREEN_POSITION_NE_V           # North East Vertical
        XFCE_SCREEN_POSITION_E              # East
        XFCE_SCREEN_POSITION_SE_V           # South East Vertical

        # bottom
        XFCE_SCREEN_POSITION_SW_H           # South West Horizontal
        XFCE_SCREEN_POSITION_S              # South
        XFCE_SCREEN_POSITION_SE_H           # South East Horizontal

        # floating
        XFCE_SCREEN_POSITION_FLOATING_H     # Floating Horizontal
        XFCE_SCREEN_POSITION_FLOATING_V     # Floating Vertical


    const GType           xfce_panel_plugin_get_type()
    const gchar          *xfce_panel_plugin_get_name            (XfcePanelPlugin   *plugin)

    const gchar          *xfce_panel_plugin_get_display_name    (XfcePanelPlugin   *plugin)

    const gchar          *xfce_panel_plugin_get_comment         (XfcePanelPlugin   *plugin)

    gint                  xfce_panel_plugin_get_unique_id       (XfcePanelPlugin   *plugin)

    const gchar          *xfce_panel_plugin_get_property_base   (XfcePanelPlugin   *plugin)

    const gchar *        *xfce_panel_plugin_get_arguments       (XfcePanelPlugin   *plugin)

    gint                  xfce_panel_plugin_get_size            (XfcePanelPlugin   *plugin)

    gboolean              xfce_panel_plugin_get_expand          (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_set_expand          (XfcePanelPlugin   *plugin,
                                                                 gboolean           expand)

    gboolean              xfce_panel_plugin_get_shrink          (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_set_shrink          (XfcePanelPlugin   *plugin,
                                                                 gboolean           shrink)

    gboolean              xfce_panel_plugin_get_small           (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_set_small           (XfcePanelPlugin   *plugin,
                                                                 gboolean           small)

    gint                  xfce_panel_plugin_get_icon_size       (XfcePanelPlugin   *plugin)

    GtkOrientation        xfce_panel_plugin_get_orientation     (XfcePanelPlugin   *plugin)

    XfcePanelPluginMode   xfce_panel_plugin_get_mode            (XfcePanelPlugin   *plugin)

    guint                 xfce_panel_plugin_get_nrows           (XfcePanelPlugin   *plugin)

    XfceScreenPosition    xfce_panel_plugin_get_screen_position (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_take_window         (XfcePanelPlugin   *plugin,
                                                                 GtkWindow         *window)

    void                  xfce_panel_plugin_add_action_widget   (XfcePanelPlugin   *plugin,
                                                                 GtkWidget         *widget)

    void                  xfce_panel_plugin_menu_insert_item    (XfcePanelPlugin   *plugin,
                                                                 GtkMenuItem       *item)

    void                  xfce_panel_plugin_menu_show_configure (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_menu_show_about     (XfcePanelPlugin   *plugin)

    gboolean              xfce_panel_plugin_get_locked          (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_remove              (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_block_menu          (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_unblock_menu        (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_register_menu       (XfcePanelPlugin   *plugin,
                                                                 GtkMenu           *menu)

    GtkArrowType          xfce_panel_plugin_arrow_type          (XfcePanelPlugin   *plugin)

    void                  xfce_panel_plugin_position_widget     (XfcePanelPlugin   *plugin,
                                                                 GtkWidget         *menu_widget,
                                                                 GtkWidget         *attach_widget,
                                                                 gint              *x,
                                                                 gint              *y)

    void                  xfce_panel_plugin_position_menu       (GtkMenu           *menu,
                                                                 gint              *x,
                                                                 gint              *y,
                                                                 gboolean          *push_in,
                                                                 gpointer           panel_plugin)

    void                  xfce_panel_plugin_focus_widget        (XfcePanelPlugin   *plugin,
                                                                 GtkWidget         *widget)

    void                  xfce_panel_plugin_block_autohide      (XfcePanelPlugin   *plugin,
                                                                 gboolean           blocked)

    gchar                *xfce_panel_plugin_lookup_rc_file      (XfcePanelPlugin   *plugin)

    gchar                *xfce_panel_plugin_save_location       (XfcePanelPlugin   *plugin,
                                                                 gboolean           create)
