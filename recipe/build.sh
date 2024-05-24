#!/bin/bash

set -eox pipefail

#export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig
#export PIP_NO_BUILD_ISOLATION=True
#export PIP_NO_DEPENDENCIES=True
#export PIP_IGNORE_INSTALLED=True
#export PIP_NO_INDEX=True
#export PYTHONDONTWRITEBYTECODE=True

#EXTRA_FLAGS=""
#NP_INC="${SP_DIR}/numpy/core/include/"
echo "PYTHON TARGET=${PYTHON}"

if [ `uname` == Darwin ]; then
    export  LDFLAGS="$LDFLAGS  -Wl,-flat_namespace,-undefined,suppress"
fi


#if [[ $CONDA_BUILD_CROSS_COMPILATION == "1" ]]; then
    # Add pkg-config to cross-file binaries since meson will disable it
    # See https://github.com/mesonbuild/meson/issues/7276
    #echo "pkg-config = '$(which pkg-config)'" >> "$BUILD_PREFIX"/meson_cross_file.txt
    # Use Meson cross-file flag to enable cross compilation
    #EXTRA_FLAGS="--cross-file $BUILD_PREFIX/meson_cross_file.txt"
    #NP_INC=""
#fi

# This is done on two lines so that the command will return failure info if it fails
#PKG_CONFIG=$(which pkg-config)
#export PKG_CONFIG

#########
## FOR SETUPTOOLS

# MESON_ARGS is used within setup.py to pass extra arguments to meson
# We need these so that dependencies on the build machine are not incorrectly used by meson when building for a different target
#export MESON_ARGS="-Dincdir_numpy=${NP_INC} -Dpython_target=${PYTHON} ${MESON_ARGS}"
export MESON_ARGS="-Dpython_target=${PYTHON} ${MESON_ARGS}"

# We use this instead of pip install . because the way meson builds from within a conda-build process puts the build
# artifacts where pip install . can't find them. Here we explicitly build the wheel into the working director, wherever that is
# and then tell pip to install the wheel in the working directory. Also, python -m build is now the recommended way to build
# see https://packaging.python.org/en/latest/tutorials/packaging-projects/
$PYTHON -m build -n -x -w .
$PYTHON -m pip install --prefix "${PREFIX}" --no-deps dist/*.whl
#pip install --prefix "${PREFIX}" --no-deps --no-index --find-links dist pyoptsparse
#bin/rm -rf ${SP_DIR}/meson_build

#########
## IF SWITCH BACK TO MESON-PYTHON, DO THIS INSTEAD:

# HACK: extend $CONDA_PREFIX/meson_cross_file that's created in
# https://github.com/conda-forge/ctng-compiler-activation-feedstock/blob/main/recipe/activate-gcc.sh
# https://github.com/conda-forge/clang-compiler-activation-feedstock/blob/main/recipe/activate-clang.sh
# to use host python; requires that [binaries] section is last in meson_cross_file
#echo "python = '${PREFIX}/bin/python'" >> ${CONDA_PREFIX}/meson_cross_file.txt

# meson-python already sets up a -Dbuildtype=release argument to meson, so
# we need to strip --buildtype out of MESON_ARGS or fail due to redundancy
#MESON_ARGS_REDUCED="$(echo $MESON_ARGS | sed 's/--buildtype release //g')"

# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
#$PYTHON -m build -w -n -x -Csetup-args=${MESON_ARGS_REDUCED// / -Csetup-args=} || (cat build/meson-logs/meson-log.txt && exit 1)

#$PYTHON -m pip install --no-deps --no-build-isolation dist/py*.whl
