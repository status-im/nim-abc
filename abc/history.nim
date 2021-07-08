import std/sets
import ./txstore

export sets

type
  History* = object
    transactions*: HashSet[TxHash]

func past(store: TxStore, txHash: TxHash, history: var History) =
  if transaction =? store[txHash]:
    for (hash, _) in transaction.inputs:
      if not history.transactions.contains hash:
        history.transactions.incl(hash)
        store.past(hash, history)

func past(store: TxStore, ackHash: AckHash, history: var History) =
  if ack =? store[ackHash]:
    if previous =? ack.previous:
      store.past(previous, history)
    for txHash in ack.transactions:
      if not history.transactions.contains txHash:
        history.transactions.incl(txHash)
        store.past(txHash, history)

func past*(store: TxStore, hash: TxHash|AckHash): History =
  store.past(hash, result)

func past*(store: TxStore, hashes: varargs[AckHash]): History =
  for hash in hashes:
    store.past(hash, result)
