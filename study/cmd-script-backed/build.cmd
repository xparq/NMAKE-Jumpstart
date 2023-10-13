@echo off
call %~dp0tooling/_setenv.cmd

:: The original NMAKE-driven process:
::busybox sh %~dp0tooling/build/_build.sh %*

:: The new script-driven process:
tooling/build/brutebuild %*
