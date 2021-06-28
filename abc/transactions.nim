import pkg/nimcrypto
import pkg/stint
import ./keys

export stint
export keys

type
  Transaction* = object
    inputs: seq[TxInput]
    outputs: seq[TxOutput]
    signature: Signature
  TxInput* = tuple
    txHash: TxHash
    owner: PublicKey
  TxOutput* = tuple
    owner: PublicKey
    amount: UInt256
  TxHash* = distinct MDigest[256]

func `==`*(a, b: TxHash): bool {.borrow.}

func init*(_: type Transaction,
           inputs: openArray[TxInput],
           outputs: openArray[TxOutput]): Transaction =
  Transaction(inputs: @inputs, outputs: @outputs)

func init*(_: type Transaction,
           outputs: openArray[TxOutput]): Transaction =
  Transaction.init([], outputs)

func inputs*(transaction: Transaction): seq[TxInput] =
  transaction.inputs

func outputs*(transaction: Transaction): seq[TxOutput] =
  transaction.outputs

func toBytes*(hash: TxHash): array[32, byte] =
  MDigest[256](hash).data

func toBytes*(transaction: Transaction): seq[byte] =
  result.add(transaction.inputs.len.uint8)
  for (txHash, owner) in transaction.inputs:
    result.add(txHash.toBytes)
    result.add(owner.toBytes)
  result.add(transaction.outputs.len.uint8)
  for (owner, amount) in transaction.outputs:
    result.add(owner.toBytes)
    result.add(amount.toBytes)

func hash*(transaction: Transaction): TxHash =
  TxHash(sha256.digest(transaction.toBytes))
