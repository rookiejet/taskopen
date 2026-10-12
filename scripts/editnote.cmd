@echo off
rem Opens a Notes file and creates a header if the file does not exist.
rem
rem Usage: editnote <file-path> <description> <uuid>
rem
rem Requires the EDITOR environment variable to name an editor.

setlocal EnableExtensions DisableDelayedExpansion

if "%~3"=="" (
    echo Usage: %~nx0 ^<file-path^> ^<description^> ^<uuid^>
    exit /b 1
)

set "FILE=%~1"
set "DESC=%~2"
set "UUID=%~3"

if not exist "%FILE%" (
    rem create the parent directory and add a markdown task header
    if not exist "%~dp1." mkdir "%~dp1." >NUL 2>&1
    setlocal EnableDelayedExpansion
    >"!FILE!" echo(* [ ] !DESC!  #!UUID!
    endlocal
)

call %EDITOR% "%FILE%"
exit /b %ERRORLEVEL%
