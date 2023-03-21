#### MSVC Jumpstart Makefile, v0.04                            (Public Domain)
#### -> https://github.com/xparq/NMAKE-Jumpstart
####
#### BEWARE! Uses recursive NMAKE invocations, so update the macro below if
#### you rename this file:
THIS_MAKEFILE=Makefile

#-----------------------------------------------------------------------------
# Config - Project layout
#-----------------------------------------------------------------------------
PRJ_NAME=example
main_lib=$(lib_dir)/$(PRJ_NAME)$(buildmode_suffix).lib
main_exe=$(exe_dir)/$(PRJ_NAME)$(buildmode_suffix).exe

src_dir=src.test
out_dir=out
lib_dir=$(out_dir)
exe_dir=$(out_dir)
obj_dir=$(out_dir)/obj
cxx_mod_ifc_dir=$(out_dir)/ifc
# Put (only) these into the lib (relative to src_dir; leave it empty for "all"):
lib_src_subdir=

# Source (translation unit) basename filter:
units_pattern=*

# External dependencies:
ext_include_dirs=
ext_lib_dirs=
ext_libs=

#-----------------------------------------------------------------------------
# Config - Build options
#-----------------------------------------------------------------------------
# Build alternatives (override from the command-line, too, if needed):
DEBUG=0
CRT=static

CFLAGS=-W4
CXXFLAGS=-std:c++latest
# Note: C++ compilation would use $(CFLAGS), too.


#=============================================================================
#                     NO EDITS NEEDED BELOW, NORMALLY...
#=============================================================================
.SUFFIXES: .c .cpp .cxx .ixx

obj_sources=.cpp .cxx .c


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
# Normalize all the (prj-local) paths before potentially passing them to any
# arcane "DOS" commands only to make them choke on fwd. slashes!...
#-----------------------------------------------------------------------------
main_lib=$(main_lib:/=\)
main_exe=$(main_exe:/=\)
src_dir=$(src_dir:/=\)
out_dir=$(out_dir:/=\)
lib_dir=$(lib_dir:/=\)
obj_dir=$(obj_dir:/=\)
cxx_mod_ifc_dir=$(cxx_mod_ifc_dir:/=\)

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
# The -O...s below are taken from Dr. Memory's README/Quick start.
# -ZI enables edit-and-continue (but it only exists for Intel CPUs!).
cflags_debug_1=$(_cflags_crt_linkmode)d -ZI -Od -Oy- -Ob0 -RTCsu -DDEBUG -Fd$(out_dir)/
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
# External include & lib search paths
#------
!if "$(ext_include_dirs)" != ""
!if [set INCLUDE=%INCLUDE%;$(ext_include_dirs)]
!endif
!endif

!if "$(ext_lib_dirs)" != ""
!if [set LIB=%LIB%;$(ext_lib_dirs)]
!endif
!endif

#!if "$(ext_lib_dirs)" != ""
#LINKFLAGS=$(LINKFLAGS) -libpath:$(ext_lib_dirs)
#!endif

#-----------------------------------------------------------------------------
# Split the target tree across build alternatives...
#!! Would be nice to just split the root, but the libs and exes can be
#!! off the tree (for convenience & flexibility, e.g. differentiated by name
#!! suffixes etc.)... Which leaves us with dispatching the obj_dir instead
#!! -- and leaving the lib_dir and exe_dir totally ignored... :-/
#-----------------------------------------------------------------------------
!if "$(CRT)" == "dll"
obj_dir=$(obj_dir).dl
# And this for the lib/exe *files* instead:
crt_linkmode_suffix=$(crt_linkmode_suffix)-dl
!endif

!if "$(DEBUG)" == "1"
obj_dir=$(obj_dir).DEBUG
# And this for the lib/exe *files* instead:
debugmode_suffix=-d
!endif

buildmode_suffix=$(crt_linkmode_suffix)$(debugmode_suffix)

#-----------------------------------------------------------------------------
# Adjust paths for the inference rules, according to the current subdir-recursion
#-----------------------------------------------------------------------------
src_dir=$(src_dir)\$(DIR)
obj_dir=$(obj_dir)\$(DIR)

#=============================================================================
# Rules...
#=============================================================================
#-----------------------------------------------------------------------------
# Default target - walk through the src tree dir-by-dir & build each,
#                  plus do an initial and a final wrapping round
#-----------------------------------------------------------------------------
traverse_src_tree:
	@cmd /v:on /c <<treewalk.cmd
	@echo off
	rem !!The make cmd. below fails to run without the extra shell! :-o
	rem !!Also -> #8 why the env. var here can't be called just "make"!... ;)
	set _make_=cmd /c $(MAKE_CMD)
	set srcroot_fullpath=!CD!\$(src_dir)
	:: echo $(src_dir)
	:: echo !srcroot_fullpath!
	rem Do the root level first (-> preps!)...
	rem (Note: naming a (different) target would avoid inf. recursion.)
	!_make_! /c start compiling
	rem Scan the source tree for sources...
	for /f %%i in ('dir /s /b /a:d !srcroot_fullpath!') do (
		rem It's *vital* to use a local name here, not dir (==DIR!!!):
		set _dir_=%%i
		set _dir_=!_dir_:%srcroot_fullpath%=!
		if exist %%i\*.cpp !_make_! /c compiling DIR=!_dir_!
		if exist %%i\*.cxx !_make_! /c compiling DIR=!_dir_!
		if exist %%i\*.c   !_make_! /c compiling DIR=!_dir_!
	)
	!_make_! RECURSED_FOR_FINISHING=1 finish
<<

#-----------------------------------------------------------------------------
# Inference rules for .obj compilation...
# NOTE: The prefix paths have been updated (see way above) to match the
#       subdir the tree traversal (recursion) is currently at!
#-----------------------------------------------------------------------------
{$(src_dir)}.c{$(obj_dir)}.obj::
	$(CC) $(CFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cxx{$(obj_dir)}.obj::
	$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

#!!?? This is probably not the way to compile mod. ifcs!...:
#{$(src_dir)}.ixx{$(obj_dir)}.ifc::
#	$(CXX) $(CFLAGS) $(CXXFLAGS) -ifcOutput $(cxx_mod_ifc_dir)/ $<


#-----------------------------------------------------------------------------
# "Tasks" (one-off and type-related higher-level rules for meta/admin jobs)...
#-----------------------------------------------------------------------------
start: mk_main_target_dirs mk_main_lib_rule_inc

compiling: mk_obj_dirs objs

finish: $(main_lib) $(main_exe)

mk_main_target_dirs:
# Pre-create the output dirs, as MSVC can't be bothered:
	@if not exist "$(out_dir)" md "$(out_dir)"
	@if not exist "$(lib_dir)" md "$(lib_dir)"
	@if not exist "$(exe_dir)" md "$(exe_dir)"
#!!	@if not exist "$(cxx_mod_ifc_dir)" md "$(cxx_mod_ifc_dir)"

mk_obj_dirs:
# These vary for each subdir, so can't be done just once at init:
	@if not exist "$(obj_dir)" md "$(obj_dir)"

objs: $(src_dir)/$(units_pattern).c*
# Do the .c after all the other patterns that could also match ".c*"!:
	@$(MAKE_CMD) RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,\
		$(subst .c,.obj,$(subst .cxx,.obj,$(subst .cpp,.obj,$**))))

mainlib_rule_inc=$(out_dir)\mainlib_rule.inc
mk_main_lib_rule_inc:
	@cmd /v:on /c <<mklib.cmd
	@echo off
	for /r $(src_dir)\$(lib_src_subdir) %%o in ($(units_pattern).c*) do  (
		set _o_=%%o
		set _o_=!_o_:%CD%\$(src_dir)=!
		for %%x in ($(obj_sources)) do (
			set _o_=!_o_:%%x=.obj!
		)
		set objlist=!objlist! $(obj_dir)!_o_:.cpp=.obj!
	)
	echo $(main_lib): !objlist! > $(mainlib_rule_inc)
<<
# And this crap is here separately only because echo can't echo TABs:
	@type << >> $(mainlib_rule_inc)
	@echo Creating lib: $$@...
	lib -nologo -out:$$@ $$**
<<

clean:
# Cleans only the target tree of the current build alternative!
# And no way I'd just let loose a blanket RD /S /Q "$(out_dir)"!...
	@if not "$(abspath $(obj_dir))" == "$(abspath .\$(obj_dir))" echo - ERROR: Invalid object dir path: "$(obj_dir)" && exit -1
# Stop listing all the deleted .obj files despite /q -> cmd /e:off (self-explanatory, right?)
	@if exist "$(obj_dir)\*.obj" cmd /e:off /c del /s /q "$(obj_dir)\*.obj"
# To let the idiotic tools run at least, the dir must exist, so if it was deleted
# in a previous run, we must recreate it just to be able to check and then delete
# it right away again... Otherwise: "The system cannot find the file specified."):
	@if not exist "$(obj_dir)" mkdir "$(obj_dir)"
	@dir "$(obj_dir)" /s /b /a:-d 2>nul || rd /s /q "$(obj_dir)"
# Delete the lib/exe separately, as they may be off-tree:
	@if exist "$(main_lib)" del "$(main_lib)"
	@if exist "$(main_exe)" del "$(main_exe)"
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
	@echo - NOTE: Some build targets may still have been left around, if they are not in """$(out_dir)""".


#-----------------------------------------------------------------------------
# Actual (low-level) one-off build jobs...
#-----------------------------------------------------------------------------
#------------------------
# Build the "main" lib
#------
!ifdef RECURSED_FOR_FINISHING
!include $(mainlib_rule_inc)
!endif

#------------------------
# Build the "main" exe
#------
$(main_exe): $(obj_dir)\main.obj $(main_lib)
	@echo Creating executable: $@...
	link -nologo $(LINKFLAGS) -out:$@ $(ext_libs) $**
