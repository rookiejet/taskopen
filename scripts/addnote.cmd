@echo off
rem Annotates a task with 'Notes' or 'Notes.*'.
rem
rem Usage: addnote <id>
rem
rem INSTALLATION
rem Add this to your ~/.taskrc:
rem  alias.addnote=execute C:\path\to\addnote.cmd

setlocal EnableExtensions DisableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<id^>
    exit /b 1
)

rem read the description from 'task <id> info'
set "DESC="
for /f "tokens=1,*" %%A in ('task %~1 info ^| findstr /B /C:"Description"') do set "DESC=%%B"

setlocal EnableDelayedExpansion
echo Attaching to task %~1 '!DESC!'.
endlocal

set "EXT="
set /p "EXT=Type a file extension (or none): "

set "ANN=Notes"
if not "%EXT%"=="" set "ANN=Notes.%EXT%"

task %~1 annotate -- %ANN%
exit /b %ERRORLEVEL%
