from glib cimport gsize


cdef extern from '<glib-object.h>':
    ctypedef gsize GType
    ctypedef struct GObject
    ctypedef struct GValue
    ctypedef struct GParamSpec
    ctypedef struct GInterfaceInfo
