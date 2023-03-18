# ***
# *** BEWARE! This makefile will be recursed (with the list of obj. to compile)!
# ***         (You can use `!ifdef RECURSED` for checking.)
# ***
#https://stackoverflow.com/questions/65196542/using-nmake-with-wildcarded-targets
.SUFFIXES: .cpp

!ifdef RECURSED
!if "$(DIR)" == ""
node=main
!else
node=$(DIR)
!endif
!message Compiling: "$(node)"...
!endif

name=example
lib=$(lib_dir)/$(name)($_debug_suffix).lib
_debug_suffix=$(subst 1,-d,$(DEBUG))
# Fixup for DEBUG=0:
_debug_suffix=$(subst 0,,$(_debug_suffix))

src_dir=src/$(DIR)
out_dir=out

obj_dir=$(out_dir)/obj/$(DIR)
lib_dir=$(out_dir)

units_pattern = *


all::
	@if not exist "$(obj_dir:/=\)" md "$(obj_dir:/=\)"

all:: objs lib

lib:
###	lib -out:$@ $(obj_dir)
##	lib -nologo -out:$(lib) $(obj_dir)/$(units_pattern).obj
#	@set _objs=dummy
#	@for /r $(obj_dir) %%o in ($(units_pattern).obj) do set _objs=%%o
#	echo %_objs%%

objs: $(src_dir)/$(units_pattern).cpp
#  echo $(patsubst $(src_dir)/%,$(obj_dir)/%,$(**:.cpp=.obj))
	@$(MAKE) -nologo RECURSED=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,$(**:.cpp=.obj))
#... out/sub/deep.obj deep.obj

{$(src_dir)}.cpp{$(obj_dir)}.obj::
	@$(CC) -nologo -c -Fo$(obj_dir)/ $<
