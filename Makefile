# ***
# *** BEWARE! This makefile will be recursed via two paths:
# *** - first from the dir traversal loop (only 1 depth level)
# *** - then also with the list of obj. files for that dir to compile
# ***

.SUFFIXES: .c .cpp .cxx .ixx

name=example
lib=$(lib_dir)/$(name)$(_debug_suffix).lib

!ifdef RECURSED_FOR_COMPILING
!if "$(DIR)" == ""
node=main
!else
node=$(DIR)
!endif
!message Processing: "$(node)"...
!endif


src_dir=src/$(DIR)
out_dir=out
lib_dir=$(out_dir)
obj_dir=$(out_dir)/obj/$(DIR)
cxx_modifc_dir=$(out_dir)/mod

units_pattern = *


#-----------------------------------------------------------------------------
#! Normalize all the dirs before passing them to any arcane "DOS" commands
#! that could choke on fwd. slashes!
src_dir=$(src_dir:/=\)
out_dir=$(out_dir:/=\)
lib_dir=$(lib_dir:/=\)
obj_dir=$(obj_dir:/=\)
cxx_modifc_dir=$(cxx_modifc_dir:/=\)

#-----------------------------------------------------------------------------
CFLAGS=$(CFLAGS) -nologo -c
CXXFLAGS=$(CXXFLAGS) -ifcSearchDir $(cxx_modifc_dir)

_debug_suffix=$(subst 1,-d,$(DEBUG))
# Fixup for DEBUG=0:
_debug_suffix=$(subst 0,,$(_debug_suffix))


#-----------------------------------------------------------------------------
# Default target - walk through the src tree dir-by-dir & build each,
#                  plus do an initial and a final wrapping round
traverse_src_tree::
	@cmd /nologo /c <<treewalk.cmd
	@echo off
	setlocal enabledelayedexpansion
	set make=nmake -nologo -f Makefile
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
	endlocal
<<

#-----------------------------------------------------------------------------
start: mk_target_dirs
compiling: objs
finish: lib

mk_target_dirs:
# Pre-create the output dirs, as MSVC can't be bothered:
	@if not exist "$(lib_dir)"        md "$(lib_dir)"
	@if not exist "$(obj_dir)"        md "$(obj_dir)"
	@if not exist "$(cxx_modifc_dir)" md "$(cxx_modifc_dir)"

lib: 
###	lib -out:$@ $(obj_dir)
##	lib -nologo -out:$(lib) $(obj_dir)/$(units_pattern).obj
#	@set _objs=dummy
#	@for /r $(obj_dir) %%o in ($(units_pattern).obj) do @echo %%o
	@cmd /nologo /c <<mklib.cmd
	@echo off
	setlocal enabledelayedexpansion
	for /r $(obj_dir) %%o in ($(units_pattern).obj) do  (
		set _o_=%%o
		set _o_=!_o_:%CD%\=!
		set objlist=!objlist! !_o_!
	)
	lib /nologo /out:$(lib) !objlist!
<<

objs: $(src_dir)/$(units_pattern).c*
# Do the .c after all the other patterns that could also match ".c*"!:
	@$(MAKE) -nologo RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,\
		$(subst .c,.obj,$(subst .cxx,.obj,$(subst .cpp,.obj,$**))))

#!!Would fail with fatal error U1037 dunno how to maka *.ixx, if they don't happen to exist!
#!!objs:: $(src_dir)/$(units_pattern).ixx
#!!	@$(MAKE) -nologo RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,$(**:.ixx=.ifc))


#-----------------------------------------------------------------------------
{$(src_dir)}.c{$(obj_dir)}.obj:
	$(CC)   $(CFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

{$(src_dir)}.cxx{$(obj_dir)}.obj::
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -Fo$(obj_dir)/ $<

#!!?? This is probably not the way to compile mod. ifcs!...:
{$(src_dir)}.ixx{$(obj_dir)}.ifc::
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -ifcOutput $(cxx_modifc_dir)/ $<

