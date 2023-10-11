# Alas, the preproc. can't pick up newly set env. vars... :-/

# Also, why doesn't this work?
!if [             "set X=x" && echo Can't get the shell to see its own %X%...]
!endif
!if [cmd       /c "set X=x" && echo Can't get the shell to see its own %X%...]
!endif
!if [cmd /v:on /c "set X=x" && echo Can't get the shell to see its own !X!...]
!endif

!message X = $(X)


!if [set A=a]
!endif
!if [echo A = "%A%" all right from another command, though!]
!endif

!message But not from the makefile: A = $(A)	# Still no luck... ;)


# Wish...:
res = $[set A=a]
!message res = $(res)
