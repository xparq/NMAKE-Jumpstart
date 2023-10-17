To integrate the template script into the Makefile:

- Call it from some default rule with `@cmd /c <<...` like this:

  Makefile:
	...
	bootstrap:
		@cmd /c <<$(out_dir)\bbb.cmd
	!!
	!! COPY THE SCRIPT TEMPLATE HERE...
	!!
	<<

- Make sure the $(THIS_MAKEFILE) NMAKE macro (referenced by the script) is
  set before that rule def.

- Replace each occurrence of $^ with $$^ (for valid NMAKE embedded doc syntax)!
  NOTE: It's crucial that NONE $(MACRONAME) refs would be altered, though!
  Fortunately (basically as a happenstance), all other $... expressions in the
  sctipt start with $^ (so as to be valid CMD syntax...), and happen to be
  easily replaced.
