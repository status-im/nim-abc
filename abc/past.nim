import ./txstore

func past(store: TxStore, txHash: TxHash, accumulator: var seq[TxHash]) =
  if transaction =? store[txHash]:
    for (hash, _) in transaction.inputs:
      if not accumulator.contains hash:
        accumulator.add(hash)
        store.past(hash, accumulator)

func past(store: TxStore, ackHash: AckHash, accumulator: var seq[TxHash]) =
  if ack =? store[ackHash]:
    if previous =? ack.previous:
      store.past(previous, accumulator)
    for txHash in ack.transactions:
      if not accumulator.contains txHash:
        accumulator.add(txHash)
        store.past(txHash, accumulator)

func past*(store: TxStore, hash: TxHash|AckHash): seq[TxHash] =
  store.past(hash, result)

func past*(store: TxStore, hashes: varargs[AckHash]): seq[TxHash] =
  for hash in hashes:
    store.past(hash, result)
