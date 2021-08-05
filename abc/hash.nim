import std/hashes
import pkg/nimcrypto

type
  HashKind* {.pure.} = enum Tx, Ack
  Hash* = object
    kind*: HashKind
    hash: MDigest[256]

func hash*(bytes: openArray[byte], kind: HashKind): Hash =
  Hash(kind: kind, hash: sha256.digest(bytes))

func toBytes*(hash: Hash): array[32, byte] =
  hash.hash.data

func hash*(hash: Hash): hashes.Hash =
  cast[int](hash.hash.data)

func `$`*(hash: Hash): string =
  case hash.kind
  of Tx:
    "Tx(" & $hash.hash & ")"
  of Ack:
    "Ack(" & $hash.hash & ")"
