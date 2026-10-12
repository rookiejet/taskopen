@echo off
rem Edit the raw annotation text.
rem
rem Usage: rawedit ^<id^|uuid^> "annotation text"
rem
rem Use with the following lines in taskopen's config file:
rem   [Actions]
rem   edit.regex = ".*"
rem   edit.command = "rawedit $UUID \"$ANNOTATION\""
rem
rem   [CLI]
rem   alias.edit = "normal --include=edit"
rem
rem Requires the EDITOR environment variable to name an editor.

setlocal EnableExtensions DisableDelayedExpansion

if "%~2"=="" (
    echo Usage: %~nx0 ^<id^|uuid^> "annotation text"
    exit /b 1
)

set "ID=%~1"
set "OLD=%~2"

rem note: taskwarrior does not support multi-line annotations, therefore only
rem       the first line of the edited file is used
set "TMPFILE=%TEMP%\taskopen_rawedit_%RANDOM%_%RANDOM%.txt"
set "NEW="
setlocal EnableDelayedExpansion
>"!TMPFILE!" echo(!OLD!
call %EDITOR% "!TMPFILE!"
set /p "NEW="<!TMPFILE!
del "!TMPFILE!" >NUL 2>&1

if "!OLD!"=="!NEW!" (
    echo No changes detected
    exit /b 0
)

rem TODO remove as soon as tw bug TW-1821 has been fixed ('/'s must still be escaped)
echo(!OLD!| findstr /C:"/" >NUL
if not errorlevel 1 (
    echo Cannot replace annotations which contain '/'s ^(see #1174^).
    exit /b 1
)
rem END REMOVE

task !ID! mod "/!OLD!/!NEW!/"
exit /b !ERRORLEVEL!
