import pkg/questionable
import abc

let a, b, v1, v2 = PrivateKey.random

proc alice*(_: type PrivateKey): PrivateKey =
  a

proc bob*(_: type PrivateKey): PrivateKey =
  b

proc victor*(_: type PrivateKey): PrivateKey =
  v1

proc vanna*(_: type PrivateKey): PrivateKey =
  v2

proc alice*(_: type PublicKey): PublicKey =
  PrivateKey.alice.toPublicKey

proc bob*(_: type PublicKey): PublicKey =
  PrivateKey.bob.toPublicKey

proc victor*(_: type PublicKey): PublicKey =
  PrivateKey.victor.toPublicKey

proc vanna*(_: type PublicKey): PublicKey =
  PrivateKey.vanna.toPublicKey

proc genesis*(_: type Transaction): Transaction =
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  !Transaction.new({alice: 100.u256, bob: 100.u256}, victor)
