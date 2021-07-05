import ./txstore

func past*(store: TxStore, txHash: Hash, accumulator: var seq[Hash]) =
  if transaction =? store.getTx(txHash):
    for (hash, _) in transaction.inputs:
      if not accumulator.contains hash:
        accumulator.add(hash)
        store.past(hash, accumulator)

func past*(store: TxStore, txHash: Hash): seq[Hash] =
  store.past(txHash, result)
