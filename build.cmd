@echo off
setlocal enabledelayedexpansion

set src_root=%CD%\src

rem Do the root level
@nmake -nologo

rem Do the subdirs
for /f %%i in ('cmd /c dir %src_root% /s /b /a:d') do (
	set tmp_=%%i
	set crap=!tmp_:%src_root%\=!
	@nmake -nologo DIR=!crap!
)

endlocal
