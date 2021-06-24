import pkg/blscurve as bls
import pkg/nimcrypto

type
  PrivateKey* = distinct bls.SecretKey
  PublicKey* = distinct bls.PublicKey

proc `==`*(a, b: PrivateKey): bool {.borrow.}
proc `==`*(a, b: PublicKey): bool {.borrow.}

proc random*(_: type PrivateKey): PrivateKey =
  var seed = newSeq[byte](64)
  doAssert randomBytes(seed) == seed.len
  doAssert deriveMasterSecretKey(bls.SecretKey(result), seed)
  burnArray(seed)

proc erase*(key: var PrivateKey) =
  burnMem(key)

proc toPublicKey*(private: PrivateKey): PublicKey =
  doAssert publicFromSecret(bls.PublicKey(result), bls.SecretKey(private))

