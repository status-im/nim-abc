import pkg/questionable
import abc/keys
import abc/transactions
import abc/wallet

proc example*(_: type PrivateKey): PrivateKey =
  PrivateKey.random

proc example*(_: type PublicKey): PublicKey =
  PrivateKey.example.toPublicKey

proc example*(_: type Transaction): Transaction =
  let alice, bob = PublicKey.example
  let genesis = !Transaction.init({alice: 32.u256, bob: 10.u256})
  !Transaction.init({genesis.hash: alice}, {alice: 2.u256, bob: 30.u256})

proc example*(_: type Wallet): Wallet =
  let key = PrivateKey.example
  Wallet.init(key)
