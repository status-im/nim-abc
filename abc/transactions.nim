import std/sequtils
import std/sugar
import pkg/nimcrypto
import pkg/stint
import pkg/questionable
import ./keys
import ./helpers
import ./hash

export stint
export keys
export hash

type
  Transaction* = object
    inputs: seq[TxInput]
    outputs: seq[TxOutput]
    validator: PublicKey
    signature: Signature
  TxInput* = tuple
    transaction: Hash
    owner: PublicKey
  TxOutput* = tuple
    owner: PublicKey
    value: UInt256

func init*(_: type Transaction,
           inputs: openArray[TxInput],
           outputs: openArray[TxOutput],
           validator: PublicKey): ?Transaction =
  if outputs.len == 0:
    return none Transaction

  if outputs.map(output => output.owner).hasDuplicates:
    return none Transaction

  for input in inputs:
    if input.transaction.kind != HashKind.Tx:
      return none Transaction

  some Transaction(inputs: @inputs, outputs: @outputs, validator: validator)

func init*(_: type Transaction,
           outputs: openArray[TxOutput],
           validator: PublicKey): ?Transaction =
  Transaction.init([], outputs, validator)

func inputs*(transaction: Transaction): seq[TxInput] =
  transaction.inputs

func outputs*(transaction: Transaction): seq[TxOutput] =
  transaction.outputs

func signature*(transaction: Transaction): Signature =
  transaction.signature

func validator*(transaction: Transaction): PublicKey =
  transaction.validator

func add*(transaction: var Transaction, signature: Signature) =
  transaction.signature = aggregate(transaction.signature, signature)

func toBytes*(transaction: Transaction): seq[byte] =
  result.add(transaction.inputs.len.uint8)
  for (txHash, owner) in transaction.inputs:
    result.add(txHash.toBytes)
    result.add(owner.toBytes)
  result.add(transaction.outputs.len.uint8)
  for (owner, value) in transaction.outputs:
    result.add(owner.toBytes)
    result.add(value.toBytes)
  result.add(transaction.validator.toBytes)

func hash*(transaction: Transaction): Hash =
  hash(transaction.toBytes, HashKind.Tx)

func sign*(key: PrivateKey, transaction: var Transaction) =
  transaction.add(key.sign(transaction.hash.toBytes))

func hasValidSignature*(transaction: Transaction): bool =
  if transaction.inputs.len == 0:
    return false

  var signees: seq[PublicKey]
  for (_, owner) in transaction.inputs:
    signees.add(owner)
  let message = transaction.hash.toBytes
  let signature = transaction.signature
  let signee = aggregate(signees)
  signee.verify(message, signature)
