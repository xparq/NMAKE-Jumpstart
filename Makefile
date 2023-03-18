# ***
# *** BEWARE! This makefile will be recursed (with the list of obj. to compile)!
# ***         (You can use `!ifdef RECURSED` for checking.)
# ***
#     Based on the idea of: https://stackoverflow.com/a/65223598/1479945

.SUFFIXES: .cpp .cxx .c

name=example

!ifdef RECURSED
!if "$(DIR)" == ""
node=main
!else
node=$(DIR)
!endif
!message Compiling: "$(node)"...
!endif

lib=$(lib_dir)/$(name)($_debug_suffix).lib

src_dir=src/$(DIR)
out_dir=out

obj_dir=$(out_dir)/obj/$(DIR)
lib_dir=$(out_dir)

units_pattern = *

cxx_modifc_dir=$(out_dir)/mod



#-----------------------------------------------------------------------------
CC_FLAGS=$(CC_FLAGS) -nologo -c
CC_FLAGS=$(CC_FLAGS) -ifcSearchDir $(cxx_modifc_dir)

_debug_suffix=$(subst 1,-d,$(DEBUG))
# Fixup for DEBUG=0:
_debug_suffix=$(subst 0,,$(_debug_suffix))


#-----------------------------------------------------------------------------
all::
	# Pre-create the output dirs, as MSVC can't be bothered:
	@if not exist "$(lib_dir:/=\)"        md "$(lib_dir:/=\)"
	@if not exist "$(obj_dir:/=\)"        md "$(obj_dir:/=\)"
	@if not exist "$(cxx_modifc_dir:/=\)" md "$(cxx_modifc_dir:/=\)"

all:: objs lib

lib:
###	lib -out:$@ $(obj_dir)
##	lib -nologo -out:$(lib) $(obj_dir)/$(units_pattern).obj
#	@set _objs=dummy
#	@for /r $(obj_dir) %%o in ($(units_pattern).obj) do set _objs=%%o
#	echo %_objs%%

objs: $(src_dir)/$(units_pattern).cpp
	@$(MAKE) -nologo RECURSED=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,$(**:.cpp=.obj))


#-----------------------------------------------------------------------------
{$(src_dir)}.c {$(obj_dir)}.obj::
	@$(CC) -Fo$(obj_dir)/ $<

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	@$(CC) -Fo$(obj_dir)/ $<

{$(src_dir)}.cxx{$(obj_dir)}.obj::
	@$(CC) -Fo$(obj_dir)/ $<

#!!?? I'm not sure if this is actually the proper way to compile mod. ifcs!...:
{$(src_dir)}.ixx{$(obj_dir)}.ifc::
	@$(CC) -ifcOutput $(cxx_modifc_dir)/ $<
