import std/tables
import ./transactions

type
  TxStore* = object
    genesis: Hash
    transactions: Table[Hash, Transaction]

export transactions

func add*(store: var TxStore, transactions: varargs[Transaction]) =
  for transaction in transactions:
    store.transactions[transaction.hash] = transaction

func init*(_: type TxStore, genesis: Transaction): TxStore =
  result.genesis = genesis.hash
  result.add(genesis)

func genesis*(store: TxStore): Hash =
  store.genesis

func hasTx*(store: TxStore, hash: Hash): bool =
  store.transactions.hasKey(hash)

func `[]`*(store: TxStore, hash: Hash): Transaction =
  store.transactions[hash]
