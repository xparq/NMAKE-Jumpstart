@echo off
call %~dp0tooling/_setenv.cmd

:: The original NMAKE-driven process with auto-rebuild:
::busybox sh %~dp0tooling/build/_auto-rebuild.sh %*

:: The new script-driven process (without auto-rebuild yet!):
nmake %*
