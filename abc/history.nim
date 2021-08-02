import std/sets
import ./txstore

export sets

type
  History* = object
    genesis*: Hash
    transactions*: HashSet[Hash]
    missing*: HashSet[Hash]
    invalid*: HashSet[Hash]

func checkValue(store: TxStore, transaction: Transaction): bool =
  var valueIn, valueOut = 0.u256

  for (hash, owner) in transaction.inputs:
    if inputTx =? store.getTransaction(hash):
      for output in inputTx.outputs:
        if output.owner == owner:
          valueIn += output.value

  for (_, value) in transaction.outputs:
    valueOut += value

  valueIn == valueOut

func next(store: TxStore, history: History, transaction: Transaction): seq[Hash] =
  for (hash, _) in transaction.inputs:
    if not history.transactions.contains(hash):
      result.add(hash)

func next(store: TxStore, history: History, ack: Ack): seq[Hash] =
  for hash in ack.transactions:
    if not history.transactions.contains(hash):
      result.add(hash)

func past(store: TxStore, hash: Hash, history: var History) =
  case hash.kind
  of HashKind.Tx:
    if hash == store.genesis:
      return

    without transaction =? store.getTransaction(hash):
      history.missing.incl(hash)
      return

    if not transaction.hasValidSignature or not store.checkValue(transaction):
      history.invalid.incl(hash)

    for hash in store.next(history, transaction):
      history.transactions.incl(hash)
      store.past(hash, history)
  of HashKind.Ack:
    without ack =? store.getAck(hash):
      history.missing.incl(hash)
      return

    if not ack.hasValidSignature:
      history.invalid.incl(hash)

    if previous =? ack.previous:
      store.past(previous, history)

    for txHash in store.next(history, ack):
      history.transactions.incl(txHash)
      store.past(txHash, history)

func past*(store: TxStore, hash: Hash): History =
  result.genesis = store.genesis
  store.past(hash, result)

func past*(store: TxStore, hashes: varargs[Hash]): History =
  result.genesis = store.genesis
  for hash in hashes:
    store.past(hash, result)

func isValid*(history: History): bool =
  history.missing.len == 0 and
  history.invalid.len == 0
