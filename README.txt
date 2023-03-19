NOTES:

* Due to NMAKE's inability to handle arbitrary subdirs flexibly in the 
  source/target tree (namely, in inference rules), recursive dir traversal
  is delegated to shell commands (e.g. in a wrapper script, or a driver rule)
  instead.

  (While NMAKE can execute shell commands during preproc. time to gather
  files or subdirs recursively anywhere, the problem is that the results
  of those commands can't be assigned to macros. !INCLUDE files could be
  created on-the-fly during preprocessing time, but that feels like an
  even more cumbersome and/or brittle approach than the one chosen here.)

* To avoid having to name the taget modules one by one, the only sane way
  to enumerate them (with most make tools) is

    1. to assume a one-to-one relationship between certain source file
       types ("translation units" in C/C++) and corresponding target files,

    2. and map those source names to their matching target name pairs
       using inference rules to compile them.

  However, due to another inability of NMAKE, i.e. that it can only match
  wildcards on dependency lines -- which is too late for using the results
  as target lists in other rules --, a recursion trick is used, as described 
  below. (Note: GNU make has macro facilities to discover paths with wildcards
  during preprocessing time *and* set them as macro values, so such target
  lists matching the source layout can be assembled easily.)

  With NMAKE, where wildcard-expansion can only propagate from dependency
  lines to command blocks, there's one more line, where the results of
  wildcard-matching can still make it to rule definitions, as targets:
  the make command-line itself!

  So, we can call NMAKE again, now with the expanded target file list,
  and let it then find the rules to build them!

  Well, almost... Because of its crippled path matching in inference rules,
  we also have to pass it the current subdir, so that it can use it in those
  rules... This means that we must process the source tree dir-by-dir; can't
  just grab all the sources, translate them to target names, and pass that
  entire list to a new make subprocess in one go... Which then also means
  that every dir will need a new NMAKE process. (Well, at least it's not a
  recursive NMAKE proces tree (which should definitely be avoided).)

  (Of course, the abomination NMAKE is, even this will entail a lot of
  convoluted workarounds (to perform basic string conversions, or cover
  corner cases etc.), so this is easier said than done -- but at least
  it _can_ be done, eventually.)

------------------------------------------------------------------------------
TMP. NOTES TO MYSELF:

#!!Would fail with fatal error U1037 dunno how to make *.ixx, if they don't happen to exist!
#!!objs:: $(src_dir)/$(units_pattern).ixx
#!!	@$(MAKE) -nologo RECURSED_FOR_COMPILING=1 DIR=$(DIR) $(patsubst $(src_dir)/%,$(obj_dir)/%,$(**:.ixx=.ifc))


To avoid the issue when a given source type -- used as a wildcard dependency
-- doesn't exist in the given source dir, this hackey won't work, because they
will catch all the _existing_ cases, too:

$(src_dir)/$(units_pattern).cpp:
#!! Well, no `%|eF` either: it "requires a dependent"! ;)
	@echo Bu! Silencing the "Dunno how to make *.cpp" error, when no such file exists.
$(src_dir)/$(units_pattern).cxx:
	@echo Bu! Silencing the "Dunno how to make *.cxx" error, when no such file exists.
$(src_dir)/$(units_pattern).c:
	@echo Bu! Silencing the "Dunno how to make *.c" error, when no no such file exists.
$(src_dir)/$(units_pattern).ixx:
	@echo Bu! Silencing the "Dunno how to make *.ixx" error, when no no such file exists.


To mitigate the stupid "can't build unmatched wildcard" error, the combined
`objs: c*` rule can (coincidentally...) cover in one rule the cases, where
_at least some_ .c* source exists in the given dir...

------------------------------------------------------------------------------
The wildcard-recursion trick: https://stackoverflow.com/a/65223598/1479945
