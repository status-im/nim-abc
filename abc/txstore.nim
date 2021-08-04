import pkg/questionable
import std/tables
import std/sets
import std/sequtils
import ./transactions
import ./acks
import ./dag
import ./voting

type
  TxStore* = ref object
    genesis: Hash
    transactions: Table[Hash, Transaction]
    acks: Table[Hash, Ack]
    dag: SortedDag[Hash]
    voting: Voting

export questionable
export transactions
export acks

func addToDag(store: TxStore, transaction: Transaction) =
  for input in transaction.inputs:
    store.dag.add(transaction.hash -> input.transaction)

func addToDag(store: TxStore, ack: Ack) =
  if previous =? ack.previous:
    store.dag.add(ack.hash -> previous)
  for transaction in ack.transactions:
    store.dag.add(ack.hash -> transaction)

func calculateYea(store: TxStore, transaction: Transaction, ack: Ack): UInt256 =
  if transaction.validator == ack.validator:
    result = transaction.value

func calculateNay(store: TxStore, transaction: Transaction, ack: Ack): UInt256 =
  for (previousHash, owner) in transaction.inputs:
    without previous =? store.transactions.?[previousHash]:
      continue
    if previous.validator == ack.validator:
      result += previous.outputValue(owner)

func updateVote(store: TxStore, hash: Hash, ack: Ack) =
  without transaction =? store.transactions.?[hash]:
    return

  let yea = store.calculateYea(transaction, ack)
  let nay = store.calculateNay(transaction, ack)

  if yea > 0:
    for candidate in ack.transactions:
      store.voting.voteYea(candidate, hash, yea)

  if nay > 0:
    for candidate in ack.transactions:
      store.voting.voteNay(candidate, hash, nay)

func isConfirmed*(store: TxStore, hash: Hash): bool

func updateVotes(store: TxStore, ack: Ack) =
  var todo = ack.transactions
  for hash in store.dag.visit(ack.hash):
    if todo.len == 0:
      break
    if hash in ack.transactions:
      continue
    store.updateVote(hash, ack)
    todo.keepItIf(not store.isConfirmed(it))

func add*(store: TxStore, transactions: varargs[Transaction]) =
  for transaction in transactions:
    store.transactions[transaction.hash] = transaction
    store.addToDag(transaction)

func add*(store: TxStore, acks: varargs[Ack]) =
  for ack in acks:
    store.acks[ack.hash] = ack
    store.addToDag(ack)
    store.updateVotes(ack)

func new*(_: type TxStore, genesis: Transaction): TxStore =
  let store = TxStore(
    genesis: genesis.hash,
    dag: SortedDag[Hash].new,
    voting: Voting.init(((genesis.value * 2) div 3) + 1)
  )
  store.add(genesis)
  store.voting.confirm(genesis.hash)
  store

func genesis*(store: TxStore): Hash =
  store.genesis

func getTransaction*(store: TxStore, hash: Hash): ?Transaction =
  doAssert hash.kind == HashKind.Tx
  store.transactions.?[hash]

func getAck*(store: TxStore, hash: Hash): ?Ack =
  doAssert hash.kind == HashKind.Ack
  store.acks.?[hash]

func isConfirmed*(store: TxStore, hash: Hash): bool =
  store.voting.isConfirmed(hash)
