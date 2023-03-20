WARNING: Still in early development! (Just passed the "early proto for 
building the entirely void toy test sources" stage...)

It aims to have the following features, though:

- [x] Single-file drop-in build to kickstart simple C/C++ projects
- [x] Flexible and scaleable enough to allow reasonable growth without
      worrying about a real build sytem
- [.] Familiar config macros, with ready-to-use defaults for simple setups
- [.] Basic facilities to configure external deps. (libs)
- [x] Doesn't require external deps. itself (beyond MSVC + Windows)
- [x] Handle src. subdirs transparently (something NMAKE hates to do...)
- [x] Build a lib from the sources
- [x] Build executables
- [ ] Basic (configurable) smoke-testing of build results
- [x] DEBUG/RELEASE builds
- [.] Static/DLL builds
- [ ] Separate target trees for incompatible build options
- [ ] Cleanup task
- [ ] Header dependency auto-tracking
- [ ] (Some) support for C++ modules
- [ ] Auto-detect changes in the build command line or in env. vars
      to trigger full rebuild


DEV. NOTES:

* Due to NMAKE's inability to handle arbitrary subdirs flexibly in the 
  source/target tree (namely, in inference rules), recursive dir traversal
  has to be delegated to shell commands (e.g. in a wrapper script, or a
  driver rule) instead.

  (While NMAKE can execute shell commands during preproc. time to gather
  files or subdirs recursively anywhere, the problem is that the results
  of those commands can't be assigned to macros. !INCLUDE files could be
  created on-the-fly during preprocessing time, but only very simple ones,
  as the hostile "programming environment" of the !if[...] NMAKE directive
  combined with the CMD shell command-line you land on within that makes
  a Mars-mission feel like a dream holiday in comparison!)

* To avoid having to name the taget modules one by one, especially across
  multiple directories, the only sane way to enumerate them (with most make
  tools) is

    1. to assume a 1-to-1 relationship between the (relative) paths of
       certain source file types (i.e. the C/C++ translation units) and
       their corresponding targets (i.e. object files),

    2. and map those source names to their matching target names to allow
       compiling -- via inference rules -- implicitly, identifying them by
       their types and locations, not their names.

  However, due to two other inabilities of NMAKE, i.e. that a) it can't do
  pattern-matching for paths in inference rules, and b) it can only match
  wildcards on dependency lines -- which is too late for using the results
  as target lists in other rules --, a recursion trick is used, as described 
  below. (Idea from: https://stackoverflow.com/a/65223598/1479945)
  (Note: GNU make does support path patterns in inference rules, and also
  has macro facilities to manipulate paths with wildcards during preproc.
  time (*and* lets you set the results as macro values), which makes
  handling filesystem trees practically trivial there.)

  With NMAKE, where wildcard-expansion results can only propagate from
  dependency lines downward to command blocks, there's one more "secret"
  place, where those wildcard-matching results can still make their way
  to rule definitions, as targets: the make command-line itself.

  So, we can call NMAKE again, now with the expanded target list, and
  let it then find the matching rules to build them.

  Well, almost... Because of its crippled path matching in inference rules,
  we also have to pass the current subdir to it explicitly, so it can
  use that in those rules. This also means that we must process the source
  tree dir-by-dir -- can't just grab all the sources, `patsubst` them
  to corresponding target names, and pass the whole list to a new make
  subprocess in one go... (So, every dir will need a new child NMAKE
  process. Well, at least it's not a recursive NMAKE proces tree.)

  (Of course, with the abomination NMAKE is, even this will entail a lot
  of convoluted workarounds, so this is easier said than done -- but at
  least it _can_ be done, eventually.
  What's still a long way away, though, is header autodependecy tracking.
  GCC is, again, way ahead of MSVC in this regard, unfortunately. I.e. the
  `CL -showIncludes` option is a bad joke.)
