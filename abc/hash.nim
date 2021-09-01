import std/hashes
import pkg/nimcrypto

type
  HashKind* {.pure.} = enum Tx, Ack
  Hash* = object
    kind*: HashKind
    hash: MDigest[256]
  Hashing* = object
    kind: HashKind
    context: sha256

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

func init*(_: type Hashing, kind: HashKind): Hashing =
  result.kind = kind
  result.context.init()

func update*(hashing: var Hashing, bytes: openArray[byte]) =
  hashing.context.update(bytes)

func finish*(hashing: var Hashing): Hash =
  let hash = hashing.context.finish()
  hashing.context.clear()
  Hash(kind: hashing.kind, hash: hash)
