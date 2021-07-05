import pkg/questionable
import ./txstore

func checkValue(store: TxStore, transaction: Transaction): bool =
  var valueIn, valueOut = 0.u256

  for (hash, owner) in transaction.inputs:
    for output in store.getTx(hash).outputs:
      if output.owner == owner:
        valueIn += output.value

  for (_, value) in transaction.outputs:
    valueOut += value

  valueIn == valueOut

func hasValidTx*(store: TxStore, txHash: Hash): bool =
  if txHash == store.genesis:
    return true

  if not store.hasTx(txHash):
    return false

  let transaction = store.getTx(txHash)

  if not transaction.hasValidSignature:
    return false

  for (hash, _) in transaction.inputs:
    if not store.hasValidTx(hash):
      return false

  store.checkValue(transaction)

func hasValidAck*(store: TxStore, ackHash: Hash): bool =
  if not store.hasAck(ackHash):
    return false

  let ack = store.getAck(ackHash)

  if not ack.hasValidSignature:
    return false

  if previous =? ack.previous:
    if not store.hasValidAck(previous):
      return false

  for transaction in ack.transactions:
    if not store.hasValidTx(transaction):
      return false

  true
