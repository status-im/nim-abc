import pkg/questionable
import abc

let a, b, v = PrivateKey.random

proc alice*(_: type PrivateKey): PrivateKey =
  a

proc bob*(_: type PrivateKey): PrivateKey =
  b

proc victor*(_: type PrivateKey): PrivateKey =
  v

proc alice*(_: type PublicKey): PublicKey =
  a.toPublicKey

proc bob*(_: type PublicKey): PublicKey =
  b.toPublicKey

proc victor*(_: type PublicKey): PublicKey =
  v.toPublicKey

proc genesis*(_: type Transaction): Transaction =
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  !Transaction.init({alice: 100.u256, bob: 100.u256}, victor)
