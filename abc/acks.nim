import pkg/questionable
import ./hash
import ./keys

export hash
export keys

type
  Ack* = object
    previous: ?Hash
    transactions: seq[Hash]
    signature: ?Signature

func init*(_: type Ack, transactions: openArray[Hash]): ?Ack =
  if transactions.len == 0:
    return none Ack

  some Ack(transactions: @transactions)

func init*(_: type Ack,
           previous: Hash,
           transactions: openArray[Hash]): ?Ack =
  without var ack =? Ack.init(transactions):
    return none Ack

  ack.previous = previous.some
  some ack

func previous*(ack: Ack): ?Hash =
  ack.previous

func transactions*(ack: Ack): seq[Hash] =
  ack.transactions

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

func hash*(ack: Ack): Hash =
  hash(ack.toBytes)

func sign*(key: PrivateKey, ack: var Ack) =
  ack.signature = key.sign(ack.hash.toBytes).some
