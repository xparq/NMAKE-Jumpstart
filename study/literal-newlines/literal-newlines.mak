template_garbled_with_an_extra_space_after_the_1st_tab =\
	@echo off^
	echo nothing^
	echo a caret: ^^^
	echo end^

# Note: the final newline is added implicitly even if not specified!
# (See more at the next example!)

template_garbled_trailing_spaces_trimmed = @echo off ^
	echo nothing ^
	echo a caret: ^^ ^
	echo end         ^
	^

# Note: ALL the trailing whitespace at the end will be chopped off,
# and then a final \n will be added! :-o

template_ok = @echo off^
	echo nothing^
	echo a caret: ^^^
	echo end  ^


#-------------------------------------
all: mac_bad mac_bad_trim mac_ok
	<<script_direct.cmd
	@echo off
	echo nothing
	echo a caret: ^^
	echo end
<<keep

mac_bad:
	<<script_from_mac_bad_space.cmd
	$(template_garbled_with_an_extra_space_after_the_1st_tab)
<<keep

mac_bad_trim:
	<<script_from_mac_bad_trim.cmd
	$(template_garbled_trailing_spaces_trimmed)
<<keep

mac_ok:
	<<script_from_mac_ok.cmd
	$(template_ok)
<<keep

