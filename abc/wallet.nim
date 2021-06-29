import ./keys
import ./transactions

export keys

type
  Wallet* = object
    key: PrivateKey

func init*(_: type Wallet, key: PrivateKey): Wallet =
  Wallet(key: key)

func id*(wallet: Wallet): PublicKey =
  wallet.key.toPublicKey

func sign*(wallet: Wallet, transaction: var Transaction) =
  wallet.key.sign(transaction)
