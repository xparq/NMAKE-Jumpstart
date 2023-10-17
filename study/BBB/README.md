The build wrapper script `build-example.cmd` is just an example showing how
to adapt to an existing user-provided `setenv` script for config.

In the default use case (!!add example), where the config is written directly
into a customized Makefile, just calling `nmake` would be all there's to do.

::----------------------------------------------------------------------------
:: TODO
::
:: -	Move the prototype config from the script template to setenv.cmd!
::
:: -	Add simpler alternative (default) example where the config is right
::	in the Makefile!
::
:: -	Properly define the cfg API, first of all for the script, and then,
::	as a consequence, for the Makefile (as they must speak a common
::	language)
::
:: -	Keep the "template" script's ability to still run on its own, i.e.
::	even being the build entry point, via defining its config API (and
::	then either having the cfg. preset by a caller, or embedded in it).
::
:: -	Document that this script expects to be called while having been CD'ed
::	to the project dir (where the build is to be carried out)!
::
:: -	Add a dep. for at least manual header-change tracking...
::
:: FIX:	No checks for some x=%OBJ_ROOT%\... prefixes, and possibly others!
::	- Some/all iteration loops fail with no exclude patterns (bad conditional structures!)
::	E.g. a syntax error for findstr:
::		echo !_f_! | findstr /R "%UNITS_NO_COMPILE_PATH_PATTERN%" > nul
:: -	Option for batch mode on/off! With many files, a comp. error would not
::	write the other successfully compiled ones to disk, so each build
::	would start from scratch! :-/
::
:: -	Use /LIBPATH:$^(obj_dir) + bare obj files for readability -- but only in flat
::	mode, to avoid silent accidental name clashes across multiple subdirs
::	(which are more likely to be intentional namespaces, too, in tree mode!).
::	(Not that it would be easy in tree mode anyway. :) )
::	- It's kinda undocumented tho that it works for obj. files just as well as libs...
::
::----------------------------------------------------------------------------
:: DONE
::
:: +	Just use NMAKE's /Y to disable batch mode, that's it.
::
