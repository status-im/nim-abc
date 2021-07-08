import std/sets
import ./txstore

export sets

type
  History* = object
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

func past(store: TxStore, txHash: TxHash, history: var History) =
  if txHash == store.genesis:
    return

  if transaction =? store[txHash]:
    if transaction.hasValidSignature and store.checkValue(transaction):
      for (hash, _) in transaction.inputs:
        if not history.transactions.contains hash:
          history.transactions.incl(hash)
          store.past(hash, history)
    else:
      history.invalidTx.incl(txHash)
  else:
    history.missingTx.incl(txHash)

func past(store: TxStore, ackHash: AckHash, history: var History) =
  if ack =? store[ackHash]:
    if ack.hasValidSignature:
      if previous =? ack.previous:
        store.past(previous, history)
      for txHash in ack.transactions:
        if not history.transactions.contains txHash:
          history.transactions.incl(txHash)
          store.past(txHash, history)
    else:
      history.invalidAck.incl(ackHash)
  else:
    history.missingAck.incl(ackHash)

func past*(store: TxStore, hash: TxHash|AckHash): History =
  store.past(hash, result)

func past*(store: TxStore, hashes: varargs[AckHash]): History =
  for hash in hashes:
    store.past(hash, result)

func isValid*(history: History): bool =
  history.missingTx.len == 0 and
  history.invalidTx.len == 0 and
  history.missingAck.len == 0 and
  history.invalidAck.len == 0
