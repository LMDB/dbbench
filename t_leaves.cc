/* Copyright (c) 2026 Howard Chu @ Symas Corp. */

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

#include <leaves/mmap.hpp>
#include <leaves/version.hpp>

#include "dbb.h"

leaves::MapStorage::storage_ptr storage;
leaves::MapStorage::DB db;

static void db_open(int dbflags) {
	storage = leaves::MapStorage::create(FLAGS_db);
	db = storage->open("main");
}

static void db_close() {
	storage = NULL;
}

static void db_write(DBB_local *dl) {
	DBB_global *dg = dl->dl_global;

	if (dg->dg_num != FLAGS_num) {
		char msg[100];
		snprintf(msg, sizeof(msg), "(%ld ops)", dg->dg_num);
		DBB_message(dl, msg);
	}

	DBB_val dv;
	auto cursor = db.cursor();
	int64_t bytes = 0;
	unsigned long i = 0;
	dv.dv_size = FLAGS_value_size;
	do {
		cursor.start_transaction();
		for (int j = 0; j < dg->dg_batchsize; j++) {
			const uint64_t k = (dg->dg_order == DO_FORWARD) ? i+j : (DBB_random(dl->dl_rndctx) % FLAGS_num);
			char key[100];
			snprintf(key, sizeof(key), "%016lx", k);
			DBB_randstring(dl, &dv);
			cursor.find(leaves::Slice(key));
			cursor.value(leaves::Slice(dv.dv_data, dv.dv_size));
			bytes += FLAGS_value_size + FLAGS_key_size;
			DBB_opdone(dl);
		}
		cursor.commit();
		i += dg->dg_batchsize;
	} while (!DBB_done(dl));
	dl->dl_bytes += bytes;
}

static void db_read(DBB_local *dl) {
	DBB_global *dg = dl->dl_global;

	int64_t bytes = 0;
	auto cursor = db.cursor();
	if (dl->dl_order == DO_RANDOM) {
		std::string value;
		size_t read = 0;
		size_t found = 0;
		char key[100];
		do {
			cursor.update();
			const uint64_t k = DBB_random(dl->dl_rndctx) % FLAGS_num;
			snprintf(key, sizeof(key), "%016lx", k);
			read++;
			cursor.find(leaves::Slice(key));
			if (cursor.is_valid()) {
				leaves::Slice value = cursor.value();
				bytes += FLAGS_key_size + value.size();
				found++;
			}
			DBB_opdone(dl);
		} while (!DBB_done(dl));
		char msg[100];
		snprintf(msg, sizeof(msg), "(%zd of %zd found)", found, read);
		DBB_message(dl, msg);
	} else {
		int i = 0;
		if (dl->dl_order == DO_FORWARD) {
			for (cursor.first(); i < dg->dg_reads && cursor.is_valid(); cursor.next()) {
				leaves::Slice key = cursor.key();
				leaves::Slice value = cursor.value();
				bytes += key.size() + value.size();
				DBB_opdone(dl);
				++i;
			}
		} else {
			for (cursor.last(); i < dg->dg_reads && cursor.is_valid(); cursor.prev()) {
				leaves::Slice key = cursor.key();
				leaves::Slice value = cursor.value();
				bytes += key.size() + value.size();
				DBB_opdone(dl);
				++i;
			}
		}
	}
	dl->dl_bytes += bytes;
}

static char *db_verstr() {
	static char vstr[32];
	snprintf(vstr, sizeof(vstr), LEAVES_VERSION);
	return vstr;
}

static arg_desc db_opts[] = {
	{ NULL }
};

static DBB_backend db_leaves = {
	"leaves",
	"Leaves",
	db_opts,
	db_verstr,
	db_open,
	db_close,
	db_read,
	db_write
};

extern DBB_backend *dbb_backend;
DBB_backend *dbb_backend = &db_leaves;

