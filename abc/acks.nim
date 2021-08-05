import pkg/questionable
import ./hash
import ./keys

export hash
export keys

type
  Ack* = ref object
    previous: ?Hash
    transactions: seq[Hash]
    validator: PublicKey
    hash: Hash
    signature: ?Signature

func toBytes*(ack: Ack): seq[byte] =
  let previous = ack.previous |? Hash.default
  result.add(previous.toBytes)
  result.add(ack.transactions.len.uint8)
  for transaction in ack.transactions:
    result.add(transaction.toBytes)
  result.add(ack.validator.toBytes)

func new(_: type Ack,
         previous: ?Hash,
         transactions: openArray[Hash],
         validator: PublicKey): ?Ack =
  if previous =? previous and previous.kind != HashKind.Ack:
    return none Ack

  if transactions.len == 0:
    return none Ack

  for transaction in transactions:
    if transaction.kind != HashKind.Tx:
      return none Ack

  var ack = Ack(
    previous: previous,
    transactions: @transactions,
    validator: validator
  )
  ack.hash = hash(ack.toBytes, HashKind.Ack)
  some ack

func new*(_: type Ack,
          transactions: openArray[Hash],
          validator: PublicKey): ?Ack =
  Ack.new(Hash.none, transactions, validator)

func new*(_: type Ack,
          previous: Hash,
          transactions: openArray[Hash],
          validator: PublicKey): ?Ack =
  Ack.new(previous.some, transactions, validator)

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

func hash*(ack: Ack): Hash =
  ack.hash

func sign*(key: PrivateKey, ack: var Ack) =
  ack.signature = key.sign(ack.hash.toBytes).some

func hasValidSignature*(ack: Ack): bool =
  without signature =? ack.signature:
    return false

  let message = ack.hash.toBytes
  let signee = ack.validator
  signee.verify(message, signature)
