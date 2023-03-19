src_main=src
out_dir=out

#-----------------------------------------------------------------------------
# Default target
traverse_src_dirs:
	cmd /nologo /c <<crap.cmd
	@echo off
	setlocal enabledelayedexpansion
	set make=nmake -nologo -f dirtree.mak 
	set srcroot_fullpath=!CD!\$(src_main)
	rem Do the root level first (the `main` would avoid inf. recursion!)...
	!make! src_main
	rem Scan the source tree for sources...
	for /f %%i in ('dir /s /b /a:d !srcroot_fullpath!') do (
		set dir=%%i
		set dir=!dir:%srcroot_fullpath%\=!
		!make! src_sub DIR=!dir!
	)
	endlocal
<<

#-----------------------------------------------------------------------------
# Src top-level
src_main:
	@echo Main...

#-----------------------------------------------------------------------------
# Src subdirs
src_sub:
	@echo Sub: $(DIR)...
