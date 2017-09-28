# Copyright (c) 2017 Howard Chu @ Symas Corp.

MAINSRCS = main.c args.c histogram.c random.c
MAINOBJS = main.o args.o histogram.o random.o

TESTSRCS = t_bdb.c t_lmdb.c t_leveldb.cc t_basho.cc t_hyper.cc t_rocksdb.cc
TESTOBJS = t_bdb.o t_lmdb.o t_leveldb.o t_basho.o t_hyper.o t_rocksdb.o

TESTS = t_bdb t_lmdb t_leveldb t_basho t_hyper t_rocksdb

OPT = -O2 -DNDEBUG
CC = gcc -pthread
CXX = g++ -pthread
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

t_basho: dbb.o t_basho.o
	$(CXX) -o $@ $^ ../basho_leveldb/libleveldb.a -lsnappy
t_basho.o: t_basho.cc
	$(CXX) -c $(CFLAGS) -I../basho_leveldb/include $^

t_hyper: dbb.o t_hyper.o
	$(CXX) -o $@ $^ ../HyperLevelDB/.libs/libhyperleveldb.a -lsnappy
t_hyper.o: t_hyper.cc
	$(CXX) -c $(CFLAGS) -I../HyperLevelDB/include $^

t_rocksdb: dbb.o t_rocksdb.o
	$(CXX) -o $@ $^ ../rocksdb/librocksdb.a -lsnappy -llz4 -lz -lbz2 -lzstd
t_rocksdb.o: t_rocksdb.cc
	$(CXX) -std=c++11 -c $(CFLAGS) -I../rocksdb/include $^

