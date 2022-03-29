from cpython.object cimport PyObject


cdef extern from 'Python.h':
    int Py_file_input
    PyObject* PyRun_String(const char *str, int start, PyObject *globals, PyObject *locals)
