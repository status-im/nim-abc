import pkg/questionable
import std/tables
import ./transactions
import ./acks

type
  TxStore* = ref object
    genesis: Hash
    transactions: Table[Hash, Transaction]
    acks: Table[Hash, Ack]

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

func genesis*(store: TxStore): Hash =
  store.genesis

func getTransaction*(store: TxStore, hash: Hash): ?Transaction =
  doAssert hash.kind == HashKind.Tx
  store.transactions.?[hash]

func getAck*(store: TxStore, hash: Hash): ?Ack =
  doAssert hash.kind == HashKind.Ack
  store.acks.?[hash]
