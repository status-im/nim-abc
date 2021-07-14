import std/sets
import ./txstore

export sets

type
  History* = object
    genesis*: TxHash
    transactions*: HashSet[TxHash]
    missingTx*: HashSet[TxHash]
    missingAck*: HashSet[AckHash]
    invalidTx*: HashSet[TxHash]
    invalidAck*: HashSet[AckHash]

func checkValue(store: TxStore, transaction: Transaction): bool =
  var valueIn, valueOut = 0.u256

  for (hash, owner) in transaction.inputs:
    if inputTx =? store[hash]:
      for output in inputTx.outputs:
        if output.owner == owner:
          valueIn += output.value

  for (_, value) in transaction.outputs:
    valueOut += value

  valueIn == valueOut

func next(store: TxStore, history: History, transaction: Transaction): seq[TxHash] =
  for (hash, _) in transaction.inputs:
    if not history.transactions.contains(hash):
      result.add(hash)

func next(store: TxStore, history: History, ack: Ack): seq[TxHash] =
  for hash in ack.transactions:
    if not history.transactions.contains(hash):
      result.add(hash)

func past(store: TxStore, txHash: TxHash, history: var History) =
  if txHash == store.genesis:
    return

  without transaction =? store[txHash]:
    history.missingTx.incl(txHash)
    return

  if not transaction.hasValidSignature or not store.checkValue(transaction):
    history.invalidTx.incl(txHash)
    return

  for hash in store.next(history, transaction):
    history.transactions.incl(hash)
    store.past(hash, history)

func past(store: TxStore, ackHash: AckHash, history: var History) =
  without ack =? store[ackHash]:
    history.missingAck.incl(ackHash)
    return

  if not ack.hasValidSignature:
    history.invalidAck.incl(ackHash)
    return

  if previous =? ack.previous:
    store.past(previous, history)

  for txHash in store.next(history, ack):
    history.transactions.incl(txHash)
    store.past(txHash, history)

func past*(store: TxStore, hash: TxHash|AckHash): History =
  result.genesis = store.genesis
  store.past(hash, result)

func past*(store: TxStore, hashes: varargs[AckHash]): History =
  result.genesis = store.genesis
  for hash in hashes:
    store.past(hash, result)

func isValid*(history: History): bool =
  history.missingTx.len == 0 and
  history.invalidTx.len == 0 and
  history.missingAck.len == 0 and
  history.invalidAck.len == 0
