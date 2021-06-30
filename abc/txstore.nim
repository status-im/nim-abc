import std/tables
import std/hashes
import ./transactions

type
  TxStore* = object
    genesis: TxHash
    transactions: Table[TxHash, Transaction]

export transactions

func hash(h: TxHash): Hash =
  h.toBytes.hash

func add*(store: var TxStore, transactions: varargs[Transaction]) =
  for transaction in transactions:
    store.transactions[transaction.hash] = transaction

func init*(_: type TxStore, genesis: Transaction): TxStore =
  result.genesis = genesis.hash
  result.add(genesis)

func genesis*(store: TxStore): TxHash =
  store.genesis

func hasTx*(store: TxStore, hash: TxHash): bool =
  store.transactions.hasKey(hash)

func `[]`*(store: TxStore, hash: TxHash): Transaction =
  store.transactions[hash]
