import os
import shlex
import subprocess
import sysconfig
from distutils.core import setup
from typing import Dict, List

from Cython.Build import cythonize
from Cython.Distutils import Extension, build_ext


def parse_cflags(args):
    kwargs = {
        'include_dirs': [],
        'libraries': [],
        'library_dirs': [],
    }
    for arg in args:
        if arg[0] != '-' or len(arg) < 3:
            continue

        opt, value = arg[1], arg[2:]
        if opt == 'I':
            kwargs['include_dirs'].append(value)
        elif opt == 'L':
            kwargs['library_dirs'].append(value)
        elif opt == 'l':
            kwargs['libraries'].append(value)

    return kwargs


def get_pkgconfig_cython_kwargs(*packages):
    res = subprocess.check_output([
        'pkg-config',
        '--cflags',
        '--libs', *packages,
    ])
    res = res.decode('utf-8')
    res = res.strip()
    args = shlex.split(res)

    return parse_cflags(args)


def get_python_config_cython_kwargs():
    res = ' '.join([
        sysconfig.get_config_var('LIBS'),
        sysconfig.get_config_var('INCLUDEPY'),
        sysconfig.get_config_var('BLDLIBRARY'),
    ])
    args = shlex.split(res)

    return parse_cflags(args)


def merge_cython_kwargs(*kwargses: Dict[str, List[str]], **kwargs) -> Dict[str, List[str]]:
    res = {
        'include_dirs': [],
        'libraries': [],
        'library_dirs': [],
        **kwargs,
    }

    for kwargs in kwargses:
        for key, value in kwargs.items():
            if key not in res:
                res[key] = value
            else:
                res[key].extend(value)

    return res


class NoSuffixBuilder(build_ext):
    def get_ext_filename(self, ext_name):
        filename = super().get_ext_filename(ext_name)
        suffix = sysconfig.get_config_var('EXT_SUFFIX')
        _, ext = os.path.splitext(filename)
        return filename.replace(suffix, '') + ext


module_kwargs = merge_cython_kwargs(
    get_pkgconfig_cython_kwargs('libxfce4panel-2.0'),
    get_pkgconfig_cython_kwargs('libxfce4util-1.0'),
    get_pkgconfig_cython_kwargs('pygobject-3.0'),
    get_python_config_cython_kwargs(),
    libraries=['canberra', 'gsound'],
)


setup(
    package_dir={'': 'src'},
    ext_modules=cythonize(
        module_list=[
            Extension(
                name='libxfce4airhorn',
                sources=['src/libxfce4airhorn.pyx', 'src/plugin.c'],
                export_symbols=['xfce_panel_module_construct'],
                extra_link_args=[
                    *shlex.split(sysconfig.get_config_var('LINKFORSHARED')),
                    '-Wl,--allow-multiple-definition',
                ],
                **module_kwargs,
            )
        ],
        gdb_debug=True,
    ),
    cmdclass={'build_ext': NoSuffixBuilder},
)
