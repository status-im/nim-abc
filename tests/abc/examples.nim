import std/random
import pkg/questionable
import abc
import abc/acks
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
  let carol = PublicKey.example
  let victor = PublicKey.victor
  let genesis = Transaction.genesis
  let amount = rand(100).u256
  var transaction = !Transaction.new(
    {genesis.hash: alice},
    {carol: amount, alice: 100.u256 - amount},
    victor
  )
  transaction

proc example*(_: type Ack): Ack =
  let tx1, tx2 = Transaction.example
  let validator = PublicKey.example
  !Ack.new([tx1.hash, tx2.hash], validator)
