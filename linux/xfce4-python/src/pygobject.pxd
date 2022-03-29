from cpython cimport PyTypeObject, PyObject

from glib cimport gchar, gint, guint, gpointer, gboolean, GError, GOptionGroup
from glib_object cimport GType, GObject, GValue, GParamSpec, GInterfaceInfo


cdef extern from '<pygobject.h>':
    ctypedef struct GClosure
    ctypedef struct PyGClosure
    ctypedef struct PyGObject

    ctypedef void (*GDestroyNotify)(gpointer data)
    ctypedef void (*PyGThreadBlockFunc) ()
    ctypedef int (*PyGClassInitFunc) (gpointer gclass, PyTypeObject *pyclass)
    ctypedef void (* PyClosureExceptionHandler) (GValue *ret, guint n_param_values, const GValue *params)

    ctypedef struct _PyGObject_Functions "struct _PyGObject_Functions"
    cdef _PyGObject_Functions *_PyGObject_API

    GObject *pygobject_get(PyGObject *v)
    gboolean pygobject_check(PyObject *v, PyObject *base)

    void pygobject_register_class(PyObject *dict, const gchar *class_name, GType gtype, PyTypeObject *type, PyObject *bases);
    void pygobject_register_wrapper(PyObject *self);
    PyTypeObject *pygobject_lookup_class(GType type);
    PyObject *pygobject_new(GObject *obj);
    PyObject *pygobject_new_full(GObject *obj, gboolean steal, gpointer g_class);
    PyTypeObject *PyGObject_Type;

    GClosure *pyg_closure_new(PyObject *callback, PyObject *extra_args, PyObject *swap_data);
    void      pygobject_watch_closure(PyObject *self, GClosure *closure);
    GDestroyNotify pyg_destroy_notify;

    GType pyg_type_from_object(PyObject *obj);
    GType pyg_type_from_object_strict(PyObject *obj, gboolean strict);
    PyObject *pyg_type_wrapper_new(GType type);

    gint pyg_enum_get_value(GType enum_type, PyObject *obj, gint *val);
    gint pyg_flags_get_value(GType flag_type, PyObject *obj, guint *val);
    void pyg_register_gtype_custom(GType gtype, PyObject *(* from_func)(const GValue *value), int (* to_func)(GValue *value, PyObject *obj));
    int pyg_value_from_pyobject(GValue *value, PyObject *obj);
    int pyg_value_from_pyobject_with_error(GValue *value, PyObject *obj);
    PyObject *pyg_value_as_pyobject(const GValue *value, gboolean copy_boxed);

    void pyg_register_interface(PyObject *dict, const gchar *class_name, GType gtype, PyTypeObject *type);

    PyTypeObject *PyGBoxed_Type;
    void pyg_register_boxed(PyObject *dict, const gchar *class_name, GType boxed_type, PyTypeObject *type);
    PyObject *pyg_boxed_new(GType boxed_type, gpointer boxed, gboolean copy_boxed, gboolean own_ref);

    PyTypeObject *PyGPointer_Type;
    void pyg_register_pointer(PyObject *dict, const gchar *class_name, GType pointer_type, PyTypeObject *type);
    PyObject *pyg_pointer_new(GType boxed_type, gpointer pointer);

    void pyg_enum_add_constants(PyObject *module, GType enum_type, const gchar *strip_prefix);
    void pyg_flags_add_constants(PyObject *module, GType flags_type, const gchar *strip_prefix);

    const gchar *pyg_constant_strip_prefix(const gchar *name, const gchar *strip_prefix);

    gboolean pyg_error_check(GError **error);

    PyTypeObject *PyGParamSpec_Type;
    PyObject *pyg_param_spec_new(GParamSpec *spec);
    GParamSpec *pyg_param_spec_from_object(PyObject *tuple);
    int pyg_pyobj_to_unichar_conv(PyObject *pyobj, void* ptr);
    PyObject *pyg_param_gvalue_as_pyobject(const GValue* gvalue, gboolean copy_boxed, const GParamSpec* pspec);
    int pyg_param_gvalue_from_pyobject(GValue* value, PyObject* py_obj, const GParamSpec* pspec);

    PyTypeObject *PyGEnum_Type;
    PyObject *pyg_enum_add(PyObject *module, const char *type_name_, const char *strip_prefix, GType gtype);
    PyObject* pyg_enum_from_gtype(GType gtype, int value);

    PyTypeObject *PyGFlags_Type;
    PyObject *pyg_flags_add(PyObject *module, const char *type_name_, const char *strip_prefix, GType gtype);
    PyObject* pyg_flags_from_gtype(GType gtype, guint value);

    void      pyg_register_class_init(GType gtype, PyGClassInitFunc class_init);
    void      pyg_register_interface_info(GType gtype, const GInterfaceInfo *info);

    void      pyg_add_warning_redirection(const char *domain, PyObject   *warning);
    void      pyg_disable_warning_redirections();

    gboolean  pyg_gerror_exception_check(GError **error);
    PyObject* pyg_option_group_new(GOptionGroup *group);

