# Copyright (c) 2017 Howard Chu @ Symas Corp.

MAINSRCS = main.c args.c histogram.c random.c
MAINOBJS = main.o args.o histogram.o random.o

TESTSRCS = t_bdb.c t_lmdb.c t_leveldb.cc
TESTOBJS = t_bdb.o t_lmdb.o t_leveldb.o

TESTS = t_bdb t_lmdb t_leveldb

OPT = -O2 -DNDEBUG
CC = gcc -pthread
CXX = g++ -std=c++0x -pthread
CFLAGS = $(OPT)

all: $(TESTS)

clean:
	rm -f dbb.o $(MAINOBJS) $(TESTOBJS) $(TESTS)

dbb.o:	$(MAINOBJS)
	$(LD) -r -o $@ $^

t_bdb: dbb.o t_bdb.o
	$(CC) -o $@ $^ -Wl,-Bstatic -ldb -Wl,-Bdynamic -lm

t_lmdb: dbb.o t_lmdb.o
	$(CC) -o $@ $^ -Wl,-Bstatic -llmdb -Wl,-Bdynamic -lsnappy -lm

t_leveldb: dbb.o t_leveldb.o
	$(CXX) -o $@ $^ ../leveldb/out-static/libleveldb.a -lsnappy

t_leveldb.o: t_leveldb.cc
	$(CXX) -c $(CFLAGS) -I../leveldb/include $^
