@echo on
setlocal enabledelayedexpansion

REM Set a few environment variables that are not set due to
REM https://github.com/conda/conda-build/issues/3993
REM set PIP_NO_BUILD_ISOLATION=True
REM set PIP_NO_DEPENDENCIES=True
REM set PIP_IGNORE_INSTALLED=True
REM set PIP_NO_INDEX=True
REM set PYTHONDONTWRITEBYTECODE=True

REM check if clang-cl is on path as required
clang-cl.exe --version
if %ERRORLEVEL% neq 0 exit 1

REM set compilers to clang-cl
set "CC=clang-cl"
set "CXX=clang-cl"

REM flang 17 still uses "temporary" name
set "FC=flang-new"

REM need to read clang version for path to compiler-rt
FOR /F "tokens=* USEBACKQ" %%F IN (`clang.exe -dumpversion`) DO (
    SET "CLANG_VER=%%F"
)

REM attempt to match flags for flang as we set them for clang-on-win, see
REM https://github.com/conda-forge/clang-win-activation-feedstock/blob/main/recipe/activate-clang_win-64.sh
REM however, -Xflang --dependent-lib=msvcrt currently fails as an unrecognized option, see also
REM https://github.com/llvm/llvm-project/issues/63741
set "FFLAGS=-D_CRT_SECURE_NO_WARNINGS -D_MT -D_DLL --target=x86_64-pc-windows-msvc -nostdlib"
set "LDFLAGS=--target=x86_64-pc-windows-msvc -nostdlib -Xclang --dependent-lib=msvcrt -fuse-ld=lld"
set "LDFLAGS=%LDFLAGS% -Wl,-defaultlib:%BUILD_PREFIX%/Library/lib/clang/!CLANG_VER:~0,2!/lib/windows/clang_rt.builtins-x86_64.lib"

REM see explanation here:
REM https://github.com/conda-forge/scipy-feedstock/pull/253#issuecomment-1732578945
set "MESON_RSP_THRESHOLD=320000"

%PYTHON% -m pip install --prefix "%PREFIX%" --no-deps --no-build-isolation . -vv
REM -wnx flags mean: --wheel --no-isolation --skip-dependency-check
REM %PYTHON% -m build -w -n -x .
REM if %ERRORLEVEL% neq 0 (type builddir\meson-logs\meson-log.txt && exit 1)

REM `pip install dist\numpy*.whl` does not work on windows,
REM so use a loop; there's only one wheel in dist/ anyway
REM for /f %%f in ('dir /b /S .\dist') do (
    REM need to use force to reinstall the tests the second time
    REM (otherwise pip thinks the package is installed already)
    REM %PYTHON% -m pip install --prefix "%PREFIX%" --no-deps %%f
    REM if %ERRORLEVEL% neq 0 exit 1
REM )
