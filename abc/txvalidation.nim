import ./txstore

func checkValue(store: TxStore, transaction: Transaction): bool =
  var valueIn, valueOut = 0.u256

  for (hash, owner) in transaction.inputs:
    for output in store[hash].outputs:
      if output.owner == owner:
        valueIn += output.value

  for (_, value) in transaction.outputs:
    valueOut += value

  valueIn == valueOut

func hasValidTx*(store: TxStore, hash: TxHash): bool =
  if hash == store.genesis:
    return true

  if not store.hasTx(hash):
    return false

  let transaction = store[hash]

  if not transaction.hasValidSignature:
    return false

  for (hash, _) in transaction.inputs:
    if not store.hasValidTx(hash):
      return false

  store.checkValue(transaction)
