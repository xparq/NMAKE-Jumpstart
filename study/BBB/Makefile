#### MSVC Jumpstart Makefile, new gen.
#### -> https://github.com/xparq/NMAKE-Jumpstart
####
#### BEWARE! Uses recursive NMAKE invocations, so update the macro below if
#### you rename this file:
THIS_MAKEFILE=Makefile
#
# NOTE: Macros can't be set on the NMAKE command line, only here, because the
#       recursion won't pass them along!... (But see custom_build_options!)
#
VERBOSE_CMD=0	# 0 .. 2. This one *can* be overriden from the cmdline! (see custom_build_options!)

#-----------------------------------------------------------------------------
# Config - Project layout
#-----------------------------------------------------------------------------
PRJ_NAME=$(SZ_APPNAME)
# Use the lower-case (processed) path macros here:
#main_lib=$(lib_dir)/$(PRJ_NAME)$(buildmode_suffix).lib
main_exe=$(exe_dir)/$(PRJ_NAME)$(buildmode_suffix).exe
# Main targets to build:
BUILD = $(main_lib) $(main_exe)

SRC_DIR=src
OUT_DIR=out
LIB_DIR=$(OUT_DIR)
EXE_DIR=$(OUT_DIR)
OBJ_DIR=$(OUT_DIR)/obj
CXX_MOD_IFC_DIR=$(OUT_DIR)
# Put (only) these into the lib (relative to SRC_DIR; leave it empty for "all"):
LIB_SRC_SUBDIR=

# Source (translation unit) basename filter (CMD shell glob pattern):
UNITS_PATTERN=*
# Ignore-filter on full-path source names -> NMAKE `filterout` pattern list syntax!
# Multiple patterns must be separated by spaces. Do NOT quote the list!
UNITS_NO_COMPILE_PATTERN=.off .tmp
# Ignore-filter on full-path source names -> `findstr` REGEX syntax!
# Multiple patterns must be separated by spaces. Do NOT quote the list!
UNITS_NO_AUTOLINK_PATTERN=main\.cpp \.off \.tmp sz[/\\]test
UNITS_NO_LIB_PATTERN=$(UNITS_NO_AUTOLINK_PATTERN)

#!! Kludge until I find out the correct way:
#!! Also done manually, coz no way to track the actual deps automatically...:
OON_CPP_MODULE_IFCS=\
	$(cxx_mod_ifc_dir)/Storage.ifc 

#!! Sigh... No header autodep... And no unified obj list either to use as a target! :-/
#!! Also, must use a fixed path (not necessary absolute, but definitely not just .),
#!! or else the filenames/patterns would be mistakenly applied to the current subdir,
#!! and MAKE would fail with "dunno how to make..."
#!! Also, must NOT use $(src_dir) $(src_dir_abspath) here, as those will also point
#!! to the current node of the source tree, not its root! :-o
OBJ_DEPS_manually=$(SRC_DIR)/*.hpp $(SRC_DIR)/cfg.h \
	$(SRC_DIR)/Model/*.hpp \
	$(SRC_DIR)/View/*.hpp \
	$(SRC_DIR)/UI/*.hpp \
	$(SRC_DIR)/UI/adapter/SFML/*.hpp \
#	$(SRC_DIR)/Platform/*.hpp \
	$(SRC_DIR)/adapter/SFML/*.hpp \
	$(SRC_DIR)/sz/*.hh \

#
# External dependencies:
#
EXT_INCLUDE_DIRS=
EXT_LIB_DIRS=
EXT_LIBS=\
	$(SFML_LIBROOT)/lib/$(sfml_and_deps_libs) \
	extern/sfw/lib/msvc/sfw$(_cflags_crt_linkmode)$(_buildmode_debug_file_suffix).lib \
	extern/zstd/msvc/zstd$(_cflags_crt_linkmode).lib \


#-----------------------------------------------------------------------------
# Config - Build options
#-----------------------------------------------------------------------------
# Build alternatives (override from the command-line, too, if needed):
DEBUG=0
CRT=dll
#!Sz: CRT=dll is always the case with the pre-built SFML libs, so not use changing it!
# Custom build options can also be added:
SFML=static
# Custom build options need to be passed along for recursion explicitly:
custom_build_options = SFML=$(SFML) VERBOSE_CMD=$(VERBOSE_CMD)

# Custom Tools:
#!Sz: Assuming being called from a script that has already set the path:
ECHO=@echo
#! Unnecessary:
#MKDIR=$(BB) mkdir -p

# Comp. flags:
CFLAGS=-W4 -Iinclude
CXXFLAGS=-std:c++latest
# Note: C++ compilation would use $(CFLAGS), too.

# Output dir/file suffixes for build alternatives
# NOTE: Must differ from their "no ..." counterparts to avoid code (linking)
#       mismatches!
#!Sz: CRT=dll is always the case with the pre-built SFML libs, so not use changing it! (See also at CRT=...)
buildmode_crtdll_dir_suffix=.crtdll
buildmode_crtdll_file_suffix=-crtdll
buildmode_debug_dir_suffix=.DEBUG
buildmode_debug_file_suffix=-d

SFML_linkmode=$(SFML)
buildmode_dir_suffix=.sfml-$(SFML_linkmode)

#!-------------------------------------
#!Sz Other custom options for OON...
#!-------------------------------------
!if "$(SFML)" == "static"
CFLAGS=$(CFLAGS) -DSFML_STATIC
!endif
CXXFLAGS=-std:c++latest
# Note: C++ comp. commands would use $(CFLAGS), too! (!!Which may be stupid, and change later...!!)

# Adapt the various flavors of the SFML libs (as per the debug/link modes)...
sfml_libs_static=sfml-graphics-s.lib sfml-window-s.lib sfml-system-s.lib \
	sfml-audio-s.lib

sfml_libs_dll=sfml-graphics.lib sfml-window.lib sfml-system.lib \
	sfml-audio.lib

!if "$(SFML)" == "static"
sfml_libs=$(sfml_libs_static)
sfml_and_deps_libs=$(sfml_libs) opengl32.lib freetype.lib\
	ogg.lib vorbis.lib vorbisenc.lib vorbisfile.lib flac.lib openal32.lib \
	user32.lib kernel32.lib gdi32.lib winmm.lib advapi32.lib
!else if "$(SFML)" == "dll"
sfml_libs=$(sfml_libs_dll)
sfml_and_deps_libs=$(sfml_libs) opengl32.lib
!endif

!if defined(DEBUG) && $(DEBUG) == 1
sfml_libs=$(substi .lib,-d.lib,$(sfml_libs))
!endif

#=============================================================================
#                     NO EDITS NEEDED BELOW, NORMALLY...
#=============================================================================
obj_source_exts=cpp cxx cc c

#-----------------------------------------------------------------------------
# Show current processing stage...
#-----------------------------------------------------------------------------
!ifdef RECURSED_FOR_COMPILING
!if "$(DIR)" == ""
node=(main)
!else
node="$(DIR)"
!endif
!message Processing source dir: $(node)...
!endif

#-----------------------------------------------------------------------------
# Normalize the (prj-local) paths before potentially passing them to any of
# the arcane "DOS" commands only to make them choke on fwd. slashes!...
# + Also guard against accidental \ prefixes for empty dirs!
#   (Note: \ needs to be escaped here. Quoted paths are NOT handled here,
#   because those couldn't be used later anyway for appending subdirs, so
#   quoting is assumed to be handled at the last moment, when passing the
#   paths to commands!)
#-----------------------------------------------------------------------------
#! Not prefixdir=$(MAKEDIR), as most of these are subdirs!
#! Also: abspath'ed, so that user code doesn't have to worry about accidental
#! crosstalk between relative subdir macros like ($src_dir) across multiple
#! recursive runs for the indivirual source subdirs!... :-o
prefixdir=.
#! This is still too hamfisted if some were in fact ment to be absolute paths!
#! Anyway, at leat it's erring on the safe side.
src_dir         = $(prefixdir)\$(patsubst \\%,%,$(SRC_DIR:/=\))
out_dir         = $(prefixdir)\$(patsubst \\%,%,$(OUT_DIR:/=\))
lib_dir         = $(prefixdir)\$(patsubst \\%,%,$(LIB_DIR:/=\))
exe_dir         = $(prefixdir)\$(patsubst \\%,%,$(EXE_DIR:/=\))
obj_dir         = $(prefixdir)\$(patsubst \\%,%,$(OBJ_DIR:/=\))
cxx_mod_ifc_dir = $(prefixdir)\$(patsubst \\%,%,$(CXX_MOD_IFC_DIR:/=\))
!if "$(main_lib)" != ""
main_lib        = $(prefixdir)\$(patsubst \\%,%,$(main_lib:/=\))
!endif
!if "$(main_exe)" != ""
main_exe        = $(prefixdir)\$(patsubst \\%,%,$(main_exe:/=\))
!endif
# And this one is really a subdir, which will be prefixed internally with src_dir,
# so don't mess it up with the same adjustment, just normalize the slashes:
lib_src_subdir  = $(LIB_SRC_SUBDIR:/=\)

# Now, this one, OTOH, must be the normalized *full* path of the src root:
#   src_dir_abspath = $(MAKEDIR)\$(src_dir)
# -- used in the command blocks for abs->rel conversion (via direct path
# string replacement in the tree traversal loops), which needs to be as
# robust as possible! (And are still too brittle!...)
# Except...: if the path contains spaces, then it's considered a list,
# and each item would get separately normalized! (Quoting doesn't help! :-/ )
# So... Behold this shameless abomination of a workaround:
_SPACE_=$(subst x,,x x)
p=$(subst $(_SPACE_),<FAKE_SPACE>,$(MAKEDIR)\$(src_dir))
src_dir_abspath=$(subst <FAKE_SPACE>,$(_SPACE_),$(abspath $(p)))


#-----------------------------------------------------------------------------
# Set/adjust tool options (according to the config)...
#-----------------------------------------------------------------------------
# Preserve the original NMAKE flags & explicitly supported macros on recursion:
MAKE_CMD=$(MAKE) /nologo /$(MAKEFLAGS) /f $(THIS_MAKEFILE) DEBUG=$(DEBUG) CRT=$(CRT)

CFLAGS=-nologo -c $(CFLAGS)
CXXFLAGS=-EHsc $(CXXFLAGS)
!if "$(cxx_mod_ifc_dir)" != ""
CXXFLAGS=-ifcSearchDir $(cxx_mod_ifc_dir) $(CXXFLAGS)
!endif

#----------------------------
# Static/DLL CRT link mode
#------
!if "$(CRT)" == "static"
_cflags_crt_linkmode=-MT
!else if "$(CRT)" == "dll"
_cflags_crt_linkmode=-MD
!else
!error Unknown CRT link mode: $(CRT)!
!endif

#----------------------
# DEBUG/RELEASE mode
#------
cflags_debug_0=$(_cflags_crt_linkmode) -O2 -DNDEBUG
cflags_debug_1=$(_cflags_crt_linkmode)d -ZI -Od -Oy- -Ob0 -RTCsu -DDEBUG -Fd$(out_dir)/
	# The -O...s above are borrowed from Dr. Memory's README/Quick start.
	# -ZI enables edit-and-continue (but it only exists for Intel CPUs!).
linkflags_debug_0=
linkflags_debug_1=-debug -incremental -editandcontinue -ignore:4099

!if defined(DEBUG) && $(DEBUG) == 1
_cflags_debugmode=$(cflags_debug_1)
_linkflags_debugmode=$(linkflags_debug_1)
!else if $(DEBUG) == 0
_cflags_debugmode=$(cflags_debug_0)
_linkflags_debugmode=$(linkflags_debug_0)
!else
!error Unknown debug mode: $(DEBUG)!
!endif

CFLAGS=$(_cflags_debugmode) $(CFLAGS)
LINKFLAGS=$(_linkflags_debugmode) $(LINKFLAGS)


#---------------------------------------
# Update the INCLUDE & LIB env. vars for external tools
#------
!if "$(EXT_INCLUDE_DIRS)" != ""
!if [set INCLUDE=%INCLUDE%;$(EXT_INCLUDE_DIRS)]
!endif
!endif

!if "$(EXT_LIB_DIRS)" != ""
!if [set LIB=%LIB%;$(EXT_LIB_DIRS)]
!endif
!endif
# Or, alternatively:
#!if "$(EXT_LIB_DIRS)" != ""
#LINKFLAGS=$(LINKFLAGS) -libpath:$(EXT_LIB_DIRS)
#!endif

#-----------------------------------------------------------------------------
# Split the target tree across build alternatives...
#!! Would be nice to just split the root, but the libs and exes can be
#!! off the tree (for convenience & flexibility, e.g. differentiated by name
#!! suffixes etc.)... Which leaves us with dispatching the obj_dir instead
#!! -- and leaving the lib_dir and exe_dir totally ignored... :-/
#-----------------------------------------------------------------------------
# For the output dirs (currently only the obj. dir), and
# for the output files (currently the lib/exe files)
!if "$(CRT)" == "dll"
buildmode_dir_suffix=$(buildmode_dir_suffix)$(buildmode_crtdll_dir_suffix)
buildmode_file_suffix=$(buildmode_file_suffix)$(buildmode_crtdll_file_suffix)
!endif

!if "$(DEBUG)" == "1"
_buildmode_debug_file_suffix=$(buildmode_debug_file_suffix)
_buildmode_debug_dir_suffix=$(buildmode_debug_dir_suffix)
buildmode_dir_suffix=$(buildmode_dir_suffix)$(buildmode_debug_dir_suffix)
buildmode_file_suffix=$(buildmode_file_suffix)$(buildmode_debug_file_suffix)
!endif

obj_dir=$(obj_dir)$(buildmode_dir_suffix)

#-----------------------------------------------------------------------------
# Adjust paths for the inference rules, according to the current subdir-recursion
#-----------------------------------------------------------------------------
!if "$(DIR)" != ""
src_dir=$(src_dir)\$(DIR)
obj_dir=$(obj_dir)\$(DIR)
!endif

#=============================================================================
# Rules...
#=============================================================================












bootstrap:
	@cmd /c <<$(out_dir)\bbb.cmd
@echo off
setlocal EnableExtensions
setlocal EnableDelayedExpansion

call :setd VERBOSE %1 1
::	0 - 3
set BATCH_COMPILE=on


::============================================================================
:: CONFIG
::============================================================================
:: We expect to be in the project dir, so...:
call :setd PRJ_ROOT "%PRJ_ROOT%" .

:: Just a synonym, for added confusion:
set "PRJ_DIR=%PRJ_ROOT%"

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

::============================================================================
:: ENGINE
::============================================================================
set "TAB=	"

:: Force flat obj dirs (!!should only be done in batch-compile mode!...)
set OBJ_DIR_FLAT=1
	::!! Well, non-flat doesn't work: MSVC can't put objects into various subdirs
	::!! when running in batch mode! :-/ They all must go to the same /Fo dir!

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


set "MAIN_MAKEFILE=$(THIS_MAKEFILE)"
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
	echo BBB_CC_PROXY = @echo $$^< >>     "%BBB_MAKEFILE_TEMPLATE%"
	echo ^^!endif >>                     "%BBB_MAKEFILE_TEMPLATE%"

	echo ^^!if ^^!defined^(BBB_MAIN_TARGET^) >> "%BBB_MAKEFILE_TEMPLATE%"
	echo BBB_MAIN_TARGET = %SZ_APPNAME%>>       "%BBB_MAKEFILE_TEMPLATE%"
	echo ^^!endif >>                            "%BBB_MAKEFILE_TEMPLATE%"

	::
	:: Rule for main target depending on all the objs...
	::
	:: Alas, this can't be the same list as a @list file for the linker:
	:: the trailing \ for the makefile lines is unknown to the MSVC tools!
	echo $$^(BBB_MAIN_TARGET^): \>> "%BBB_MAKEFILE_TEMPLATE%"
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
		set "__inference_commands__=$$^(BBB_CC_PROXY^)"
		if "!_ext_!" == ".ixx" (		
rem			set "__inference_commands__=@echo $$^(CXX^) $$^(CFLAGS^) $$^(CXXFLAGS^) -Fo%obj_dir%\{}\ -ifcOutput %obj_dir%\{}\ $$^<"
		) else (
rem			set "__inference_commands__=@echo $$^(CXX^) $$^(CFLAGS^) $$^(CXXFLAGS^) -Fo%obj_dir%\{}\ $$^<"
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
::echo - setd: %1 = [!%1!]
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
<<KEEP



































#!! SADLY...:
#!!
#!! We cannot construct the obj target list from the local sources (see compile_dir...), because
#!! NMAKE can only process wildcards on rule lines, where it's too late for this... :-/
#!!local_objs = $(no wildcard function!... )
#!!
#
# Trigger the inference rules by changed headers, too!...
#$(local_objs) : $(OBJ_DEPS_manually)

#-----------------------------------------------------------------------------
# Inference rules for .obj compilation...
# NOTE: The src & obj paths have been updated (see above) to match the subdir,
#       where the tree traversal (recursion) is currently at.
#-----------------------------------------------------------------------------
# Can't direclty add $(patsubst %,.%,$(obj_source_exts)) to .SUFFIXES, as that
# would trigger a syntax error! :-o Well, at least we have a descriptive name:
_compilable_src_exts_=$(patsubst %,.%,$(obj_source_exts))
.SUFFIXES:$(_compilable_src_exts_) .ixx .ifc .exe

#-----------------------------------------------------------------------------
!if "$(VERBOSE_CMD)" == "" || "$(VERBOSE_CMD)" == "0"
_mute=@
!endif
{$(src_dir)}.c{$(obj_dir)}.obj::
	$(_mute)$(CC) $(CFLAGS) -Fo$(obj_dir)\ $<

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	$(_mute)$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)\ $<
{$(src_dir)}.cxx{$(obj_dir)}.obj::
	$(_mute)$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)\ $<
{$(src_dir)}.cc{$(obj_dir)}.obj::
	$(_mute)$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)\ $<

#!!?? This is probably not the way to compile mod. ifcs!...:
{$(src_dir)}.ixx{$(cxx_mod_ifc_dir)}.ifc::
	$(_mute)$(CXX) $(CFLAGS) $(CXXFLAGS) -ifcOutput $(cxx_mod_ifc_dir)\ -Fo$(obj_dir)\ $<


#!message !! before treewaalk: abspath == $(src_dir_abspath), includes: $(OBJ_DEPS_manually)

#-----------------------------------------------------------------------------
# Default target - walk through the src tree dir-by-dir & compile all the
#                  sources, plus do an initial & a final wrapping round...
#-----------------------------------------------------------------------------
traverse_src_tree: init
	@cmd /v:on /c <<$(out_dir)\treewalk.cmd
	@echo off
	rem !!The make cmd. below fails to run without the extra shell! :-o
	rem !!Also -> #8 why the env. var here can't be called just "make"!... ;)
	set "_make_=cmd /c $(MAKE_CMD)"
	:: echo $(src_dir)
	:: echo !src_dir_abspath!
	rem Do the root level first (preps + top-level sources)...
	rem (Note: naming a (different) target would avoid inf. recursion!)
	set _dir_=$(src_dir)
        for %%x in ($(obj_source_exts)) do (
		if "$(VERBOSE_CMD)" GEQ "2" echo [!_dir_!/*.%%x]
		if "$(VERBOSE_CMD)" GEQ "2" echo if exist "$(src_dir)\*.%%x" echo [-^> !_make_! /c compiling SRC_EXT_=%%x $(custom_build_options)]
		                                 if exist "$(src_dir)\*.%%x"           !_make_! /c compiling SRC_EXT_=%%x $(custom_build_options)
		if errorlevel 1 exit -1
	)
	rem Scan the rest of the source tree for sources...
	for /f "delims=" %%d in ('dir /s /b /a:d "$(src_dir_abspath)"') do (
		rem It's *vital* to use a local name here, not `dir` (== $(DIR)!!!):
		set "_dir_=%%d"

		echo !_dir_! | findstr /L "$(UNITS_NO_COMPILE_PATTERN)" > nul
		if not errorlevel 1 (
			if "$(VERBOSE_CMD)" GEQ "1" echo - EXCLUDE DIR: !_dir_!
		) else (
			set "_dir_=!_dir_:$(src_dir_abspath)\=!"
			for %%x in ($(obj_source_exts)) do (
				if "$(VERBOSE_CMD)" GEQ "2" echo [!_dir_!/*.%%x]
				if "$(VERBOSE_CMD)" GEQ "2" if exist "%%d\*.%%x" echo [-^> !_make_! /c compiling DIR=!_dir_! SRC_EXT_=%%x $(custom_build_options)]
				rem  ... !_make_! ... "DIR=!_dir_!" would FAIL! if the NMAKE path has spaces! :-ooo
				rem See #224!
				                            if exist "%%d\*.%%x"           !_make_! /c compiling DIR=!_dir_! SRC_EXT_=%%x $(custom_build_options)
				if errorlevel 1 exit -1
			)
		)
	)
	!_make_! RECURSED_FOR_FINISHING=1 $(custom_build_options) finish
<<keep
#! '
#! This ' above is just to help the FAR Editor's syntax-highlighting to balance
#! a prev. one... :-o :) (Find it, understand why it's all of natural, problematic,
#! and fortunate, and appreciate this little gem like the interesting corpse
#! of a poor little rare animal on a forest hike. :) )

#-----------------------------------------------------------------------------
# Workflow Control Rules
#-----------------------------------------------------------------------------

# This rule is implicitly selected as the default target, only on the first run:
init: mk_main_target_dirs compile_mod_ifcs mk_mainlib_objdep_inc mk_mainexe_objdep_inc

# This rule is explicitly selected on the command-line of recursive calls for subdirs:
compiling: mk_obj_dir compile_dir

# This rule is explicitly selected on the command-line after processing the entire tree:
finish: $(BUILD)

mk_main_target_dirs: # Pre-create the output dirs, as MSVC can't be bothered...
	@if not exist "$(out_dir)" md "$(out_dir)"
	@if not exist "$(lib_dir)" md "$(lib_dir)"
	@if not exist "$(exe_dir)" md "$(exe_dir)"
#!!	@if not exist "$(cxx_mod_ifc_dir)" md "$(cxx_mod_ifc_dir)"

mk_obj_dir: # These vary for each subdir, so can't be done just once at init!
	@if not exist "$(obj_dir)" md "$(obj_dir)"

compile_mod_ifcs: mk_obj_dir $(OON_CPP_MODULE_IFCS)
#!! This doesn't have any modules-specific subdir (pre-creation) support yet,
#!! so actually setting the modules dirs to anything would fail the 1st time!
#!! (Even interface-only ones seem to generate .obj files, at least with MSVC!)

# The main workhorse rule...
#!! Albeit passing the targets on the cmd-line kill batch-mode inference rules in the child run,
#!! it might still be work around if the file set would be passed as a macro, and then a plain dep.
#!! rule using it could get inference working nominally again!...
!ifdef SRC_EXT_
compile_dir: $(OON_FULL_REBUILD_BY_MANUAL_DEPS) $(src_dir)\$(UNITS_PATTERN).$(SRC_EXT_)
!if "$(VERBOSE_CMD)" == "2"
	@$(ECHO) [[COMPILING *.$(SRC_EXT_) in """$(DIR)"""]: $(filterout $(UNITS_NO_COMPILE_PATTERN),$(patsubst $(src_dir)\\%,$(obj_dir)\\%, $(subst .$(SRC_EXT_),.obj,$**)))]]
!endif
	@$(MAKE_CMD) RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(custom_build_options)\
		$(filterout $(UNITS_NO_COMPILE_PATTERN),$(patsubst $(src_dir)\\%,$(obj_dir)\\%, $(subst .$(SRC_EXT_),.obj,$**)))
!endif


obj_list_file=$(obj_dir)\obj.list
mainlib_rules_inc=$(out_dir)\main_lib_rules.inc
mainexe_rules_inc=$(out_dir)\main_exe_rules.inc

#!!DRY the duplicate scriptlets below!
_mainlibexe_rules_inc_cmd_body=^
	@echo off^
	set "_TAB_=	"^
        for %%x in ($(obj_source_exts)) do (^
		...^
	)^
	...^

!if "$(main_lib)" != ""
mk_mainlib_objdep_inc: mk_obj_dir
	@cmd /v:on /c <<$(out_dir)\mklibrules.cmd
	@echo off
        for %%x in ($(obj_source_exts)) do (
		set "_ext_=%%x"
		for /r "$(src_dir)\$(lib_src_subdir)" %%o in ($(UNITS_PATTERN).!_ext_!) do (
			set "_o_=%%o"
			echo !_o_! | findstr /R "$(UNITS_NO_LIB_PATTERN)" > nul
			if not errorlevel 1 (
				if "$(VERBOSE_CMD)" GEQ "1" echo - EXCLUDE FROM LIB: !_o_!
			) else (
				set "_o_=!_o_:$(src_dir_abspath)\=!"
				for %%x in ($(obj_source_exts)) do (
					set "_o_=!_o_:.%%x=.obj!"
				)
				set "objlist=!objlist! $(obj_dir)\!_o_!"
			)
		)
	)
	echo !objlist! > $(obj_list_file)
	set "_TAB_=	"
	echo $(main_lib): !objlist!               >  $(mainlib_rules_inc)
	rem echo %_TAB_%Creating lib: $$@...      >> $(mainlib_rules_inc)
	rem echo %_TAB_%lib -nologo -out:$$@ $$** >> $(mainlib_rules_inc)
<<keep
!else
mk_mainlib_objdep_inc:
!endif
!if "$(main_exe)" != ""
mk_mainexe_objdep_inc: mk_obj_dir
	@cmd /v:on /c <<$(out_dir)\mkexerules.cmd
	@echo off
        for %%x in ($(obj_source_exts)) do (
		set "_ext_=%%x"
		for /r "$(src_dir)\$(lib_src_subdir)" %%o in ($(UNITS_PATTERN).!_ext_!) do (
			set "_o_=%%o"
			echo !_o_! | findstr /R "$(UNITS_NO_AUTOLINK_PATTERN)" > nul
			if not errorlevel 1 (
				if "$(VERBOSE_CMD)" GEQ "1" echo - EXCLUDE FROM AUTO-LINK: !_o_!
			) else (
				set "_o_=!_o_:$(src_dir_abspath)\=!"
				for %%x in ($(obj_source_exts)) do (
					set "_o_=!_o_:.%%x=.obj!"
				)
				set "objlist=!objlist!$(obj_dir)\!_o_! "
			)
		)
	)
	echo !objlist! > $(obj_list_file)
	rem No use even for this as a deps hack, as it's included only in the post-dirwalk final round, with no proper comp. context:
	rem echo !objlist!: $(OBJ_DEPS_manually) ^>  $(mainexe_rules_inc)
	rem And this is bad, too, as by the time of linking there's no way back to seeing the whole tree and do inferencing...
	rem echo $(main_exe): !objlist! > $(mainexe_rules_inc)
	echo #!!  > $(mainexe_rules_inc)
	echo #!! Make a rule file with inference rules for each subdir instead!... >> $(mainexe_rules_inc)
	echo #!! >> $(mainexe_rules_inc)
<<keep
!else
mk_mainexe_objdep_inc:
!endif

clean:
# Cleans only the target tree of the current build alternative!
# And no way I'd just let loose a blanket RD /S /Q "$(out_dir)"!...
	@if not "$(abspath $(obj_dir))" == "$(abspath .\$(obj_dir))" echo - ERROR: Invalid object dir path: "$(obj_dir)" && exit -1
# Stop listing all the deleted .obj files despite /q -> cmd /e:off (self-explanatory, right?)
	@if exist "$(obj_dir)\*.obj" cmd /e:off /c del /s /q "$(obj_dir)\*.obj"
	@if exist "$(obj_list_file)" cmd /e:off /c del $(obj_list_file)
# To let the idiotic tools run at least, the dir must exist, so if it was deleted
# in a previous run, we must recreate it just to be able to check and then delete
# it right away again... Otherwise: "The system cannot find the file specified."):
	@if not exist "$(obj_dir)" mkdir "$(obj_dir)"
	@dir "$(obj_dir)" /s /b /a:-d 2>nul || rd /s /q "$(obj_dir)"
# Delete the main targets (lib/exe) separately, as they may be outside the tree:
	@for %f in ($(build)) do @if exist "%f" del "%f"
# Delete some other cruft, too:
	@del "$(out_dir)\*.pdb" "$(out_dir)\*.idb" "$(out_dir)\*.ilk" 2>nul
	@if exist "$(mainlib_rule_inc)" del "$(mainlib_rule_inc)"

clean_all:
	@if not "$(abspath $(out_dir))" == "$(abspath .\$(out_dir))" echo - ERROR: Invalid output dir path: "$(out_dir)" && exit -1
# RD will ask...:
# - But to let the idiotic tools run at least, the dir must exist, so if it was deleted
# in a previous run, we must recreate it just to be able to check and then delete it
# right away again... Otherwise: "The system cannot find the file specified."):
	@if not exist "$(out_dir)" mkdir "$(out_dir)"
	@if not "$(abspath $(out_dir))" == "$(abspath .)" @rd /s "$(out_dir)"
# Delete the libs/exes separately, as they may be off-tree:
	@if exist "$(main_lib)" del "$(main_lib)"
	@if exist "$(main_exe)" del "$(main_exe)"
#!!Still can't do the entire "matrix" tho! :-/ (Behold the freakish triple quotes here! ;) )
	@$(ECHO) - NOTE: Some build targets may still have been left around, if they are not in """$(out_dir)""".


#-----------------------------------------------------------------------------
# Actual ("low-level") build jobs...
#-----------------------------------------------------------------------------

# Dependency rules for the main lib/exe
## Sorry, no autodeps.; see at the compile_dir: rule!
### OON legacy: $(OBJS) $(CPP_MODULE_IFCS): $(INCLUDES) $(CPP_MODULE_SOURCES)


#------------------------
# Build the "main" lib
#------
!if "$(main_lib)" != ""
!ifdef RECURSED_FOR_FINISHING
!include $(mainlib_rules_inc)
!endif
#! Exploiting the fact that single-: rules are combined, so the deps. are in the include,
#! and the commands can be here, while still considering the dependencies:
$(main_lib):
	@$(ECHO) Creating lib: $@...
#!!Add VERBOSE support, but not with !if, but a $(mute)=@ cond. macro:
	lib -nologo -out:$@ $**
!endif

#------------------------
# Build the "main" exe
#------
!if "$(main_exe)" != ""
!ifdef RECURSED_FOR_FINISHING
!include $(mainexe_rules_inc)
!endif
#! See at main_lib: about implicitly combining the included deps.!
$(main_exe): $(obj_dir)\main.obj $(main_lib)
	@$(ECHO) Creating executable: $@...
#!!Add VERBOSE support, but not with !if, but a $(mute)=@ cond. macro:
	link -nologo $(LINKFLAGS) -out:$@ @$(obj_list_file) $(EXT_LIBS) $**
!endif

## Especially for this one...:
$(obj_dir)/main.obj: $(OON_HASH_INCLUDE_FILE)

!if defined(OON_HASH_INCLUDE_FILE)
$(OON_HASH_INCLUDE_FILE):
	$(ECHO) "	Make last commit ID available for #including..."
	$(BB) sh tooling/git/_create_commit_hash_include_file.sh
	$(ECHO)
!else
!message -ERROR: OON_HASH_INCLUDE_FILE not defined. Env setup not run?
!endif

#-----------------------------------------------------------------------------
# Some auto-remake support (-- the rest is in the OON build script!)
# Changing the makefile triggers a full rebuild.
#!! I'm sure there's a better way for this, but for now:
OON_FULL_REBUILD_BY_MANUAL_DEPS=$(OON_CPP_MODULE_IFCS)

#!ifdef SRC_EXT_
#!! I seriously don't understand why this nonsense is actually needed to trigger a full recomp.!
#!! It's adding /some of/ the /sources/ (of the current dir run) to the targets, right?! :-o
#!! Why is it even not a "dunno how to make" error?!
#OON_FULL_REBUILD_BY_MANUAL_DEPS=$(OON_FULL_REBUILD_BY_MANUAL_DEPS) $(src_dir)\$(UNITS_PATTERN).$(SRC_EXT_)
#!endif

$(OON_FULL_REBUILD_BY_MANUAL_DEPS): $(THIS_MAKEFILE)


#-----------------------------------------------------------------------------
#!!
#!! While prototyping, this is a mishmash of original NMAKE settings and the
#!! faked dummy config of brutebild.cmd! Neither can rely on the other yet! :)
#!!
#!! The thing here should be generated by the BBild script! (Yes, in addition
#!! to the previously generated interim dependency builder makefile, for now!)
#!!
BBB_build: BBB_init BBB_main

_mute=
# Set build params (main target name, per-file inference command to compiling etc.)...
# Just $(main_exe) would summon the eponymous zombie OON target, so, dodge that...:
BBB_MAIN_TARGET = $(main_exe).EXE
#!message BBB_MAIN_TARGET = $(BBB_MAIN_TARGET)
BBB_CC_PROXY = $(_mute)$(CXX) $(CFLAGS) $(CXXFLAGS) -ifcOutput $(cxx_mod_ifc_dir)\ -Fo$(OBJ_DIR_) $<

#!message include: $(BBB_MAKEFILE_TEMPLATE)
!ifdef BBB_MAKEFILE_TEMPLATE
!include $(BBB_MAKEFILE_TEMPLATE)
!endif

BBB_init:
#	if not exist "$(IFC_ROOT)" md %IFC_ROOT%
#	if not exist "$(OBJ_ROOT)" md %OBJ_ROOT%

BBB_main: $(BBB_MAIN_TARGET)

$(BBB_MAIN_TARGET):
#! See at main_lib: about implicitly combining the included deps.!
#! NOTE: That works only because $(ASK_NMAKE_MAKEFILE) is included above
#$(main_exe): $(obj_dir)\main.obj $(main_lib)
#	@$(ECHO) Creating executable: $@...
#!!Add VERBOSE support, but not with !if, but a $(mute)=@ cond. macro:
	$(_mute)link -nologo $(LINKFLAGS) -out:$@ $** $(main_lib)
# $(EXT_LIBS)
