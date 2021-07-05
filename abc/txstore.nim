import std/tables
import ./transactions
import ./acks

type
  TxStore* = object
    genesis: Hash
    transactions: Table[Hash, Transaction]
    acks: Table[Hash, Ack]

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

func genesis*(store: TxStore): Hash =
  store.genesis

func hasTx*(store: TxStore, hash: Hash): bool =
  store.transactions.hasKey(hash)

func hasAck*(store: TxStore, hash: Hash): bool =
  store.acks.hasKey(hash)

func getTx*(store: TxStore, hash: Hash): Transaction =
  store.transactions[hash]

func getAck*(store: TxStore, hash: Hash): Ack =
  store.acks[hash]
