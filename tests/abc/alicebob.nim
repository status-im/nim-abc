import pkg/questionable
import abc

let a, b = PrivateKey.random

proc alice*(_: type PrivateKey): PrivateKey =
  a

proc bob*(_: type PrivateKey): PrivateKey =
  b

proc alice*(_: type PublicKey): PublicKey =
  a.toPublicKey

proc bob*(_: type PublicKey): PublicKey =
  b.toPublicKey

proc genesis*(_: type Transaction): Transaction =
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  !Transaction.init({alice: 100.u256, bob: 100.u256})
