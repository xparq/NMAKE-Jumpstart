#### NMAKE + MSVC C/C++ lib-builder Makefile, v0.01            (Public Domain)
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
name=example
lib=$(lib_dir)/$(name)$(lib_debug_suffix).lib

src_dir=src
out_dir=out
lib_dir=$(out_dir)
exe_dir=$(out_dir)
obj_dir=$(out_dir)/obj
cxx_mod_ifc_dir=$(out_dir)/mod

# Defaults:
DEBUG=0
LINKMODE=static
units_pattern = *

CFLAGS=-W4
CXXFLAGS=-EHsc -std:c++latest
# Note: C++ compilation would use $(CFLAGS), too.

#=============================================================================
#                     NO EDITS NEEDED BELOW, NORMALLY...
#=============================================================================
.SUFFIXES: .c .cpp .cxx .ixx

#-----------------------------------------------------------------------------
# Show current processing stage...
#-----------------------------------------------------------------------------
!ifdef RECURSED_FOR_COMPILING
!if "$(DIR)" == ""
node=main
!else
node=$(DIR)
!endif
!message Processing: "$(node)"...
!endif

# Adjust these for the current subdir-recursion:
src_dir=$(src_dir)/$(DIR)
obj_dir=$(obj_dir)/$(DIR)

#-----------------------------------------------------------------------------
#! Normalize all the (local) dirs before potentially passing them to any
#! arcane "DOS" commands only to choke on fwd. slashes...
#-----------------------------------------------------------------------------
src_dir=$(src_dir:/=\)
out_dir=$(out_dir:/=\)
lib_dir=$(lib_dir:/=\)
obj_dir=$(obj_dir:/=\)
cxx_mod_ifc_dir=$(cxx_mod_ifc_dir:/=\)

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

lib_debug_suffix=$(subst 1,-d,$(DEBUG))
# Fixup for DEBUG=0:
lib_debug_suffix=$(subst 0,,$(lib_debug_suffix))

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
traverse_src_tree::
	@cmd /v:on /c <<treewalk.cmd
	@echo off
	rem !!This below had failed to run without the extra shell. (I'm not even surprised any more.)
	set make=cmd /c $(MAKE_CMD)
	set srcroot_fullpath=!CD!\$(src_dir)
	:: echo $(src_dir)
	:: echo !srcroot_fullpath!
	rem Do the root level first (-> preps!)...
	rem (Note: naming a (different) target would avoid inf. recursion.)
	!make! start compiling
	rem Scan the source tree for sources...
	for /f %%i in ('dir /s /b /a:d !srcroot_fullpath!') do (
		rem It's *vital* to use a local name here, not dir (==DIR!!!):
		set _dir_=%%i
		set _dir_=!_dir_:%srcroot_fullpath%=!
		!make! compiling DIR=!_dir_!
	)
	!make! finish
<<

#-----------------------------------------------------------------------------
# Other task-target rules...
#-----------------------------------------------------------------------------
start: mk_main_target_dirs

compiling: mk_obj_dirs objs

finish: lib

mk_main_target_dirs:
# Pre-create the output dirs, as MSVC can't be bothered:
	@if not exist "$(lib_dir)" md "$(lib_dir)"
	@if not exist "$(cxx_mod_ifc_dir)" md "$(cxx_mod_ifc_dir)"

mk_obj_dirs:
# These vary for each subdir, so can't be done just once at init:
	@if not exist "$(obj_dir)" md "$(obj_dir)"

lib: 
	@echo Creating lib...
	@cmd /v:on /c <<mklib.cmd
	@echo off
	for /r $(obj_dir) %%o in ($(units_pattern).obj) do  (
		set _o_=%%o
		set _o_=!_o_:%CD%\=!
		set objlist=!objlist! !_o_!
	)
	lib -nologo -out:$(lib) !objlist!
<<

objs: $(src_dir)/$(units_pattern).c*
# Do the .c after all the other patterns that could also match ".c*"!:
	@$(MAKE_CMD) RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,\
		$(subst .c,.obj,$(subst .cxx,.obj,$(subst .cpp,.obj,$**))))

#-----------------------------------------------------------------------------
# Inference rules for .obj compilation...
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
