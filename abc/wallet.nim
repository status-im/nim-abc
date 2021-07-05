import ./keys
import ./transactions
import ./acks

export keys
export transactions
export acks

type
  Wallet* = object
    key: PrivateKey

func init*(_: type Wallet, key: PrivateKey): Wallet =
  Wallet(key: key)

func id*(wallet: Wallet): PublicKey =
  wallet.key.toPublicKey

func sign*(wallet: Wallet, transaction: var Transaction) =
  wallet.key.sign(transaction)

func sign*(wallet: Wallet, ack: var Ack) =
  wallet.key.sign(ack)
