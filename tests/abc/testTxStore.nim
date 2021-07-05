import abc/txstore
import ./basics
import ./alicebob

suite "Transaction Store":

  let genesis = Transaction.genesis
  let transaction = Transaction.example
  let ack = Ack.example

  test "is initialized with a genesis transaction":
    let store = TxStore.init(genesis)
    check store.hasTx(genesis.hash)
    check store.getTx(genesis.hash) == genesis

  test "stores transactions":
    var store = TxStore.init(genesis)
    check not store.hasTx(transaction.hash)
    store.add(transaction)
    check store.hasTx(transaction.hash)
    check store.getTx(transaction.hash) == transaction

  test "stores acks":
    var store = TxStore.init(genesis)
    check not store.hasAck(ack.hash)
    store.add(ack)
    check store.hasAck(ack.hash)
    check store.getAck(ack.hash) == ack
