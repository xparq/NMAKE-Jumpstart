#### NMAKE + MSVC C/C++ lib-builder Makefile, v0.02            (Public Domain)
####
#### BEWARE! It will be recursed via two different paths:
#### - first from the dir-traversal loop (only 1 additional depth
####   level; the dir-traversal is NOT recursive!)
#### - then also with the list of obj. files for that dir to compile
#### Accordingly, update this macro below if you rename this file!
THIS_MAKEFILE=Makefile

#-----------------------------------------------------------------------------
# Project config. Edit as needed!
#-----------------------------------------------------------------------------
PRJ_NAME=example
main_lib=$(lib_dir)/$(PRJ_NAME)$(lib_suffix).lib
main_exe=$(exe_dir)/$(PRJ_NAME)$(exe_suffix).exe

src_dir=src
out_dir=out
lib_dir=$(out_dir)
exe_dir=$(out_dir)
obj_dir=$(out_dir)/obj
cxx_mod_ifc_dir=$(out_dir)/mod

# Put (only) these into the lib
# (Relative to src_dir; keep it empty for the root of it!)
lib_src_subdir=

# Options:
DEBUG=0
LINKMODE=static
units_pattern=*
CFLAGS=-W4
CXXFLAGS=-EHsc -std:c++latest
# Note: C++ compilation would use $(CFLAGS), too.

# External dependencies:
ext_include_path=
ext_lib_path=
ext_libs=

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
#! Normalize all the (prj-local) paths before potentially passing them to any
#! arcane "DOS" commands only to make them choke on fwd. slashes!...
#-----------------------------------------------------------------------------
main_lib=$(main_lib:/=\)
main_exe=$(main_exe:/=\)
src_dir=$(src_dir:/=\)
out_dir=$(out_dir:/=\)
lib_dir=$(lib_dir:/=\)
obj_dir=$(obj_dir:/=\)
cxx_mod_ifc_dir=$(cxx_mod_ifc_dir:/=\)

#!!!! I can't do path translation in !if[...] one-liners, so there's not
#!!!! much point in collecting the sources in a file, as they can only
#!!!! be used too late, in commands, anyway... :-/
#!!!! See the mk_main_lib_dep_list: rule hack instead!
#!! Collect all the lib sources (for further processing later)
#!! (Mind each \ in the dir command! ;) )
#!!!if ![dir /s /b $(src_dir)\$(main_lib_root_dir)\*.c* > $(libsrclist_tmp)]
#!!!endif


#-----------------------------------------------------------------------------
# Set/adjust tool options (according to the config)...
#-----------------------------------------------------------------------------
# Preserve the original NMAKE flags & explicitly supported macros on recursion:
MAKE_CMD=$(MAKE) /nologo /$(MAKEFLAGS) /f $(THIS_MAKEFILE) DEBUG=$(DEBUG) LINKMODE=$(LINKMODE)

CFLAGS=-nologo -c $(CFLAGS)
CXXFLAGS=-ifcSearchDir $(cxx_mod_ifc_dir) $(CXXFLAGS)

#-----------------------------
# DEBUG/RELEASE adjustments
#------
CFLAGS_DEBUG_0=$(CFLAGS_CRT_LINKMODE) -O2 -DNDEBUG
# The -O...s below are taken from Dr. Memory's README/Quick start.
# -ZI enables edit-and-continue (but it only exists for Intel CPUs!).
CFLAGS_DEBUG_1=$(CFLAGS_CRT_LINKMODE)d -ZI -Oy- -Ob0 -DDEBUG -Fd$(out_dir)/
LINKFLAGS_DEBUG_0=
LINKFLAGS_DEBUG_1=-debug -incremental -editandcontinue -ignore:4099

!if defined(DEBUG) && $(DEBUG) == 1
#!!message DEBUG mode.
CFLAGS_DEBUGMODE=$(CFLAGS_DEBUG_1)
LINKFLAGS_DEBUGMODE=$(LINKFLAGS_DEBUG_1)
!else if $(DEBUG) == 0
#!!message Release mode.
CFLAGS_DEBUGMODE=$(CFLAGS_DEBUG_0)
LINKFLAGS_DEBUGMODE=$(LINKFLAGS_DEBUG_0)
!else
!error Unknown debug mode: $(DEBUG)!
!endif

CFLAGS=$(CFLAGS_DEBUGMODE) $(CFLAGS_LINKMODE) $(CFLAGS)
LINKFLAGS=$(LINKFLAGS_DEBUGMODE) $(LINKFLAGS)

#-----------------------------------------------------------------------------
# Split the target tree across build alternatives...
#!! Would be nice to just split the root, but the libs and exes can be
#!! off the tree (for convenience & flexibility, e.g. differentiated by name
#!! suffixes etc.)... Which leaves us with dispatching the obj_dir instead
#!! -- and leaving the lib_dir and exe_dir unhandled yet if those targets
#!! are not being treated specially!!
#-----------------------------------------------------------------------------
#!!Shouldn't be necessary; further dispatching can be incremental!
#!!_src_dir_root=$(src_dir)
#!!_obj_dir_root=$(obj_dir)

!if "$(LINKMODE)" == "dll"
obj_dir=$(obj_dir).dl
# And this for the lib/exe *files* instead:
linkmode_suffix=$(linkmode_suffix)-dl
!endif

!if "$(DEBUG)" == "1"
obj_dir=$(obj_dir).DEBUG
# And this for the lib/exe *files* instead:
debugmode_suffix=-d
!endif

lib_suffix=$(linkmode_suffix)$(debugmode_suffix)
exe_suffix=$(linkmode_suffix)$(debugmode_suffix)

#-----------------------------------------------------------------------------
# Adjust paths for the inference rules, according to the current subdir-recursion
#-----------------------------------------------------------------------------
src_dir=$(src_dir)\$(DIR)
obj_dir=$(obj_dir)\$(DIR)


#------------------------------------
# Static/DLL link-mode adjustments
#------
!if "$(LINKMODE)" == "static"
CFLAGS_CRT_LINKMODE=-MT
!else if "$(LINKMODE)" == "dll"
CFLAGS_CRT_LINKMODE=-MD
!else
!error Unknown link mode: $(LINKMODE)!
!endif


#-----------------------------------------------------------------------------
# Default target - walk through the src tree dir-by-dir & build each,
#                  plus do an initial and a final wrapping round
#-----------------------------------------------------------------------------
traverse_src_tree:
	@cmd /v:on /c <<treewalk.cmd
	@echo off
	rem !!This below fails to run without the extra shell! :-o
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
		!_make_! /c compiling DIR=!_dir_!
	)
	!_make_! RECURSED_FOR_FINISHING=1 finish
<<

#-----------------------------------------------------------------------------
# Other task-rules...
#-----------------------------------------------------------------------------
start: mk_main_target_dirs mk_main_lib_rule_inc

compiling: mk_obj_dirs objs

finish: default_lib default_exe

mk_main_target_dirs:
# Pre-create the output dirs, as MSVC can't be bothered:
	@if not exist "$(lib_dir)" md "$(lib_dir)"
	@if not exist "$(cxx_mod_ifc_dir)" md "$(cxx_mod_ifc_dir)"

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

default_lib: $(main_lib)

default_exe: $(main_exe)

clean:
# Cleans only the target tree of the current build alternative!
# (A clean_all rule would be nice, too.)
# And no way I'd just let loose an RD /S /Q "$(obj_dir)"!...
	@cmd /e:on /c del /s "$(obj_dir)\*.obj"
#	@for /r "$(obj_dir)" %%d in (.) do @if exist %%d\*.obj del %%d\*.obj
#!!This doesn't work for checking an empty tree...:
#!!	@cmd /c dir "$(obj_dir)" /s /b /a:-d || echo rd "$(obj_dir)"
	@if exist "$(main_lib)" del "$(main_lib)"
	@if exist "$(main_exe)" del "$(main_exe)"

#=============================================================================
# Actual build rules for the task-rules above...
#=============================================================================

#-----------------------------------------------------------------------------
# Build the "main lib" -> GH Issue #2 about force-rebuilding it!
#-----------------------------------------------------------------------------
!ifdef RECURSED_FOR_FINISHING
!include $(mainlib_rule_inc)
!endif

#-----------------------------------------------------------------------------
# Build the "main executable"
#-----------------------------------------------------------------------------
$(main_exe): $(obj_dir)\main.obj $(main_lib)
	@echo Creating executable: $@...
	link -nologo $(LINKFLAGS) -out:$@ $(ext_libs) $**

#-----------------------------------------------------------------------------
# Inference rules for .obj compilation...
# NOTE: The prefix paths have been updated (see way above) to match the
#       subdir the tree traversal (recursion) is currently at!
#-----------------------------------------------------------------------------
{$(src_dir)}.c{$(obj_dir)}.obj::
	$(CC)   $(CFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cxx{$(obj_dir)}.obj::
	$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

#!!?? This is probably not the way to compile mod. ifcs!...:
#{$(src_dir)}.ixx{$(obj_dir)}.ifc::
#	$(CXX) $(CFLAGS) $(CXXFLAGS) -ifcOutput $(cxx_mod_ifc_dir)/ $<
