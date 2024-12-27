# Copyright 2020 Richard Lincoln. All rights reserved.

# PREFIX = /usr/local
# LIBDIR = $(PREFIX)/lib/lib
PREFIX = $(HOME)
LIBDIR = $(shell pwd)/../klusolve/Lib

PPC = ppcx64
PPCFLAGS = -MDelphi -v0ew -vm5025,5027,5029,9001 \
-dUseCThreads -dNOINDY -dNODJSON -dNOFNCS -dNOGIS -dDSS_CAPI -dDEBUG1 \
-Fl$(LIBDIR) \
-FE.. -FU./units \
-Scghi -Cg -Fd -CF64 -k-lc -k-lm -k-lgcc_s -k-lstdc++ -Px86_64 -Tlinux

PPCFLAGS += -g -gv -Ct -O1
#PPCFLAGS += -O3

# VALGRIND = valgrind
VALGRIND = 

all: opendsscmd

opendsscmd:
	cd CMD && mkdir -p units
	cd CMD && $(PPC) $(PPCFLAGS) -oopendsscmd OpenDSSCmd.pas

install: opendsscmd
	install -t $(PREFIX)/bin opendsscmd

check: opendsscmd
	$(VALGRIND) ./opendsscmd CMD/test/IEEE13Nodeckt.dss

clean:
	rm -rf CMD/units/
	rm -f link.res opendsscmd
