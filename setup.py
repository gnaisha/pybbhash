import sys
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

EXTRA_COMPILE_ARGS=['-std=c++11']
if sys.platform == 'darwin':              # Mac OS X?
    EXTRA_COMPILE_ARGS.extend(['-arch', 'x86_64', '-mmacosx-version-min=10.7',
                               '-stdlib=libc++'])
 

setup(
   name='bbhash',
   version='0.1dev2',
   description="A Python wrapper for the BBHash Minimal Perfect Hash Function",
   author="C. Titus Brown",
   author_email="titus@idyll.org",
   license="BSD 3-clause",
   url="http://github.com/dib-lab/pybbhash",
   setup_requires=["Cython>=0.25.2", "setuptools>=18.0"],
   install_requires=['Cython>=0.25.2', "setuptools>=18.0"],
   ext_modules =
          [Extension('bbhash',
                     sources=['bbhash.pyx'],
                     depends=['BooPHF.h'],
                     language='c++',
                     extra_compile_args=EXTRA_COMPILE_ARGS)],
   headers=['BooPHF.h'],
   cmdclass = {'build_ext': build_ext}
)
