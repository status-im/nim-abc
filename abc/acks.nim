import pkg/questionable
import ./hash
import ./keys

export hash
export keys

type
  Ack* = object
    previous: ?Hash
    transactions: seq[Hash]
    validator: PublicKey
    signature: ?Signature

func init*(_: type Ack,
           transactions: openArray[Hash],
           validator: PublicKey): ?Ack =
  if transactions.len == 0:
    return none Ack

  some Ack(transactions: @transactions, validator: validator)

func init*(_: type Ack,
           previous: Hash,
           transactions: openArray[Hash],
           validator: PublicKey): ?Ack =
  without var ack =? Ack.init(transactions, validator):
    return none Ack

  ack.previous = previous.some
  some ack

func previous*(ack: Ack): ?Hash =
  ack.previous

func transactions*(ack: Ack): seq[Hash] =
  ack.transactions

func validator*(ack: Ack): PublicKey =
  ack.validator

func signature*(ack: Ack): ?Signature =
  ack.signature

func `signature=`*(ack: var Ack, signature: Signature) =
  ack.signature = signature.some

func toBytes*(ack: Ack): seq[byte] =
  let previous = ack.previous |? Hash.default
  result.add(previous.toBytes)
  result.add(ack.transactions.len.uint8)
  for transaction in ack.transactions:
    result.add(transaction.toBytes)
  result.add(ack.validator.toBytes)

func hash*(ack: Ack): Hash =
  hash(ack.toBytes)

func sign*(key: PrivateKey, ack: var Ack) =
  ack.signature = key.sign(ack.hash.toBytes).some

func hasValidSignature*(ack: Ack): bool =
  without signature =? ack.signature:
    return false

  let message = ack.hash.toBytes
  let signee = ack.validator
  signee.verify(message, signature)
