import pkg/questionable
import ./txstore

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

func hasValidTx*(store: TxStore, txHash: TxHash): bool =
  if txHash == store.genesis:
    return true

  without transaction =? store[txHash]:
    return false

  if not transaction.hasValidSignature:
    return false

  for (hash, _) in transaction.inputs:
    if not store.hasValidTx(hash):
      return false

  store.checkValue(transaction)

func hasValidAck*(store: TxStore, ackHash: AckHash): bool =
  without ack =? store[ackHash]:
    return false

  if not ack.hasValidSignature:
    return false

  if previous =? ack.previous:
    if not store.hasValidAck(previous):
      return false

  for transaction in ack.transactions:
    if not store.hasValidTx(transaction):
      return false

  true

func hasValidAcks*(store: TxStore, hashes: varargs[AckHash]): bool =
  for hash in hashes:
    if not store.hasValidAck(hash):
      return false
  true
