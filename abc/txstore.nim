import pkg/questionable
import std/tables
import ./transactions
import ./acks

type
  TxStore* = ref object
    genesis: TxHash
    transactions: Table[TxHash, Transaction]
    acks: Table[AckHash, Ack]

export questionable
export transactions
export acks

func add*(store: TxStore, transactions: varargs[Transaction]) =
  for transaction in transactions:
    store.transactions[transaction.hash] = transaction

func add*(store: TxStore, acks: varargs[Ack]) =
  for ack in acks:
    store.acks[ack.hash] = ack

func new*(_: type TxStore, genesis: Transaction): TxStore =
  let store = TxStore(genesis: genesis.hash)
  store.add(genesis)
  store

func genesis*(store: TxStore): TxHash =
  store.genesis

func `[]`*(store: TxStore, hash: TxHash): ?Transaction =
  store.transactions.?[hash]

func `[]`*(store: TxStore, hash: AckHash): ?Ack =
  store.acks.?[hash]
