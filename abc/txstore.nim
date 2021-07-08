import pkg/questionable
import std/tables
import ./transactions
import ./acks

type
  TxStore* = object
    genesis: TxHash
    transactions: Table[TxHash, Transaction]
    acks: Table[AckHash, Ack]

export questionable
export transactions
export acks

func add*(store: var TxStore, transactions: varargs[Transaction]) =
  for transaction in transactions:
    store.transactions[transaction.hash] = transaction

func add*(store: var TxStore, acks: varargs[Ack]) =
  for ack in acks:
    store.acks[ack.hash] = ack

func init*(_: type TxStore, genesis: Transaction): TxStore =
  result.genesis = genesis.hash
  result.add(genesis)

func genesis*(store: TxStore): TxHash =
  store.genesis

func getTx*(store: TxStore, hash: TxHash): ?Transaction =
  store.transactions.?[hash]

func getAck*(store: TxStore, hash: AckHash): ?Ack =
  store.acks.?[hash]
