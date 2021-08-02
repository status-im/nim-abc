import abc/txstore
import ./basics
import ./alicebob

suite "Transaction Store":

  let genesis = Transaction.genesis
  let transaction = Transaction.example
  let ack = Ack.example

  test "is initialized with a genesis transaction":
    let store = TxStore.new(genesis)
    check store.getTransaction(genesis.hash) == genesis.some

  test "stores transactions":
    let store = TxStore.new(genesis)
    check store.getTransaction(transaction.hash).isNone
    store.add(transaction)
    check store.getTransaction(transaction.hash) == transaction.some

  test "stores acks":
    let store = TxStore.new(genesis)
    check store.getAck(ack.hash).isNone
    store.add(ack)
    check store.getAck(ack.hash) == ack.some
