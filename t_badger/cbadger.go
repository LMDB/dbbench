/* Copyright (c) 2017 Howard Chu @ Symas Corp. */

package main

/*
#include "dbb.h"
*/
import "C"

import (
	"github.com/dgraph-io/badger"
	"unsafe"
)

//export BadgerOpen
func BadgerOpen(dir *C.char, flags C.int, d0 unsafe.Pointer ) int {
	db := (**badger.DB)(d0)
	opt := badger.DefaultOptions
	opt.Dir = C.GoString(dir)
	opt.ValueDir = opt.Dir
	if (flags & 1) != 0 {
		opt.SyncWrites = false
	}
	var err error
	*db, err = badger.Open(&opt)
	if err != nil {
		return -1
	}
	return 0
}

//export BadgerClose
func BadgerClose(d0 unsafe.Pointer) int {
	db := (*badger.DB)(d0)
	err := db.Close()
	if err != nil {
		return -1
	}
	return 0
}

//export BadgerTxnBegin
func BadgerTxnBegin(d0 unsafe.Pointer, flags C.int, t0 unsafe.Pointer) {
	db := (*badger.DB)(d0)
	txn := (**badger.Txn)(t0)
	var update bool
	update = (flags & 1) != 0
	*txn = db.NewTransaction(update)
}

//export BadgerTxnCommit
func BadgerTxnCommit(t0 unsafe.Pointer) int {
	txn := (*badger.Txn)(t0)
	err := txn.Commit(nil)
	if err != nil {
		return -1
	}
	return 0
}

//export BadgerTxnAbort
func BadgerTxnAbort(t0 unsafe.Pointer) {
	txn := (*badger.Txn)(t0)
	txn.Discard()
}

type slicer struct {
	ptr unsafe.Pointer
	len int
	cap int
}

func valslice(val *C.DBB_val, slc *[]byte) {
	var kptr unsafe.Pointer
	kptr = (unsafe.Pointer)(slc)
	var sptr *slicer
	sptr = (*slicer)(kptr)
	sptr.ptr = val.dv_data
	sptr.len = int(val.dv_size)
	sptr.cap = sptr.len
}

//export BadgerGet
func BadgerGet(t0 unsafe.Pointer, key *C.DBB_val, val *C.DBB_val) int {
	txn := (*badger.Txn)(t0)
	var ks []byte
	valslice(key, &ks)
	i, err := txn.Get(ks)
	if err != nil {
		return -1
	}
	v, err := i.Value()
	val.dv_size = C.size_t(len(v))
	val.dv_data = unsafe.Pointer(&v[0])
	return 0
}

//export BadgerPut
func BadgerPut(t0 unsafe.Pointer, key *C.DBB_val, val *C.DBB_val) int {
	txn := (*badger.Txn)(t0)
	var ks []byte
	var vs []byte
	valslice(key, &ks)
	valslice(val, &vs)
	err := txn.Set(ks, vs, 0)
	if err != nil {
		return -1
	}
	return 0
}

//export BadgerCursorOpen
func BadgerCursorOpen(t0 unsafe.Pointer, flags C.int, c0 unsafe.Pointer) {
	txn := (*badger.Txn)(t0)
	cursor := (**badger.Iterator)(c0)
	opt := badger.DefaultIteratorOptions
	if (flags & 1) != 0 {
		opt.Reverse = true
	}
	*cursor = txn.NewIterator(opt)
	(*cursor).Rewind()
}

//export BadgerCursorNext
func BadgerCursorNext(c0 unsafe.Pointer, key *C.DBB_val, val *C.DBB_val) int {
	cursor := (*badger.Iterator)(c0)
	if !cursor.Valid() {
		return -1
	}
	it := cursor.Item()
	v, err := it.Value()
	if err != nil {
		return -1
	}
	val.dv_size = C.size_t(len(v))
	val.dv_data = unsafe.Pointer(&v[0])
	k := it.Key()
	key.dv_size = C.size_t(len(k))
	key.dv_data = unsafe.Pointer(&k[0])
	cursor.Next()
	return 0
}

//export BadgerCursorClose
func BadgerCursorClose(c0 unsafe.Pointer) {
	cursor := (*badger.Iterator)(c0)
	cursor.Close()
}
