import pkg/questionable
import ./hash

export hash

type
  Ack* = object
    previous: ?Hash
    transactions: seq[Hash]

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

func toBytes*(ack: Ack): seq[byte] =
  let previous = ack.previous |? Hash.default
  result.add(previous.toBytes)
  result.add(ack.transactions.len.uint8)
  for transaction in ack.transactions:
    result.add(transaction.toBytes)

func hash*(ack: Ack): Hash =
  hash(ack.toBytes)
