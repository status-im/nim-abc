import std/hashes
import pkg/nimcrypto

type
  TxHash* = distinct MDigest[256]
  AckHash* = distinct MDigest[256]

func `==`*(a, b: TxHash): bool {.borrow.}
func `==`*(a, b: AckHash): bool {.borrow.}
func `$`*(h: TxHash): string {.borrow.}
func `$`*(h: AckHash): string {.borrow.}

func hash*[H: TxHash|AckHash](_: type H, bytes: openArray[byte]): H =
  H(sha256.digest(bytes))

func toBytes*(hash: TxHash|AckHash): array[32, byte] =
  MDigest[256](hash).data

func hash*(hash: TxHash|AckHash): Hash =
  hashes.hash(hash.toBytes)
