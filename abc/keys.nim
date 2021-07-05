import std/sugar
import std/sequtils
import pkg/blscurve as bls
import pkg/nimcrypto
import pkg/questionable

type
  PrivateKey* = distinct bls.SecretKey
  PublicKey* = distinct bls.PublicKey
  Signature* = distinct bls.Signature

func `==`*(a, b: PrivateKey): bool {.borrow.}
func `==`*(a, b: PublicKey): bool {.borrow.}
func `==`*(a, b: Signature): bool {.borrow.}

func `$`*(s: PrivateKey): string {.error: "Private keys should not be printed".}
func `$`*(s: PublicKey): string {.borrow.}
func `$`*(s: Signature): string {.borrow.}

proc random*(_: type PrivateKey): PrivateKey =
  var seed = newSeq[byte](64)
  doAssert randomBytes(seed) == seed.len
  doAssert deriveMasterSecretKey(bls.SecretKey(result), seed)
  burnArray(seed)

func erase*(key: var PrivateKey) =
  burnMem(key)

func toPublicKey*(private: PrivateKey): PublicKey =
  doAssert publicFromSecret(bls.PublicKey(result), bls.SecretKey(private))

func sign*(key: PrivateKey, message: openArray[byte]): Signature =
  Signature(bls.SecretKey(key).sign(message))

func verify*(key: PublicKey,
             message: openArray[byte],
             signature: Signature): bool =
  ## TODO: not safe w.r.t. rogue public-key attack. Needs implementation of
  ## modified BLS multi-signature construction as described in:
  ## https://crypto.stanford.edu/~dabo/pubs/papers/BLSmultisig.html
  bls.PublicKey(key).verify(message, bls.Signature(signature))

func aggregate*(keys: varargs[PublicKey]): PublicKey =
  var aggregate: bls.PublicKey
  doAssert aggregateAll(aggregate, @keys.map(key => bls.PublicKey(key)))
  PublicKey(aggregate)

func aggregate*(signatures: varargs[Signature]): Signature =
  var aggregate: bls.Signature
  doAssert aggregateAll(aggregate, @signatures.map(sig => bls.Signature(sig)))
  Signature(aggregate)

func toBytes*(key: PublicKey): seq[byte] =
  var bytes: array[48, byte]
  doAssert serialize(bytes, bls.PublicKey(key))
  @bytes

func fromBytes*(_: type PublicKey, bytes: openArray[byte]): ?PublicKey =
  var key: bls.PublicKey
  if key.fromBytes(bytes):
    PublicKey(key).some
  else:
    PublicKey.none
