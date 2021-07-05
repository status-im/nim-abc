import std/hashes except Hash
import pkg/nimcrypto

type
  Hash* = distinct MDigest[256]

func `==`*(a, b: Hash): bool {.borrow.}
func `$`*(h: Hash): string {.borrow.}

func hash*(bytes: openArray[byte]): Hash =
  Hash(sha256.digest(bytes))

func toBytes*(hash: Hash): array[32, byte] =
  MDigest[256](hash).data

func hash*(hash: Hash): hashes.Hash =
  hashes.hash(hash.toBytes)
