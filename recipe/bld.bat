@echo on
setlocal enabledelayedexpansion

REM Set a few environment variables that are not set due to
REM https://github.com/conda/conda-build/issues/3993
set PIP_NO_BUILD_ISOLATION=True
set PIP_NO_DEPENDENCIES=True
set PIP_IGNORE_INSTALLED=True
set PIP_NO_INDEX=True
set PYTHONDONTWRITEBYTECODE=True

REM see explanation here:
REM https://github.com/conda-forge/scipy-feedstock/pull/253#issuecomment-1732578945
set "MESON_RSP_THRESHOLD=320000"

REM MinGW pkgconfig doen't find anything and gets in the way of the conda one
del /s /q %BUILD_PREFIX%\Library\mingw-w64\bin\pkg-config*

REM -wnx flags mean: --wheel --no-isolation --skip-dependency-check
%PYTHON% -m build -w -n -x .
if %ERRORLEVEL% neq 0 (type builddir\meson-logs\meson-log.txt && exit 1)

REM `pip install dist\numpy*.whl` does not work on windows,
REM so use a loop; there's only one wheel in dist/ anyway
for /f %%f in ('dir /b /S .\dist') do (
    REM need to use force to reinstall the tests the second time
    REM (otherwise pip thinks the package is installed already)
    pip install %%f --force-reinstall
    if %ERRORLEVEL% neq 0 exit 1
)
