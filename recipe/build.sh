#!/bin/bash
set -ex

export PIP_NO_BUILD_ISOLATION=True
export PIP_NO_DEPENDENCIES=True
export PIP_IGNORE_INSTALLED=True
export PIP_NO_INDEX=True
export PYTHONDONTWRITEBYTECODE=True

# HACK: extend $CONDA_PREFIX/meson_cross_file that's created in
# https://github.com/conda-forge/ctng-compiler-activation-feedstock/blob/main/recipe/activate-gcc.sh
# https://github.com/conda-forge/clang-compiler-activation-feedstock/blob/main/recipe/activate-clang.sh
# to use host python; requires that [binaries] section is last in meson_cross_file
echo "python = '${PREFIX}/bin/python'" >> ${CONDA_PREFIX}/meson_cross_file.txt

# meson-python already sets up a -Dbuildtype=release argument to meson, so
# we need to strip --buildtype out of MESON_ARGS or fail due to redundancy
MESON_ARGS_REDUCED="$(echo $MESON_ARGS | sed 's/--buildtype release //g')"

# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
$PYTHON -m build -w -n -x -Csetup-args=${MESON_ARGS_REDUCED// / -Csetup-args=} || (cat build/meson-logs/meson-log.txt && exit 1)

$PYTHON -m pip install dist/py*.whl --force-reinstall
