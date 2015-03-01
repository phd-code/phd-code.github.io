import numpy as np
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
        cmdclass = {'build_ext': build_ext},
        ext_modules = [Extension("load_balance",["load_balance.pyx"],
            #language="c++",
            include_dirs=[np.get_include()])])