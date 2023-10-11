.SUFFIXES: .in .out

INDIR_=.\in
OUTDIR_=.\out

all: $(OUTDIR_)\a.out $(OUTDIR_)\b.out

# Alas, this fails:
all: $(OUTDIR_)\sub\x1.out $(OUTDIR_)\sub\x2.out 


{$(INDIR_)}.in{$(OUTDIR_)}.out::
	@echo $<
