from libc.stddef cimport wchar_t


cdef extern from '<stdlib.h>':
    size_t mbstowcs(wchar_t *pwcs, const char *str, size_t n)
