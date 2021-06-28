import pkg/blscurve as bls
import pkg/nimcrypto

type
  PrivateKey* = distinct bls.SecretKey
  PublicKey* = distinct bls.PublicKey
  Signature* = distinct bls.Signature

proc `==`*(a, b: PrivateKey): bool {.borrow.}
proc `==`*(a, b: PublicKey): bool {.borrow.}
proc `==`*(a, b: Signature): bool {.borrow.}

proc random*(_: type PrivateKey): PrivateKey =
  var seed = newSeq[byte](64)
  doAssert randomBytes(seed) == seed.len
  doAssert deriveMasterSecretKey(bls.SecretKey(result), seed)
  burnArray(seed)

proc erase*(key: var PrivateKey) =
  burnMem(key)

proc toPublicKey*(private: PrivateKey): PublicKey =
  doAssert publicFromSecret(bls.PublicKey(result), bls.SecretKey(private))

proc sign*(key: PrivateKey, message: openArray[byte]): Signature =
  Signature(bls.SecretKey(key).sign(message))

proc verify*(key: PublicKey,
             message: openArray[byte],
             signature: Signature): bool =
  ## TODO: not safe w.r.t. rogue public-key attack. Needs implementation of
  ## modified BLS multi-signature construction as described in:
  ## https://crypto.stanford.edu/~dabo/pubs/papers/BLSmultisig.html
  bls.PublicKey(key).verify(message, bls.Signature(signature))
