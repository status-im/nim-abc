import ./txstore

func past*(store: TxStore, txHash: TxHash, accumulator: var seq[TxHash]) =
  if transaction =? store[txHash]:
    for (hash, _) in transaction.inputs:
      if not accumulator.contains hash:
        accumulator.add(hash)
        store.past(hash, accumulator)

func past*(store: TxStore, txHash: TxHash): seq[TxHash] =
  store.past(txHash, result)
