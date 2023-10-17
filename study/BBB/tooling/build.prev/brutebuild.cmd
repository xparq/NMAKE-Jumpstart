@echo off
setlocal EnableExtensions
setlocal EnableDelayedExpansion

::!!!!!!::
:: TODO ::
::!!!!!!::
::
:: -	Add a dep. for at least manual header-change tracking...
::
:: FIX:	No checks for some x=%OBJ_ROOT%\... prefixes, and possibly others!
::	- Some/all iteration loops fail with no exclude patterns (bad conditional structures!)
:: 	E.g. a syntax error for findstr:
::		echo !_f_! | findstr /R "%UNITS_NO_COMPILE_PATH_PATTERN%" > nul
:: -	Option for batch mode on/off! With many files, a comp. error would not
::	write the other successfully compiled ones to disk, so each build
::	would start from scratch! :-/
::
:: -	Use /LIBPATH:$obj_dir + bare obj files for readability -- but only in flat
::	mode, to avoid silent accidental name clashes across multiple subdirs
::	(which are more likely to be intentional namespaces, too, in tree mode!).
::	(Not that it would be easy in tree mode anyway. :) )
::	- It's kinda undocumented tho that it works for obj. files just as well as libs...
::
::++++++::
:: DONE ::
::++++++::
::
:: +	Just use NMAKE's /Y to disable batch mode, that's it.
::

call :setd VERBOSE %1 1
::	0 - 3
set BATCH_COMPILE=on


::============================================================================
:: CONFIG
::============================================================================
call "%~dp0../_setenv.cmd"
:: This has aiso CD'd to the project dir!
:: So...:
call :setd PRJ_ROOT "%PRJ_ROOT%" .

:: Just a synonym, for added confusion:
set "PRJ_DIR=%PRJ_ROOT%"

::!!set MAIN_EXE=$(OUT_DIR)\test.exe

:: These are relative to PRJ_DIR:
set SRC_ROOT=src
::!! This should morph into a higher-level type-wise iteration control to allow
::!! doing different things for different source types...:
set OBJ_SRC_EXTS=.cpp .cc .cxx .ixx .c

set OUT_DIR=out
set OBJ_ROOT=%OUT_DIR%\obj.some-build-variant

::set OBJ_DIR_FLAT=1
	::!! No support for tree modes (normal per-file vs. batched-per-dir) yet!

set IFC_ROOT=%OUT_DIR%

::set UNITS_PATTERN=* <- default
::set UNITS_PATTERN=*.c*
:: Ignore-filter on full-path source names -> NMAKE `filterout` pattern list syntax!
:: Multiple patterns must be separated by spaces. Do NOT quote the list!
set UNITS_NO_COMPILE_PATH_PATTERN=.off .tmp
:: Ignore-filter on full-path source names -> `findstr` REGEX syntax!
:: Multiple patterns must be separated by spaces. Do NOT quote the list!
::
::!!?? WHY DOES FINDSTR TREAT THESE AS REGEXES EVEN WITH /L????????? :-ooooooooooooo
::!! Alas, no nice link-time path filering when OBJ_DIR_FLAT... :-/
::!!set UNITS_NO_AUTOLINK_PATH_PATTERN=\.off \.tmp sz[/\\]test
set     UNITS_NO_AUTOLINK_PATH_PATTERN=\.off \.tmp sz[/\\]test counter.obj 
::
set UNITS_NO_LIB_PATH_PATTERN=%UNITS_NO_AUTOLINK_PATTERN%


::echo PRJ_ROOT: %PRJ_ROOT%
::echo PRJ_DIR: %PRJ_DIR%
::echo BUILD_TOOL_DIR: %BUILD_TOOL_DIR%

::============================================================================
:: ENGINE
::============================================================================
set "TAB=	"

:: Force flat obj dirs (!!should only be done in batch-compile mode!...)
set OBJ_DIR_FLAT=1
	::!! Well, non-flat doesn't work: MSVC can't put objects into various subdirs
	::!! when running in batch mode! :-/ They all must go to the same /Fo dir!

call :addslash BUILD_TOOL_DIR

set "prj_root=%PRJ_DIR%"
call :addslash prj_root_ "%prj_root%"
call :addslash out_dir_  "%OUT_DIR%"

set "src_dir=%prj_root_%%SRC_ROOT%"
set "obj_dir=%prj_root_%%OBJ_ROOT%"
call :addslash src_dir_ "%prj_root_%%SRC_ROOT%"
call :addslash obj_dir_ "%prj_root_%%OBJ_ROOT%"

:: "Own" the source tree...
call :check_dir "%src_dir%" src_dir_abs || exit 1
::echo %src_dir% (echo %src_dir_abs%)

:: Obj_dir would be created if missing, later... -- but that's that thing,
:: "later" would be too late! E.g. the obj. list would be created there, and
:: that's gonna happen pretty soon... So, create it now:
call :check_dir "%obj_dir%" obj_dir_abs || MD "%obj_dir%"
call :check_dir "%obj_dir%" obj_dir_abs || exit 1
::echo %obj_dir% (echo %obj_dir_abs%)


set "MAIN_MAKEFILE=%BUILD_TOOL_DIR%Makefile.msvc"
set "BBB_MAKEFILE_TEMPLATE=%out_dir_%RoboMake.msvc.mak"

set "dirlist_file=%out_dir_%.src-dirs.tmp"
set "srclist_file=%out_dir_%.src-sources.tmp"
set "objlist_file=%out_dir_%.src-objects.tmp"

::
:: Collect candidate source subdirs...
::
if "%VERBOSE%" GEQ "1" echo Preparing to build "%src_dir_abs%"...
:: Add an empty line if more details are expected:
if "%VERBOSE%" GEQ "2" echo.
call :create_dirlist "%dirlist_file%" "%src_dir%" "%UNITS_PATTERN%" "%UNITS_NO_COMPILE_PATH_PATTERN%"
::	Note: This pattern above can only filter dirs in this stage yet!
if "%VERBOSE%" GEQ "2" echo.

::
:: Collect candidate source files...
::
if "%VERBOSE%" GEQ "2" echo Preparing file lists...
if "%VERBOSE%" GEQ "2" echo.
if "%VERBOSE%" GEQ "3" echo Scanning sources:
if exist "%srclist_file%" DEL "%srclist_file%"
if exist "%objlist_file%" DEL "%objlist_file%"
for %%x in (%OBJ_SRC_EXTS%) do ( set _ext_=%%x
if "%VERBOSE%" GEQ "2" echo Collecting *!_ext_!...
rem	call :exec_each "%dirlist%" "if exist src\{}\*!_ext_! dir /b src\{}\*!_ext_!"

	rem !! This + create_dirlist could be replaced with a combined routine
	rem !! that could collect both dirs and files in go of tree iteration
	rem !! (into separete results files) -- if that's actully faster, as
	rem !! this comes right after the tree scan, with a hot cache!...
	rem !! But... FOR /f or /r can only do EITHER files OR dirs, and even
	rem !! if using DIR, the results would still need to be checked for
	rem !! type after the fact! :-/ That doesn't feel like an advantage! :)
	for /r "%src_dir%" %%f in (*!_ext_!) do ( set "_f_abs_=%%f"
		set "_f_=!_f_abs_:%src_dir_abs%\=!"

		echo !_f_! | findstr /R "%UNITS_NO_COMPILE_PATH_PATTERN%" > nul
		if errorlevel 2 (
			echo - ERROR: Failed to apply filter on^: "!_f_!"^^!
			rem exit /b 1
		) else if not errorlevel 1 (
if "%VERBOSE%" GEQ "1" echo - SKIP FILE ^(%UNITS_NO_COMPILE_PATH_PATTERN%^): !_f_!
		) else (
			rem No need to quote: each item is on its own line:
			echo !_f_!>>   "%srclist_file%"
			set _obj_=!_f_:%%x=.obj!

			if defined OBJ_DIR_FLAT (
				rem `basename`...
				for %%F in ("!_obj_!") do set "_obj_=%%~nxF
			)

			echo !_obj_!>> "%objlist_file%"
if "%VERBOSE%" GEQ "2" echo + FILE:^ "!_f_!" %TAB%^(abs: "!_f_abs_!"^)
if "%VERBOSE%" GEQ "3" echo Added obj.:^   "!_obj_!"
		)
	)
rem	if errorlevel 1 exit -1
)
if "%VERBOSE%" GEQ "2" echo.


::----------------------------------------------------------------------------
:: Generate LINK/LIB dependency rules for inclusion from other makefiles...
::-----------------------------------------

	if exist "%BBB_MAKEFILE_TEMPLATE%" DEL "%BBB_MAKEFILE_TEMPLATE%"

	:: Config "glueware" to support including the makefile with adjustable
	:: parameters (e.g. for dependency queries, or real build etc.)

	::! These could in theory be just as well passed via the NMAKE command-line,
	::! but anything non-trivial, with spaces and special chars etc. is a
	::! definite *NIGHTMARE* with CMD, so better just write it as the default,
	::! and then override it from the main, pre-written (caller/driver)
	::! makefile instead!
	echo ^^!if ^^!defined^(BBB_CC_PROXY^) >> "%BBB_MAKEFILE_TEMPLATE%"
	echo BBB_CC_PROXY = @echo $^< >>     "%BBB_MAKEFILE_TEMPLATE%"
	echo ^^!endif >>                     "%BBB_MAKEFILE_TEMPLATE%"

	echo ^^!if ^^!defined^(BBB_MAIN_TARGET^) >> "%BBB_MAKEFILE_TEMPLATE%"
	echo BBB_MAIN_TARGET = %SZ_APPNAME%>>       "%BBB_MAKEFILE_TEMPLATE%"
	echo ^^!endif >>                            "%BBB_MAKEFILE_TEMPLATE%"

	::
	:: Rule for main target depending on all the objs...
	::
	:: Alas, this can't be the same list as a @list file for the linker:
	:: the trailing \ for the makefile lines is unknown to the MSVC tools!
	echo $^(BBB_MAIN_TARGET^): \>> "%BBB_MAKEFILE_TEMPLATE%"
		call :exec_each "%objlist_file%" "echo %TAB%%obj_dir%\{} \" >> "%BBB_MAKEFILE_TEMPLATE%"
	echo. >> "%BBB_MAKEFILE_TEMPLATE%"

::-----------------------------------------
:: Generate Makefile to see what changed...
::-----------------------------------------
	::
	:: Inference rules:
	::

	echo .SUFFIXES: %OBJ_SRC_EXTS% >>  "%BBB_MAKEFILE_TEMPLATE%"

	::call :print_NMAKE_inference_rules "%OBJ_SRC_EXTS%"
	setlocal
	for %%x in (%OBJ_SRC_EXTS%) do ( set _ext_=%%x
		rem !! Can't pass the cmd arg. to print_NMAKE_inference_batch_rule if it contains spaces, because
		rem !! CMD gets confused by its own idiotic quoting rules, let alone the challenge of passing
		rem !! multi-line text, so the command block is passed via %__inference_commands__%...
		set "__inference_commands__=$^(BBB_CC_PROXY^)"
		if "!_ext_!" == ".ixx" (		
rem			set "__inference_commands__=@echo $^(CXX^) $^(CFLAGS^) $^(CXXFLAGS^) -Fo%obj_dir%\{}\ -ifcOutput %obj_dir%\{}\ $^<"
		) else (
rem			set "__inference_commands__=@echo $^(CXX^) $^(CFLAGS^) $^(CXXFLAGS^) -Fo%obj_dir%\{}\ $^<"
		)
		echo.>> "%BBB_MAKEFILE_TEMPLATE%"
		echo # Inference rules for *!_ext_!...>> "%BBB_MAKEFILE_TEMPLATE%"
		echo.>> "%BBB_MAKEFILE_TEMPLATE%"
		if defined OBJ_DIR_FLAT (
			set "exec_arg=call :print_NMAKE_inference_batch_rule !_ext_! .obj %src_dir%\{} %obj_dir% DUMMY_CMD_PLACEHOLDER"
		) else (
			set "exec_arg=call :print_NMAKE_inference_batch_rule !_ext_! .obj %src_dir%\{} %obj_dir%\{} DUMMY_CMD_PLACEHOLDER"
		)
::		echo :exec_each "%dirlist_file%" "!exec_arg!"
		call :exec_each "%dirlist_file%" "!exec_arg!">> "%BBB_MAKEFILE_TEMPLATE%"
	)
	endlocal


::=====================================================================================
::=====================================================================================
::=====================================================================================
::
::   NOW, READY TO RUN THE BUILD...
::
::=====================================================================================
::=====================================================================================
::===================================================================================

if "%VERBOSE%" GEQ "1" echo Building...
:: Add an empty line if more details are expected:
if "%VERBOSE%" GEQ "2" echo.

::For testing:
::(call :get_changed_sources "%srclist_file%") && type "%srclist_file%" && exit

::
:: Create target dirs for the handicapped MSVC tools...
::
::!! Should go in the makefile!...
::!! But calling this one (for tree mode) from there would be another nightmare:
:: For tree-modes:
::call :exec_each  "%dirlist_file%" "if not exist %OBJ_ROOT%\{} md %OBJ_ROOT%\{}"

if not exist %IFC_ROOT% md %IFC_ROOT%
if not exist %OBJ_ROOT% md %OBJ_ROOT%

if "%BATCH_COMPILE%"=="on" (
	set "nmake_batch_switch="
	if "%VERBOSE%" GEQ "2" echo Batch-compiling: on
) else (
	set "nmake_batch_switch=/Y"
	if "%VERBOSE%" GEQ "2" echo Batch-compiling: off
)

if exist %MAIN_MAKEFILE% nmake /nologo %nmake_batch_switch% /f %MAIN_MAKEFILE% BBB_build
goto :eof


:: OPTIONAL:
::----------------------------------------------------------------------------
:get_changed_sources
::
:: Use the BBB_MAKEFILE_TEMPLATE to get the list of newly touched sources
::
:: IN   listfile
::
	set "listfile=%~1"

	:: Replace the list of sources with the changed ones:
	call :empty_file "%srclist_file%"
	::NOTE:: /C required for silencing it when "target is up-to-date", and
	::       /Y for disabling batch mode (just to ensure one file per line):
	nmake /c /nologo /Y /f %BBB_MAKEFILE_TEMPLATE% >> "%listfile%"
	if errorlevel 1 exit 1
	goto :eof


::!!!--------------------------------------------------------------------------------
::!!! OBSOLETE MONKEYING BELOW:
::!!!
::
:: Prepare linker-ready obj list: prepend the obj dir
::
::!! Should go to the tmp. makefile too, as a linker rule, which could then just be
::!! included by the main makefile (similarly to the Jumpstart rule generation stuff)!
::
set "linker_objlist_file=%OBJ_ROOT%\linkable_objects.tmp"
call :exec_each "%objlist_file%" "echo %TAB%%obj_dir%\{}"> "%linker_objlist_file%" "%UNITS_NO_AUTOLINK_PATH_PATTERN%"
::
:: Compile & Link (by NMAKE again)...
::
call :check_file_empty "%srclist_file%"
if not errorlevel 1 (
	echo No fresh sources to build.
	if exist %MAIN_MAKEFILE% nmake /nologo /f %MAIN_MAKEFILE% fast_track_link
) else (
	echo Rebuilding after source changes...
	if exist %MAIN_MAKEFILE% nmake /nologo /f %MAIN_MAKEFILE% fast_track_compile
	if exist %MAIN_MAKEFILE% nmake /nologo /f %MAIN_MAKEFILE% fast_track_link
)

goto :eof
::!!!--------------------------------------------------------------------------------



::=====================================================================================
:setd
:: Set a variable to a value, or if that's empty (or ""), then to a default (if one is
:: provided).
::
:: The intended use case is sanitizing arguments like
::
::	call :setd var %1 default
:: or
::	call :setd var %~1 default
:: or
::	call :setd var "%~1" default
::
:: OUT  %1: name of variabla to set
:: IN   %2: value to set
:: IN   %3: default value, if %2 is "" (or other placeholder for an empty value)
::
::echo - setd: 1 = [%1]
::echo - setd: 2 = [%2]
::echo - setd: 3 = [%3]
	if _%2_ == __ exit 1 &rem Neither main nor default value! :-o
	set "%1=%~2"
	if "%~2" == "" set "%1=%~3"
::echo - setd: $%1 = [!%1!]
	goto :eof

::-------------------------------------------------------------------------------------
:check_dir
::
:: IN   %1: dir path (default: .)
:: OUT  %2: name of variabla in which to return the abs. path of dir (optional)
::
::!!Sigh...	setlocal
	call :setd _dir_ "%~1" .

::echo check_dir: 1 = [%1]
::echo check_dir: quoted ~1 = ["%~1"]
::echo check_dir: _dir_ = [%_dir_%]

	set "_retvar_=%~2"
	pushd "%_dir_%" 2> nul
	if errorlevel 1 (
rem Don't spoil the client's output! :-o
rem		echo - WARNING: Can't use dir: "!_dir_!" ^(from !CD!^)
		exit /b 1
	)
	if not "" == "%_retvar_%" set "%_retvar_%=%CD%"
	set _dir_=
	set _retvar_=
	popd
	exit /b
::!!Sigh...:
	if not "" == "%_retvar_%" (
echo wtf
		endlocal & set "!_retvar_!=!CD!"
echo above
	) else (
		endlocal
	)
	popd
	goto :eof

::-------------------------------------------------------------------------------------
:empty_file
:: (Re)create file as empty
::
:: IN   %1: file path
::
	< nul set /p "=" > "%~1"
	goto :eof

::-------------------------------------------------------------------------------------
:check_file_empty
::
:: Returns errorlevel 0 if empty otherwise 1 (so && on the call should work)
::
:: IN   %1: file path
::
	if not exist "%~1" (
		exit /b 1
	) else if %~z1 equ 0 (
		exit /b 0
	) else (
		exit /b 1
	)
	goto :eof

::-------------------------------------------------------------------------------------
:addslash
::
:: Append backslash to a path "in a sensible manner"...
::
:: OUT  %1: variable name in which to return the result (or do nothing if empty)
:: IN   %2: dir path
::
:: If the path has a slash already, none is added.
:: If it's empty (or ""), or ends with a colon (i.e. likely a drive's current dir), 
:: .\ is appended instead.
:: If no path is specified, the one in the named variable is used.
::
::!! Sigh, this would prevent setting the result var, too! :)
::!!	setlocal
	if _%~1_ == __ exit /b 1
	set "_result_var_=%~1"
	call :setd _path_ "%~2" "!%~1!"

	:: This would fail if the path was quoted, so the unquoting at init is crucial!
	set "_eos_=!_path_:~-1!"
	if        _%_eos_%_ == _\_ (
		set "%_result_var_%=%_path_%"
	) else if _%_eos_%_ == _/_ (
		set "%_result_var_%=%_path_%"
	) else if _%_eos_%_ == _:_ (
		set "%_result_var_%=%_path_%.\"
	) else if _%_path_%_ == __ (
		set "%_result_var_%=%_path_%.\"
	) else (
		set "%_result_var_%=%_path_%\"
	)
::!!	endlocal
	set _eos_=
	set _path_=
	set _result_var_=
	goto :eof

:_addslash_test
	setlocal
	(call :addslash) || echo Should be ERROR: no return var! (OK, if you see this line.)
	(call :addslash res)  && echo Should be .\   [!res!]
	call :addslash res "" && echo Should be .\   [!res!]
	call :addslash res ./ && echo Should be ./   [!res!]
	call :addslash res X: && echo Should be X:.\ [!res!]
	:: Use the var in-place
	(call :addslash res) && echo Should be X:.\ [!res!]
	set res=
	call :addslash res && echo Should be .\ [!res!]
	endlocal
	exit /b

::-------------------------------------------------------------------------------------
:create_dirlist
::
:: Create a (filtered) list of (sub)directories of a tree
::
:: IN   %1: dir-list filename (default: .dirlist.tmp)
:: IN   %2: tree root dir (default: .)
:: IN   %3: include pattern: only add dirs that have such filenames (default: *)
:: IN   %4: exclude_pattern pattern (default: none)
::
	setlocal
	set "dirlistfile=%~1" && if not defined dirlistfile set "dirlistfile=.dirlist.tmp"
	set "root=%~2"        && if not defined root        set "root=."
	call :setd include_pattern "%~3" *
	set "exclude_pattern=%~4"
	set "tempfile=.tempfile.tmp"
	set "TAB=	"

::echo include_pattern = [%include_pattern%]

	pushd "%root%"
		set root_abspath=%CD%\
		rem Fix double \\ in case of X:\
		set "root_abspath=!root_abspath:\\=\!"
	popd
if "%VERBOSE%" GEQ "3" echo Scanning tree: %root_abspath%

	rem Create the list file...
	rem The first empty line is significant: it's for the root of %root%!
	rem (Clients can decide to easily ignore it, or use as "" or . for the tree root.)
	echo. > %dirlistfile%
:: Except... The counterpart for loops in CMD are too happy to ignore that line altogether. :-/
:: So...:
::!!??	echo . > %dirlistfile%

	for /d /r "%root_abspath%" %%d in (*) do ( set "_dir_abs_=%%d"
:: Or:	for /f "delims=" %%d in ('dir /s /b /a:d "%root_abspath%"') do (
if "%VERBOSE%" GEQ "3" echo Considering dir^: "!_dir_!" %TAB%^(abs: "!_dir_abs_!"^)
		set "_dir_=!_dir_abs_:%root_abspath%=!"

		rem ! Pathname filtering should be done before dir content globbing, but that
		rem ! would involve calling `findstr` for each name, which is way too heavy!... :-/
		rem !! Also, the non-emptiness of the excl. pattern must also be checked,
		rem !! complicating the lame ifs into an even more annoyig level...
		rem echo !_dir_! | findstr /R "%exclude_pattern%" > NUL
		rem if not errorlevel 1 (
		if 1==0 (
if "%VERBOSE%" GEQ "1" echo - DIR: !_dir_! ^(filtered^)
		) else (
			if exist "!_dir_abs_!\%include_pattern%" (
if "%VERBOSE%" GEQ "2" echo +? DIR: "!_dir_!"
				echo !_dir_!>> %dirlistfile%
			) else (
if "%VERBOSE%" GEQ "2" echo - DIR: "!_dir_!" ^(has no %include_pattern%^)
			)
		)
	)

	if not "%exclude_pattern%" == "" (
		findstr /V /R "%exclude_pattern%" "%dirlistfile%" > "%tempfile%"
		if errorlevel 2 (
			echo - ERROR: Failed to filter to: "%dirlistfile%"^^!
			exit /b 1
		) else if not errorlevel 1 (
			rem Some filtering occurred, report...
if "%VERBOSE%" GEQ "1" (
			for /f %%d in ('findstr /R "%exclude_pattern%" "%dirlistfile%"') do (
				set "xlist=!xlist!, %%d"
				rem Quoting looked noisy & we have the comma anyway:
				rem set "xlist=!xlist!, ^"%%d^""
			)
			if defined xlist (
				set "xlist=!xlist:~2!" &rem Remove leading sep.
if "%VERBOSE%" GEQ "1"		echo - SKIP DIR ^(%exclude_pattern%^): !xlist!
)			)
			move /y "%tempfile%" "%dirlistfile%" > nul
			if errorlevel 1 echo - ERROR: Failed to move temp. file "%tempfile%"
		)
	)
	endlocal
	goto :eof

::-------------------------------------------------------------------------------------
:exec_each
::
:: Apply (templated) command to each line of a list file
::
:: IN  %1: input list filename
:: IN  %2: command template, where each {} is replaced with the current line of the input list
:: IN  %3: exclude pattern, like with create_dirlist
::
:: E.g. to print each line of the input: exec_each listfile "echo {}"
::
	setlocal
	set "listfile=%~1"
	set "cmd=%~2"
	set "exclude_pattern=%~3"

	if "%cmd%" == "" exit /b

	if exist "%listfile%" for /f "tokens=*" %%f in (%listfile%) do ( set "_f_=%%f"
		set _skip_=
		if not "%exclude_pattern%" == "" (
			echo !_f_! | findstr /R "%exclude_pattern%" > nul
			if errorlevel 2 (
				echo - ERROR: Failed to apply filter to^: "!_f_!"^^! >&2
				rem exit /b 1
			) else if not errorlevel 1 (
if "%VERBOSE%" GEQ "2" echo - SKIP: !_f_! ^(matching %exclude_pattern%^) >&2
				set _skip_=1
			)
		)
		if not defined _skip_ %cmd:{}=!_f_!%
	)
	endlocal
	goto :eof

::-------------------------------------------------------------------------------------
:print_NMAKE_inference_batch_rule
::
:: IN   %1: source ext. (with the . prefix)
:: IN   %2: target ext. (with the . prefix)
:: IN   %3: source dir path
:: IN   %4: target dir path
:: IN   %5: command block
::
	setlocal
	set "_inext_=%~1"
	set "_outext_=%~2"
	set "_inpath_=%~3"
	set "_outpath_=%~4"
	rem Can't shift for %* :-/ Use it as-is, no unquoting:
::!! Yeah, no...: set "_cmd_=%5%6%7%8%9"
	set "_cmd_=%__inference_commands__%"
	set "TAB=	"
	
	::!! This should be done by the caller, via exec_each ..., not here!...
	set "_cmd_=!__inference_commands__:{}=%_outpath_%!"

	echo {%_inpath_%}%_inext_%{%_outpath_%}%_outext_%::
	if not "%_cmd_%" == "" (
		echo %TAB%%_cmd_%
	) else (
		echo EMPTY
	)

	endlocal
	goto :eof

rem IGNORE THIS WIP:
::-------------------------------------------------------------------------------------
:print_NMAKE_inference_batch_rules
::
:: IN   %1: source ext. list (with the . prefix)
:: IN   %2: command block for the rule
::
	set "_extlist_=%~1"
	set "_cmd_block_=%~2"

	setlocal
	for %%x in (%_extlist_%) do ( set _ext_=%%x

		rem !! Can't pass the cmd arg. to print_NMAKE_inference_batch_rule if it contains spaces, because
		rem !! CMD gets confused by its own idiotic quoting rules, let alone the challenge of passing
		rem !! multi-line text, so the command block is passed via %__inference_commands__%...
		set "__inference_commands__=$^(_mute^)$^(CXX^) $^(CFLAGS^) $^(CXXFLAGS^) -Fo$^(obj_dir^)\ $^<"

		set "exec_arg=call :print_NMAKE_inference_batch_rule !_ext_! .obj src\{}\ %OUT_DIR_%{}\ DUMMY_CMD_PLACEHOLDER"
		echo :exec_each "%dirlist_file%" "!exec_arg!"
		call :exec_each "%dirlist_file%" "!exec_arg!"
	)
	endlocal
	goto :eof


::=====================================================================================
::!! JUNKYARD !!
::=====================================================================================
			set "_dir_=!_dir_:$(src_dir_abspath)\!"
			for %%x in ($(obj_source_exts)) do (
				if "$(VERBOSE_CMD)" GEQ "2" echo [!_dir_!/*.%%x]
				if "$(VERBOSE_CMD)" GEQ "2" if exist "%%d\*.%%x" echo [-^> !_make_! /c compiling DIR=!_dir_! SRC_EXT_=%%x $(custom_build_options)]
				rem ... !_make_! ... "DIR=!_dir_!" would FAIL! if the NMAKE path has spaces! :-ooo
				rem See #224!
				                            if exist "%%d\*.%%x"           !_make_! /c compiling DIR=!_dir_! SRC_EXT_=%%x $(custom_build_options)
				if errorlevel 1 exit -1
			)
