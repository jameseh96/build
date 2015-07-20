@REM Common script run by various Jenkins commit-validation builds.

@REM Checks out the changeset specified by (GERRIT_PROJECT,GERRIT_REFSPEC) from
@REM Gerrit server GERRIT_HOST:GERRIT_PORT, compiles and then runs unit tests
@REM for GERRIT_PROJECT (if applicable).
@REM
@REM Triggered on patchset creation in a project's repo.

@IF NOT DEFINED GERRIT_HOST (
    @echo "Error: Required environment variable 'GERRIT_HOST' not set."
    @exit /b 1
)

@IF NOT DEFINED GERRIT_PORT (
    @echo "Error: Required environment variable 'GERRIT_PORT' not set."
    @exit /b 2
)

@IF NOT DEFINED GERRIT_PROJECT (
    @echo "Error: Required environment variable 'GERRIT_PROJECT' not set."
    @exit /b 3
)

@IF NOT DEFINED GERRIT_REFSPEC (
    @echo "Error: Required environment variable 'GERRIT_REFSPEC' not set."
    @exit /b 4
)
@IF NOT DEFINED target_arch (
    set target_arch=amd64
    @echo Notice: environment variable 'target_arch' not set. Defaulting to 'amd64'.
)

@REM How many jobs to run in parallel by default?
@IF NOT DEFINED PARALLELISM (
    set PARALLELISM=8
)
@IF NOT DEFINED TEST_PARALLELISM (
    set TEST_PARALLELISM=%PARALLELISM%
)

@echo.
@echo ============================================
@echo ===    environment                       ===
@echo ============================================

set
@echo.
set source_root=%WORKSPACE%
call tlm\win32\environment
@echo on

@echo.
@echo ============================================
@echo ===    clean                             ===
@echo ============================================

@REM Windows build is serial and there is no ccache, hence very slow.
@REM To try to alleviate this, we *don't* perform a top-level clean, only for
@REM the project subdirectory and Go objects (as it's incremental build is a bit flaky).
@REM This should speed things up a little, but still
@REM ensures that the correct number of warnings are reported for this project.
pushd build\%GERRIT_PROJECT%
nmake clean
popd
del /F/Q/S godeps\pkg goproj\pkg goproj\bin

@echo.
@echo ============================================
@echo ===    update %GERRIT_PROJECT%           ===
@echo ============================================

@REM there are components (eg build) that don't get checked out
@REM to the directory by the same name. Figure out the checkout
@REM dir using repo (CBD-1587). All repo commands are not windows
@REM compatible like repo forall. So we have use this method on
@REM windows
set CHECKOUT_DIR=%GERRIT_PROJECT%
set BASE_DIR=%GERRIT_PROJECT%
for /f "tokens=1-3" %%i in ('repo info %GERRIT_PROJECT% ^| findstr "Mount Path"') do (
    set BASE_DIR=%%k
)
for /f %%i in ("%BASE_DIR%") do set CHECKOUT_DIR=%%~ni

pushd %CHECKOUT_DIR%
@REM Both of these *must* succeed to continue; hence goto :error
@REM if either fail.
git fetch ssh://%GERRIT_HOST%:%GERRIT_PORT%/%GERRIT_PROJECT% %GERRIT_REFSPEC% || goto :error
git checkout --force FETCH_HEAD || goto :error
popd

@echo.
@echo ============================================
@echo ===               Build                  ===
@echo ============================================

nmake EXTRA_CMAKE_OPTIONS="" || goto :error

@echo.
@IF NOT DEFINED SKIP_UNIT_TESTS (
    @IF EXIST build\%GERRIT_PROJECT%\Makefile (
        @echo ============================================
        @echo ===          Run unit tests              ===
        @echo ============================================

        pushd build\%GERRIT_PROJECT%
        @REM  -j%PARALLELISM% : Run tests in parallel.
        @REM  -T Test   : Generate XML output file of test results.
        nmake test ARGS="-j%TEST_PARALLELISM% --output-on-failure --no-compress-output -T Test"
        popd
    ) ELSE (
        @echo ============================================
        @echo ===    No ${GERRIT_PROJECT} Makefile - skipping unit tests
        @echo ============================================
    )
) ELSE (
    @echo ============================================
    @echo ===    SKIP_UNIT_TESTS set - skipping unit tests
    @echo ============================================
)

:end
exit /b 0

:error
@echo Previous command failed with error #%errorlevel%.
exit /b %errorlevel%
