@echo off
rem This script is supposed to be used with an archive action such as the following:
rem   archfiles.regex = "Documents\\\\((?:Projects|Notes)\\\\.*)"
rem   archfiles.command = "archive $FILE %USERPROFILE%\\archive\\$LAST_MATCH"
rem   archfiles.filtercommand = "archive $FILE"
rem
rem Usage: archive <srcpath> [<dstpath>]
rem
rem With only one argument, the script tests whether the file is ready to be
rem archived. With two arguments, the file is moved and the annotation of the
rem referencing task is updated.

setlocal EnableExtensions DisableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<srcpath^> ^<dstpath^>
    exit /b 1
)

set "SRCFILE=%~1"

rem taskwarrior does not support search patterns with '/'s or '\'s;
rem as a workaround, we replace them by regex '.'s
set "SEARCH=%SRCFILE:\=.%"
set "SEARCH=%SEARCH:/=.%"

if not "%~2"=="" goto :move

rem only test if path is ready to be archived
set "COUNT=0"
for /f %%I in ('task _ids "%SEARCH%" ^| find /c /v ""') do set "COUNT=%%I"
if "%COUNT%"=="1" (
    echo okay
    exit /b 0
)
echo Not archivable
exit /b 1

:move
set "DSTFILE=%~2"
for %%I in ("%DSTFILE%") do set "DSTPATH=%%~dpI"
if not exist "%DSTPATH%" mkdir "%DSTPATH%"
move /Y "%SRCFILE%" "%DSTFILE%" >NUL
if errorlevel 1 exit /b 1

set "IDS="
for /f "delims=" %%I in ('task uuids "%SEARCH%"') do set "IDS=%%I"

task %IDS% denotate -- "%SRCFILE%" && task %IDS% annotate -- "%DSTFILE%"
exit /b %ERRORLEVEL%
