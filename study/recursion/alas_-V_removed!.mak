inherited = $(inherited).

!if "$(inherited)" != "..."
all:
	echo inherited=$(inherited)
	$(MAKE) /V /f "alas_-V_removed!.mak"
!endif
