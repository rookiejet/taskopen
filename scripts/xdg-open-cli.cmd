@echo off
rem Use this script to overwrite the default file opener with %EDITOR% for
rem text files.
rem
rem Usage: xdg-open-cli <file-path>

setlocal EnableExtensions

if "%~1"=="" (
    echo Usage: %~nx0 ^<file-path^>
    exit /b 1
)

rem use %EDITOR% for opening text files
for %%E in (.txt .text .md .markdown .rst .log .csv .tsv .json .yaml .yml .xml .ini .cfg .conf .toml .nim .c .h .cpp .py .rb .js .ts .css .html .sh .bat .cmd .ps1) do (
    if /I "%%E"=="%~x1" (
        call %EDITOR% "%~1"
        exit /b %ERRORLEVEL%
    )
)

start "" "%~1"
exit /b 0
