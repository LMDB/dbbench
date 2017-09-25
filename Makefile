# Copyright (c) 2017 Howard Chu @ Symas Corp.

MAINSRCS = main.c args.c histogram.c random.c
MAINOBJS = main.o args.o histogram.o random.o

TESTSRCS = t_bdb.c t_lmdb.c
TESTOBJS = t_bdb.o t_lmdb.o

TESTS = t_bdb t_lmdb

OPT = -O2
CC = gcc -pthread
CFLAGS = $(OPT)

all: $(TESTS)

clean:
	rm -f $(MAINOBJS) $(TESTOBJS) $(TESTS)

t_bdb: $(MAINOBJS) t_bdb.o
	$(CC) -o $@ $^ -Wl,-Bstatic -ldb -Wl,-Bdynamic -lm

t_lmdb: $(MAINOBJS) t_lmdb.o
	$(CC) -o $@ $^ -Wl,-Bstatic -llmdb -Wl,-Bdynamic -lsnappy -lm
