@echo off
setlocal

rem robobackup.cmd
set _global_version=0.1

rem The MIT License - http://www.opensource.org/licenses/mit-license.php

rem Copyright (c) 2012 Tor Edvardsson

rem Permission is hereby granted, free of charge, to any person obtaining a copy
rem of this software and associated documentation files (the "Software"), to deal
rem in the Software without restriction, including without limitation the rights
rem to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
rem copies of the Software, and to permit persons to whom the Software is
rem furnished to do so, subject to the following conditions:

rem The above copyright notice and this permission notice shall be included in
rem all copies or substantial portions of the Software.

rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
rem IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
rem AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
rem OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
rem THE SOFTWARE.


rem TODO
rem help
rem zip support?
rem detect aborted backups
rem command line parameters
rem remove old backups
rem checkout archive
rem exclude files
rem exlude dirs
rem debug mode

rem GLOBALS
rem _global_version
rem _global_year
rem _global_month
rem _global_day
rem _global_hours
rem _global_minutes
rem _global_ts
rem _global_number_of_tries

set _source_dir=C:\Foo\Bar
set _target_dir=F:\Gazonk\Donk

set _global_number_of_tries=2

call :getDate _global_year,_global_month,_global_day
call :getTime _global_hours,_global_minutes
set _global_ts=%_global_year%-%_global_month%-%_global_day%-%_global_hours%-%_global_minutes%


rem echo [%_global_year%] [%_global_month%] [%_global_day%] [%_global_hours%] [%_global_minutes%]
rem echo [%_global_ts%]

call :doBackup "%_source_dir%","%_target_dir%"

endlocal
goto :eof

:getDate
    setlocal
    for /f "tokens=3" %%g in (
        'reg query "HKEY_CURRENT_USER\Control Panel\International" /v sDate') do (
            set _date_delim=%%g
        )
    )

    if %_date_delim%=="" (
        echo ERROR: Failed to read registry for date delimiter.
        exit /b 1
    )
    
    for /f "tokens=1,2,3 delims=%_date_delim%" %%g in ('date /t') do (
        set _year=%%g
        set _month=%%h
        set _day=%%i
    )
    call :stripSpaces %_day%,_day      rem why is there an extra space in _day?
    endlocal & (
        set %~1=%_year%
        set %~2=%_month%
        set %~3=%_day%
    )
goto :eof

:getTime
    setlocal
    for /f "tokens=3" %%g in (
        'reg query "HKEY_CURRENT_USER\Control Panel\International" /v sTime') do (
            set _time_delim=%%g
        )
    )

    if %_time_delim%=="" (
        echo ERROR: Failed to read registry for time delimiter.
        exit /b 1
    )

    for /f "tokens=1,2 delims=%_time_delim%" %%g in ('time /t') do (
        set _hours=%%g
        set _minutes=%%h
    )
    endlocal & (
        set %~1=%_hours%
        set %~2=%_minutes%
    )
goto :eof

:doBackup
    setlocal
    set _from_dir=%~1
    set _to_dir=%~2

    dir "%_from_dir%" >nul 2>&1
    if not exist "%_from_dir%" (
        echo ERROR: Can't find source directory %_from_dir%
        exit /b 1
    )

    dir "%_to_dir%" >nul 2>&1
    if not exist "%_to_dir%" (
        echo ERROR: Can't find target directory %_to_dir%
        exit /b 1
    )

    set _base_dir=%_to_dir%\%_global_year%\%_global_month%
    set _complete_dir=%_base_dir%\complete_%_global_ts%
    set _complete_log=%_complete_dir%.log
    set _incremental_dir=%_base_dir%\incremental_%_global_ts%
    set _incremental_log=%_incremental_dir%.log
    
    rem echo %_base_dir%
    rem echo %_complete_dir%
    rem echo %_incremental_dir%
    
    if not exist "%_base_dir%" (
        call :doComplete "%_from_dir%","%_complete_dir%","%_complete_log%"
    ) else (
        call :doIncremental "%_from_dir%","%_incremental_dir%","%_incremental_log%"
    )
    endlocal
goto :eof

:doComplete
    setlocal
    echo Starting complete backup.
    set _from_dir=%~1
    set _to_dir=%~2
    set _log_file=%~3

    rem echo [%_from_dir%] [%_to_dir%] [%_log_file%]

    if not exist "%_to_dir%" (
        mkdir "%_to_dir%"
    )

    robocopy "%_from_dir%" "%_to_dir%" /E /R:%_global_number_of_tries% /CREATE /NP /LOG:"%_log_file%
    robocopy "%_from_dir%" "%_to_dir%" /E /R:%_global_number_of_tries% /NP /LOG+:"%_log_file%
    attrib -A "%_from_dir%" /S /D
    endlocal
goto :eof

:doIncremental
    setlocal
    echo Starting incremental backup.
    set _from_dir=%~1
    set _to_dir=%~2
    set _log_file=%~3

    rem echo [%_from_dir%] [%_to_dir%] [%_log_file%]

    if not exist "%_to_dir%" (
        mkdir "%_to_dir%"
    )

    robocopy "%_from_dir%" "%_to_dir%" /M /R:%_global_number_of_tries% /NP /LOG:"%_log_file%
    endlocal
goto :eof

:stripSpaces
    setlocal
    set _tmp=%~1
    endlocal & set %~2=%_tmp%
goto :eof
