# MUST USE UPPER-CASE FOR ENV INTEROP.!...

INHERITED = $(INHERITED).

!if "$(INHERITED)" != "..."
all:
	echo INHERITED=$(INHERITED)
	set INHERITED=$(INHERITED)
	$(MAKE) /f inherit_via_env.mak
!endif
