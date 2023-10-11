BUILDER_TOOL_DIR=tmp
BUILDER_THIS_MAKEFILE=Makefile



#-----------------------------------------------------------------------------
# Internals...
#-----------------------------------------------------------------------------
toolname=buildtool
toolsrc=$(BUILDER_TOOL_DIR)\$(toolname).c
toolfile=$(BUILDER_TOOL_DIR)\$(toolname).exe
tool=$(toolfile) # Just a comfy shorthand


#-----------------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------------
.PHONY: all bootstrap build_job
all: bootstrap build_job

build_job:
	$(tool)


bootstrap: $(tool)
$(tool): $(BUILDER_THIS_MAKEFILE)
$(tool):
	@if not exist "$(BUILDER_TOOL_DIR)" md "$(BUILDER_TOOL_DIR)"
	@$(CC) /nologo /Fe$(toolfile) /Fo$(BUILDER_TOOL_DIR)\ <<$(toolsrc)
#include <stdio.h>
int main(int argc, char** argv)
{
	printf("Alive! :) \n");
}
<<KEEP
