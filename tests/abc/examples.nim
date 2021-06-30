import std/random
import pkg/questionable
import abc
import ./alicebob

proc example*(_: type PrivateKey): PrivateKey =
  PrivateKey.random

proc example*(_: type PublicKey): PublicKey =
  PrivateKey.example.toPublicKey

proc example*(_: type Wallet): Wallet =
  let key = PrivateKey.example
  Wallet.init(key)

proc example*(_: type Transaction): Transaction =
  let alice = PublicKey.alice
  let bob = PublicKey.bob
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  let amount = rand(100).u256
  var transaction = !Transaction.init(
    {genesis.hash: alice},
    {bob: amount, alice: 100.u256 - amount},
    victor
  )
  transaction
